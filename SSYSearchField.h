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

/*!
 @brief     Prepends a new string to the receiver's recentSearches array, 
 deleting any earlier copies
 
 @details   NSSearchField is supposed to "automatically" add new search strings
 to its recentSearches.  In my experience, it works about 5% of the time and
 I can't figure out why or not.  This method works 100% of the time.  Invoke
 it during the action method ("search:", or whatever) of your search field.
 
 This method was added to fix that unreliable behavior in BookMacster 1.16
 
 @param    newString  The new string to be prepended.  OK if it is nil, or
 empty, or if it matches the current first item in the receiver's recentSearches
 array.  In these cases, this method has no effect.  The latter case is now for 
 efficiency, because does a lot of work whenever anything is done to affect
 the little menu inside of an NSSearchField, including the fact that it makes
 a copy of its menu from its template.  Originally, it was because I was not
 aware of this behavior and the more this method had no effect, the less I saw
 the effect of a bug which was caused by my lack of awareness.
 */
- (void)appendToRecentSearches:(NSString*)newString ;

@end
