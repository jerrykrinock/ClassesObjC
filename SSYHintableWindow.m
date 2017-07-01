#import "SSYHintableWindow.h"
#import "SSYHintArrow.h"


@implementation SSYHintableWindow

- (void)sendEvent:(NSEvent *)event {
	[SSYHintArrow removeIfEvent:event] ;
	[super sendEvent:event] ;
}

@end
