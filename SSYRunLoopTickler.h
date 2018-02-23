#import <Cocoa/Cocoa.h>

/*!
 @brief    A class providing a method to "tickle" the run loop with a 
 dummy input source, causing a blocked -[NSRunLoop runMode:beforeDate:]
 to return.

 @details  This is useful in designs which worked in Mac OS 10.5 because
 they have run loops in background tools or secondary threads that were
 being run when needed by behind-the-scenes input sources.  These input
 sources were apparently added by Cocoa in Mac OS 10.5, but they are not
 added in Mac OS 10.6.  This is probably because 10.6 is using Grand
 Central Dispatch or something else instead of run loops for whatever
 it's doing.
 
 An explanation from James Bucanek:
 
 Just for the record, notifications don't need run loops. Notifications
 are delivered synchronously in the thread that posted the notifications.
 The exceptions are distributed notifications and notification queues.
 
 However, the code that was generating the notification might have needed
 a run loop (which could explain why it was never generated), and the
 -performSelector:... family *definitely* needs a run loop as it queues
 a deferred message to a run loop's input source.
 
 -- 
 James Bucanek
 
*/
__attribute__((visibility("default"))) @interface SSYRunLoopTickler : NSObject {
}

/*!
 @brief    Inserts a dummy input source into the current run loop in
 NSDefaultRunLoopMode, and sends a message to it, which will cause a
 blocked -[NSRunLoop runMode:beforeDate:] elsewhere in the program to
 return.

 @details  Removes the dummy input source after a delay of 0.0.
*/
+ (void)tickle ;

@end
