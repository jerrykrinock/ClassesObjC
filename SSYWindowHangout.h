#import <Cocoa/Cocoa.h>

/*
 @brief    Provides a place for window controllers that control transient
 windows to "hang out" without being deallocced, so that you don't junk
 up your app delegate with repeated boilerplate code and instance variables.
 */
@interface SSYWindowHangout : NSObject {
    NSWindowController* m_windowController ;
}


/*
 @brief    Adds a window controller to a global set, in which it will be
 retained until its window closes
 
 @details  This is useful for controllers of "transient" windows, or example,
 Preferences windows. Also, because window controllers own their windows, so
 we are in effect hanging out the windows too.
 
 I understand that, instead of storing the hangout dictionary as a static
 variable, Apple would have used their "shared instance" design pattern.
 I believe this is desirable if you might ever want more than one of these,
 but I don't in this case, and would rather avoid the extra overhead of
 complexity.  Therefore, this method is a class method.
*/
+ (void)hangOutWindowController:(NSWindowController*)windowController ;

/*
 @brief    Returns the first window controller in the receiver's hangout
 whose window controller  is of a given class, or nil if none such is found
 
 @details  This method makes this class useful for windows such as Preferences
 whose controllers should only have one instance in the app, because there
 should be only one such window.  Instead of keeping the window controller
 as an instance variable of your app delegate, this method empowers you to refer
 to it in the hangout.  To access such a unique window, send this message.  If
 it returns nil, there is none yet.  In that case, create the window controller
 and then hang it out by sending +hangOutWindowController:.
 */
+ (NSWindowController*)hungOutWindowControllerOfClass:(Class)class ;

@end
