#import <Cocoa/Cocoa.h>

/*!
 @brief    This class provides a control which consists of a non-editable NSTextField
 <i>label</i> and, below it, an NSMatrix of radio buttons in a single column.
 
 @details  May be used, for example for a user to select <i>Favorite Color</i>, <i>Gender</i>,
 etc. etc.
 
 Under the hood, uses NSTextFields to provide the text of each cell in the
 NSMatrix of radio buttons.  This allows text to wrap.  Cell spacing will
 expand as required to fit the cell with the most text height.
 */
@interface SSYLabelledRadioButtons : NSView {
	BOOL firstDrawing ;
	// If you select an NSMatrix' cell too early, it won't work for some reason.
	// In drawRect:, it works.  So, I override -drawRect: to select th3
	// "preselected" cell.  Note: In a 1x3 matrix, if not set, it selects the middle cell.
	// Possibly this is a problem/bug?
	NSInteger preselectedIndex ;
	CGFloat m_width ;
	NSArray* m_choices ;
}

@property (assign) CGFloat width ;

/*!
 @brief    Convenience method for getting an autoreleased instance of this class.

 @param    label  The text value of the <i>label</i> which will appear above
 the matrix in the returned instance.&nbsp; May be nil if you don't want a label.
 @param    choices  An array of strings giving the localized names of the choices
 to appear in the matrix.
 @param    width  The width that the returned view will be.
 @result   The instance, autoreleased
*/
+ (SSYLabelledRadioButtons*)radioButtonsWithLabel:(NSString*)label
										  choices:(NSArray*)choices
										    width:(CGFloat)width ;

/*!
 @brief    The index of the row selected in the receiver's matrix button.
 
 @details  Use this method if you want to pre-select a cell, instead of
 accessing the matrix and sending it -selectCell.&nbsp;  The reason is that
 if you select the cell too early, it won't work for some reason,
 possibly a bug in Cocoa?&nbsp;  This accessor uses a little work-around
 under the hood.
 
 If selectedIndex is not set, it defaults to 0. 
*/
@property NSInteger selectedIndex ;


/*!
 @brief    The receivers choices which were set during initialization
*/
@property (retain, readonly)  NSArray* choices ;

/*!
 @brief    Resizes the height of the receiver to accomodate the its current values,
 subject to allowsShrinking
 
 @param    allowShrinking  YES if the height is allowed to be reduced.  If this parameter
 is NO, and less height than the current height is required, this invocation will not reduce
 the height but will instead leave empty space.
 */
- (void)sizeHeightToFitAllowShrinking:(BOOL)allowShrinking ;

/*!
 @brief    Changes the height of the receiver and its subviews as
 required to accomodate the cells' texts and the receiver's
 current maxWidth
*/
- (void)sizeToFit ;

@end

