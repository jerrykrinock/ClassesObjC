#import <Cocoa/Cocoa.h>

/*
 @brief    A subclass of NSWindow instance methods which behave appropriately
in case a process is launched as or is transformed to a background or
 UI element type (currentType != SSYProcessTyperTypeForeground),
 
 This class was added in BookMacster 1.16.1.
 */
@interface SSYBackgroundAwareWindow : NSWindow {
}

/*
 @brief    Override which returns NO if the the current process is not a
 foreground process (currentType != SSYProcessTyperTypeForeground), otherwise
 invokes super
 */
- (BOOL)canBecomeMainWindow ;

/*
 @brief    Override which returns NO if the the current process is not a
 foreground process (currentType != SSYProcessTyperTypeForeground), otherwise
 invokes super
 */
- (BOOL)canBecomeKeyWindow ;




@end
