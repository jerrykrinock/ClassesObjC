#import <Cocoa/Cocoa.h>


@interface SSYMiniProgressWindow : NSWindow {
}

/*!
 @brief    Displays a small window, at floating level, showing an
 indeterminate progress bar and a verb, at a given point 

 @details  This window will be visible until it is deallocced.
 Hold a reference until you want to close the window, then release it.
 @param    point  The desired upper left corner of the window, in 
 screen coordinates.  If this results in the window being partially
 or totally off the screen, this point is adjusted as required, to
 keep it completely on the screen.
*/
- (SSYMiniProgressWindow*)initWithVerb:(NSString*)verb
								 point:(NSPoint)point ;

@end
