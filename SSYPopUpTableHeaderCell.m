#import "SSYPopUpTableHeaderCell.h"
#import "NS(Attributed)String+Geometrics.h"

@interface SSYPopUpTableHeaderCell ()

@property CGFloat lostWidth ;
@property CGFloat sortIndicatorLeftEdge ;
@property (copy) NSString* priorSelectedTitle ;
@property SSYPopupTableHeaderCellSortState sortState ;

@end


@implementation SSYPopUpTableHeaderCell

@synthesize lostWidth ;
@synthesize priorSelectedTitle = _priorSelectedTitle ;

- (void)dealloc {
    [_priorSelectedTitle release] ;
    
    [super dealloc] ;
}

- (id)copyWithZone:(NSZone *)zone {
    SSYPopUpTableHeaderCell* copy = [[SSYPopUpTableHeaderCell allocWithZone: zone] init] ;
	[copy setLostWidth:[self lostWidth]] ;
	
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

- (void)performClickWithFrame:(NSRect)frame
                       inView:(NSView *)controlView {
    NSEvent* event = [NSApp currentEvent] ;
    NSPoint eventPoint = [event locationInWindow] ;
    NSPoint point = [controlView convertPoint:eventPoint
                                     fromView:nil];
    CGFloat eventX = point.x ;
    if (eventX < [self sortIndicatorLeftEdge]) {
        [super performClickWithFrame:frame
                              inView:controlView] ;
    }
    else {
        NSTableView* tableView = [(NSTableHeaderView*)controlView tableView] ;
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
                        }
                        break ;
                    case SSYPopupTableHeaderCellSortStateNotSorted:
                    case SSYPopupTableHeaderCellSortStateSortedDescending:
                    default:
                        [self setSortState:SSYPopupTableHeaderCellSortStateSortedAscending] ;
                        if ([tableColumn respondsToSelector:@selector(sortAsAscending:)]) {
                            [tableColumn sortAsAscending:YES] ;
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
    }
}

- (void)drawWithFrame:(NSRect)cellFrame
			   inView:(NSView*)controlView {
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
	
	// Second, draw the pair of popup arrows near the right edge
	// and also remove width from the right of cellFrame.size.width
	// so that only the part available for text remains in cellFrame.size.width
	if (cellFrame.size.width > 0) {
        // Design is based on a cell frame height of 17.0 pixels,
		// which I believe is the standard and only height for an NSTableHeaderView
		// But design is scaled in case anyone ever comes up with a new height.
		CGFloat scaleFactor = cellFrame.size.height / 17.0 ;
        NSBezierPath* path ;
        
        CGFloat sortIndicatorWidth = 17.0 * scaleFactor ;
        CGFloat arrowMargin = 3.0 * scaleFactor ;
        CGFloat sortIndicatorMarginH = 5.5 * scaleFactor ;
        CGFloat sortIndicatorMarginV = 6.5 * scaleFactor ;

        CGFloat sortIndicatorRight = NSMaxX(cellFrame) - sortIndicatorMarginH ;
        CGFloat sortIndicatorLeft = NSMaxX(cellFrame) - sortIndicatorWidth + sortIndicatorMarginH ;
        CGFloat sortIndicatorMiddle = (sortIndicatorRight + sortIndicatorLeft) / 2 ;
        CGFloat sortIndicatorVertexY ;
        CGFloat sortIndicatorBaseY ;
        if ([self sortState] == SSYPopupTableHeaderCellSortStateSortedDescending) {
            // Point down
            sortIndicatorBaseY = sortIndicatorMarginV ;
            sortIndicatorVertexY = cellFrame.size.height - sortIndicatorMarginV ;
        }
        else {
            // Point up
            sortIndicatorVertexY = sortIndicatorMarginV ;
            sortIndicatorBaseY = cellFrame.size.height - sortIndicatorMarginV ;
        }
        
		CGFloat arrowSeparationY = 3.0 * scaleFactor ;
		CGFloat arrowHeight = (cellFrame.size.height - arrowSeparationY)/2 - arrowMargin ;
		CGFloat arrowWidth = arrowHeight ;
		CGFloat arrowHalfWidth = arrowWidth/2.0 ;
		CGFloat middleY = cellFrame.size.height / 2 ;
		CGFloat lostWidth_ = sortIndicatorWidth + arrowWidth ;
		[self setLostWidth:lostWidth_] ;
		CGFloat arrowMinX = NSMaxX(cellFrame) - lostWidth_ ;
		CGFloat arrowOffsetY = arrowSeparationY / 2 ;
		CGFloat topArrowBottom = middleY + arrowOffsetY ;
		CGFloat bottomArrowTop = middleY - arrowOffsetY ;
        
        // We'll need this later, for hit testing in -performClickWithFrame::
        [self setSortIndicatorLeftEdge:sortIndicatorLeft] ;
		
        // Draw the sort indicator
        path = [NSBezierPath bezierPath] ;
        if ([self sortState] != SSYPopupTableHeaderCellSortStateNotSorted) {
            [path setLineWidth:2.5] ;
            [[NSColor blueColor] set] ;
        }
        [path moveToPoint:NSMakePoint(sortIndicatorLeft, sortIndicatorBaseY)] ;
        [path lineToPoint:NSMakePoint(sortIndicatorMiddle, sortIndicatorVertexY)] ;
        [path lineToPoint:NSMakePoint(sortIndicatorRight, sortIndicatorBaseY)] ;
        [path stroke] ;
        
        [[NSColor blackColor] set] ;
        
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
		
		cellFrame.size.width -= lostWidth_ ;

        CGFloat xMargin = 1.0 * scaleFactor ;
        CGFloat yMargin = 3.7 * scaleFactor ;
        NSPoint titlePoint = NSMakePoint(NSMinX(cellFrame) + xMargin, yMargin) ;
        NSAttributedString* truncatedTitle = [[self attributedTitle] attributedStringTruncatedToWidth:cellFrame.size.width - xMargin
                                                                                               height:cellFrame.size.height] ;
        [truncatedTitle drawAtPoint:titlePoint] ;
    }
}

@end