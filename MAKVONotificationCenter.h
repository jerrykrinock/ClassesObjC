//
//  MAKVONotificationCenter.h
//  MAKVONotificationCenter
//
//  Created by Michael Ash on 10/15/08.
//

#import <Cocoa/Cocoa.h>

/*!
 @brief    A class, normally used as a singleton, with improvements over Apple's
 -[NSObject -addObserver:forKeyPath:options:context:] and -[NSObject removeObserver:forKeyPath:] methods.
 @details  See http://mikeash.com/?page=pyblog/key-value-observing-done-right.html#comment-c725ea36f22415152e31afb4c45e3d46
*/
@interface MAKVONotificationCenter : NSObject
{
	NSMutableDictionary*	observations;
}

/*!
 @brief    Returns an application-wide MAKVONotificationCenter singleton instance
*/
+ (id)defaultCenter;

/*!
 @brief    Adds an observer to the receiver.

 @details  Usually, you'll use the -[NSObject(MAKVONotification) addObserver:forKeyPath:selector:userInfo:options:]
 instead of this one.&nbsp;  See that method's documentation for specification of other
 other parameters and the result.&nbsp;  I really don't think we need to expose
 this method, but I'm just leaving it because maybe Mike had a reason.
 @param    target  The object to be observed for changes
 */
- (id)addObserver:(id)observer
		   object:(id)target
		  keyPath:(NSString *)keyPath
		 selector:(SEL)selector
		 userInfo:(id)userInfo
		  options:(NSKeyValueObservingOptions)options;

/*!
 @brief    Removes all observations with a given observer from the receiver.
 
 @details  This method is the Easy Way of removing observers.&nbsp;  It is recommended
 in the usual situation where you want to remove all of an observer's observations at
 once.&nbsp;  Typically this is done in -dealloc, or in -didTurnIntoFault if the observer
 is a managed object inheriting from NSManagedObject.&nbsp;  Can be safely invoked,
 and performs no-op, even if observer has no MAKVONotificationCenter observers.
 @param    observation  The observer to be removed
 */
- (void)removeObserver:(id)observer ;

/*!
 @brief    Removes a given observation from the receiver.
 
 @details  This method is the Middle Way of removing observers.&nbsp;  It is useful if
 you add an observation to an observer for a temporary purpose, and then want to remove it
 without removing the observer's other observations.
 @param    observation  An instance of the opaque class MAKVObservation which was returned
 by -addObserver:forKeyPath:selector:userInfo:options:.&nbsp;  If this parameter is nil or
 if it does not exist in the receiver, no harm is done -- this method will no-op.
 */
- (void)removeObservation:(id)observation ;

@end

/*!
 @brief   A category on NSObject which replaces two methods of Apple's
 NSKeyValueObserving informal protocol

 @details  
*/
@interface NSObject (MAKVONotification)

/*!
 @brief    Adds a KVO observer of the receiver to the application-wide MAKVONotificationCenter.

 @details  Our replacement for -[NSObject -addObserver:forKeyPath:options:context:], the 
 "underlying method"
 @param    observer  See documentation of the underlying method.
 @param    keyPath  See documentation of the underlying method.
 @param    selector  The message which will be sent to the observer when
 an observation occurs.&nbsp;  This selector should have the following signature:
 - (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)target change:(NSDictionary*)change userInfo:(id)userInfo.
 The parameters keyPath, object and change will be as stated for the selector
 in documentation of the underlying method.&nbsp; The userInfo will be the
 userInfo that you pass to this method.
 @param    userInfo  A dictionary which will be passed to the observer's
 selector when an observation occurs.
 @param    options  See documentation of the underlying method.
 @result   If the operation succeeds, an instance of the opaque class MAKVObservation
 which you may send back as a parameter to -removeObservation: if you choose to use
 the Middle Way of removing observers.&nbsp;  If the operation fails because an
 observation with the given parameters already exists, returns nil.
 */
- (id)addObserver:(id)observer
	   forKeyPath:(NSString *)keyPath
		 selector:(SEL)selector
		 userInfo:(id)userInfo
		  options:(NSKeyValueObservingOptions)options;

/*!
 @brief    Removes an observer of the receiver from the MAKVONotificationCenter.&nbsp;
 The observation is specified by the observer, key path and selector that you passed
 in when adding it.

 @details  Our replacement for -[NSObject -removeObserver:forKeyPath:], the
 "underlying method".&nbsp; This method is the Hard Way of removing observers.&nbsp;
 The -removeXXX methods of MAKVONotificationCenter are easier to use and are recommended.
 @param    observer  See documentation of the underlying method.
 @param    keyPath  See documentation of the underlying method.
 @param    selector  The selector which was passed to -addObserver:forKeyPath:selector:userInfo:options:
 when the observation was added to the receiver.
*/
- (void)removeObserver:(id)observer
			   keyPath:(NSString *)keyPath
			  selector:(SEL)selector;

@end
