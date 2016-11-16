#import <Cocoa/Cocoa.h>


/*!
 @brief    This class provides a control which consists of a non-editable NSTextField
 <i>label</i> and, below it, a non-editable list of strings (choices), displayed in
 an NSScrollView+NSTableView, and below that, if the control contains more than
 one item, a button for the user to select "All", and if the control allows
 an empty selection, "None".  The height of the scroll/table is adjusted to fit the
 content, up to a given maximum table height.
 
 @details  May be used, for example for a user to select several items from a list.
 */
@interface SSYLabelledList : NSView
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= 1060) 
	<NSTableViewDataSource, NSTableViewDelegate>
#endif
{
	NSTextField* labelView ;
	NSScrollView* scrollView ;
    NSView* allOrNoneView ;
	NSArray* choices ;
	NSArray* m_toolTips ;
	NSDictionary* cellTextAttributes ;
	CGFloat maxTableHeight ;
}

/*!
 @brief    Convenience method for getting an autoreleased instance of this class.
 
 @param    label  The string in the <i>label</i> which will appear above
 the list in the returned instance.&nbsp; If allowsMultipleSelection has
 not been set to NO, a localized version of "Hold down the 'shift' or
 \xe2\x8c\x98 key to select more than one." will be appended.
 (Or instead of \x escapes, use %C format specifier with substution 0x2318.)
 @param    choices  An array of strings, to appear in the list
 @param    allowsMultipleSelection  Sets whether or not the receiver's table
 view allows a multiple selection
 @param    allowsEmptySelection  Sets whether or not the receiver's table view
 allows a empty selection
 @param    toolTips  An array of toolTip strings, and/or NSNull objects,
 corresponding by index to choices.  Number of objects in this array should equal
 the number in the choices array.  If no tooltips are desired, pass nil.  If
 tooltips are desired for only some choices, pass an array with NSNull objects
 at the indexes which have no tooltips.
 @param    maxTableHeight  The maximum height allowed of the scroll/table view.&nbsp; 
 If this height is not enough to accomodate the given choices, a vertical scroller
 will appear.
 @result   The instance, autoreleased
 */
+ (SSYLabelledList*)listWithLabel:(NSString*)label
						  choices:(NSArray*)choices
          allowsMultipleSelection:(BOOL)allowsMultipleSelection
             allowsEmptySelection:(BOOL)allowsEmptySelection
						 toolTips:(NSArray*)toolTips
					lineBreakMode:(NSLineBreakMode)lineBreakMode
				   maxTableHeight:(CGFloat)maxTableHeight ;

/*!
 @brief    Sets the set of indexes to be initially selected (suggested)
 when the list is displayed.
*/
- (void)setSelectedIndexes:(NSIndexSet*)selectedIndexes ;

/*!
 @brief    Returns the set of indexes selected in the receiver's list,
 from the receiver's choices.
 */
- (NSIndexSet*)selectedIndexes ;

/*!
 @brief    Returns the set of strings selected in the receiver's list
 */
- (NSArray*)selectedValues ;

/*!
 @brief    Sets the delegate of the receiver's table view

 @details  This is useful if you have buttons that need to be enabled
 after a selection is made.&nbsp;  In the delegate, implement
 -tableViewSelectionDidChange:.
 @param    delegate  
*/
- (void)setTableViewDelegate:(id)delegate ;

/*!
 @brief    Returns the font used in the receiver's table view.
*/
+ (NSFont*)tableFont ;

@end

