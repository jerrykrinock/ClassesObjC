#import <Cocoa/Cocoa.h>

/*!
 @brief    A text field which will maintain the same vertical center
 when the font size is changed.
*/
@interface SSYVerticalCenteredTextField : NSTextField {

}

/*!
 @brief    Overridden to adjust the receiver's frame.origin.y so that
 the vertical center of the text remains approximately the same.

 @details  If the pointSize of the new font is the same as that of the
 receiver's current font, simply invokes super.
 
 Calculates the change in y as -0.55 times the change in point size.
 This was empirically determined.  Seems like it should be -0.5. 
*/
- (void)setFont:(NSFont*)font ;

@end
