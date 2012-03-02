#import "SSYHintableWindow.h"
#import "SSYHintArrow.h"

@implementation SSYHintableWindow

- (void)sendEvent:(NSEvent *)event {
	[SSYHintArrow removeIfEvent:event] ;
	[super sendEvent:event] ;
}


#if 0
#warning Experimenting : Windowless

- (void)displayIfNeeded {
	if (WINDOWLESS) {
		return ;
	}
	[super displayIfNeeded] ;
}


- (void)display {
	if (WINDOWLESS) {
		return ;
	}
	[super display] ;
}

- (void)orderFrontRegardless {
	if (WINDOWLESS) {
		return ;
	}
	[super orderFrontRegardless] ;
}

- (void)orderFront:(id)sender {
	if (WINDOWLESS) {
		return ;
	}
	[super display] ;
}

- (void)orderBack:(id)sender {
	if (WINDOWLESS) {
		return ;
	}
	[super orderFront:sender] ;
}

- (void)makeMainWindow {
	if (WINDOWLESS) {
		return ;
	}
	[super makeMainWindow] ;
}

- (void)makeKeyWindow {
	if (WINDOWLESS) {
		return ;
	}
	[super makeKeyWindow] ;
}

- (void)makeKeyAndOrderFront:(id)sender {
	if (WINDOWLESS) {
		return ;
	}
	[super makeKeyAndOrderFront:sender] ;
}

- (void)orderWindow:(NSWindowOrderingMode)orderingMode relativeTo:(NSInteger)otherWindowNumber {
	if (WINDOWLESS) {
		return ;
	}
	[super orderWindow:orderingMode relativeTo:otherWindowNumber] ;
}

#endif

@end