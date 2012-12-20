#import "SSYOperationQueue.h"
#import "SSYOperation.h"
#import "NSOperationQueue+Depends.h"
#import "BkmxGlobals.h"
#import "Extore.h"
#import "NSError+SSYAdds.h"
#import "NSInvocation+Quick.h"
#import "NSInvocation+Nesting.h"
#import "SSYOperation.h"


NSString* const SSYOperationQueueDidEndWorkNotification = @"SSYOperationQueueDidEndWorkNotification" ;
NSString* const SSYOperationQueueDidBeginWorkNotification = @"SSYOperationQueueDidBeginWorkNotification" ;

NSString* const constKeySSYOperationQueueDoneThread = @"SSYOperationQueueDoneThread" ;
NSString* const constKeySSYOperationQueueDoneTarget = @"SSYOperationQueueDoneTarget" ;
NSString* const constKeySSYOperationQueueDoneSelectorName = @"SSYOperationQueueDoneSelectorName" ;
NSString* const constKeySSYOperationQueueInfo = @"SSYOperationQueueInfo" ;
NSString* const constKeySSYOperationQueueError = @"SSYOperationQueueError" ;
NSString* const constKeySSYOperationQueueKeepWithNext = @"SSYOperationQueueKeepWithNext" ;
NSString* const constKeySSYOperationGroup = @"SSYOperationGroup" ;


// No longer needed since override of -[SSYOperationQueue setError:] does this.  @implementation NSError (SSYOperationQueueExtras)

// No longer needed since override of -[SSYOperationQueue setError:] does this.  - (NSError*)errorByAddingOperationGroupFromInfo:(NSDictionary*)info {
// No longer needed since override of -[SSYOperationQueue setError:] does this.  	return [self errorByAddingUserInfoObject:[info objectForKey:constKeySSYOperationGroup]
// No longer needed since override of -[SSYOperationQueue setError:] does this.  									  forKey:constKeySSYOperationGroup] ;
// No longer needed since override of -[SSYOperationQueue setError:] does this.  }

// No longer needed since override of -[SSYOperationQueue setError:] does this.  @end



@implementation SSYOperationQueue

@synthesize scriptCommand = m_scriptCommand ;
@synthesize scriptResult = m_scriptResult ;
@synthesize skipOperationsExceptGroups = m_skipOperationsExceptGroups ;

- (BOOL)shouldSkipOperationsInGroup:(NSString*)group {
	NSSet* skipOperationsExceptGroups = [self skipOperationsExceptGroups] ;

	if (!skipOperationsExceptGroups) {
		return NO ;
	}
	
	if (!group) {
		return NO ;
	}
	
	if ([skipOperationsExceptGroups member:group] != nil) {
		return NO ;
	}
	
	return YES ;
}

- (NSError*)error {
	NSError* error ;
	@synchronized(self) {
		error = m_error ; ;
	}
	return error ;
}

- (void)setError:(NSError*)error
  operationGroup:(NSString*)operationGroup {
	error = [error errorByAddingUserInfoObject:operationGroup
										forKey:constKeySSYOperationGroup] ;
	
	@synchronized(self) {
		[m_error release] ;
		m_error = error ;
		[m_error retain] ;
	}
}

- (void)setError:(NSError*)error
	   operation:(SSYOperation*)operation {
	NSString* operationGroup = [[operation info] objectForKey:constKeySSYOperationGroup] ;
	[self setError:error
	operationGroup:operationGroup] ;
}

- (NSInvocation*)errorRetryInvocation {
	NSInvocation* answer ;
	if (m_errorRetryInvocations) {
		NSArray* frozenInvocations = [[NSArray alloc] initWithArray:m_errorRetryInvocations] ;
		answer = [NSInvocation invocationWithInvocations:frozenInvocations] ;
		[frozenInvocations release] ;
	}
	else {
		answer = nil ;
	}
	
	return answer ;
}

- (void)appendErrorRetryInvocation:(NSInvocation*)invocation {
	if (!m_errorRetryInvocations) {
		m_errorRetryInvocations = [[NSMutableArray alloc] init] ;
	}
	
	[m_errorRetryInvocations addObject:invocation] ;
}

- (void)removeAllErrorRetryInvocations {
	[m_errorRetryInvocations release] ;
	m_errorRetryInvocations = nil ;
}

- (id)init {
	self = [super init] ;
	if (self) {
		[self addObserver:self
			   forKeyPath:@"operations"
				  options:NSKeyValueObservingOptionOld + NSKeyValueObservingOptionNew
				  context:NULL] ;
		// By default, KVO notifications are sent only *after* the change
		// has been made, so we only need NSKeyValueObservingOptionOld,
		// not NSKeyValueObservingOptionNew.
	}
	
	return self ;
}

- (void)dealloc {
	// Probably this is not necessary but I'm paranoid about KVO.
	[self removeObserver:self
			  forKeyPath:@"operations"] ;
	
	[m_error release] ;
	[m_scriptCommand release] ;
	[m_scriptResult release] ;
	[m_errorRetryInvocations release] ;
	[m_skipOperationsExceptGroups release] ;
	
	[super dealloc] ;
}

+ (BOOL)operationGroupsDifferInfo:(NSDictionary*)info
						otherInfo:(NSDictionary*)otherInfo {
	id group1 = [info objectForKey:constKeySSYOperationGroup] ;
	id group2 = [otherInfo objectForKey:constKeySSYOperationGroup] ;
	if (group1 && group2) {
		if (![group1 isEqual:group2]) {
			return YES ;
		}
	}
	
	return NO ;
}

+ (BOOL)operationGroupsSameInfo:(NSDictionary*)info
						otherInfo:(NSDictionary*)otherInfo {
	id group1 = [info objectForKey:constKeySSYOperationGroup] ;
	id group2 = [otherInfo objectForKey:constKeySSYOperationGroup] ;
	if (group1 && group2) {
		if ([group1 isEqual:group2]) {
			return YES ;
		}
	}
	
	return NO ;
}

- (void)postQueueDidBeginWorkForObject:(id)object {
	NSNotification* notification = [NSNotification notificationWithName:SSYOperationQueueDidBeginWorkNotification
																 object:object] ;
	[[NSNotificationQueue defaultQueue] enqueueNotification:notification
											   postingStyle:NSPostNow
											   coalesceMask:(NSNotificationCoalescingOnName|NSNotificationCoalescingOnSender)
												   forModes:nil] ;
	// See header doc regarding notifications for posting style explanation
}

- (void)postQueueDidEndWorkForObject:(id)object {
	NSNotification* notification = [NSNotification notificationWithName:SSYOperationQueueDidEndWorkNotification
																 object:object] ;
	[[NSNotificationQueue defaultQueue] enqueueNotification:notification
											   postingStyle:NSPostWhenIdle
											   coalesceMask:(NSNotificationCoalescingOnName|NSNotificationCoalescingOnSender)
												   forModes:nil] ;
	// See header doc regarding notifications for posting style explanation
	// See Note at bottom of this file for coalesceMask explanation
}

- (void)observeValueForKeyPath:(NSString*)keyPath
					  ofObject:(id)object
						change:(NSDictionary*)change
					   context:(void *)context {
	if ([keyPath isEqualToString:@"operations"]) {
		if ([[self operations] count] == 0) {
			// Since the count of operations cannot be negative,
			// and since you cannot change an element in an empty
			// array and still have it be empty, the above condition
			// *might* mean that the *count* has just changed from
			// some positive number down to 0.  However, after
			// repeated testing I found that, about 10% of the time,
			// after an Import that as interrupted by an error, this
			// method would be invoked, as expected, with:
			//   oldOperations = an array of 2 operations
			//   operations = an empty array
			// but then 1 millsecond later, invoked again with
			//   oldOperations = an empty array
			//   operations = a different empty array
			// To ignore that second invocation, I added this:
			NSArray* oldOperations = [change objectForKey:NSKeyValueChangeOldKey] ;
			// Digress to more defensive programming, since KVO
			// documentation has a lot of holes in it…
			NSAssert1([oldOperations respondsToSelector:@selector(objectAtIndex:)], @"Expected operations array, got %@", oldOperations) ;
			// Now back to handling that empty old array…
			if ([oldOperations count] == 0) {
				return ;
			}
			
			NSScriptCommand* scriptCommand = [self scriptCommand] ;
			NSError* error = [self error] ;
			if (error) {
				[scriptCommand setScriptErrorNumber:[error code]] ;
				[scriptCommand setScriptErrorString:[error localizedDescription]] ;
			}		
			[self setError:nil
				 operation:nil] ;
			[scriptCommand resumeExecutionWithResult:[self scriptResult]] ;
			[self setScriptCommand:nil] ;
			
			NSOperation <SSYOwnee> * operation = [oldOperations objectAtIndex:0] ;
			id owner ;
			if ([operation respondsToSelector:@selector(owner)]) {
				owner = [operation owner] ;
			}
			else {
				owner = self ;
			}

			// It is stated in the documentation of NSOperationQueue (in the
			// introduction, not in -operations) that KVO notifications
			// for -operations can occur on any thread.  However, our
			// notifications are expected to be sent on the main thread…
			[self performSelectorOnMainThread:@selector(postQueueDidEndWorkForObject:)
								   withObject:owner
								waitUntilDone:NO] ; // as in NO deadlocks :)
			
			[self setSkipOperationsExceptGroups:nil] ;
		}
		else if ([[change objectForKey:NSKeyValueChangeOldKey] count] == 0) {
			// Since the count of operations cannot be negative,
			// and since you cannot change an element in an empty
			// array, the above condition *must* mean that the *count* 
			// has just changed from 0 to some positive number.
			// Actually, even though I add operations one at a time in
			// queueGroup:::::::::, I see that I get one notification
			// when the count jumps from 0 to, say, 5.  Apparently,
			// KVO notifications are coalesced.

			NSOperation <SSYOwnee> * operation = [[self operations] objectAtIndex:0] ;
			id owner ;
			if ([operation respondsToSelector:@selector(owner)]) {
				owner = [operation owner] ;
			}
			else {
				owner = self ;
			}
			
			// It is stated in the documentation of NSOperationQueue (in the
			// introduction, not in -operations) that KVO notifications
			// for -operations can occur on any thread.  However, our
			// notifications are expected to be sent on the main thread…
			[self performSelectorOnMainThread:@selector(postQueueDidBeginWorkForObject:)
								   withObject:owner
								waitUntilDone:NO] ; // as in NO deadlocks :)
		}
	}
}

- (void)doDone:(NSDictionary*)doneInfo {
	NSError* error = [self error] ;
	
	// Note that if the doneTarget provided to queueGroup:::::::::
	// was nil or the doneSelector was NULL, doneThread will be nil
	// and the following statements will return nil.
	NSThread* doneThread = [doneInfo objectForKey:constKeySSYOperationQueueDoneThread] ;
	id doneTarget = [doneInfo objectForKey:constKeySSYOperationQueueDoneTarget] ;
	NSString* doneSelectorName = [doneInfo objectForKey:constKeySSYOperationQueueDoneSelectorName] ;

	NSMutableDictionary* realInfo = [doneInfo objectForKey:constKeySSYOperationQueueInfo] ;
	[realInfo setValue:error
				forKey:constKeySSYOperationQueueError] ;
	[doneTarget performSelector:NSSelectorFromString(doneSelectorName)
					   onThread:doneThread
					 withObject:realInfo
				  waitUntilDone:YES] ;
	
	if (![[doneInfo objectForKey:constKeySSYOperationQueueKeepWithNext] boolValue]) {
		[self removeAllErrorRetryInvocations] ;
	}
}

- (void)queueGroup:(NSString*)group
			 addon:(BOOL)addon
	 selectorNames:(NSArray*)selectorNames
			  info:(NSMutableDictionary*)info
			 block:(BOOL)block
			 owner:(id)owner
		doneThread:(NSThread*)doneThread
		doneTarget:(id)doneTarget
	  doneSelector:(SEL)doneSelector
	   keepWithNext:(BOOL)keepWithNext {
	if (!group) {
		group = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]] ;
	}
	// Capture our invocation, for possible error recovery in case we fail
	// and need to be repeated
	// Two big changes were made in this section in BookMacster 1.9.5, on 2012 Jan 05.
	// • This section now executes unconditionally, instead of only when !keepWithNext.
	//   This was done to fix a problem wherein, if an import failed and was re-executed
	//   during error recovery, only the final Import-Grande operations (beginning with
	//   -gulpImport) would be executed, because the initial Import-Grande operations and
	//   the per-importer operations were never bundled into errorRetryInvocations.
	//   According to previous comments, the conditional execution was to eliminate a
	//   retain cycle, but it was not very well explained and even noted in the header
	//   file that this was not well understood.  I think I understand it now.  See the
	//   header file comments for this method, for parameter keepWithNext.
	// • In iterating through -[info allKeys], constKeyDocument and constKeyIxporter are no
	//   longer skipped.  The former was done to eliminate Internal Error 208-9593, and 
	//   the latter was done because I couldn't think of any reason why it should be
	//   omitted either.
	// After making these two changes, I tested the new code for memory leaks and retain
	// cycles, but all Extore and Bkmslf instances seem to dealloc as expected.
	NSMutableDictionary* originalInfo = [NSMutableDictionary dictionary] ; //WithDictionary:info] ;
	for (NSString* key in [info allKeys]) {
		if ([key isEqualToString:@"Export Info Leak Detector"]) {
			continue ;
		}
		
		[originalInfo setObject:[info objectForKey:key]
											forKey:key] ;
	}
	NSInvocation* errorRetryInvocation = [NSInvocation invocationWithTarget:self
																   selector:_cmd
															retainArguments:YES
														  argumentAddresses:
										  &group,
										  &addon,
										  &selectorNames,
										  &originalInfo,
										  &block,
										  &owner,
										  &doneThread,
										  &doneTarget,
										  &doneSelector,
										  &keepWithNext] ;
	[self appendErrorRetryInvocation:errorRetryInvocation] ;
	
	[info setObject:group
			 forKey:constKeySSYOperationGroup] ;
	
	// Create an array of operations from the array of selector names
	NSMutableArray* operations = [[NSMutableArray alloc] init] ;
	for (NSString* selectorName in selectorNames) {
		SEL selector = NSSelectorFromString(selectorName) ;
		SSYOperation* op = [[SSYOperation alloc] initWithInfo:info
													   target:nil
													 selector:selector
														owner:owner
											   operationQueue:self
												  skipIfError:YES] ;
		// Note that operation is double-retained.  We'll release it in the next loop.
		[operations addObject:op] ;
		[self addAtEndOperation:op] ;
		[op release] ;
	}
	
	[operations release] ;
	
	// Create a final operation which will be the 'done' invocation
	// and add it to the queue.
	NSMutableDictionary* doneInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									 info, constKeySSYOperationQueueInfo,
									 [NSNumber numberWithBool:keepWithNext], constKeySSYOperationQueueKeepWithNext,
									 nil] ;
	if (doneTarget && doneSelector) {
		if (!doneThread) {
			doneThread = [NSThread currentThread] ;
		}
		[doneInfo setObject:doneThread
					 forKey:constKeySSYOperationQueueDoneThread] ;
		[doneInfo setObject:doneTarget
					 forKey:constKeySSYOperationQueueDoneTarget] ;
		[doneInfo setObject:NSStringFromSelector(doneSelector)
					 forKey:constKeySSYOperationQueueDoneSelectorName] ;
		// Added in BookMacster 1.11, for no purpose other than 
		// filling out -[SSYOperation description] …
		[doneInfo setObject:group
					 forKey:constKeySSYOperationGroup] ;
	}	
	
	// Add -[self doDone:] as the final invocation in this group
	SSYOperation* op = [[SSYOperation alloc] initWithInfo:doneInfo
                                                   target:self
                                                 selector:@selector(doDone:)
                                                    owner:nil
                                           operationQueue:self
                                              skipIfError:NO] ;
	[self addAtEndOperation:op] ;
	[op release] ;
	
#if 0
#warning Logging as each group is added to SSYOperationQueue
	NSLog(@"Added group %@ of %ld ops, doneSel=%@.  Queue count now %ld",
		  group,
		  (long)([selectorNames count] + ((doneTarget && doneSelector) ? 1 : 0)),
		  NSStringFromSelector(doneSelector),
		  (long)[[self operations] count]) ;
#endif
	
	if (block) {
		[self waitUntilAllOperationsAreFinished] ;
	}
}

@end

// See "Note on Coalesce Mask" at bottom of SSYOperationQueue.m

// I refer to the following note in comments in other code

/* 
 Note on Coalesce Mask

 In Notification Programming Topics ▸ Notification Queues ▸ Coalescing Notifications,
 there is no explanation of how coalescing on *name*  occurs when you coalesce
 on *sender* [1], or vice versa.  It seems to me that the behavior is counterintuitive.
   I submitted some Document Feedback, but if you've ever written code coalescing
 notifications, and think that you might not always be getting all the notifications
 you expect, you should look this over…
 
 If I enqueue two notifications coalescing on name but not on sender, I expect that
 differences in sender would still be *respected*.  That is, if I enqueue two
 notifications with the same name but different senders, I expect that both
 notifications would be posted.  Reasoning: I'm *not* coalescing on sender.  But
 in fact, coalescing occurs and only the first notification enqueued is posted.
 
 Similarly, if I enqueue two notifications coalescing on sender but not on name,
 I expect that differences in name would still be *respected*.  That is, if I
 enqueue two notifications with the same sender but different names, I expect that
 both notifications would be posted, but in fact only the first one enqueued is posted.
 
 Now if I coalesce on both name and sender, then differences in both name and sender
 are respected, as expected, coalescing finds nothing to do, and if I then enqueue
 notifications with the same name but different senders, or the same sender but
 different names, both are posted.  So it seems that in most cases, you'll want to use
 NSNotificationCoalescingOnName|NSNotificationCoalescingOnSender.
 
 Considering the first case of two notifications posted with same name but different
 sender, here is a table of the results:
 
 *                   |  Integer Value  |       Number of 
 *                   |  of Coalescing  | Notifications Posted     
 *  Coalesce on…     |  Mask           | Expected  |   Actual
 ------------------------------------------------------------
 *  None             |       0         |     2     |     2
 *  Name only        |       1         |     2     |     1
 *  Name and Sender  |       3         |     2     |     2
 
 The "Actual" is counterintuitive because "stronger" coalescing should always either
 suppress notifications or have no effect.  Stronger coalescing should mean possibly
 fewer notifications.  But it doesn't work that way.  The Actual Number of
 Notifications Posted, as a function of "coalescing", is non-monotonic.
 
 
 [1] The API and documentation use "sender" and "object" interchangeably :(
 
 
 Here is code for a demo Foundation Tool project for anyone who'd like to play with this:
 
 #import <Cocoa/Cocoa.h>
 
 NSString* const MyNote1 = @"MyNote1" ;
 NSString* const MyNote2 = @"MyNote2" ;
 NSString* const MyNote3 = @"MyNote3" ;
 NSString* const MyNote4 = @"MyNote4" ;
 
 @interface Foo : NSObject {
 NSInteger m_index ;
 }
 
 @property (assign) NSInteger index ;
 
 @end
 
 @implementation Foo ;
 
 @synthesize index = m_index ;
 
 - (NSString*)description {
 return [NSString stringWithFormat:
 @"Foo%d",
 [self index]] ;
 }
 
 @end
 
 
 
 @interface Observer : NSObject {
 BOOL m_done ;
 }
 
 @property (assign) BOOL done ;
 -(void)observeNote:(NSNotification*)note ;
 
 @end
 
 @implementation Observer
 
 @synthesize done = m_done ;
 
 -(void)observeNote:(NSNotification*)note {
 NSLog(@"Received %@ with object: %@",
 [note name],
 [note object]) ;
 }
 
 - (void)beDone:(NSTimer*)timer {
 [self setDone:YES] ;
 }
 
 @end
 
 
 // See "Note on Coalesce Mask" at bottom of SSYOperationQueue.m
 
 int main(int argc, char *argv[]) {
 NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init] ;
 
 Observer* observer = [[Observer alloc] init] ;
 [[NSNotificationCenter defaultCenter] addObserver:observer
 selector:@selector(observeNote:)
 name:MyNote1
 object:nil] ;
 [[NSNotificationCenter defaultCenter] addObserver:observer
 selector:@selector(observeNote:)
 name:MyNote2
 object:nil] ;
 [[NSNotificationCenter defaultCenter] addObserver:observer
 selector:@selector(observeNote:)
 name:MyNote3
 object:nil] ;
 [[NSNotificationCenter defaultCenter] addObserver:observer
 selector:@selector(observeNote:)
 name:MyNote4
 object:nil] ;
 
 Foo* foo1 = [[Foo alloc] init] ;
 foo1.index = 1 ;
 Foo* foo2 = [[Foo alloc] init] ;
 foo2.index = 2 ;
 Foo* foo3 = [[Foo alloc] init] ;
 foo3.index = 3 ;
 Foo* foo4 = [[Foo alloc] init] ;
 foo4.index = 4 ;
 Foo* foo5 = [[Foo alloc] init] ;
 foo5.index = 5 ;
 Foo* foo6 = [[Foo alloc] init] ;
 foo6.index = 6 ;
 
 NSNotification* note ;
 NSInteger coalesceMask ;
 
 coalesceMask = 0 ;
 
 note = [NSNotification notificationWithName:MyNote1
 object:foo1] ;
 [[NSNotificationQueue defaultQueue] enqueueNotification:note
 postingStyle:NSPostWhenIdle
 coalesceMask:coalesceMask
 forModes:nil] ;
 
 note = [NSNotification notificationWithName:MyNote1
 object:foo2] ;
 [[NSNotificationQueue defaultQueue] enqueueNotification:note
 postingStyle:NSPostWhenIdle
 coalesceMask:coalesceMask
 forModes:nil] ;
 
 coalesceMask = (NSNotificationCoalescingOnName) ;
 
 note = [NSNotification notificationWithName:MyNote2
 object:foo3] ;
 [[NSNotificationQueue defaultQueue] enqueueNotification:note
 postingStyle:NSPostWhenIdle
 coalesceMask:coalesceMask
 forModes:nil] ;
 
 note = [NSNotification notificationWithName:MyNote2
 object:foo4] ;
 [[NSNotificationQueue defaultQueue] enqueueNotification:note
 postingStyle:NSPostWhenIdle
 coalesceMask:coalesceMask
 forModes:nil] ;
 
 
 coalesceMask = (
 NSNotificationCoalescingOnName
 |
 NSNotificationCoalescingOnSender
 ) ;
 
 note = [NSNotification notificationWithName:MyNote3
 object:foo5] ;
 [[NSNotificationQueue defaultQueue] enqueueNotification:note
 postingStyle:NSPostWhenIdle
 coalesceMask:coalesceMask
 forModes:nil] ;
 
 note = [NSNotification notificationWithName:MyNote3
 object:foo6] ;
 [[NSNotificationQueue defaultQueue] enqueueNotification:note
 postingStyle:NSPostWhenIdle
 coalesceMask:coalesceMask
 forModes:nil] ;
 
 NSRunLoop* runLoop = [NSRunLoop currentRunLoop] ;
 [NSTimer scheduledTimerWithTimeInterval:0.5
 target:observer
 selector:@selector(beDone:)
 userInfo:nil
 repeats:NO] ;
 NSDate* oneSecondFromNow = [NSDate dateWithTimeIntervalSinceNow:1.0] ;
 while (![observer done] && [runLoop runMode:NSDefaultRunLoopMode
 beforeDate:oneSecondFromNow]) {
 }
 
 [observer release] ;
 [foo1 release] ;
 [foo2 release] ;
 [foo3 release] ;
 [foo4 release] ;
 [foo5 release] ;
 [foo6 release] ;
 
 
 [pool drain] ;
 
 return 0 ;     
 } */