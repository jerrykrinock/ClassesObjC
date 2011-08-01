#import <Cocoa/Cocoa.h>


@interface SSYToolbarButton : NSToolbarItem {
	NSInteger m_value ;
	NSImage* m_onImage ;
	NSImage* m_offImage ;
	id m_externalTarget ;
	SEL m_externalAction ;
}

/*!
 @brief    Whether or not the button is pushed in (NSOnState) 
 or protruding out (NSOffState).

 @details  This is KVO-compliant and is also exposed as a binding.
*/
@property (assign) NSInteger value ;

/*!
 @brief    The image that will be displayed when the button is 
 switched into the ON state.
*/
@property (retain) NSImage* onImage ;

/*!
 @brief    The image that will be displayed when the button is
 switched into the OFF state.
 */
@property (retain) NSImage* offImage ;

@end
