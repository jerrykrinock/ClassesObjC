#import <Cocoa/Cocoa.h>


/*!
 @brief    A window controller for a temporary window which only has one 
 instance in the application.

 @details  An instance of this object is allocated when required, observes
 NSWindowWillCloseNotification, and releases itself when it receives notification
 that its window is closing.
 
 In the xib file,
 *  File's Owner should be set to your subclass of this class
 *  File's Owner 'window' outlet should be wired to a window
 *  The window should have checked
 **  ON  Release When Closed
 **  OFF Visible At Launch
 * MEMORY should be set to
 **  ON  Deferred
 **  ON  One Shot
 **  Buffered
*/
@interface SSYTempWindowController : NSWindowController {
}

/*!
 @brief    Returns the name of the nib file containing the receiver's window.

 @details  Subclasses must implement.  Simply return an NSString constant.&nbsp;
 Default implementation logs an internal error and returns nil.&nbsp;
 
 The window in this nib should be set to Release When Closed.
*/
+ (NSString*)nibName ;

/*!
 @brief    Shows the window of the app's single instance of this class,
 creating one if none exists.
 @result   The app's single instance
*/
+ (id)showWindow ;

@end
