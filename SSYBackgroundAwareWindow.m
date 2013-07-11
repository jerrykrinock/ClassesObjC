#import "SSYBackgroundAwareWindow.h"
#import "SSYProcessTyper.h"

@implementation SSYBackgroundAwareWindow

- (BOOL)keepHidden {
    return ([SSYProcessTyper currentType] != SSYProcessTyperTypeForeground) ;
}

- (BOOL)canBecomeKeyWindow {
    if ([self keepHidden]) {
        return NO ;
    }
    return [super canBecomeKeyWindow] ;
}

- (BOOL)canBecomeMainWindow {
    if ([self keepHidden]) {
        return NO ;
    }
    return [super canBecomeMainWindow] ;
}

#if 0
#warning Experimenting with More Windowlessness
// I found it not necessary to override these methods, so I didn't.
// But maybe I didn't find all the corner cases.  Someday, I might?

/*
 @brief    Override which becomes a no-op if the the current process is not a
 foreground process (currentType != SSYProcessTyperTypeForeground), otherwise
 invokes super
 */
- (void)displayIfNeeded {
	if ([self keepHidden]) {
		return ;
	}
	[super displayIfNeeded] ;
}

- (void)display {
	if ([self keepHidden]) {
		return ;
	}
	[super display] ;
}

- (void)orderFrontRegardless {
	if ([self keepHidden]) {
		return ;
	}
	[super orderFrontRegardless] ;
}

- (void)orderFront:(id)sender {
	if ([self keepHidden]) {
		return ;
	}
	[super display] ;
}

- (void)orderBack:(id)sender {
	if ([self keepHidden]) {
		return ;
	}
	[super orderFront:sender] ;
}

- (void)makeMainWindow {
	if ([self keepHidden]) {
		return ;
	}
	[super makeMainWindow] ;
}

- (void)makeKeyWindow {
	if ([self keepHidden]) {
		return ;
	}
	[super makeKeyWindow] ;
}

- (void)makeKeyAndOrderFront:(id)sender {
	if ([self keepHidden]) {
		return ;
	}
	[super makeKeyAndOrderFront:sender] ;
}

- (void)orderWindow:(NSWindowOrderingMode)orderingMode relativeTo:(NSInteger)otherWindowNumber {
	if ([self keepHidden]) {
		return ;
	}
	[super orderWindow:orderingMode relativeTo:otherWindowNumber] ;
}

#endif

@end
