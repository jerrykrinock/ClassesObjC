#import <Cocoa/Cocoa.h>

@interface SSYDragDestinationTextView : NSTextView {
}

@property BOOL activateUponDrop ;

/*!
 @brief    A wrapper around @property fieldEditor, which has a more meaningful
 name than fieldEditor
 
 @details  You can get the same result in Interface Builder, by switching on the
 receiver's *Field Editor* checkbox.
 */
@property BOOL ignoreTabsAndReturns ;

@end


