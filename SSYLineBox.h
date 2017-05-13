#import <Cocoa/Cocoa.h>

/*!
 @brief    Subclass of NSBox which makes collapses into a grayscale vertical or
 horizontal line, with whiteness=0.2, alpha=1.0, thickness=1.0 point, and is
 ignored by VoiceOver.
 
 @details  This subclass is useful in macOS 10.10 or later.  For some
 reason, the "Vertical Line" and "Horizontal Line" NSBox objects in the
 xib library, which produce a fairly dark line in earlier versions of macOS,
 produce a very light gray line in macOS 10.10 that is barely discernable on
 a white background.  Just change the object class of your Vertical Line and
 Horizontal Line objects from NSBox to SSYLineBox.
 */
@interface SSYLineBox : NSBox

@end
