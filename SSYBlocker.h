#import <Cocoa/Cocoa.h>


/*!
 @brief    This class exposes three methods to block a "waiter" thread
 until a "worker" thread completes work.
 
 @details  The typical usage of an SSYBlocker is:
 
 • Waiter or Worker sends +alloc -init.
 • Worker sends -lockLock.
 • Worker begins work.
 • Waiter sends -blockForLock, which blocks.
 • Worker completes work.
 • Worker sends -unlockLock
 • -blockForLock returns, and Waiter continues its execution
 
 Memory management of an SSYBlocker instance can be dangerous
 if you cannot guarantee the order in which the messages will
 be sent, or edge cases in which they might be re-sent.  If you
 don't have too many of these things, you might want to be
 conservative and retain them as instance variables of some
 long-lived object.
*/
@interface SSYBlocker : NSObject {
	NSConditionLock* m_lock ;
}

/*!
 @brief    Initializes the receiver and its condition lock.
 */
- (id)init ;

/*!
 @brief    Locks the receiver's condition lock.
 */
- (void)lockLock ;

/*!
 @brief    Blocks until the receiver's condition lock is unlocked
 by -unlockLock.
 */
- (void)blockForLock ;

/*!
 @brief    Unlocks the receiver's condition lock.
 
 @details  Before unlocking the lock, this method checks to see that the
 receiver's lock is still locked, so it is OK if, during some edge case
 condition, you send this message more than once.
 */
- (void)unlockLock ;

@end
