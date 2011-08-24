#import <Cocoa/Cocoa.h>


/*!
 @brief    A subclass of NSMenu which acts as a delegate for any
 dynamically-updated items you may add to it, and for itself,
 retaining the necessary information and sending a specified message when
 the user clicks an item which has been delegated to the SSYDynamicMenu.
 
 @details  To display a hierarchical menu, Cocoa sends NSMenuDelegate
 messages to the delegate of each menu item.  To display a menu in a
 popup button, Cocoa sends an NSMenuDelegate message to the button's
 menu's delegate.
 
 Having the owning menu be the delegate for its
 dynamically-updated menu items provides a handy and logical place to
 retain the invocation information (target, selector, and targetInfo)
 needed to fulfill the user's click.  Note that this only works if the
 invocation information does not change throughout the life of the
 SSYDynamicMenu.  This is the case if there is no info, and also for
 created-on-the-fly contextual menus.  Todo: Define an "target info
 getter target" and "target info getter selector" to be specified in
 lieu of targetInfo, for longer-lived SSYDynamicMenu instances whose
 targetInfo may change.
 
 Although it provides the required information and is designed to be
 a delegate of the NSMenuItem, SSYDynamicMenu does **not** implement
 either the non-lazy NSMenuDelegate method menuNeedsUpdate: nor the lazy
 delegate methods numberOfItemsInMenu: and menu:updateItem:atIndex:shouldCancel:.
 You must subclass SSYDynamicMenu and implemenent these methods.
 Subclassing is recommended instead of using a category for large
 projects because, if both the non-lazy and lazy methods are somehow
 available, which methods are invoked by Cocoa is not defined.
 
 In implementing menu:updateItem:atIndex:shouldCancel:, you should set the
 target of each menu item to the SSYDynamicMenu instance and the action to
 @selector(hierarchicalMenuAction:).  However, this does not work for
 flat menus attached to popup buttons.  In this case, set the target and the
 action of the SSYDynamicMenu instance.
 
 Since bindings to menus are rather sparse, this class also provides a weak
 reference to an owningPopUpButton.  You can set this and use it to 
 update the selection in your -menuNeedsUpdate method with code like this:
 *   NSPopUpButton* owningPopUpButton = [self owningPopUpButton] ;
 *   if (selectedMenuItem) {
 *       [owningPopUpButton selectItem:selectedMenuItem] ;
 *       [owningPopUpButton synchronizeTitleAndSelectedItem] ;
 *   }
 
 Handy for updating nonhierarchical menus, SSYDynamicMenu also provides instance
 variables for the current represented objects and selected represented object.
 */
@interface SSYDynamicMenu : NSMenu
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5) 
	<NSMenuDelegate> 
#endif
{
	id m_target ;
	SEL m_selector ;
	id m_targetInfo ;
	NSArray* m_representedObjects ;
	id m_selectedRepresentedObject ;
	id m_owningPopUpButton ; // weak
}

/*!
 @brief    Invokes super and then sets the delegate of the receiver
 to the receiver itself.
*/
- (id)initWithTitle:(NSString*)title ;

/*!
 @brief    Invokes super and then sets the delegate of the receiver
 to the receiver itself.
 */
- (id)initWithCoder:(NSCoder *)coder ;

/*!
 @brief    
 
 @details   When the user clicks a menu selection which has been delegated to
 the receiver, a message will be sent a specified target, via a specified
 selector with one or two arguments.
 
 If the specified selector has one argument, the argument passed in the
 message will be the -representedObject of the clicked menu item.
 
 If the specified selector has two arguments, the first argument passed in
 the message will be a targetInfo which was passed to initWithTarget:::.
 Typically, this is a payload of some kind.  The second argument,
 'selectedObject', will be the -representedObject of the clicked menu item.
 
 Example 1.  Say the menu's action is to set the representedObject to
 be an instance variable of some target.  The selector would be a setter
 such as setFoo: and the targetInfo would be nil.
 
 Example 2.  Say the menu's action is to move some selected objects to a
 different location in a hierarchy.  The selector should be something like
 moveObjects:toNewParent:, and the targetInfo should be the selected objects
 
 Example 3.  Say the menu's action is to add a new object which has been 
 created to a user-specified location in a hierarchy.  The selector should
 be something like moveObject:toNewParent:, and the targetInfo should be the
 new object.
 
 This method is the designated initializer for SSYDynamicMenu
 
 @param    target  An object which will receive a message when the user clicks
 a menu selection which has been delegated to the receiver.  This
 parameter is retained by the SSYDynamicMenu instance.
 
 @param    selector  A selector which will be sent to the target when the
 user clicks a menu selection which has been delegated to the receiver.
 This selector must take one or two parameters, having either of the
 following signatures
 *     handleSelectedObject:
 *     handleInfo:selectedObject:
 
 @param    targetInfo  The first parameter that will be sent in the
 message to the target via the selector, if it has two arguments.
 This parameter is retained by the SSYDynamicMenu instance.
 */
- (id)initWithTarget:(id)target
			selector:(SEL)selector
		  targetInfo:(id)targetInfo ;

/*!
 @brief    Setter which can be used if the designated initializer is not
 used when instantiating an SSYDynamicMenu, such as will occur if one
 is placed into a nib.
*/
@property (retain) id target ;

/*!
 @brief    Setter which can be used if the designated initializer is not
 used when instantiating an SSYDynamicMenu, such as will occur if one
 is placed into a nib.
 */
@property (assign) SEL selector ;

/*!
 @brief    Setter which can be used if the designated initializer is not
 used when instantiating an SSYDynamicMenu, such as will occur if one
 is placed into a nib.
 */
@property (retain) id targetInfo ;

/*!
 @brief    A reference to the receiver's currently represented objects.
 
 @details    You may set this before -menuNeedsUpdate will be invoked,
 and then reference it within your -menuNeedsUpdate implementation.
 */
@property (retain) NSArray* representedObjects ;

/*!
 @brief    A reference to the represented object of the receiver's
 current selection.
 
 @details    You may set this before -menuNeedsUpdate will be invoked,
 and then reference it within your -menuNeedsUpdate implementation.
 */
@property (retain) id selectedRepresentedObject ;

/*!
 @brief    Weak reference to the popup button which owns the receiver,
 or nil if there is no popup button.
 */
@property (assign) id owningPopUpButton ;

/*!
 @brief    Invokes the non-lazy populating method -menuNeedsUpdate,
 which should be implemented by your subclass or category.

 @details  Do not use this if your subclass or category does not 
 implements the non-lazy populating methods.
*/
- (void)reload ;

@end
