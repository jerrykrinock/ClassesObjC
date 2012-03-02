#import <Cocoa/Cocoa.h>
#import "SRCommon.h"  // for KeyCombo

extern NSString* const SSYShortcutActuatorDidNonemptyNotification ;
extern NSString* const SSYShortcutActuatorDidEmptyNotification ;


@interface SSYShortcutActuator : NSObject {
	NSMutableDictionary* m_registeredShortcutInfos ;
	NSMutableDictionary* m_selectorNameLookup ;
	NSUInteger m_shortcutSerialNumber ;
	BOOL m_isHandlerInstalled ;
}

/*!
 @brief    

 @details  This function was written by Harry Jordan of
 Inquisitive Software, Brighton, UK, http://inquisitivesoftware.com/
 Specifically, it was ripped from
 http://inquisitivecocoa.com/2009/04/05/key-code-translator/
 @param    keyCode  
 @param    modifierFlags  
 @result   
*/
+ (NSString*)stringForKeyCode:(NSInteger)keyCode
				modifierFlags:(NSUInteger)modifierFlags ;


/*!
 @brief    Returns a human-readable ASCII description of a modifiers
 key number, for example "cmd+opt+ctrl+shift+func"

 @details  This is intended for debugging; it is not localized.
*/
+ (NSString*)descriptionOfModifiers:(NSUInteger)modifiers ;

/*!
 @brief    Creates if not yet existing, and then returns the
 shared actuator for this application.

 @details  Even if there are no shortcuts to be set or removed,
 if you want shortcuts which were remembered in the app's user
 defaults to be installed and work, you should invoke this
 method.
*/
+ (SSYShortcutActuator*)sharedActuator ;

/*!
 @brief    Installs a Carbon Event handler for a given shortcut
 key combination to a given selector in [NSApp delegate], and
 also registers this combination and selector in standard user
 defaults, so that it will be installed whenever the shared
 actuator is created, typically whenever this app is relaunched.

 @details  
 @param    keyCode  The key code for the new handler, or -1
 to remove the handler
 @param    modifierFlags  The Cocoa modifier keys for the new handler, for
 example NSShiftKeyMask+NSCommandKeyMask+NSAlternateKeyMask+NSControlKeyMask
 @param    selectorName  The name of the selector of the message which
 will be sent to [NSApp delegate], if it responds, when the user
 presses the shortcut.  This selector's signature must take 0 parameters.
 */
- (void)setKeyCode:(NSInteger)keyCode
	 modifierFlags:(NSUInteger)modifierFlags
	  selectorName:(NSString*)selectorName ;

- (KeyCombo)keyComboForSelectorName:(NSString*)selectorName ;

- (void)disableAllShortcuts ;
- (void)enableAllShortcuts ;


@end
