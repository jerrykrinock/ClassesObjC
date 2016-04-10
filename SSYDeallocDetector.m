#import "SSYDeallocDetector.h"


@implementation SSYDeallocDetector

@synthesize invocation = m_invocation ;
@synthesize logMsg = m_logMsg ;

#if 0
#warning  Logging R&R of Dealloc Detector
- (id)retain {
	NSLog(@"75133: Retained SSYDeallocDetector %p", self) ;
	return [super retain] ;
}

- (oneway void)release {
	NSLog(@"75143: Released SSYDeallocDetector %p", self) ;
	[super release] ;
}
#endif

- (void)dealloc {
	[[self invocation] invoke] ;
	[m_invocation release] ;

    if (m_logMsg) {
        NSLog(@"Deallocced %p %@", (__bridge void*)self, m_logMsg) ;
    }
    [m_logMsg release] ;
    
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