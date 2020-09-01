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


NSString* const constKeySSYLabelledListLabelView = @"labelView" ;
NSString* const constKeySSYLabelledListScrollView = @"scrollView" ;
NSString* const constKeySSYLabelledListTableView = @"tableView";
NSString* const constKeySSYLabelledListChoices = @"choices" ;
NSString* const constKeySSYLabelledListCellTextAttributes = @"cellTextAttributes" ;

@interface SSYLabelledList ()

/* Comment in August 2020: I think that all of the subviews below could be
 assign instead of retain.  There is no reason to retain subviews because
 superviews retain them.  But I don't want to spend any more time on this
 old code that works. */
@property (retain) NSTextField* labelView ;
@property (assign) NSScrollView* scrollView ;
@property (retain) NSTableView* tableView ;
@property (retain) NSView* allOrNoneView ;
@property (retain) NSArray* choices ;
@property (retain) NSArray* toolTips ;
@property (retain) NSDictionary* cellTextAttributes ;
@property CGFloat maxTableHeight ;

@end


@implementation SSYLabelledList

@synthesize labelView ;
@synthesize scrollView ;
@synthesize tableView;
@synthesize allOrNoneView ;
@synthesize choices ;
@synthesize toolTips = m_toolTips ;
@synthesize cellTextAttributes ;
@synthesize maxTableHeight ;

- (void)setSelectedIndexes:(NSIndexSet*)selectedIndexes {
	[[self tableView] selectRowIndexes:selectedIndexes
				  byExtendingSelection:NO] ;
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
    [self.allOrNoneView sizeHeightToFitAllowShrinking:NO] ;
	NSRect frame = [[self tableView] frame] ;
    NSView* scrableView;  // either a scroll view or a table view
    if (frame.size.height < [self maxTableHeight]) {
        /* All Rows ill fit without scrolling.  Just add the table view
         as a subview.  Do not create a scroll view. */
        scrableView = [self tableView];
        [self addSubview:scrableView];
        /* Removing the scroll view is defensive programming, in case
         anyone ever modifies this class in such a way as to allow the
         number of choices to be modified after init, or in case row
         height somehow changes, or some other weird thing. */
        [[self scrollView] removeFromSuperviewWithoutNeedingDisplay];
        [self setScrollView:nil];
    } else {
        /* Create and add a scroll view, and stitch the table view into
         it. */
        frame.size.height = [self maxTableHeight];
        scrableView = self.scrollView;
        if (!scrableView) {
            scrableView = [[NSScrollView alloc] initWithFrame:frame];
            [self addSubview:scrableView];
            [scrableView release];
            self.scrollView = (NSScrollView*)scrableView;
        }
        self.scrollView.hasVerticalScroller = YES;
        self.scrollView.borderType = NSNoBorder;
        self.scrollView.autohidesScrollers = YES;
        self.scrollView.documentView = self.tableView;
        // Next line looks weird.  I suppose it makes sense, if there is only
        // one control in the keyboard loop at this level??
        [self.scrollView setNextKeyView:self.scrollView];

        scrableView = [self scrollView];
    }
    [scrableView setFrame:frame];
    [scrableView setAutoresizingMask:NSViewWidthSizable] ;

	// Set y positions
    CGFloat y = 0.0 ;
    if (self.allOrNoneView) {
        y += [self.allOrNoneView height] ;
        y += SPACE_BETWEEN/4 ;
    }
    [scrableView setBottom:y] ;
    y += [scrableView height] ;
	y += SPACE_BETWEEN ;
	[[self labelView] setBottom:y] ;
	y += [[self labelView] height] ;
	
	// Set overall height
	[self setHeight:y] ;
}


+ (NSFont*)tableFont {
	return [NSFont systemFontOfSize:12.0] ;
}

- (id)     initWithLabel:(NSString*)label
                 choices:(NSArray*)choices_
 allowsMultipleSelection:(BOOL)allowsMultipleSelection
    allowsEmptySelection:(BOOL)allowsEmptySelection
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
		[tableView_ setAllowsMultipleSelection:allowsMultipleSelection] ;
		[tableView_ setAllowsEmptySelection:allowsEmptySelection] ;
		// Todo: The following should be parameterized
		[tableView_ setHeaderView:nil] ;
		[tableView_ setDelegate:self] ;
        [tableView_ setRowHeight:[[SSYLabelledList tableFont] boundingRectForFont].size.height] ;
		
		NSTableColumn *column = [[SSYLabelledListTableColumn alloc] initWithIdentifier:@"choices"];        
		// Todo: The following should be parameterized
		[column setEditable:NO] ;
        [tableView_ addTableColumn:column] ;
        [column release] ;
        self.tableView = tableView_;
        [tableView_ release] ;
				
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
        
        if (allowsMultipleSelection && (choices.count > 1)) {
            NSView* allOrNoneView_ = [[NSView alloc] initWithFrame:NSZeroRect] ;
            NSButton* allButton = [[NSButton alloc] initWithFrame:NSZeroRect] ;
            [allButton setFont:[NSFont systemFontOfSize:13]] ;
            [allButton setBezelStyle:NSSmallSquareBezelStyle] ;
            [allButton setTitle:NSLocalizedString(@"All", nil)] ;
            [allButton sizeToFit] ;
            [allButton setTarget:tableView_] ;
            [allButton setAction:@selector(selectAll:)] ;
            [allOrNoneView_ addSubview:allButton] ;
            [allButton release] ;
            if (allowsEmptySelection) {
                NSButton* noneButton = [[NSButton alloc] initWithFrame:NSZeroRect] ; ;
                [noneButton setFont:[NSFont systemFontOfSize:13]] ;
                [noneButton setBezelStyle:NSSmallSquareBezelStyle] ;
                [noneButton setTitle:NSLocalizedString(@"None", nil)] ;
                [noneButton sizeToFit] ;
                [noneButton setTarget:tableView_] ;
                [noneButton setAction:@selector(deselectAll:)] ;
                NSRect noneButtonFrame = noneButton.frame ;
                noneButtonFrame.origin.x = allButton.frame.origin.x + allButton.frame.size.width ;
                noneButton.frame = noneButtonFrame ;
                [allOrNoneView_ addSubview:noneButton] ;
                [noneButton release] ;
            }
            
            [allOrNoneView_ setHeight:allButton.frame.size.height] ;
            [allOrNoneView_ setLeftEdge:0.0] ;
            [self setAllOrNoneView:allOrNoneView_] ;
            [self addSubview:allOrNoneView_] ;
            [allOrNoneView_ release] ;
        }
        
		[self setAutoresizingMask:NSViewWidthSizable] ;
		
		// Start out with self and subviews all at same width,
		// then set to track future changes to self's width
		[self setWidth:[textField width]] ;
		[[self labelView] setAutoresizingMask:NSViewWidthSizable] ;
        [[self allOrNoneView] setAutoresizingMask:NSViewWidthSizable] ;
		
		// Note that the final layout is done later, when
		// -sizeHeightToFitAllowShrinking is invoked during layout.
		// That's because the height of the labelView will depend on
		// the width of the labelView (words must fit), and we don't
		// know the final width yet.
        
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
    NSView* scrableView;
    if (self.scrollView) {
        scrableView = self.scrollView;
    } else {
        scrableView = self.tableView;
    }
    
    [scrableView setNextKeyView:view];
}

- (BOOL)becomeFirstResponder {
	BOOL x = [[self window] makeFirstResponder:[self scrollView]] ;
	return x ;
}

+ (SSYLabelledList*)listWithLabel:(NSString*)label
						  choices:(NSArray*)choices_
          allowsMultipleSelection:(BOOL)allowsMultipleSelection
             allowsEmptySelection:(BOOL)allowsEmptySelection
						 toolTips:(NSArray*)toolTips
					lineBreakMode:(NSLineBreakMode)lineBreakMode
					maxTableHeight:(CGFloat)maxTableHeight {
	SSYLabelledList* instance = [[SSYLabelledList alloc] initWithLabel:label
															   choices:choices_
                                               allowsMultipleSelection:allowsMultipleSelection
                                                  allowsEmptySelection:allowsEmptySelection
															  toolTips:toolTips
														 lineBreakMode:lineBreakMode
														  maxTableHeight:maxTableHeight] ;
	return [instance autorelease] ;
}

- (void)dealloc {
	[labelView release] ;
    [tableView release];
    [allOrNoneView release] ;
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
		toolTip = @"" ;
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
    
	[coder encodeObject:labelView forKey:constKeySSYLabelledListLabelView] ;
    [coder encodeObject:scrollView forKey:constKeySSYLabelledListScrollView] ;
    [coder encodeObject:tableView forKey:constKeySSYLabelledListTableView] ;
	[coder encodeObject:choices forKey:constKeySSYLabelledListChoices] ;
	[coder encodeObject:cellTextAttributes forKey:constKeySSYLabelledListCellTextAttributes] ;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder] ;
	
	labelView = [[coder decodeObjectForKey:constKeySSYLabelledListLabelView] retain] ;
	scrollView = [coder decodeObjectForKey:constKeySSYLabelledListScrollView] ;
    tableView = [[coder decodeObjectForKey:constKeySSYLabelledListTableView] retain];
	choices = [[coder decodeObjectForKey:constKeySSYLabelledListChoices] retain] ;
	cellTextAttributes = [[coder decodeObjectForKey:constKeySSYLabelledListCellTextAttributes] retain] ;
	return self ;
}

@end

