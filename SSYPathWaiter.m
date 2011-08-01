#import "SSYPathWaiter.h"
#import "SSYPathObserver.h"
#import "SSYBlocker.h"
#import "NSInvocation+Quick.h"
#import "SSYRunLoopTickler.h"

// For debugging
#import "NSDate+NiceFormats.h"

#define SSYPathWaiterNotifeeConditionWaiting 0
#define SSYPathWaiterNotifeeConditionDone 1

NSString* const constKeySSYPathWaiterObserver = @"obsr" ;
NSString* const constKeySSYPathWaiterNotifee = @"ntfe" ;
NSString* const constKeySSYPathWaiterBlocker = @"blkr" ;
NSString* const constKeySSYPathWaiterPath = @"path" ;
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
	NSString* path = [info objectForKey:constKeySSYPathWaiterPath] ;
	SSYBlocker* blocker = [info objectForKey:constKeySSYPathWaiterBlocker] ;

	SSYPathObserver* observer = [[SSYPathObserver alloc] init] ;
	SSYPathWaiterNotifee* notifee = [[SSYPathWaiterNotifee alloc] init] ;
	
	[blocker lockLock] ;
	
	NSError* error = nil ;
	BOOL ok = [observer addPath:path
					 watchFlags:SSYPathObserverChangeFlagsDelete
				   notifyThread:[NSThread currentThread]
					   userInfo:self
						error_p:&error] ;
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



- (BOOL)blockUntilDeletedPath:(NSString*)path
					  timeout:(NSTimeInterval)timeout {
	BOOL ok = YES ;
	// There may be a possibility of a race condition here.  I'm not sure if this fixes it
	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		SSYBlocker* blocker = [[SSYBlocker alloc] init] ;
		
		NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
							  blocker, constKeySSYPathWaiterBlocker,
							  path, constKeySSYPathWaiterPath,
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

	return ok ;
}
@end