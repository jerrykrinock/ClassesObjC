#import "SSYPathWaiter.h"
#import "SSYBlocker.h"

// For debugging

#define SSYPathWaiterNotifeeConditionWaiting 0
#define SSYPathWaiterNotifeeConditionDone 1

NSString* const constKeySSYPathWaiterObserver = @"obsr" ;
NSString* const constKeySSYPathWaiterNotifee = @"ntfe" ;
NSString* const constKeySSYPathWaiterBlocker = @"blkr" ;
NSString* const constKeySSYPathWaiterPaths = @"paths" ;
NSString* const constKeySSYPathWaiterWatchFlags = @"flgs" ;
NSString* const constKeySSYPathWaiterTimeout = @"tmot" ;

@interface SSYPathWaiterNotifee : NSObject {
	BOOL m_isDone ;
}

@property (assign) BOOL isDone ;

@end

@interface SSYPathWaiter ()

@property (assign) BOOL succeeded ;

@end


@implementation SSYPathWaiterNotifee

@synthesize isDone = m_isDone ;

- (void)processNote:(NSNotification*)note {
	NSDictionary* info = [note userInfo] ;
	SSYPathWaiter* waiter = [info objectForKey:SSYPathObserverUserInfoKey] ;
	[waiter setSucceeded:YES] ;
	[self setIsDone:YES] ;	
}

- (void)timeOutTimer:(NSTimer*)timer {
	[self setIsDone:YES] ;	
}


@end


@implementation SSYPathWaiter


@synthesize succeeded = m_succeeded ;

- (void)waitWithInfo:(NSDictionary*)info {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init] ;
	
	NSTimeInterval timeout = [[info objectForKey:constKeySSYPathWaiterTimeout] doubleValue] ;
	NSSet* paths = [info objectForKey:constKeySSYPathWaiterPaths] ;
	uint32_t watchFlags = (uint32_t)[[info objectForKey:constKeySSYPathWaiterWatchFlags] unsignedIntegerValue] ;
	SSYBlocker* blocker = [info objectForKey:constKeySSYPathWaiterBlocker] ;

	SSYPathObserver* observer = [[SSYPathObserver alloc] init] ;
	SSYPathWaiterNotifee* notifee = [[SSYPathWaiterNotifee alloc] init] ;
	
	[blocker lockLock] ;
	
	NSError* error = nil ;
	BOOL ok = YES ;
    for (NSString* path in paths) {
        ok = [observer addPath:path
					 watchFlags:watchFlags
				   notifyThread:[NSThread currentThread]
					   userInfo:self
						error_p:&error] ;
        if (!ok) {
            break ;
        }
    }
    
	if (ok) {
		[[NSNotificationCenter defaultCenter] addObserver:notifee
												 selector:@selector(processNote:)
													 name:SSYPathObserverChangeNotification
												   object:observer] ;
		[NSTimer scheduledTimerWithTimeInterval:timeout
										 target:notifee
									   selector:@selector(timeOutTimer:)
									   userInfo:info
										repeats:NO] ;
		
#if 0
		BOOL keepGoing = YES ;
		while (keepGoing) {
			BOOL moreToRun = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
													  beforeDate:[NSDate distantFuture]] ;
			BOOL isDone = [notifee isDone] ;
			keepGoing = moreToRun && !isDone ;
		}
#else		
		while (![notifee isDone] && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
															 beforeDate:[NSDate distantFuture]]) {
		}
#endif

		[[NSNotificationCenter defaultCenter] removeObserver:notifee] ;
	}
	else {
		NSLog(@"5485348 error: %@", error) ;
	}
	
	[blocker unlockLock] ;
	[notifee release] ;
	[observer release] ;
	
	[pool drain] ;
}



- (BOOL)blockUntilWatchFlags:(uint32_t)watchFlags
                       paths:(NSSet*)paths
					 timeout:(NSTimeInterval)timeout {
	BOOL ok = YES ;

    // As always when dealing with files, there is a possibility of a race
    // condition here.  But we check anyhow.
    NSMutableSet* pathsExisting = [[NSMutableSet alloc] init] ;
    for (NSString* path in paths) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [pathsExisting addObject:path] ;
        }
    }
    
    if ([pathsExisting count] > 0) {
		SSYBlocker* blocker = [[SSYBlocker alloc] init] ;
		
		NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
							  blocker, constKeySSYPathWaiterBlocker,
							  pathsExisting, constKeySSYPathWaiterPaths,
							  [NSNumber numberWithUnsignedLong:watchFlags], constKeySSYPathWaiterWatchFlags,
							  [NSNumber numberWithDouble:timeout], constKeySSYPathWaiterTimeout,
							  nil] ;
		
		NSThread* notifeeThread = [[NSThread alloc] initWithTarget:self
														  selector:@selector(waitWithInfo:)
															object:info] ;
		// Name the thread, to help in debugging.
		[notifeeThread setName:@"SSYPathWaiter-Notifee"] ;
		[notifeeThread start] ;	
		
		// Will block here until work is done, or timeout
		[blocker blockForLock] ;
		ok = [self succeeded] ;
		
		[notifeeThread cancel] ;
		[notifeeThread release] ;

		[blocker release] ;
	}
    else {
        ok = NO ;
    }

    [pathsExisting release] ;
    
	return ok ;
}

- (BOOL)blockUntilWatchFlags:(uint32_t)watchFlags
						path:(NSString*)path
					 timeout:(NSTimeInterval)timeout {
    return [self blockUntilWatchFlags:watchFlags
                                paths:[NSSet setWithObject:path]
                              timeout:timeout] ;
}

@end