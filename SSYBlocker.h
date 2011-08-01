#import <Cocoa/Cocoa.h>


/*!
 @brief    This class exposes three methods to block a "manager" thread
 until a "worker" thread completes work.
*/
@interface SSYBlocker : NSObject {
	NSConditionLock* m_lock ;
}

/*!
 @brief    Initializes the receiver and its condition lock.
 
 @details  This method should be invoked on the "manager" thread.
 */
- (id)init ;

/*!
 @brief    Locks the receiver's condition lock.
 
 @details  This method should be invoked on the "worker" thread before
 beginning the work.
 */
- (void)lockLock ;

/*!
 @brief    Blocks until the receiver's condition lock is unlocked
 by -unlockLock, and then, before returning, removes the condition
 lock from the receiver's info dictionary.
 
 @details  This method should be invoked on the "manager" thread after
 spinning off the "worker" thread to do the work. 
 */
- (void)blockForLock ;

/*!
 @brief    Unlocks the receiver's condition lock.
 
 @details  This method should be invoked on the "worker" thread after work
 has been completed.  Before unlocking the lock, it checks to
 see that it is still locked, so it is OK if, during some error
 condition, you send -prepareLock, -lockLock, and then send
 this message more than once.
 */
- (void)unlockLock ;

@end
