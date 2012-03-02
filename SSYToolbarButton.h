#import <Cocoa/Cocoa.h>


/*!
 @brief    A toolbar item which has a tristate 'value' attribute,
 and three each additional images, labels and tooltips which 
 replace super's image, label and tooltip when the value is changed

 @details  
*/
@interface SSYToolbarButton : NSToolbarItem {
	NSInteger m_value ;
	NSImage* m_onImage ;
	NSImage* m_offImage ;
	NSImage* m_disImage ;
	NSString* m_onLabel ;
	NSString* m_offLabel ;
	NSString* m_disLabel ;
	NSString* m_onToolTip ;
	NSString* m_offToolTip ;
	NSString* m_disToolTip ;
	id m_externalTarget ;
	SEL m_externalAction ;
}

/*!
 @brief    An internal variable, generally NSOnState,
 NSOffState or NSMixedState.

 @details  This is KVO-compliant and is also exposed as a binding.
*/
@property (assign) NSInteger value ;

/*!
 @brief    The image that will be displayed when the receiver's 
 value is set to NSOnState.
*/
@property (retain) NSImage* onImage ;

/*!
 @brief    The image that will be displayed when the receiver's
 value is set to NSOnState.
 */
@property (retain) NSImage* offImage ;

/*!
 @brief    The image that will be displayed when the receiver's
 value is set to NSMixedState.
 */
@property (retain) NSImage* disImage ;

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

@end
