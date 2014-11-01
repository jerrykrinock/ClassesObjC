#import "SSYPopUpTableHeaderCell.h"

@interface SSYPopUpTableHeaderCell ()

@property CGFloat lostWidth ;

@end


@implementation SSYPopUpTableHeaderCell

@synthesize lostWidth ;

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

- (void)drawWithFrame:(NSRect)cellFrame
			   inView:(NSView*)controlView {
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
		// Arrow design is based on a cell frame height of 17.0 pixels,
		// which I believe is the standard and only height for an NSTableHeaderView
		// But design is scaled in case anyone ever comes up with a new height.
		CGFloat scaleFactor = cellFrame.size.height / 17.0 ;
		CGFloat whitespaceOnRight = 5.0 * scaleFactor ;
		CGFloat whitespaceOnTopOrBottom = 3.0 * scaleFactor ;
		CGFloat arrowSeparationY = 3.0 * scaleFactor ;
		
		CGFloat arrowHeight = (cellFrame.size.height - arrowSeparationY)/2 - whitespaceOnTopOrBottom ;
		CGFloat arrowWidth = arrowHeight ;
		CGFloat arrowHalfWidth = arrowWidth/2.0 ;
		CGFloat middleY = cellFrame.size.height / 2 ;
		CGFloat lostWidth_ = whitespaceOnRight + arrowWidth ;
		[self setLostWidth:lostWidth_] ;
		CGFloat arrowMinX = NSMaxX(cellFrame) - lostWidth_ ;
		CGFloat arrowOffsetY = arrowSeparationY / 2 ;
		CGFloat topArrowBottom = middleY + arrowOffsetY ;
		CGFloat bottomArrowTop = middleY - arrowOffsetY ;
		
		NSBezierPath* path ;
		[[NSColor blackColor] set] ;

		// Draw the top arrow (that points up)
		path = [NSBezierPath bezierPath] ;
		[path moveToPoint:NSMakePoint(arrowMinX, topArrowBottom)] ;
		[path relativeLineToPoint:NSMakePoint(arrowWidth, 0)] ;
		[path relativeLineToPoint:NSMakePoint(-arrowHalfWidth, arrowHeight)] ;
		[path closePath] ;
		[path fill] ;
		
		// Draw the lower triangle that points down
		path = [NSBezierPath bezierPath] ;
		[path moveToPoint:NSMakePoint(arrowMinX, bottomArrowTop)] ;
		[path relativeLineToPoint:NSMakePoint(arrowWidth, 0)] ;
		[path relativeLineToPoint:NSMakePoint(-arrowHalfWidth, -arrowHeight)] ;
		[path closePath] ;
		[path fill] ;
		
		cellFrame.size.width -= lostWidth_ ;
	}

	// Third, draw only the interior portion of the popup menu, "which includes
	// the image or text portion but does not include the border"
	// This will draw the title of the currently-selected item.
	[self drawInteriorWithFrame:cellFrame
						 inView:controlView] ;
}

@end