#import "SSYFileDropView.h"

@interface SSYFileDropView ()

@property (copy) NSString* filePath ;

@end


@implementation SSYFileDropView

@synthesize filePath = m_filePath ;


- (void)dealloc {
    [m_filePath release] ;
    
    [super dealloc] ;
}

//  When I first wrote this subclass, -target and -action would return
//  nil even after -setTarget and -setAction.  The reason is given in
//  ADC Home > Reference Library > Guides > Cocoa > Events & Other Input > Action Messages.
//  "NSControl provides methods for setting and using the target object and the action method.
//  However, these methods require that an NSControl’s cell (or cells) be NSActionCells or
//  custom cells that hold action and target as instance variables and can respond to the
//  NSControl methods."
//  The fix is found in http://www.cocoabuilder.com/archive/message/cocoa/2003/4/14/75930
//  FROM : Pierre-Loïc Raynaud  DATE : Mon Apr 14 11:45:55 2003
//  If you wrote a NSControl subclass without using cells, and you want to 
//  use target/actions, you just have to link your Control with a 
//  NSActionCell by adding in your NSControl subclass implementation:
+ (Class) cellClass {
    return [NSActionCell class];
}
// Like magic, it works!

// This method is never invoked ?!?
- (id)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	if (self) {
		[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]] ;
		[image registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]] ;
	}
	return self ;
}


- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]] ;
        [self display] ;
	}
	return self;
}

- (void)setPath:(NSString*)path
{
	// Set instance variable
	[self setFilePath:path];

	NSString* displayName ;
	NSImage* displayImage ;
	NSString* displayToolTip ;
	
	if (path) {
		// Path is not specified
		
		// displayName
		displayName = NSLocalizedString(@"dropFileOrDriveHere", nil) ;
		
		// image
		displayImage = [NSImage imageNamed:@"DropItHere"] ;
		
		// toolTip
		displayToolTip = NSLocalizedString(@"youNeedADestinationToBackUpYourDataTo", nil) ;
	}
	else {
		NSFileManager* fm = [NSFileManager defaultManager] ;
		
		if ([fm fileExistsAtPath:path]) {
			// Path is specified and is available
			
			// image
			displayImage = [[NSWorkspace sharedWorkspace] iconForFile:path] ;
			if (!displayImage) {
				displayImage = [NSImage imageNamed:@"DiskOrFileNotAvailable"] ;
			}
			[displayImage setScalesWhenResized:YES] ;
			[displayImage setSize:NSMakeSize(48.0, 48.0)] ;
			
			// displayName
			displayName = [fm displayNameAtPath:path] ;
			
			// toolTip
			displayToolTip = path ;
		}
		else {
			// Path is specified but is not available

			// image
			displayImage = [NSImage imageNamed:@"DiskOrFileNotAvailable"] ;
			
			// displayName
			displayName = [NSString stringWithFormat:@"%@:\n%@",
				NSLocalizedString(@"notAvailable", nil),
				[[NSFileManager defaultManager] displayNameAtPath:path] ] ;

			// toolTip
			displayToolTip = path ;
		}
	}
	
	// Write to UI
	[label setStringValue:displayName] ;	
	[image setImage:displayImage] ;
	[self setToolTip: displayToolTip] ;

	[self display] ;
}

- (NSString*)path {
	return [self filePath] ;
}

- (void)setObjectValue:(id)objectValue {
	[self setPath:objectValue] ;
}

- (id)objectValue {
	return [self path] ;
}


//	Draw method is overridden to do drop highlighing
- (void)drawRect:(NSRect)rect
{
	// Draw the normal frame first
	[super drawRect:rect];
	
	// Then do the highlighting
	if (highlight) {
		[[NSColor grayColor] set];
		[NSBezierPath setDefaultLineWidth:5];
		[NSBezierPath strokeRect:rect];
	}
}

//////////////////////////////////
// Dragging Destination methods
//////////////////////////////////

// Called whenever a drag enters our drop zone:
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	highlight = YES;
	[self setNeedsDisplay:YES];
	return NSDragOperationCopy; // Accept data as a copy operation
}

// Called whenever a drag exits our drop zone
- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	highlight = NO;
	[self setNeedsDisplay:YES];
}

// Method to determine if we can accept the drop
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	// Drag is finished, so remove any highlighting
	highlight = NO;
	[self setNeedsDisplay:YES];
	
	// Later, fix this verify that the dragged item is a volume
	// But for now, just
	return YES;
} 

// This is to actually accept the drop
- (BOOL)performDragOperation:(id <NSDraggingInfo>)info
{
	NSPasteboard *pboard = [info draggingPasteboard];
	
	
	// Dragging Filenames From Finder or the List
	if ([[pboard types] containsObject:NSFilenamesPboardType]) {
		
		NSArray * files = [pboard propertyListForType:NSFilenamesPboardType];
		NSEnumerator * enumerator = [files objectEnumerator];
		NSString * filePath;
		
		// If the first file exists, process and display the result, and
		// then tell super to send our action to our target
		if (filePath = [enumerator nextObject]) {
			[self setPath:filePath];
			[super sendAction:[self action] to:[self target]] ;
		}
		
		return YES;
	}
	
	return NO;
}


@end