#import "SSYDisplayAlotPopUpButtonCell.h"

@implementation SSYDisplayAlotPopUpButtonCell

#if 0
#warning No kludge SSYPopUpButtonCell
#else

- (void)dismissPopUp {
	[super dismissPopUp] ;
	[[self controlView] display] ;
}

#if (MAC_OS_X_VERSION_MAX_ALLOWED < 101000)
// OS X 10.9.x or earlier
// This makes absolutely no sense.
#define NSCellHitResult NSUInteger
#endif

- (NSCellHitResult)hitTestForEvent:(NSEvent *)event
                            inRect:(NSRect)cellFrame
                            ofView:(NSView *)controlView {
	NSUInteger result = [super hitTestForEvent:event
										inRect:cellFrame
										ofView:controlView] ;
	[controlView display] ;
	return result ;
}

#endif

@end