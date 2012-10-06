#import "SSRadioButtonCell.h"

#define DEFAULT_BUTTON_SPACING 1.0
#define END_INSET 2.0

@implementation SSRadioButtonCell

+ (void)initialize {
    [self setKeys:[NSArray arrayWithObjects:@"numberOfButtons", @"widths", nil]
    triggerChangeNotificationsForDependentKey:@"widths"];

    [self setKeys:[NSArray arrayWithObjects:@"numberOfButtons", @"widths", nil]
    triggerChangeNotificationsForDependentKey:@"indexedWidths"];	
}

/*
// Implemented this NSFormatter method for debugging.  Doesn't make any sense, but I get
// this message when dropping an SSRadioButtonCell onto an NSTableColumn in Interface Builder.
- (NSAttributedString*)attributedStringForObjectValue:(id)object withDefaultAttributes:(NSDictionary*)attributes {
	NSAttributedString* as = [[NSAttributedString alloc] initWithString:@"foob SSRadioButtonCell"] ;
	return [as autorelease] ;
}
*/

- (void)setObjectValue:(id <NSCopying>)object {
	if (object) {
		[super setObjectValue:object] ;
	}
}

- (void)setSelectedImage:(NSImage*)newImage {
	if (_selectedImage != newImage) {
		[_selectedImage release];
		_selectedImage = [newImage copy];
	}
}

- (NSImage*)selectedImage { 
	return _selectedImage ;
}

- (void)setDeselectedImage:(NSImage*)newImage {
	if (_deselectedImage != newImage) {
		[_deselectedImage release];
		_deselectedImage = [newImage copy];
	}
}

- (NSImage*)deselectedImage {
	return _deselectedImage ;
}

- (void)setWidths:(NSMutableArray*)newWidths {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"WidthsWillChange" object:nil] ;
	if (_widths != newWidths) {
		[_widths release];
		_widths = [newWidths mutableCopy] ;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"WidthsDidChange" object:nil] ;
}

- (NSMutableArray*)widths {
	return _widths ;
}


- (void)setWidth:(CGFloat)width forSegment:(NSInteger)segment {
	NSMutableArray* widths = [self widths] ;
	NSInteger widthsCount = [widths count] ;
	if ((segment >= 0) && (segment < widthsCount)) {
		CGFloat endInset =  ((segment==0) || (segment==(widthsCount-1)))
		? END_INSET : 0.0 ;
			
		
		NSNumber* widthNumber = [NSNumber numberWithDouble:(width - endInset)] ;
		[widths replaceObjectAtIndex:segment withObject:widthNumber] ;
	}
}

- (void)triggerKVO {
	[self setWidths:[self widths]] ;
}

// Probably NSCoder protocol conformance is needed for archiving by Interface Builder.
- (id)initWithCoder:(NSCoder*)decoder {
    self = [super initWithCoder:decoder];
    
    _selectedImage = [[decoder decodeObjectForKey:@"selectedImage"] retain] ;
    _deselectedImage = [[decoder decodeObjectForKey:@"deselectedImage"] retain] ;
	_widths = [[decoder decodeObjectForKey:@"widths"] retain] ;
	
	_numberOfButtons = [_widths count] ;
    
    
	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder {
    [super encodeWithCoder:encoder];
    
    [encoder encodeObject:[self selectedImage] forKey:@"selectedImage"] ;
    [encoder encodeObject:[self deselectedImage] forKey:@"deselectedImage"] ;
    [encoder encodeObject:[self widths] forKey:@"widths"] ;
    
    return;
}


// Documentation
// Control and Cell Programming Topics for Cocoa
//    Subclassing NSCell
// makes the following stupidly vague statement:
// "If the subclass contains instance variables that hold pointers to objects,
// consider overriding copyWithZone: to duplicate the objects. The default
// version copies only pointers to the objects."
// What the hell do them mean by "consider"?  This is supposed to be 
// technical documentation, not a poetry class.  Well,
// it turns out that, if this cell is used in an NSTableColumn at least,
// copies seem to be made whenever the cell is clicked.
// Therefore, if you don't implement the following, you get frequent crashes.
- (id) copyWithZone:(NSZone*)zone {
    SSRadioButtonCell *cellCopy = [super copyWithZone:zone];
	
    // For explanation of this see:
	// Memory Management Programming Guide for Cocoa
	//    Implementing Object Copy
	//        Using NSCopyObject()
	cellCopy->_selectedImage = nil;
    [cellCopy setSelectedImage:[self selectedImage]];
	cellCopy->_deselectedImage = nil;
    [cellCopy setDeselectedImage:[self deselectedImage]];
	cellCopy->_widths = nil ;
	[cellCopy setWidths:[self widths] ] ;

	cellCopy->_currentFrameInControlView = _currentFrameInControlView ;
	cellCopy->_numberOfButtons = _numberOfButtons ;

	return cellCopy;
}

- (void)setEnabled:(BOOL)enabled {
}

- (id) init {
	self = [super init] ;
	if (self != nil) {
		// Since -[NSImage imageNamed:] does not work in frameworks for some reason,
		// we have to dig for image resources with our bare hands...
		NSBundle* bundle = [NSBundle bundleForClass:[self class]];
		NSString* imagePath ;
		NSImage* image ;

		[self setType:NSImageCellType] ;
		// The above does not "take" until you set the image
		
		imagePath = [NSBundle pathForResource:@"SSRadioButtonCellIcon" ofType:@"tiff" 
								  inDirectory:[bundle bundlePath]];
		image = [[NSImage alloc] initByReferencingFile:imagePath];
		[self setImage:image] ;
		[image release] ;
		
		imagePath = [NSBundle pathForResource:@"RadioButtonSelectedSmall" ofType:@"png" 
								  inDirectory:[bundle bundlePath]];
		image = [[NSImage alloc] initByReferencingFile:imagePath];
		[self setSelectedImage:image] ;
		[image release] ;
		
		imagePath = [NSBundle pathForResource:@"RadioButtonDeselectedSmall" ofType:@"png" 
								  inDirectory:[bundle bundlePath]];
		image = [[NSImage alloc] initByReferencingFile:imagePath];
		[self setDeselectedImage:image] ;
		[image release] ;
		
		[self setContinuous:YES] ;
		[self setWidths:[NSMutableArray arrayWithCapacity:16]] ;

		// Set to a harmless default value:
		[self setObjectValue:[NSNumber numberWithInteger:1]] ;
	}
	return self;
}

- (void) dealloc {
    [_selectedImage release] ;
    [_deselectedImage release] ;
	[_widths release] ;
	
	[super setObjectValue:nil] ;
    [super dealloc] ;
}


- (id)defaultObjectValueAtIndex:(NSInteger)index {
	return [[[SSRadioButtonCell alloc] init] autorelease] ;
}

- (id)stringForObjectValue:(id)object {
	return [object description] ;
}


- (void)setNumberOfButtons:(NSInteger)x {
	_numberOfButtons = x ;
	NSMutableArray* widths = [self widths] ;
	NSInteger currentWidthsCount = [widths count] ;
	CGFloat defaultWidth = [[self selectedImage] size].width + DEFAULT_BUTTON_SPACING ;
	NSNumber* defaultWidthNumber = [NSNumber numberWithDouble:defaultWidth] ;
	NSInteger i ;
	
	// If requested number is less than current, add new default widths
	for (i=currentWidthsCount; i<x; i++) {
		[widths addObject:defaultWidthNumber] ;
	}
	
	// If requested number is greater than current, remove widths
	while ([widths count] > x) {
		[widths removeLastObject] ;
	}
	
	[self setWidths:widths] ;
}

- (NSInteger)numberOfButtons {
	return _numberOfButtons ;
}

// I implemented this to see if it would be invoked after dropping in
// Interface Builder, but it never gets invoked by IB.
// It does get invoked when the app runs, in lieu of drawInteriorWithFrame:  ARGHHHH!!
/* - (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	[controlView lockFocus];
	
	NSImage* image = [self image] ;
	[image setFlipped: [controlView isFlipped]];
	[image drawInRect:cellFrame
			 fromRect:NSMakeRect(0,
								 0,
								 NSWidth(cellFrame),
								 NSHeight(cellFrame))
			operation:NSCompositeSourceOver fraction:1.0] ;
				
	[controlView unlockFocus];
}
 */

// This method is invoked to draw the cell when it is instantiated and
// run in an actual application (i.e., not in Interface Builder).
- (void) drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {    
    NSNumber *objectValue = [self objectValue];

    if (objectValue) {
		[controlView lockFocus] ;
		
		NSInteger selectedIndex = [objectValue integerValue] ;
		NSInteger i ;
		
		NSImage* selectedImage = [self selectedImage] ;
		NSImage* deselectedImage = [self deselectedImage] ;
		NSArray* widths = [self widths] ;
		CGFloat x = NSMinX(cellFrame) ; // will increase in loop
		CGFloat verticalInset = (NSHeight(cellFrame) - [selectedImage size].height)/2 + 1.0 ;
			// We add the 1.0 because it looks better to be a little closer to the bottom
			// than the top.  More verticalOffset <--> radio button is farther DOWN.
			// Tried 0.55 instead of 1.0 but this made the buttons stretch to elliptical shape
			// with longer axis vertical.  Looked really weird.
		CGFloat y = NSMinY(cellFrame) + verticalInset ;   // will stay constant
		CGFloat height = [selectedImage size].height ;     // will stay constant
		
		for (i = 0; i < [self numberOfButtons]; i++) {
			CGFloat width = [[widths objectAtIndex:i] doubleValue] ;
			NSRect rect = NSMakeRect(x, y, width, height) ;
			if (NSIntersectsRect(rect, cellFrame)) {
				NSRect intersectRect = NSIntersectionRect(rect, cellFrame) ;
				NSImage* image = (i == selectedIndex) ? selectedImage : deselectedImage ;
				CGFloat centeringOffset = (width - [image size].width) / 2  ;
				[image setFlipped: [controlView isFlipped]];
				[image drawInRect:NSOffsetRect(intersectRect, centeringOffset, 0.0)
						 fromRect:NSMakeRect(0,
											 0,
											 NSWidth(intersectRect),
											 NSHeight(intersectRect))
						operation:NSCompositeSourceOver fraction:1.0] ;
			}

			x += width ;
		}

		[controlView unlockFocus];
	}
}

- (BOOL) trackMouse:(NSEvent*)theEvent
			 inRect:(NSRect)cellFrame
			 ofView:(NSView*)controlView
	   untilMouseUp:(BOOL)untilMouseUp {
    _currentFrameInControlView = [self drawingRectForBounds:cellFrame];
    return [super trackMouse:theEvent
					  inRect:cellFrame
					  ofView:controlView
				untilMouseUp:untilMouseUp] ;
}

- (BOOL) startTrackingAt:(NSPoint)startPoint
				  inView:(NSView*)controlView {
    [super startTrackingAt:startPoint
					inView:controlView] ;
    return YES;
}

- (BOOL) continueTracking:(NSPoint)lastPoint
					   at:(NSPoint)currentPoint
				   inView:(NSView *)controlView {
    if ([super continueTracking:lastPoint
							 at:currentPoint
						 inView: controlView]) {
        NSNumber* newObjectValue = [self calculateSelectionForPoint:currentPoint
															 inView: controlView] ;
		[self setObjectValue:newObjectValue] ;
    }

    return YES;
}

- (void) stopTracking:(NSPoint)
		 lastPoint at:(NSPoint)stopPoint
			   inView:(NSView*)controlView
			mouseIsUp:(BOOL)flag {
	NSNumber* newObjectValue = [self calculateSelectionForPoint:stopPoint
														 inView: controlView] ;
    [self setObjectValue:newObjectValue];	
    [super stopTracking: lastPoint at: stopPoint inView: controlView mouseIsUp: flag];
}

- (NSNumber*)calculateSelectionForPoint:(NSPoint)point
								 inView:(NSView*)controlView {

	CGFloat zeroX = NSMinX([self drawingRectForBounds:_currentFrameInControlView]) ;
	CGFloat x = point.x - zeroX ;
	NSArray* widths = [self widths] ;
	NSInteger numberOfWidths = [widths count] ;
	
	CGFloat end = 0 ;
	NSInteger selectedIndex = 0 ;
	NSInteger i ;
	for (i=0; i<numberOfWidths; i++) {
		end += [[widths objectAtIndex:i] doubleValue] ;
		if (x < end) {
			selectedIndex = i ;
			break ;
		}
	}
				
	NSNumber* selection = [NSNumber numberWithInteger:selectedIndex] ;
	
    return selection ;
}

@end
