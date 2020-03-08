#import <Cocoa/Cocoa.h>

@interface SSYPassMouseEventsToSiblingTextField : NSTextField;
@end

/*!
 @brief    This class provides a checkbox for which text wrapping actually works.
 
 @details  Under the hood, uses an NSTextField to replace the title of the checkbox.
 */
@interface SSYWrappingCheckbox : NSControl {
	SSYPassMouseEventsToSiblingTextField* m_textField ;
	NSButton* m_checkbox ;
	CGFloat m_maxWidth ;
}

/*!
 @brief    The text-wrapping label field to the right of the checkbox,
 which replaces its title.

 @details  Since self retains this as a subview, we only need a weak, 
 i.e. (assign) reference
*/
@property (assign) SSYPassMouseEventsToSiblingTextField* textField ;

/*!
 @brief    The NSButton which does the work, except that its title
 is not used.
 
 @details  Since self retains this as a subview, we only need a weak, 
 i.e. (assign) reference
 */
@property (assign) NSButton* checkbox ;

/*!
 @brief    The maximum width allowed for the receiver, which is
 enforced by text-wrapping the title.

 @details  
*/
@property (assign) CGFloat maxWidth ;

/*!
 @brief    The state of the receiver's checkbox
*/
@property (assign) NSCellStateValue state ;

/*!
 @brief    Designated initializer for SSYWrappingCheckbox.
 
 @param    title  The text value of the <i>label</i> which will appear to the
 right of the checkbox in the returned instance, where its title would normally be.
 @param    maxWidth  The maximum width that the returned view will be.
 */
- (id)initWithTitle:(NSString*)title
		   maxWidth:(CGFloat)maxWidth ;

/*!
 @brief    Convenience method for getting an autoreleased instance of this class.

 @param    title  The text value of the <i>label</i> which will appear to the
 right of the checkbox in the returned instance, where its title would normally be.
 @param    maxWidth  The maximum width that the returned view will be.
 @result   The instance, autoreleased
*/
+ (SSYWrappingCheckbox*)wrappingCheckboxWithTitle:(NSString*)title
										 maxWidth:(CGFloat)width ;

/*!
 @brief    Resizes the height of the receiver to accomodate the its current values,
 subject to allowsShrinking.
 
 @param    allowShrinking  YES if the height is allowed to be reduced.  If this parameter
 is NO, and less height than the current height is required, this invocation will not reduce
 the height but will instead leave empty space.
 */
- (void)sizeHeightToFitAllowShrinking:(BOOL)allowShrinking ;

@end

