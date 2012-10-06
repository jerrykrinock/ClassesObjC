#import "SSYLabelledList.h"
#import "NSView+Layout.h"
#import "SSYAlert.h"
#import "NSView+Layout.h"

@interface SSYLabelledListTableColumn : NSTableColumn {}

@end

@implementation SSYLabelledListTableColumn

- (id)dataCell {
	id cell = [super dataCell] ;
	[cell setFont:[SSYLabelledList tableFont]] ;
	return cell ;
}

@end


// Todo: Get rid of this category, and similar categories on other classes.
// Its method should be declared in a protocol.  It is required by -[SSYAlert doLayout].
@interface NSTableView (Layout)

- (void)sizeHeightToFitAllowShrinking:(BOOL)allowShrinking ;

@end

@implementation NSTableView (Layout)

- (void)sizeHeightToFitAllowShrinking:(BOOL)allowShrinking {
	CGFloat height = [self numberOfRows] * [self rowHeight] + ([self numberOfRows]-1)*[self intercellSpacing].height ;
	[self setHeight:height] ;
	
	// Super implementation makes sure that we're not too high for the screen.
	[super sizeHeightToFitAllowShrinking:allowShrinking] ;
}	

@end


NSString* const constKeyLabelView = @"labelView" ;
NSString* const constKeyScrollView = @"scrollView" ;
NSString* const constKeyChoices = @"choices" ;
NSString* const constKeyCellTextAttributes = @"cellTextAttributes" ;

@interface SSYLabelledList ()

@property (retain) NSTextField* labelView ;
@property (retain) NSScrollView* scrollView ;
@property (retain) NSArray* choices ;
@property (retain) NSArray* toolTips ;
@property (retain) NSDictionary* cellTextAttributes ;
@property CGFloat maxTableHeight ;

@end


@implementation SSYLabelledList

@synthesize labelView ;
@synthesize scrollView ;
@synthesize choices ;
@synthesize toolTips = m_toolTips ;
@synthesize cellTextAttributes ;
@synthesize maxTableHeight ;

- (NSTableView*)tableView {
	return [[self scrollView] documentView] ;
}

- (void)setSelectedIndexes:(NSIndexSet*)selectedIndexes {
	[[self tableView] selectRowIndexes:selectedIndexes
				  byExtendingSelection:NO] ;
}

- (void)setAllowsMultipleSelection:(BOOL)flag {
	[[self tableView] setAllowsMultipleSelection:flag] ;
}

- (void)setAllowsEmptySelection:(BOOL)flag {
	[[self tableView] setAllowsEmptySelection:flag] ;
}

- (void)setTableViewDelegate:(id)delegate {
	[[self tableView] setDelegate:delegate] ;
}

- (NSIndexSet*)selectedIndexes {
	return [[self tableView] selectedRowIndexes] ;
}

- (NSArray*)selectedValues {
	return [[self choices] objectsAtIndexes:[self selectedIndexes]] ;
}

#define SPACE_BETWEEN 12.0

- (void)sizeHeightToFitAllowShrinking:(BOOL)allowShrinking {
	// Set heights
	[[self labelView] sizeHeightToFitAllowShrinking:allowShrinking] ;
	[[self tableView] sizeHeightToFitAllowShrinking:allowShrinking] ;
	NSRect frame = [[self tableView] frame] ;
	// The scroll view needs to be a little taller than the table
	// lest scrollers will appear unnecessarily.
	frame.size.height += 3.0 ;
	frame.size.height = MIN([self maxTableHeight], frame.size.height) ;
	[[self scrollView] setFrame:frame] ;
	
	// Set y positions
	CGFloat y = [[self scrollView] height] ;
	y += SPACE_BETWEEN ;
	[[self labelView] setBottom:y] ;
	y += [[self labelView] height] ;
	
	// Set overall height
	[self setHeight:y] ;
}


+ (NSFont*)tableFont {
	return [NSFont systemFontOfSize:12.0] ;
}

- (id)initWithLabel:(NSString*)label
			choices:(NSArray*)choices_
		   toolTips:(NSArray*)toolTips
	  lineBreakMode:(NSLineBreakMode)lineBreakMode
	 maxTableHeight:(CGFloat)maxTableHeight_ {
	self = [super initWithFrame:NSZeroRect] ;
	if (self != nil) {				
		[self setChoices:choices_] ;
		[self setToolTips:toolTips] ;
		
		[self setMaxTableHeight:maxTableHeight_] ;
		
		// Start with a nominal size
		NSRect nominalFrame = NSZeroRect ;
		
		NSTableView* tableView_ = [[NSTableView alloc] initWithFrame:nominalFrame] ;
        [tableView_ setDataSource:self] ;
		[tableView_ setAllowsMultipleSelection:YES] ;  // Needed since NSTableView's default value is NO.
		// [tableView_ setAllowsEmptySelection:YES] ;  // Not needed since NSTableView's default value is YES.
		// Todo: The following should be parameterized
		[tableView_ setHeaderView:nil] ;
		[tableView_ setDelegate:self] ;
		// The factor 0.7 is because the height given by boundingRectForFont is ridiculously large.
		[tableView_ setRowHeight:0.7*[[SSYLabelledList tableFont] boundingRectForFont].size.height] ;
		
		NSTableColumn *column = [[SSYLabelledListTableColumn alloc] initWithIdentifier:@"choices"];        
		// Todo: The following should be parameterized
		[column setEditable:NO] ;
        [tableView_ addTableColumn:column] ;
        [column release] ;
        
		NSScrollView* scrollView_ = [[NSScrollView alloc] initWithFrame:nominalFrame] ;
        [scrollView_ setHasVerticalScroller:YES] ;
        [scrollView_ setBorderType:NSNoBorder] ;
        [scrollView_ setAutohidesScrollers:YES] ;
        [scrollView_ setDocumentView:tableView_] ;
		[tableView_ release] ;
		
		[self setScrollView:scrollView_] ;
		[self addSubview:scrollView_] ;
		[scrollView_ release] ;
				
		NSTextField* textField ;
		textField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 0, [SSYAlert smallTextHeight])] ;
		[textField setFont:[SSYAlert smallTextFont]] ;
		[textField setBordered:NO] ;
		[textField setEditable:NO] ;
		[textField setDrawsBackground:NO] ;
		[textField setStringValue:label] ;

		[textField setLeftEdge:0.0] ;
		[self setLabelView:textField] ;
		[self addSubview:textField] ;
		[textField release] ;
		
		[self setAutoresizingMask:NSViewWidthSizable] ;
		
		// Start out with self and subviews all at same width,
		// then set to track future changes to self's width
		[self setWidth:[textField width]] ;
		[[self labelView] setAutoresizingMask:NSViewWidthSizable] ;
		[[self scrollView] setAutoresizingMask:NSViewWidthSizable] ;
		
		// Note that the final layout is done later, when
		// -sizeHeightToFitAllowShrinking is invoked during layout.
		// That's because the height of the labelView will depend on
		// the width of the labelView (words must fit), and we don't
		// know the final width yet.
		
		// This looks weird.  I suppose it makes sense, if there is only
		// one field in the keyboard loop at this level??
		[scrollView_ setNextKeyView:scrollView_] ;
		
		NSMutableParagraphStyle *ps = [[NSParagraphStyle defaultParagraphStyle] mutableCopy] ;
		[ps setLineBreakMode:lineBreakMode];
		[self setCellTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
									 ps, NSParagraphStyleAttributeName,
									 nil]] ;
		[ps release] ;		
	}
	
	return self;
}

- (void)setNextKeyView:(NSView*)view {
	[[self scrollView] setNextKeyView:view] ;
}

- (BOOL)becomeFirstResponder {
	BOOL x = [[self window] makeFirstResponder:[self scrollView]] ;
	return x ;
}

+ (SSYLabelledList*)listWithLabel:(NSString*)label
						  choices:(NSArray*)choices_
						 toolTips:(NSArray*)toolTips
					lineBreakMode:(NSLineBreakMode)lineBreakMode
					maxTableHeight:(CGFloat)maxTableHeight {
	SSYLabelledList* instance = [[SSYLabelledList alloc] initWithLabel:label
															   choices:choices_
															  toolTips:toolTips
														 lineBreakMode:lineBreakMode
														  maxTableHeight:maxTableHeight] ;
	return [instance autorelease] ;
}

- (void) dealloc {
	[labelView release] ;
	[scrollView release] ;
	[choices release] ;
	[m_toolTips release] ;
	[cellTextAttributes release] ;
	
	[super dealloc] ;
}

- (BOOL)acceptsFirstResponder {
	return YES ;
}

#pragma mark * Table View Data Source Protocol Methods

- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(NSInteger)rowIndex {
	NSAttributedString* s = [[NSAttributedString alloc] initWithString:[[self choices] objectAtIndex:rowIndex]
															attributes:[self cellTextAttributes]];
	return [s autorelease] ;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [[self choices] count] ;
}

- (NSString *)tableView:(NSTableView*)tableView
		 toolTipForCell:(NSCell*)aCell
				   rect:(NSRectPointer)rect
			tableColumn:(NSTableColumn*)aTableColumn
					row:(NSInteger)rowIndex
		  mouseLocation:(NSPoint)mouseLocation {
	id toolTip = [[self toolTips] objectAtIndex:rowIndex] ;
	if (![toolTip isKindOfClass:[NSString class]]) {
		toolTip = nil ;
	}

	return toolTip ;
}

#pragma mark * NSCoding Protocol Conformance

// See http://developer.apple.com/documentation/Cocoa/Conceptual/Archiving/Tasks/codingobjects.html

// Although NSResponder::NSControl subclasses can sometimes get away with not implementing these
// two methods, not so if the control is used in SSYAlert, because SSYAlert will encode it when
// adding to its configurations stack.

// @encode(type_spec) is a compiler directive that returns a character string that encodes 
//    the type structure of type_spec.  It can be used as the first argument of can be used as
//    the first argument of encodeValueOfObjCType:at: 

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder] ;
    
	[coder encodeObject:labelView forKey:constKeyLabelView] ;
    [coder encodeObject:scrollView forKey:constKeyScrollView] ;
	[coder encodeObject:choices forKey:constKeyChoices] ;
	[coder encodeObject:cellTextAttributes forKey:constKeyCellTextAttributes] ;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder] ;
	
	labelView = [[coder decodeObjectForKey:constKeyLabelView] retain] ;
	scrollView = [[coder decodeObjectForKey:constKeyScrollView] retain] ;
	choices = [[coder decodeObjectForKey:constKeyChoices] retain] ;
	cellTextAttributes = [[coder decodeObjectForKey:constKeyCellTextAttributes] retain] ;
	return self ;
}

@end

