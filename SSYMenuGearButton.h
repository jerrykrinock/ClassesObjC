#import <Cocoa/Cocoa.h>
#import "SSYMenuButton.h"

/*!
 @brief    Implements a "gear" button that appears as a square button
 with a gear and a down-pointing triangle, and produces a popup
 menu when clicked.

 @details  An NSButton of this class should be instantiated in
 Interface Builder with the following attributes:
 <ul>
 <li>Size: 20 x 33 points</li>
 <li>No title</li>
 <li>No image</li>
 <li>Scaling: Proportionally down</li>
 <li>Style: Square</li>
 <li>Mode: Momentary Push-In</li>
 <li>Bordered: YES</li>
 <li>Selected: YES</li>
 <li>Transparent: NO</li>
 <li>Mixed: NO</li>
 </ul>
*/
@interface SSYMenuGearButton : SSYMenuButton {
}

@end
