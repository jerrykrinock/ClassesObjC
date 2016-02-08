#import <Cocoa/Cocoa.h>

#if DEBUG
#define LOG_UNREAL_SSY_POP_UP_TABLE_HEADER_CELLS 1
#endif

enum SSYPopupTableHeaderCellSortState_enum {
    SSYPopupTableHeaderCellSortStateNotSorted = 0,
    SSYPopupTableHeaderCellSortStateSortedAscending = 1,
    SSYPopupTableHeaderCellSortStateSortedDescending = 2
} ;
typedef enum SSYPopupTableHeaderCellSortState_enum SSYPopupTableHeaderCellSortState ;

@protocol SSYPopupTableHeaderSortableColumn

- (void)sortAsAscending:(BOOL)ascending ;
- (NSFont*)headerFont ;

@end


@protocol SSYPopupTableHeaderCellTableSortableOrNot

- (BOOL)sortable ;

@end


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
 is not available for menu text because it is used by the popup arrows if used,
 sorting controls if used, and whitespace to the right of the arrows.
*/
@property (readonly) CGFloat lostWidth ;

@property (assign) BOOL isUserDefined ;

/*!
 @brief    If not nil, the receiver behaves like a plain table header cell,
 with no popup menu, but with a blue/black sort control, to match the
 blue/black sort control of SSYPopUpTableHeaderCell that have popup menus.
 
 @details  Set this if you have a column in a table of user-defined popup
 columns which you do *not* want to have a user-definfed popup menu.
 */
@property (copy) NSString* fixedNonMenuTitle ;

@end
