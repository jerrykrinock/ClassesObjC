#import "SSYOperation.h"
#import "SSYOperationQueue.h"
#import "NSError+SSYAdds.h"
#import "SSYDebug.h"
#import "NSDate+NiceFormats.h"

#if DEBUG
// Do not ship with this because method names will be logged so crackers can see.
#if 0
#warning Logging SSYOperationLinker Operations (a cracking risk)
#define LOGGING_SSYOPERATIONLINKER_OPERATIONS 1
#import "BkmxGlobals.h"
#import "Client.h"
#import "Ixporter.h"
#endif	
#endif

// We don't use 0 because that is the default condition of NSConditionLock if
// no condition has been set.
#define SSY_OPERATION_BLOCKED 1
#define SSY_OPERATION_CLEARED 2

NSString* const constKeySSYOperationLock = @"SSYOperationLock" ;

@interface SSYOperation ()

@property (retain) id target ;
@property (assign) BOOL skipIfError ;

@end



@implementation SSYOperation

@synthesize info = m_info ;
@synthesize target = m_target ;
@synthesize selector = m_selector ;
@synthesize operationQueue = m_operationQueue ;
@synthesize cancellor = m_cancellor ;
@synthesize skipIfError = m_skipIfError ;

- (id)owner {
	return m_owner ;
}

- (void)setOwner:(id)owner {
	m_owner = owner ;
}

- (void)cancel {
	[[self cancellor] invoke] ;
	[super cancel] ;
}

- (void)dealloc {
    [m_info release] ;
	[m_cancellor release] ;
	[m_target release] ;
	
    [super dealloc] ;
}

- (id)initWithInfo:(NSMutableDictionary*)info
			target:(id)target
		  selector:(SEL)selector
			 owner:(id)owner
	operationQueue:(SSYOperationQueue*)operationQueue
	   skipIfError:(BOOL)skipIfError {
	self = [super init] ;
    if (self) {
		[self setInfo:info] ;
		[self setSelector:selector] ;
		[self setTarget:target] ;
		[self setOwner:owner] ;
		[self setOperationQueue:operationQueue] ;
		[self setSkipIfError:skipIfError] ;
	}
	
	return self ;
}

- (NSError*)error {
	NSError* error = [[self operationQueue] error] ;

	if ([SSYOperationQueue operationGroupsDifferInfo:[error userInfo]
										   otherInfo:[self info]]) {
		error = nil ;
	}
	
	return error ;
}

- (void)setError:(NSError*)error {
	[[self operationQueue] setError:error
						  operation:self] ;
}

- (NSString*)description {
	NSString* selectorName = NSStringFromSelector([self selector]) ;
	if ([selectorName isEqualToString:@"doDone:"]) {
		selectorName = [selectorName stringByAppendingFormat:
						@" (%@)",
						[[self info] objectForKey:constKeySSYOperationQueueDoneSelectorName]] ;
	}
	return [NSString stringWithFormat:
			@"%@ %p group=%@ selector=%@",
			[self className],
			self,
			[[self info] objectForKey:constKeySSYOperationGroup],
			selectorName] ;
}

- (void)doSafely:(SEL)cmdNameC {
	NSString* selectorName = NSStringFromSelector(cmdNameC) ;
	selectorName = [selectorName stringByAppendingString:@"_unsafe"] ;
	[self performSelectorOnMainThread:NSSelectorFromString(selectorName)
						   withObject:nil
						waitUntilDone:YES] ;	
}

- (void)prepareLock {
	NSConditionLock* oldLock = [[self info] objectForKey:constKeySSYOperationLock] ;
	// Normally, oldLock should be nil at this point, if prior usage of this lock is done.
	// For a while, I did this:
	//    NSAssert3((oldLock == nil), @"Lock %p is already in info %p for %@", oldLock, [self info], self) ;
	// but that got me into some trouble.
	// So now I just log a warning if there's an old lock which has not been cleared.
	if (oldLock != nil) {
		if ([oldLock condition] != SSY_OPERATION_CLEARED) {
			NSLog(@"Warning 209-8483 %@ with condition %ld in info %p for %@ is being replaced.",
				  oldLock, (long)[oldLock condition], [self info], self) ;
		}
	}
	// I considered doing this:
	// [oldLock unlockWithCondition:SSY_OPERATION_CLEARED] ;
	// But am worried that it might raise an exception trying to unlock a lock on a
	// thread that did not lock it.  Maybe I'm just imagining that I ever saw that
	// exception, or getting it mixed up with something else.  Can't find it in
	// documentation at the moment.
	NSConditionLock* lock = [[NSConditionLock alloc] initWithCondition:SSY_OPERATION_BLOCKED] ;
	[[self info] setObject:lock
					forKey:constKeySSYOperationLock] ;
	NSString* name = [NSString stringWithFormat:
					  @"SSYOperation's built-in lock created %@ by %@ on %@ (%@main)",
					  [[NSDate date] geekDateTimeString],
					  SSYDebugCaller(),
					  [NSThread currentThread],
					  ([[NSThread currentThread] isMainThread] ? @"" : @"non-")] ;
	[lock setName:name] ;
	[lock release] ;
}

- (void)lockLock {
	NSConditionLock* lock = [[self info] objectForKey:constKeySSYOperationLock] ;
	
	// The following was added in BookMacster 1.11.2
	BOOL succeeded = [lock tryLock] ;
	if (!succeeded) {
		// This will happen if the lock is already locked
		NSLog(@"Warning 094-4701 %@", lock) ;
	}
	// Prior to BookMacster 1.11.2, the above was simply [lock lock].  I changed it to eliminate
	// deadlock if this method is called more than once prior to -unlockLock.
}

- (void)blockForLock {
	NSConditionLock* lock = [[self info] objectForKey:constKeySSYOperationLock] ;
	BOOL workFinishedInTime = [lock lockWhenCondition:SSY_OPERATION_CLEARED
										   beforeDate:[NSDate distantFuture]] ;
	
	// Will block here until lock condition is SSY_OPERATION_CLEARED
	
	if (workFinishedInTime) {
		[lock unlock] ;
	}
	
	// We are done with this lock, so …
	[[self info] removeObjectForKey:constKeySSYOperationLock] ;
}

- (void)unlockLock {
	NSConditionLock* lock = [[self info] objectForKey:constKeySSYOperationLock] ;

	// New code, BookMacster 1.11.2
	// If we send -unlockWithCondition to a condition lock which has already
	// been unlocked, Cocoa raises an exception.  To avoid that, we try to
	// lock it first.  If it's already locked, tryLock is a no-op.
	[lock tryLock] ;
	[lock unlockWithCondition:SSY_OPERATION_CLEARED] ;

#if 0
	// Old code
	// If we send -unlockWithCondition to a condition lock which has already
	// been unlocked, Cocoa raises an exception.  To avoid that, we check
	// the condition.
	if ([lock condition] == SSY_OPERATION_BLOCKED) {
		[lock unlockWithCondition:SSY_OPERATION_CLEARED] ;
	}
#endif
}


- (void)main {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init] ;
#if LOGGING_SSYOPERATIONLINKER_OPERATIONS
	NSLog(@"run op: %p extore=%@ grp=%@ prevErr=%ld nQ=%ld sel=%@ isCnc=%hhd",
		  self,
		  [(Client*)[(Ixporter*)[[self info] objectForKey:constKeyIxporter] client] displayName],
		  [[self info] objectForKey:constKeySSYOperationGroup],
		  (long)[[self error] code],
		  (long)[[[self operationQueue] operations] count], // nQ = number in queue
		  NSStringFromSelector([self selector]),
		  [self isCancelled]) ;
#endif
	
	if (![self isCancelled]) {
		if (![[self operationQueue] shouldSkipOperationsInGroup:[[self info] objectForKey:constKeySSYOperationGroup]]) {
			if (![self error] || ![self skipIfError]) {
				@try {
					id target = [self target] ;
					if (target) {
						[target performSelector:[self selector]
									 withObject:[self info]] ;
					}
					else {
						// In this case, selector is usually defined in a category
						target = self ;
						[target performSelector:[self selector]] ;
					}
				}
				@catch (NSException* exception) {
					NSString* msg = @"An exception was raised." ;
					NSError* error_ = SSYMakeError(56810, msg) ;
					error_ = [error_ errorByAddingUnderlyingException:exception] ;
					[self setError:error_] ;
				}
				@finally {
				}		
			}
			else {
				// Chain operations have been aborted.
				// This method becomes a no-op.
#if LOGGING_SSYOPERATIONLINKER_OPERATIONS
				NSLog(@"   No-op due to err") ;
#endif
			}
		}
		else {
#if LOGGING_SSYOPERATIONLINKER_OPERATIONS
			NSLog(@"   No-op due to group skip") ;
#endif
		}
	}
	else {
#if LOGGING_SSYOPERATIONLINKER_OPERATIONS
		NSLog(@"   No-op due to cancelled") ;
#endif
	}		

	[pool release] ;
}


@end