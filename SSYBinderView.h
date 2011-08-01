#import <Cocoa/Cocoa.h>


/*!
 @brief    A view which manages the bindings of its subviews

 @details  
*/
@interface SSYBinderView : NSView {
	BOOL m_isBound ;
	NSMutableSet* m_bindings ;
}

/*!
 @brief    A friendly wrapper around bind:toObject:withKeyPath:options:
 which will remember the binding and unbind it whenever the given subview
 is either removed from its superview, or else added to a superview
 that does not itself have a window, and re-bind it whenever it is added
 to a superview that does have a window.
 
 @details  No-op if any of the first four parameters are nil.
 @param    subview  The subview which will be bound; i.e. the receiver
 of bind:toObject:withKeyPath:options.
 @param    bindingName  The 'bind' parameter in bind:toObject:withKeyPath:options.
 @param    object  The 'object' parameter in bind:toObject:withKeyPath:options:
 @param    keyPath  The 'keyPath' parameter in bind:toObject:withKeyPath:options:
 @param    options  The 'options' parameter in bind:toObject:withKeyPath:options:
 */
- (void)bindSubview:(NSView*)subview
		bindingName:(NSString*)bindingName
		   toObject:(id)object
		withKeyPath:(NSString*)keyPath
			options:(NSDictionary*)options ;

/* todo
 - (void)unbindSubview:(NSView*)subview
		bindingName:(NSString*)bindingName ;
*/

@end
