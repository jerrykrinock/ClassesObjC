#import <Cocoa/Cocoa.h>

#if DEBUG
#define LOG_UNREAL_SSY_POP_UP_TABLE_HEADER_CELLS 1
#endif


/*!
 @brief    A table header cell that is a popup menu!

 @details  This class is based on Keith Blount's original work
 http://www.cocoabuilder.com/archive/message/cocoa/2005/4/16/133285
 or http://lists.apple.com/archives/cocoa-dev/2005/Apr/msg01223.html
 but I've made enough improvements to it that I decided it deserves
 to have my own SSY prefix.
*/ 
@interface SSYPopUpTableHeaderCell : NSPopUpButtonCell {
	CGFloat lostWidth ;
}

/*!
 @brief    The width on the right side of the column header which
 is not available for menu text because it is used by the popup arrows
 and whitespace to the right of the arrows.
*/
@property (readonly) CGFloat lostWidth ;

@end
