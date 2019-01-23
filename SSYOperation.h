#import <Cocoa/Cocoa.h>

@class SSYOperationQueue ;

/*!
 @brief    A subclass of NSOperation which has methods to register and
 access the error of its operation queue, and skip operations if an
 error occurs during execution of a prior operation or if it has been
 cancelled
 
 @details  The receiver will be a no-op if it has been cancelled when
 its -main function is invoked (when it is dequeued).
 
 This class also includes four methods which may be used in atypical
 situations where it is necessary to  block a "manager" thread
 while a "worker" thread completes work.
 
 Normally, when an operation sets its own error using -setError, which
 sets the error in the operation queue, any further SSYOperations
 which were created with skipIfError passed as YES and are *in the same
 operation group* become no-ops.
 
 Operations X and Y are *in the same operation group* if their info 
 dictionaries both contain values for the key SSYOperationGroup, and
 if these two values are equal as judged by +[SSYOperationQueue 
 operationGroupsDifferInfo:otherInfo:],
 */
@interface SSYOperation : NSOperation {
	NSMutableDictionary* m_info ;
	SEL m_selector ;
	id m_target ;
	SSYOperationQueue* m_operationQueue ;  // weak
	NSInvocation* m_cancellor ;
	BOOL m_skipIfError ;
    NSConditionLock* m_lock ;
}

/*!
 @brief    The info passed to SSYOperationLinker.  Worker methods may access
 this NSMutableDictionary to get parameters and set results.
 */
@property (retain) NSMutableDictionary* info ;
@property (assign) SEL selector ;
@property (assign) SSYOperationQueue* operationQueue ;

/*!
 @brief    An invocation which will be invoked whenever the receiver
 receives a -cancel message
 */
@property (retain) NSInvocation* cancellor ;


/*!
 @brief    Returns a new SSYOperation

 @details  Designated initializer for SSYOperation
 @param    info  Dictionary of information which the operation can
 access to do its work.  This dictionary is retained but, to reduce
 susceptibility to retain cycles, it is released when the receiver's
 execution is completed or cancelled, because it is no longer needed.
 @param    target  An optional target which will be sent the given selector,
 with no argument, when the receiver is executed.  If nil, the effective target will
 be the receiver itself, and it will be sent the given selector with one
 argument, the receiver's -info.
 @param    selector  A selector which will be invoked when the receiver is executed.
 If the given target is not nil, this selector must take one argument, in which will
 be passed the receiver's -info.  If the given target is nil, this selector must
 must take zero arguments.  In this case, you will typically implement the selector
 in a category of the receiver, whereby you can access the receiver's -info.
 @param    operationQueue
 @param    skipIfError
 @result   A new, initilialied SSYOperation
*/
- (id)initWithInfo:(NSMutableDictionary*)info
			target:(id)target
		  selector:(SEL)selector
	operationQueue:(SSYOperationQueue*)operationQueue
	   skipIfError:(BOOL)abortIfError ;

- (NSError*)error ;

/*!
 @brief    Sets the error of the receiver's operation queue, and into the
 userInfo dictionary of the error, adds key constKeySSYOperationGroup
 with value equal to the name of the receiver's operation group
 
 @details  Due to the addition of constKeySSYOperationGroup in the error's
 userInfo, when other operations in the receiver's queue receive an -error
 message, they will only return the error given here if their operation group's
 name is the same as that of the receiver of this message.
*/
- (void)setError:(NSError*)error ;

/*!
 @brief    Sets the error of the receiver's operation queue, without adding
 key constKeySSYOperationGroup to the userInfo of the error
 
 @details  Due to the non-addition of constKeySSYOperationGroup in the error's
 userInfo, when other operations in the receiver's queue receive an -error
 message, they will always return the error given here.
 */
- (void)setAllGroupsError:(NSError*)error ;

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
 and its current condition indicates that it has not yet been
 unlocked by -unlockLock, a warning will be logged and, in
 DEBUG builds, an assertion raised.
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

/*!
 @details  This method may be used in special cases where an error or other
 unexpected event might cause -prepareLock to be re-run before -unlockLock,
 when some operation is retried.  If this method returns YES, you should skip
 -prepareLock.
 */
- (BOOL)lockIsBlocking ;

@end
