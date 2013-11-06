#import <Cocoa/Cocoa.h>

/*
 This enum was added in BookMacster 1.14.4.  Prior to that,
 I piggybacked on kProcessTransformToForegroundApplication and 
 its two friends.  But those are not all defined in the 10.6
 SDK.  So I did it the correct way now.  For defensive programming,,
 the three values here match the values of the corresponding
 kProcessTransformToForegroundApplication and friends.
 
 I don't know what is the difference between the types "Background" and
 "UIElement".  I never user the former, only the latter.  I have not been able
 to find any explanation in Apple documemtation.
 */
enum SSYProcessTyperType_enum {
	SSYProcessTyperTypeForeground = 1,
	SSYProcessTyperTypeBackground = 2,
	SSYProcessTyperTypeUIElement = 4
} ;
typedef enum SSYProcessTyperType_enum SSYProcessTyperType ;


@interface SSYProcessTyper : NSObject {

}

+ (SSYProcessTyperType)currentType ;

/*
 @brief    Transforms the current process to foreground type if it is not.
 
 @details  Starting with BookMacster 1.19.6, this method features a "dance
 with Finder" kludge.  This kludge is to fix the issue which arose in Mac
 OS X 10.9 Mavericks, after I began invoking this method in app delegate's
 -applicationDidFinishLaunching instead of -init.  The new issue was that the
 menu still would not show when launched from an app such as Alfred version 2,
 which is itself an LSUIElement background app.  According to Alfred
 developer Andrew Pepperrell, Alfred 2 uses a standard NSWorkspace method to
 launch apps, nothing tricky.
 http://www.alfredforum.com/topic/3358-application-bookmacster-menu-does-not-show-immediately/
 The solution is to do what I call a "dance with Finder", and supposedly this
 kludge was actually recommended by Apple
 http://stackoverflow.com/questions/7596643/when-calling-transformprocesstype-the-app-menu-doesnt-show-up
 But I modified it somewhat.  First of all, I found that the delays of 0.1 did
 not help, and further that if the app was not launched by Finder but by some
 other means (Alfred, LaunchBar, AppleScript, open(1), etc.) then the Finder's
 menu would flash before BookMacster's menu would show.  Therefore I added
 additional code to detect when showing the menu failed and only initiate the
 "dance with Finder" if it fails, which should be only if launched by Alfred 2.
 Fortunately, for 10.7 and later users, method
 -[NSWorkspace sharedWorkspace] menuBarOwningApplication]
 provides the detection.  The "dance with Finder" code is a real mess, but I
 tested in 10.6, 10.7, 10.8, 10.9 and it works in all cases.
 */
+ (void)transformToForeground:(id)sender ;

#if (MAC_OS_X_VERSION_MAX_ALLOWED > 1060)

/*
 @brief    Transforms the current process to UIElement type if it is not.
 @details  Available in Mac OS X 10.7 or later.
*/
+ (void)transformToUIElement:(id)sender ;

/*
 @brief    Transforms the current process to background type if it is not.
 @details  Available in Mac OS X 10.7 or later.
 */
+ (void)transformToBackground:(id)sender ;

#endif

@end
