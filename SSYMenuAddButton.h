#import <Cocoa/Cocoa.h>
#import "SSYMenuButton.h"

/*!
 @brief    Implements a "add" button that appears as a rounded rectangular button
 with a "+" and a down-pointing triangle, and produces a popup
 menu when clicked.

 @details  An NSButton of this class should be instantiated in
 Interface Builder with the following attributes:
 <ul>
 <li>Size: 30 x 26 points</li>
 <li>No title</li>
 <li>No image</li>
 <li>Scaling: Proportionally down</li>
 <li>Bezel: Bevel</li>
 <li>Mode: Momentary Push-In</li>
 <li>Bordered: YES</li>
 <li>Transparent: NO</li>
 <li>Mixed: NO</li>
 </ul>
*/
@interface SSYMenuAddButton : SSYMenuButton {
}

@end
