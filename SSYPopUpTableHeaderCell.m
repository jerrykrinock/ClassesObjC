#import "SSYPopUpTableHeaderCell.h"
#import "NS(Attributed)String+Geometrics.h"
#import "SSYTableHeaderView.h"
//BAD:
#import "StarkTableColumn.h"

@interface SSYPopUpTableHeaderCell ()

@property CGFloat lostWidth ;
@property CGFloat sortIndicatorLeftEdge ;
@property (copy) NSString* priorSelectedTitle ;
@property (assign) NSTableHeaderView* headerView ;

@end


@implementation SSYPopUpTableHeaderCell

@synthesize lostWidth ;
@synthesize priorSelectedTitle = _priorSelectedTitle ;
@synthesize fixedNonMenuTitle = _fixedNonMenuTitle ;

- (void)dealloc {
    [_priorSelectedTitle release] ;
    [_fixedNonMenuTitle release] ;
    
    [super dealloc] ;
}

- (id)copyWithZone:(NSZone *)zone {
    SSYPopUpTableHeaderCell* copy = [[SSYPopUpTableHeaderCell allocWithZone: zone] init] ;
	[copy setLostWidth:[self lostWidth]] ;
    [copy setPriorSelectedTitle:[self priorSelectedTitle]] ;
    [copy setFixedNonMenuTitle:[self fixedNonMenuTitle]] ;
	
    return copy ;
}

- (id)init {
	if (self = [super init]) {
        // Set up the popup cell attributes
		[self setControlSize:NSMiniControlSize] ;
		[self setBordered:NO] ;
		[self setBezeled:NO] ;
		[self setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]] ;
	}

	return self ;
}

- (NSPoint)clickedPointInControlView:(NSView*)controlView {
    NSEvent* event = [NSApp currentEvent] ;
    NSPoint eventPoint = [event locationInWindow] ;
    NSPoint point = [controlView convertPoint:eventPoint
                                     fromView:nil];
    return point;
}

- (void)performClickWithFrame:(NSRect)frame
                       inView:(NSView *)controlView {
    NSPoint point = [self clickedPointInControlView:controlView] ;
    CGFloat eventX = point.x ;
    if (eventX < [self sortIndicatorLeftEdge]) {
        [super performClickWithFrame:frame
                              inView:controlView] ;
    }
    else {
        NSTableView* tableView = [(SSYTableHeaderView*)controlView tableView] ;
        NSInteger clickedColumnIndex = [(NSTableHeaderView*)controlView columnAtPoint:point] ;
        NSArray <NSTableColumn <SSYPopupTableHeaderSortableColumn>*> * columns = (NSArray <NSTableColumn <SSYPopupTableHeaderSortableColumn>*> *)[tableView tableColumns] ;
        NSInteger columnIndex = 0 ;
        for (NSTableColumn <SSYPopupTableHeaderSortableColumn> * tableColumn in columns) {
            if (columnIndex == clickedColumnIndex) {
                switch ([self sortState]) {
                    case SSYPopupTableHeaderCellSortStateSortedAscending:
                       [self setSortState:SSYPopupTableHeaderCellSortStateSortedDescending] ;
                        if ([tableColumn respondsToSelector:@selector(sortAsAscending:)]) {
                            [tableColumn sortAsAscending:NO] ;
                            [(SSYTableHeaderView*)controlView setSortedColumn:tableColumn] ;
                        }
                        break ;
                    case SSYPopupTableHeaderCellSortStateNotSorted:
                    case SSYPopupTableHeaderCellSortStateSortedDescending:
                    default:
                        [self setSortState:SSYPopupTableHeaderCellSortStateSortedAscending] ;
                        if ([tableColumn respondsToSelector:@selector(sortAsAscending:)]) {
                            [tableColumn sortAsAscending:YES] ;
                            [(SSYTableHeaderView*)controlView setSortedColumn:tableColumn] ;
                        }
                        break ;
                }
            }
            else {
                SSYPopUpTableHeaderCell* otherCell = (SSYPopUpTableHeaderCell*)[tableColumn headerCell] ;
                /* Maybe it's not really, so check */
                if ([otherCell respondsToSelector:@selector(setSortState:)]) {
                    [otherCell setSortState:SSYPopupTableHeaderCellSortStateNotSorted] ;
                }
            }
            columnIndex++ ;
        }

        /* In my BkmkMgrs project, the following line is necessary for the Find
         table to immediately redraw to update the sort indicators.  Without
         the following, the indicators will not be redrawn until the window
         is redrawn by, for example, activating another app.  Inexplicably,
         the following is *not* necessary in BkmkMgrs Content outline.
         
         Also, note that I send the message to self.headerView instead of
         self.controlView.  In this instance, for some reason, self.controlView
         is nil.  Apparently Cocoa never sets it.  I do, however, get a
         control view in -drawWithFrame:inView:.  So I assign that to my own
         private property, headerView.  I thought about assigning
         to controlView, but decided that, since I don't understand what
         Apple is doing or not doing with controlView, it would be safer
         to use a private property. */
        [self.headerView setNeedsDisplay:YES] ;
    }
}

- (void)drawWithFrame:(NSRect)cellFrame
			   inView:(NSView*)controlView {
    /* In fact, the controlView never changes, and the following line only 
     really needs to execute the first time that this method is called. */
    self.headerView = (SSYTableHeaderView*)controlView ;
    
    /* It would make more sense and be more efficient to put the following in
     an override of -setSelectedItem:, -setSelectedItemWithIndex:, and
     -setSelectedItemWithTitle:, but I could not get that to work. */
    if ([[self selectedItem] tag] < 0) {
        if ([[self priorSelectedTitle] length] > 0) {
            [self selectItemWithTitle:[self priorSelectedTitle]] ;
        }
    }
    else {
        NSString* selectedTitle = [[self selectedItem] title] ;
        if ([selectedTitle length] > 0) {
            [self setPriorSelectedTitle:selectedTitle] ;
        }
    }
    
	// Apple's documentation for this -[NSCell drawWithFrame:inView: states
	// "This method draws the cell in the currently focused view,
	// which can be different from the controlView passed in. Taking advantage
	// of this behavior is not recommended, however.
	// So, in order to not "take advantage" of this,
	if ([NSView focusView] != controlView) {
        return ;
	}
	
	// First we draw the bezel and whatever background gradient there might be.
	// We omit drawing the title by simply setting it to an empty string.
	NSTableHeaderCell* templateHeaderCell = [[NSTableHeaderCell alloc] init] ;
	[templateHeaderCell setTitle:@""] ;
	[templateHeaderCell drawWithFrame:cellFrame
							   inView:controlView] ;
	[templateHeaderCell release] ;
	
    /* Second, draw the pair of popup arrows and sort indicators near the right
     edge and also remove width from the right of cellFrame.size.width so that
     only the part available for text remains in cellFrame.size.width */
	if (cellFrame.size.width > 0) {
        // Design is based on a cell frame height of 17.0 pixels,
		// which I believe is the standard and only height for an NSTableHeaderView
		// But design is scaled in case anyone ever comes up with a new height.
		CGFloat scaleFactor = cellFrame.size.height / 17.0 ;
        NSBezierPath* path ;
        
        NSTableView* tableView = [(NSTableHeaderView*)controlView tableView] ;
        BOOL sortable = YES ;
        if ([tableView respondsToSelector:@selector(sortable)]) {
            sortable = [(NSTableView <SSYPopupTableHeaderCellTableSortableOrNot> *)tableView sortable] ;
        }
        CGFloat sortScaleFactor = sortable ? scaleFactor : 0.0 ;
        CGFloat rightMargin = sortable ? 0.0 : 5.0 ;
        
        CGFloat sortIndicatorWidth = 17.0 * sortScaleFactor ;
        CGFloat sortIndicatorMarginH = 5.5 * sortScaleFactor ;
        CGFloat sortIndicatorMarginV = 6.5 * sortScaleFactor ;

        CGFloat sortIndicatorRight = NSMaxX(cellFrame) - sortIndicatorMarginH ;
        CGFloat sortIndicatorLeft = NSMaxX(cellFrame) - sortIndicatorWidth + sortIndicatorMarginH ;
        CGFloat sortIndicatorMiddle = (sortIndicatorRight + sortIndicatorLeft) / 2 ;
        CGFloat sortIndicatorVertexY ;
        CGFloat sortIndicatorBaseY ;
        if ([self sortState] == SSYPopupTableHeaderCellSortStateSortedDescending) {
            // Sort indicator/control pointing down
            sortIndicatorBaseY = sortIndicatorMarginV ;
            sortIndicatorVertexY = cellFrame.size.height - sortIndicatorMarginV ;
        }
        else {
            // Sort indicator/control pointing up
            sortIndicatorVertexY = sortIndicatorMarginV ;
            sortIndicatorBaseY = cellFrame.size.height - sortIndicatorMarginV ;
        }
        
		CGFloat arrowSeparationY = 3.0 * scaleFactor ;
        CGFloat arrowVerticalMargin = 3.0 * scaleFactor ;
		CGFloat arrowHeight = (cellFrame.size.height - arrowSeparationY)/2 - arrowVerticalMargin ;
		CGFloat arrowWidth = arrowHeight ;
		CGFloat arrowHalfWidth = arrowWidth/2.0 ;
		CGFloat middleY = cellFrame.size.height / 2 ;
		CGFloat lostWidth_ = sortIndicatorWidth + arrowWidth + rightMargin ;
		[self setLostWidth:lostWidth_] ;
		CGFloat arrowMinX = NSMaxX(cellFrame) - lostWidth_ ;
		CGFloat arrowOffsetY = arrowSeparationY / 2 ;
		CGFloat topArrowBottom = middleY + arrowOffsetY ;
		CGFloat bottomArrowTop = middleY - arrowOffsetY ;
        
        // We'll need this later, for hit testing in -performClickWithFrame::
        [self setSortIndicatorLeftEdge:sortIndicatorLeft] ;
		
        // Draw the sort indicator/control
        if (sortable) {
            path = [NSBezierPath bezierPath] ;
            if ([self sortState] != SSYPopupTableHeaderCellSortStateNotSorted) {
                [path setLineWidth:2.5] ;
                [[NSColor blueColor] set] ;
            }
            [path moveToPoint:NSMakePoint(sortIndicatorLeft, sortIndicatorBaseY)] ;
            [path lineToPoint:NSMakePoint(sortIndicatorMiddle, sortIndicatorVertexY)] ;
            [path lineToPoint:NSMakePoint(sortIndicatorRight, sortIndicatorBaseY)] ;
            [path stroke] ;
        }
        
        [[NSColor blackColor] set] ;

        if ([self isUserDefined]) {
            // Draw the upper arrow that points up
            path = [NSBezierPath bezierPath] ;
            [path moveToPoint:NSMakePoint(arrowMinX, topArrowBottom)] ;
            [path relativeLineToPoint:NSMakePoint(arrowWidth, 0)] ;
            [path relativeLineToPoint:NSMakePoint(-arrowHalfWidth, arrowHeight)] ;
            [path closePath] ;
            [path fill] ;
            
            // Draw the lower arrow that points down
            path = [NSBezierPath bezierPath] ;
            [path moveToPoint:NSMakePoint(arrowMinX, bottomArrowTop)] ;
            [path relativeLineToPoint:NSMakePoint(arrowWidth, 0)] ;
            [path relativeLineToPoint:NSMakePoint(-arrowHalfWidth, -arrowHeight)] ;
            [path closePath] ;
            [path fill] ;
        }
		
		cellFrame.size.width -= lostWidth_ ;

        CGFloat xMargin = 1.0 * scaleFactor ;
        CGFloat yMargin = 3.7 * scaleFactor ;
        NSPoint titlePoint = NSMakePoint(NSMinX(cellFrame) + xMargin, yMargin) ;
        NSAttributedString* attributedTitle ;
        if ([self fixedNonMenuTitle]) {
            NSTableView* tableView = [(NSTableHeaderView*)controlView tableView] ;
            NSPoint point = cellFrame.origin ;
            point.x = point.x + [tableView intercellSpacing].width  ;
            point.y = point.y + [tableView intercellSpacing].height ;
            NSInteger columnIndex = [tableView columnAtPoint:point] ;
            NSArray <NSTableColumn <SSYPopupTableHeaderSortableColumn>*> * columns = (NSArray <NSTableColumn <SSYPopupTableHeaderSortableColumn>*> *)[tableView tableColumns] ;
            NSTableColumn <SSYPopupTableHeaderSortableColumn> * thisColumn = [columns objectAtIndex:columnIndex] ;
            NSFont* font = [thisColumn headerFont] ;
            NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                        font, NSFontAttributeName,
                                        nil] ;
            attributedTitle = [[NSAttributedString alloc] initWithString:[self fixedNonMenuTitle]
                                                              attributes:attributes] ;
        }
        else {
            attributedTitle = [self attributedTitle] ;
            [attributedTitle retain] ;
        }
        NSAttributedString* truncatedTitle = [attributedTitle attributedStringTruncatedToWidth:cellFrame.size.width - xMargin
                                                                                        height:cellFrame.size.height] ;
        [truncatedTitle drawAtPoint:titlePoint] ;
        [attributedTitle release] ;
    }
}

@end