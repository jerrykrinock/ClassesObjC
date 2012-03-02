#import <Cocoa/Cocoa.h>


/*!
 @brief    A notification queue which coalesces based on a
 time window

 @details  Use this class instead of NSNotificationQueue when
 NSNotificationQueue with NSPostWhenIdle is not lazy enough
 and results in too many redundant notifications for your
 purpose.  SSYLazyNotificationCenter is *lazier* than any
 of Cocoa's built-in notifications.
 
 Implementation is pretty bare-bones right now.  More features such as
 a notification object, selectively removing observations, etc.,
 could be added.
*/
@interface SSYLazyNotificationCenter : NSObject {
	NSMutableDictionary* m_observations ;
	NSMutableDictionary* m_fireTimers ;
}

+ (SSYLazyNotificationCenter*)defaultCenter ;

/*!
 @brief    Adds an observer which will lazily receive any notifications
 with a given name issued by the receiver, to a given selector. 
*/
- (void)addObserver:(id)observer
		   selector:(SEL)selector
			   name:(NSString*)name ;

/*!
 @brief    Schedules a given notification to be fired (sent) after a
 given delay, or coalesced with an already-scheduled firing.

 @details  If a notification with the same name as that of
 the given notification has already been scheduled
 but has not yet been fired, the later notification will be fired
 instead of the older notification, but it will be fired (sent)
 at the time that the existing notification was scheduled to fire.
 
 Other behaviors could be imagined.  I suppose one could
 combine the -userInfo dictionaries of all the coalesced
 notifications.  But we don't do that.
*/
- (void)enqueueNotification:(NSNotification*)note
					  delay:(NSTimeInterval)delay ;

/*!
 @brief    Removes a given observer from the receiver, so
 that it will not receive any more notifications.

 @details  
 @param    observer  
*/
- (void)removeObserver:(id)observer ;

@end
