#import <Cocoa/Cocoa.h>
#import "SSYMenuButton.h"

/*!
 @brief    Implements a "add" button that appears as a rounded rectangular button
 with a "+" and a down-pointing triangle, and produces a popup
 menu when clicked.

 @details  An NSButton of this class should be instantiated in
 Interface Builder with the following attributes:
 Style: Square
 Bordered: OFF
 Size: 23x23
 Title: <blank>
 Image: <blank>
 Scaling: Proportionally down
*/
@interface SSYMenuAddButton : SSYMenuButton {
}

@end
