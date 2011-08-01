#import "SSYDisplayAlotPopUpButtonCell.h"

@implementation SSYDisplayAlotPopUpButtonCell

#if 0
#warning No kludge SSYPopUpButtonCell
#else

- (void)dismissPopUp {
	[super dismissPopUp] ;
	[[self controlView] display] ;
}

- (NSUInteger)hitTestForEvent:(NSEvent *)event
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