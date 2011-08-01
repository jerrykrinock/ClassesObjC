#import "SSYThreadPauser.h"
#import "NSInvocation+Quick.h"

NSString* const SSYThreadPauserKeyLock = @"SSYThreadPauserKeyLock" ;
NSString* const SSYThreadPauserKeyInvocation = @"SSYThreadPauserKeyInvocation" ;

#define WORK_IS_NOT_DONE 0
#define WORK_IS_DONE 1


@implementation SSYThreadPauser

- (void)beginWorkWithInfo:(NSDictionary*)info {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init] ;
	NSConditionLock* lock = [info objectForKey:SSYThreadPauserKeyLock] ;
	[lock lock] ;
	NSInvocation* invocation = [info objectForKey:SSYThreadPauserKeyInvocation] ;
	
	// Do actual work
	[invocation invoke] ;
	
	[lock unlockWithCondition:WORK_IS_DONE] ;
	[pool drain] ;
}


+ (BOOL)blockUntilWorker:(id)worker
				selector:(SEL)selector	
				  object:(id)object
				  thread:(NSThread*)workerThread
				 timeout:(NSTimeInterval)timeout {
	SSYThreadPauser* instance = [[SSYThreadPauser alloc] init] ;
	
	NSInvocation* invocation = [NSInvocation invocationWithTarget:worker
														 selector:selector
												  retainArguments:YES
												argumentAddresses:&object] ;
	
	NSConditionLock* lock = [[NSConditionLock alloc] initWithCondition:WORK_IS_NOT_DONE] ;
	
	NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
						  invocation, SSYThreadPauserKeyInvocation,
						  lock, SSYThreadPauserKeyLock,
						  nil] ;
	
	// Begin Work
	if (workerThread) {
		[instance performSelector:@selector(beginWorkWithInfo:)
						 onThread:workerThread
					   withObject:info
					waitUntilDone:NO] ;
	}
	else {
		// Default if no workerThread given is to create one
		workerThread = [[[NSThread alloc] initWithTarget:instance
												selector:@selector(beginWorkWithInfo:)
												  object:info] autorelease] ;
		// Name the thread, to help in debugging.
		[workerThread setName:@"Worker created by SSYThreadPauser"] ;
		[workerThread start] ;
	}
	
	// Will block here until work is done, or timeout
	BOOL workFinishedInTime = [lock lockWhenCondition:WORK_IS_DONE
										   beforeDate:[NSDate dateWithTimeIntervalSinceNow:timeout]] ;
	if (workFinishedInTime) {
		[lock unlock] ;
	}
	[workerThread cancel] ;
	
	[instance release] ;
	[lock release] ;
	
	return (workFinishedInTime) ;
}


@end


#if 0

@interface WorkerDemo : NSObject {}

- (void)doWorkForTimeInterval:(NSNumber*)interval ;

@end


@implementation WorkerDemo

#define CANCEL_GRANULARITY 10

- (void)doWorkForTimeInterval:(NSNumber*)interval {
	NSLog(@"2308: Beginning work") ;
	
	NSTimeInterval timeChunk = [interval doubleValue]/CANCEL_GRANULARITY ;
	NSInteger i ;
	for (i=0; i<CANCEL_GRANULARITY; i++) {
		usleep(1e6 * timeChunk) ;
		if ([[NSThread currentThread] isCancelled]) {
			NSLog(@"2492 Cancelling work") ;
			break ;
		}
	}
	
	NSLog(@"2557: Ending work") ;
}

@end

#endif