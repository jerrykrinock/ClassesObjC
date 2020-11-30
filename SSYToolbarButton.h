#import <Cocoa/Cocoa.h>

/*!
 @brief    A toolbar item which has a tristate 'value' attribute,
 and three each additional images, labels and tooltips which 
 replace super's image, label and tooltip when the value is changed,
 and/or may be configured to flash when clicked.

 @details  
*/
@interface SSYToolbarButton : NSToolbarItem {
	NSInteger m_value ;
	NSImage* m_onImage ;
	NSImage* m_offImage ;
	NSImage* m_disImage ;
    NSImage* m_backgroundImage;
    NSImage* m_originalImage ;
	NSString* m_onLabel ;
	NSString* m_offLabel ;
	NSString* m_disLabel ;
	NSString* m_onToolTip ;
	NSString* m_offToolTip ;
	NSString* m_disToolTip ;
	id m_externalTarget ;
	SEL m_externalAction ;
    NSTimeInterval m_flashDuration ;
    NSTimer* m_flashTimer ;
}

/*!
 @brief    An internal variable, generally NSOnState,
 NSOffState or NSMixedState.

 @details  This is KVO-compliant and is also exposed as a binding.
*/
@property (assign) NSInteger value ;

/*!
 @brief    The image that will be displayed when the receiver's  value is
 NSOnState.
*/
@property (retain) NSImage* onImage ;

/*!
 @brief    The image that will be displayed when the receiver's value is
 NSOnState.
 */
@property (retain) NSImage* offImage ;

/*!
 @brief    The image that will be displayed when the receiver's value is
 NSMixedState.
 */
@property (retain) NSImage* disImage ;

/*!
 @brief    An image that will always be displayed regardless of the  receiver's
 value.
 */
@property (retain) NSImage* backgroundImage;

/*!
 @brief    The string that will be displayed under the button
 when the receiver's value is set to NSOnState.  This value
 defaults to nil, and if it is nil when the receiver's value 
 is changed to this state, the label does not change.  Thus,
 for a fixed, constant label, use super's -setLabel:
 */
@property (retain) NSString* onLabel ;

/*!
 @brief    The string that will be displayed under the button
 when the receiver's value is set to NSOnState.  This value
 defaults to nil, and if it is nil when the receiver's value 
 is changed to this state, the label does not change.  Thus,
 for a fixed, constant label, use super's -setLabel:
 
 */
@property (retain) NSString* offLabel ;

/*!
 @brief    The string that will be displayed under the button
 when the receiver's value is set to NSMixedState.  This value
 defaults to nil, and if it is nil when the receiver's value 
 is changed to this state, the label does not change.  Thus,
 for a fixed, constant label, use super's -setLabel:
 
 */
@property (retain) NSString* disLabel ;

/*!
 @brief    The receiver's toolTip
 when the receiver's value is set to NSOnState.  This value
 defaults to nil, and if it is nil when the receiver's value 
 is changed to this state, the label does not change.  Thus,
 for a fixed, constant toolTip, use super's -setToolTip:
 */
@property (retain) NSString* onToolTip ;

/*!
 @brief    The receiver's toolTip
 when the receiver's value is set to NSOnState.  This value
 defaults to nil, and if it is nil when the receiver's value 
 is changed to this state, the label does not change.  Thus,
 for a fixed, constant toolTip, use super's -setToolTip:
 */
@property (retain) NSString* offToolTip ;

/*!
 @brief    The receiver's toolTip
 when the receiver's value is set to NSMixedState.  This value
 defaults to nil, and if it is nil when the receiver's value 
 is changed to this state, the label does not change.  Thus,
 for a fixed, constant toolTip, use super's -setToolTip: 
 */
@property (retain) NSString* disToolTip ;

/*!
 @brief    Duration for which the receiver shall flash when it is clicked
 @details  The default value is 0 (no flash)
 */
@property (assign) NSTimeInterval flashDuration ;

@end

@interface SSYToolbarButtonView : NSView

@property (weak) SSYToolbarButton* toolbarItem;

/*!
 @brief    Workaround for the fact that intrinsicContentSize is not a property
 of NSToolbarItem

 @details  Oddly, although it does not change the size, this value affects
 the centering of the image in macOS 10.11.
*/
@property (assign) NSSize ssyIntrinsicContentSize ;

@end

