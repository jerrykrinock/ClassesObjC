#import <Cocoa/Cocoa.h>
#import "SRCommon.h"  // for KeyCombo, also this imports <Carbon/Carbon.h>

/*
 @brief    Posted whenever the count of shortcuts registered with the shared
 actuator increases from 0 to 1
 
 @details  The notification object is the shared actuator.  If the user defaults
 contains one or more shortcuts to be registered, this notification will be
 posted during the -init of the shared actuator.
 */
extern NSString* const SSYShortcutActuatorDidNonemptyNotification ;

/*
 @brief    Posted whenever the count of shortcuts registered with the shared
 actuator decreases from 1 to 0
 
 @details  The notification object is the shared actuator.
 */
extern NSString* const SSYShortcutActuatorDidEmptyNotification ;

/*
 @brief    Posted at the conclusion of -setKeyCode:modifierFlags:selectorName:,
 whether or not any shortcut was actually registered or unregistered
 
 @details  The notification object is the actuator to which
 -setKeyCode:modifierFlags:selectorName: was sent.
 */
extern NSString* const SSYShortcutActuatorDidChangeShortcutsNotification ;



@interface SSYShortcutActuator : NSObject {
	NSMutableDictionary* m_registeredShortcutInfos ;
	NSMutableDictionary* m_selectorNameLookup ;
	NSUInteger m_shortcutSerialNumber ;
	BOOL m_isHandlerInstalled ;
}

/*
 @brief    Returns a key path in the application's shared user defaults
 controller in which the key binding for a given selector name is stored.
 
 @details  This is useful if you want to observe changes in key bindings
 with key value observing.
 */
+ (NSString*)userDefaultsKeyPathForSelectorName:(NSString*)selectorName ;

/*!
 @brief    

 @details  This function was written by Harry Jordan of
 Inquisitive Software, Brighton, UK, http://inquisitivesoftware.com/
 Specifically, it was ripped from
 http://inquisitivecocoa.com/2009/04/05/key-code-translator/
 @param    keyCode  
 @param    modifierFlags  
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

/*!
 @brief    Returns the KeyCombo of the shortcut which is currently registered to
 invoke a give selector
 
 @details  If no such shortcut is currently registered, the 'code' member of
 the result is -1.  Or use -hasKeyComboForSelectorName: instead.
 */
- (KeyCombo)keyComboForSelectorName:(NSString*)selectorName ;

/*!
 @brief    Returns whether or not a keyboard shortcut is currently registered
 to invoke a given selector
 */
- (BOOL)hasKeyComboForSelectorName:(NSString*)selectorName ;

/*!
 @brief    Returns whether or not the receiver has one or more keyboard
 shortcuts currently registered
 */
- (BOOL)hasAnyKeyCombo ;

- (void)disableAllShortcuts ;
- (void)enableAllShortcuts ;


@end
