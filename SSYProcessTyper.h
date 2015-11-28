#import <Cocoa/Cocoa.h>

/*
 @brief    Class which provides methods for reading and setting the 'type' of
 the current process, where 'type' means Foreground, LSUIElement, or Background
*/
@interface SSYProcessTyper : NSObject {

}

+ (NSApplicationActivationPolicy)currentType ;

/*
 @brief    Transforms the current process to foreground type by setting the
 current app's activation policy, activating it, and if necessary dancing
 with another app to get ownership of the menu bar
 
 @details   This method features a kludge which "dances" with some other
 application if OS X does not give it ownership of the menu bar immediately.
 That other application is an already-running, preferably, faceless application
 (so the dance is not so visible) whose bundle identifier is returned by your
 app delegate's -associatedBackgroundAppBundleIdentifier method, if it responds
 to that selector and such an app is found to be running.  Otherwise, it dances
 with Finder.
 
 In OS X 10.11, it appears that the dance may only be necessary if app is
 launched is LSUIElement in Info.plist, is launched by Xcode and then
 made foreground during -applicationDidFinishLaunching.  If the app does get
 ownership of the menu bar immediately, then the dance is not performed. */
+ (void)transformToForeground:(id)sender ;

/*
 @brief    Transforms the current process to UIElement type by setting the
 current app's activation policy
 */
+ (void)transformToUIElement:(id)sender ;

/*
 @brief    Transforms the current process to background type by setting the
 current app's activation policy
 */
+ (void)transformToBackground:(id)sender ;

@end
