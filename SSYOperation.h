#import <Cocoa/Cocoa.h>
#import "SSYOwnee.h"

@class SSYOperationQueue ;

/*!
 @brief    A subclass of NSOperation which has methods to register and
 access the error of its operation queue, and abort operations if an
 error occurs during execution of a prior operation.
 
 @details  Class also includes four methods which may be used in atypical
 situations where it is necessary to  block a "manager" thread
 while a "worker" thread completes work.
 
 Normally, when an operation sets its own error using -setError, which
 sets the error in the operation queue, further SSYOperations become
 no-ops.  However, if the info dictionary of an operation contains
 an object for key SSYOperationGroup, and the userInfo dictionary of
 the error also contains an object for key SSYOperationGroup, and if the
 values of these keys are unequal as judged by +[NSOperationQueue 
 operationGroupsDifferInfo:info:otherInfo:], then that operation does
 *not* become a no-op.  You may use this feature to selectively abort
 some future operations but not abort others.
 */
@interface SSYOperation : NSOperation <SSYOwnee> {
	NSMutableDictionary* m_info ;
	SEL m_selector ;
	id m_owner ; // weak
	SSYOperationQueue* m_operationQueue ;  // weak
}

/*!
 @brief    The info passed to SSYOperationLinker.  Worker methods may access
 this NSMutableDictionary to get parameters and set results.
 */
@property (retain) NSMutableDictionary* info ;
@property (assign) SEL selector ;
@property (assign) SSYOperationQueue* operationQueue ;

/*!
 @brief    Returns a new SSYOperation

 @details  Designated initializer for SSYOperation
 @param    info  Dictionary of information which the operation can
 access to do its work
 @param    selector  
 @param    operationQueue  
 @result   A new, initilialied SSYOperation
*/
- (id)initWithInfo:(NSMutableDictionary*)info
		  selector:(SEL)selector
			 owner:(id)owner
	operationQueue:(SSYOperationQueue*)operationQueue ;

- (NSError*)error ;

/*!
 @brief    Sets the error of the receiver's operation queue.
*/
- (void)setError:(NSError*)error ;

- (void)skipQueuedOperationsInOtherGroups ;

/*!
 @brief    Appends the suffix _unsafe to the name of a given selector
 and performs the _unsafe selector on the main thread, making it safe(r).
 
 @param    cmdNameC  The base selector name.&nbsp; Typically, pass _cmd
 */
- (void)doSafely:(SEL)cmdNameC ;

/*!
 @brief    Creates the receiver's condition lock and sets it into
 the receiver's info dictionary.
 
 @details  Usage: Although the fundamental feature of
 SSYOperationLinker is to queue operations entered
 by a "manager" thread, sometimes it is necessary to block the
 "manager" thread from enqueing further operations until the
 result of prior operations is available.  This is one of four
 methods provided to block such a "manager" thread until a
 "worker" thread completes work.
 
 This method should be invoked on the "manager" thread just before
 spinning off the "worker" thread to do the work.
 
 SSYOperationLinker provides only one such condition lock.
 If a condition lock has previously been created by this method
 and not yet removed by -blockForLock, an exception will be raised. 
 */
- (void)prepareLock ;

/*!
 @brief    Locks the receiver's condition lock.
 
 @details  This is another of the four methods referred to in
 "Usage" in Details documentation of -prepareLock.
 
 This method should be invoked on the "worker" thread before
 beginning the work.
 */
- (void)lockLock ;

/*!
 @brief    Blocks until the receiver's condition lock is unlocked
 by -unlockLock, and then, before returning, removes the condition
 lock from the receiver's info dictionary.
 
 @details  This is another of the four methods referred to in
 "Usage" in Details documentation of -prepareLock. 
 
 This method should be invoked on the "manager" thread after
 spinning off the "worker" thread to do the work. 
 */
- (void)blockForLock ;

/*!
 @brief    Unlocks the receiver's condition lock.
 
 @details  This is another of the four methods referred to in
 "Usage" in Details documentation of -prepareLock.
 
 This method should be invoked on the "worker" thread after work
 has been completed.  Before unlocking the lock, it checks to
 see that it is still locked, so it is OK if, during some error
 condition, you send -prepareLock, -lockLock, and then send
 this message more than once.
 */
- (void)unlockLock ;

@end
