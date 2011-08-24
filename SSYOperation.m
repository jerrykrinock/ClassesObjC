#import "SSYOperation.h"
#import "SSYOperationQueue.h"
#import "NSError+SSYAdds.h"

#if DEBUG
// Do not ship with this because method names will be logged so crackers can see.
#if 1
#warning Logging SSYOperationLinker Operations (a cracking risk)
#define LOGGING_SSYOPERATIONLINKER_OPERATIONS 1
#import "BkmxGlobals.h"
#import "Client.h"
#import "Ixporter.h"
#endif	
#endif

#define SSY_OPERATION_BLOCKED 0
#define SSY_OPERATION_CLEARED 1

NSString* const constKeySSYOperationLock = @"SSYOperationLock" ;

@interface SSYOperation ()

@end


@implementation SSYOperation

@synthesize info = m_info ;
@synthesize selector = m_selector ;
@synthesize operationQueue = m_operationQueue ;
@synthesize cancellor = m_cancellor ;

- (id)owner {
	return m_owner ;
}

- (void)setOwner:(id)owner {
	m_owner = owner ;
}

- (void)cancel {
	[[self cancellor] invoke] ;
}

- (void)dealloc {
    [m_info release] ;
	[m_cancellor release] ;
	
    [super dealloc] ;
}

- (id)initWithInfo:(NSMutableDictionary*)info
		  selector:(SEL)selector
			 owner:(id)owner
	operationQueue:(SSYOperationQueue*)operationQueue {
	self = [super init] ;
    if (self) {
		[self setInfo:info] ;
		[self setSelector:selector] ;
		[self setOwner:owner] ;
		[self setOperationQueue:operationQueue] ;
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

- (void)skipQueuedOperationsInOtherGroups {
	[[self operationQueue] setSkipOperationsExceptGroup:[[self info] objectForKey:constKeySSYOperationGroup]] ;
}

- (NSString*)description {
	return [NSString stringWithFormat:
			@"%@ %p group=%@ selector=%@",
			[self className],
			self,
			[[self info] objectForKey:constKeySSYOperationGroup],
			NSStringFromSelector([self selector])] ;
}

- (void)doSafely:(SEL)cmdNameC {
	NSString* selectorName = NSStringFromSelector(cmdNameC) ;
	selectorName = [selectorName stringByAppendingString:@"_unsafe"] ;
	[self performSelectorOnMainThread:NSSelectorFromString(selectorName)
						   withObject:nil
						waitUntilDone:YES] ;	
}

- (void)prepareLock {
	NSAssert(([[self info] objectForKey:constKeySSYOperationLock] == nil), @"Lock is already in use") ;
	NSConditionLock* lock = [[NSConditionLock alloc] initWithCondition:SSY_OPERATION_BLOCKED] ;
	[[self info] setObject:lock
					forKey:constKeySSYOperationLock] ;
	[lock release] ;
}

- (void)lockLock {
	[[[self info] objectForKey:constKeySSYOperationLock] lock] ;
}

- (void)blockForLock {
	NSConditionLock* lock = [[self info] objectForKey:constKeySSYOperationLock] ;
	BOOL workFinishedInTime = [lock lockWhenCondition:SSY_OPERATION_CLEARED
										   beforeDate:[NSDate distantFuture]] ;
	if (workFinishedInTime) {
		[lock unlock] ;
	}
	
	[[self info] removeObjectForKey:constKeySSYOperationLock] ;
}

- (void)unlockLock {
	// If we send -unlockWithCondition to a condition lock which has already
	// been unlocked, Cocoa raises an exception.  To avoid that, we check
	// that -unlockLock has not already been sent for this locking cycle.
	if ([[[self info] objectForKey:constKeySSYOperationLock] condition] == SSY_OPERATION_BLOCKED) {
		[[[self info] objectForKey:constKeySSYOperationLock] unlockWithCondition:SSY_OPERATION_CLEARED] ;
	}
}


- (void)main {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init] ;
		
#if LOGGING_SSYOPERATIONLINKER_OPERATIONS
	NSLog(@"op: extore=%@ grp=%@ prevErr=%d nQ=%d nextSel=%@",
		  [(Client*)[(Ixporter*)[[self info] objectForKey:constKeyIxporter] client] displayName],
		  [[self info] objectForKey:constKeySSYOperationGroup],
		  [[self error] code],
		  [[[SSYOperationQueue maenQueue] operations] count], // nQ = number in queue
		  NSStringFromSelector([self selector])) ;
#endif
	
	if (![[self operationQueue] shouldSkipOperationsInGroup:[[self info] objectForKey:constKeySSYOperationGroup]]) {
		if (![self error]) {
			@try {
				// Note: selector is usually defined in a category
				[self performSelector:[self selector]] ;
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
		
	[pool release] ;
}


@end