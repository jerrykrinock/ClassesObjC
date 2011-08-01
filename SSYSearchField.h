#import <Cocoa/Cocoa.h>

/*!
 @brief    Notification which is posted when the user clicks the
 "cancel" button, that is, the "X" near the right edge.

 @details  The notification object is the SSYSearchField instance.
 This notification does not have a user info dictionary.
*/
extern NSString* const SSYSearchFieldDidCancelNotification ;

@interface SSYSearchField : NSSearchField {
	id m_cancelButtonTarget ;
	SEL m_cancelButtonAction ;
}

@end
