#import "SSYMultiTextFieldCell.h"


@implementation SSYMultiTextFieldCell

@synthesize images = m_images ;

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
	result->m_images = nil ;
    // and now instead we set it, which will give a retain.
	[result setImages:m_images] ;

    return result ;
}

- (void)dealloc {
	[m_images release] ;
	
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
		
#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1060
		[image drawInRect:imageFrame
                  fromRect:NSZeroRect
                 operation:NSCompositePlusDarker
                  fraction:1.0
            respectFlipped:YES
                     hints:nil] ;
#else
		if ([controlView isFlipped]) {
			imageFrame.origin.y += (cellFrame.size.height + imageDimension) / 2 ;
		}
		else {
			imageFrame.origin.y += (cellFrame.size.height - imageDimension) / 2 ;
		}
#warning 10.5!!!!!!!!!!!!!!
		[image compositeToPoint:imageFrame.origin
					  operation:NSCompositePlusDarker] ;
#endif
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
		
    NSInteger i = 0 ;
    for (NSImage* image in [self images]) {
        // Because the following method returns the as cellFrame the part
        // of the cell remaining for the text, and because this is fed
        // back in, subsequent iterations place the given images in a row,
        // starting from the left.
        cellFrame = [self drawAtLeftImage:image
                                cellFrame:cellFrame
                              controlView:controlView] ;
        i++ ;
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