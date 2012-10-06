#import "SSYMultiTextFieldCell.h"
#import "NSString+Truncate.h"
#import "NS(Attributed)String+Geometrics.h"


@implementation SSYMultiTextFieldCell

@synthesize icon1 ;
@synthesize icon2 ;

@synthesize arrowDirection ;

@synthesize overdrawsRectOfDisclosureTriangle ;

- (id)init {
	self = [super init] ;

	if (self) {

		// The following is important not just for drawing the
		// cell normally but for drawing the expansion frame tool tip
		// properly.
		[self setScrollable:YES] ;
		[self setLineBreakMode:NSLineBreakByTruncatingMiddle] ;
	}
	
	return self ;
}

- (id)copyWithZone:(NSZone *)zone {
    SSYMultiTextFieldCell *result = [super copyWithZone:zone];
    result->overdrawsRectOfDisclosureTriangle = [self overdrawsRectOfDisclosureTriangle] ;
	
	// Each time NSTableView goes to track or edit a cell, it copies  
	// it, using copyWithZone.  super just does an address copy,
	// which does not give the required -retain.  So, we chuck that:
	result->icon1 = nil ;
    result->icon2 = nil ;
	result->arrowDirection = 0 ;
    // and now instead we set it, which will give a retain.
	[result setIcon1:icon1] ;
    [result setIcon2:icon2] ;
	[result setArrowDirection:arrowDirection] ;

    return result ;
}

- (void)dealloc {
	[icon1 release] ;
	[icon2 release] ;
	
	[super dealloc] ;
}

// Setting the following to non-zero makes images scale badly
// I don't know why ... maybe it's because my bookmark and sorted/unsorted
// icons were hand-tweak to look good with the common row height (reportFontSize)
#define MARGIN_FACTOR 0.0

- (NSRect)drawAtLeftImage:(NSImage*)image
				cellFrame:(NSRect)cellFrame
			  controlView:(NSView*)controlView {
	if (image != nil) {
        [image setScalesWhenResized:YES] ;

		CGFloat imageDimension = (1-MARGIN_FACTOR) * cellFrame.size.height ;
        NSSize	imageSize ;
		imageSize.height = imageDimension ;
		imageSize.width = imageDimension ;
		[image setSize:imageSize];

        NSRect	imageFrame ;
        NSDivideRect(cellFrame, &imageFrame, &cellFrame, imageSize.width, NSMinXEdge) ;

		if ([self drawsBackground]) {
			[[self backgroundColor] set];
			NSRectFill(imageFrame);
		}
		
		if ([controlView isFlipped]) {
			//imageFrame.origin.y += (cellFrame.size.height + imageDimension) / 2 ;
		}
		else {
			//imageFrame.origin.y += (cellFrame.size.height - imageDimension) / 2 ;
		}
		
		[image drawInRect:imageFrame
                  fromRect:NSZeroRect
                 operation:NSCompositePlusDarker
                  fraction:1.0
            respectFlipped:YES
                     hints:nil] ;
		// I use plusDarker so I don't need an alpha channel - use white background and it "just works"
    }
	
	return cellFrame ;
}

/* This method never seems to run
 - (void)highlight:(BOOL)flag
		withFrame:(NSRect)cellFrame
		   inView:(NSView *)controlView {
	[super highlight:flag
		   withFrame:cellFrame
			  inView:controlView] ;
}
*/

// This is an over-ride of an NSCell method
#define LEFT_MARGIN 3.0
- (void)drawWithFrame:(NSRect)cellFrame
			   inView:(NSView *)controlView {	
	
	if ([self overdrawsRectOfDisclosureTriangle]) {
		cellFrame.size.width += (cellFrame.origin.x - LEFT_MARGIN) ;
		cellFrame.origin.x = LEFT_MARGIN ;
	}
		
	cellFrame = [self drawAtLeftImage:[self icon1]
							cellFrame:cellFrame
						  controlView:controlView] ;

	cellFrame = [self drawAtLeftImage:[self icon2]
							cellFrame:cellFrame
						  controlView:controlView] ;

	// Draw the optional arrow pointing up or down
	if ([self arrowDirection] != 0) {
		[controlView lockFocus] ;
		
		CGFloat margin = .15 ;

		// Draw the background
		NSColor* backgroundColor = [self backgroundColor] ;
		NSBezierPath* path = [NSBezierPath bezierPathWithRect:cellFrame] ;
		[backgroundColor set] ;
		[path fill] ;
		
		// Trace the arrow and bar
		CGFloat arrowLength = (1-2*margin) * cellFrame.size.height ;
		CGFloat arrowHeadHalfWidthRelativeToLength = 0.3 ;
		CGFloat arrowHeadLengthRelativeToLength = 0.5 ;
		CGFloat arrowHeadHalfWidth = arrowHeadHalfWidthRelativeToLength * arrowLength ;
		CGFloat arrowRectWidth = (2 * margin) * cellFrame.size.height + 2 * arrowHeadHalfWidth ;
		[[NSColor blueColor] set] ;
		path = [NSBezierPath bezierPath] ;
		NSPoint arrowTail = NSMakePoint(cellFrame.origin.x + arrowRectWidth/2,  cellFrame.origin.y + (.5 - [self arrowDirection] * (margin - .5)) * cellFrame.size.height) ;
		
		// Trace the arrow center line
		[path moveToPoint:arrowTail] ;
		NSPoint arrowHead = NSMakePoint(arrowTail.x,  arrowTail.y - [self arrowDirection] * arrowLength) ;
		[path lineToPoint:arrowHead] ;
		
		// Trace the two lines which make up the arrowhead
		[path relativeLineToPoint:NSMakePoint(- arrowHeadHalfWidth,  [self arrowDirection] * arrowHeadLengthRelativeToLength*arrowLength)] ;
		[path moveToPoint:arrowHead] ;
		[path relativeLineToPoint:NSMakePoint(+ arrowHeadHalfWidth,  [self arrowDirection] * arrowHeadLengthRelativeToLength*arrowLength)] ;

		// Trace the bar at the arrowhead
		[path moveToPoint:arrowHead] ;
		[path relativeLineToPoint:NSMakePoint(- arrowHeadHalfWidth, 0)] ;
		[path moveToPoint:arrowHead] ;
		[path relativeLineToPoint:NSMakePoint(+ arrowHeadHalfWidth, 0)] ;
		
		// Draw the arrow and bar
		[path stroke] ;
		
		[controlView unlockFocus];
		
		cellFrame.origin.x += arrowRectWidth ;
		cellFrame.size.width -= arrowRectWidth ;
	}		

	[super drawWithFrame:cellFrame
				  inView:controlView] ;
}


@end

 //-(BOOL)trackMouse:(NSEvent *)theEvent
//		   inRect:(NSRect)cellFrame
//		   ofView:(NSView *)controlView untilMouseUp:(BOOL)untiMouseUp
//{
//    NSPoint mousePoint = [controlView convertPoint:[theEvent locationInWindow] fromView:nil];
//    if (NSPointInRect(mousePoint cellFrame)
//		{
//        [self showPopUpWithEvent:theEvent ofView:controlView
//					   cellFrame:cellFrame];
//		}
//		else
//        //do nothing
//		return YES;
//		
//}
//
//Now you will have to creat a contextual Menu do it in  showPopUpWithEvent
//method:
//
//-(void)showPopUpWithEvent:(NSEvent*)theEvent ofView:(NSView *)controlView
//				cellFrame:(NSRect *)inCellFrame
//{
//	//Create a menu here ...say your menu object is aenu
//	[NSMenu popUpContextMenu:aMenu withEvent:theEvent
//					 forView:controlView];
//}