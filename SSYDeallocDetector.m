#import "SSYDeallocDetector.h"


@implementation SSYDeallocDetector

@synthesize invocation = m_invocation ;

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
	[super dealloc] ;
}

- (id)initWithInvocation:(NSInvocation*)invocation {
	self = [super init] ;
	if (self) {
		[self setInvocation:invocation] ;
	}
	
	return self ;
}

+ (SSYDeallocDetector*)detectorWithInvocation:(NSInvocation*)invocation {
	SSYDeallocDetector* instance = [[SSYDeallocDetector alloc] initWithInvocation:invocation] ;
	return [instance autorelease] ;
}

@end