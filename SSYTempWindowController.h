#import <Cocoa/Cocoa.h>


/*!
 @brief    A window controller for a temporary window which only has one 
 instance in the application.

 @details  An instance of this object is allocated when required, observes
 NSWindowWillCloseNotification, and releases itself when it receives
 notification that its window is closing.
 
 For a cleaner approach to this problem, which does not require subclassing,
 see [SSYWindowHangout hungOutWindowControllerOfClass:].
*/
@interface SSYTempWindowController : NSWindowController {
}

/*!
 @brief    Returns the name of the nib file containing the receiver's window.

 @details  Subclasses must implement.  Simply return an NSString constant.
 Default implementation logs an internal error and returns nil.  
 
 In this nib,
 *  File's Owner should be set to your subclass of this class
 *  File's Owner 'window' outlet should be wired to a window
 *  Said window should have these checkboxes switched ON
 **  ON  Release When Closed
 **  OFF Visible At Launch
 **  In the MEMORY section,
 ***  ON  Deferred
 ***  ON  One Shot
 ***  Buffered
*/
+ (NSString*)nibName ;

/*!
 @brief    Shows the window of the app's single instance of this class,
 creating one if none exists.
 @result   The app's single instance
*/
+ (id)showWindow ;

@end
