#import "SSYBlocker.h"

#define SSY_BLOCKER_BLOCKED 0
#define SSY_BLOCKER_CLEARED 1

@interface SSYBlocker ()

@property (retain) NSConditionLock* lock ;

@end

@implementation SSYBlocker

@synthesize lock = m_lock ;

- (void)dealloc {
	[m_lock release] ;

	[super dealloc] ;
}

- (id)init {
	self = [super init] ;
	if (self) {
		NSConditionLock* lock = [[NSConditionLock alloc] initWithCondition:SSY_BLOCKER_BLOCKED] ;
		[self setLock:lock] ;
		[lock release] ;
	}
	
	return self ;
}

- (void)lockLock {
	[[self lock] lock] ;
}

- (void)blockForLock {
	NSConditionLock* lock = [self lock] ;
	BOOL workFinishedInTime = [lock lockWhenCondition:SSY_BLOCKER_CLEARED
										   beforeDate:[NSDate distantFuture]] ;
	if (workFinishedInTime) {
		[lock unlock] ;
	}
}

- (void)unlockLock {
	// If we send -unlockWithCondition to a condition lock which has already
	// been unlocked, Cocoa raises an exception.  To avoid that, we check
	// that -unlockLock has not already been sent for this locking cycle.
	if ([[self lock] condition] == SSY_BLOCKER_BLOCKED) {
		[[self lock] unlockWithCondition:SSY_BLOCKER_CLEARED] ;
	}
}

@end