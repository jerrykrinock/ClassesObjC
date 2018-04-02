#import "SSYDeallocDetector.h"


@implementation SSYDeallocDetector

#if 0
#warning  Logging retains, releases and deallocs of Dealloc Detector
#define LOG_RETAINS_RELEASES_AND_DEALLOCS 1
#endif

#if LOG_RETAINS_RELEASES_AND_DEALLOCS
- (id)retain {
	NSLog(@"75133: Retained SSYDeallocDetector %p", (__bridge void*)self) ;
	return [super retain] ;
}

- (oneway void)release {
	NSLog(@"75143: Released SSYDeallocDetector %p", (__bridge void*)self) ;
	[super release] ;
}
#endif

- (void)dealloc {
	[_invocation invoke] ;

    [_invocation release] ;
#if LOG_RETAINS_RELEASES_AND_DEALLOCS
    NSLog(@"75153 Deallocced %p", (__bridge void*)self) ;
#else
    if (_logMsg) {
        NSLog(@"Deallocced %p %@", (__bridge void*)self, _logMsg) ;
    }
#endif

    [_logMsg release] ;
    
	[super dealloc] ;
}

- (id)initWithInvocation:(NSInvocation*)invocation
                  logMsg:(NSString*)logMsg {
	self = [super init] ;
	if (self) {
		[self setInvocation:invocation] ;
        [self setLogMsg:logMsg] ;
        if (logMsg) {
            NSLog(@"Created %p %@", (__bridge void*)self, logMsg) ;
        }
	}
	
	return self ;
}

+ (SSYDeallocDetector*)detectorWithInvocation:(NSInvocation*)invocation
                                       logMsg:(NSString*)logMsg {
    SSYDeallocDetector* instance = [[SSYDeallocDetector alloc] initWithInvocation:invocation
                                                                           logMsg:logMsg] ;
	return [instance autorelease] ;
}

@end
