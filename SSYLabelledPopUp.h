#import <Cocoa/Cocoa.h>

/*!
 @brief    This class provides a control which consists of a non-editable NSTextField
 <i>label</i> and, below it, a popup button.
 
 @details  May be used, for example for a user to select <i>Favorite Color</i>,
 etc. etc.
 */
@interface SSYLabelledPopUp : NSView {
	NSTextField* labelField ;
	NSPopUpButton* popUpButton ;
}

@property (retain) NSTextField* labelField ;
@property (retain) NSPopUpButton* popUpButton ;

/*!
 @brief    Convenience method for getting an autoreleased instance of this class.

 @param    label  The text value of the <i>label</i> which will appear above
 the popup button in the returned instance.
 @result   The instance, autoreleased
*/
+ (SSYLabelledPopUp*)popUpControlWithLabel:(NSString*)label ;

/*!
 @brief    Sets the array of choices to appear in the receiver's popup button.

 @param    choices  An array of strings
*/
- (void)setChoices:(NSArray*)choices ;

/*!
 @brief    Returns the index selected in the menu of the receiver's popup
 button.
*/
- (NSInteger)selectedIndex ;

/*!
 @brief    Resizes the height of the receiver to accomodate the its current values,
 subject to allowsShrinking
 
 @param    allowShrinking  YES if the height is allowed to be reduced.  If this parameter
 is NO, and less height than the current height is required, this invocation will not reduce
 the height but will instead leave empty space.
 */
- (void)sizeHeightToFitAllowShrinking:(BOOL)allowShrinking ;

@end

