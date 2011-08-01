#import <Cocoa/Cocoa.h>

/*!
 @brief    This class provides a control which consists of two text fields,
 a non-editable <i>key</i> field and, below it, an editable <i>value</i> field.

 @details  May be used, for example for a user to fill in a <i>Name</i>, <i>Password</i>
 <i>Favorite Animal</i>, etc. etc.  Any single line of text.
*/
@interface SSYLabelledTextField : NSControl {
	NSTextField* keyField ;
	NSTextField* valueField ;
	SEL validationSelector ;
	NSWindowController* windowController ;  // Documentation explains why this kludge is necessary
	id validationObject ;
	NSString* errorMessage ;
}

@property (retain) NSTextField* keyField ;
@property (retain) NSTextField* valueField ;
@property (assign) SEL validationSelector ;
@property (retain) id windowController ;
@property (retain) id validationObject ;
@property (retain) NSString* errorMessage ;

/*!
 @brief    Convenience method for getting an autoreleased instance of this class.

 @details  You can implement the validationSelector method in an NSString category.
 
 If a validationSelector is provided, the value entered by the user is continuously
 validated (using -controlTextDidChange:).&nbsp; After validation, the instance's "window
 controller" (see below) is tested to see if it responds to setEnabled:, or setIsEnabled:,
 and setWhyDisabled:.&nbsp; If they respond, and the entry is valid, these two messages
 are sent with arguments YES and nil, respectively.&nbsp; If they respond, and the entry
 is not valid, these two messages are sent with arguments NO and errorMessage, respectively.
 
 The instance's "window controller" is normally obtained by sending -window.windowController,
 but in some cases, such as when this control is used in an SSYAlert, the initial validation
 performed by this class' initializer is executed before being the receiver is added to its
 window's contentView, and in this case -window.windowController, will return nil.&nbsp; The
 two validation (or more likely, invalidation) messages described above will then be sent to
 nil and thus not have the intended effect.&nbsp; The fix implemented for this is that if
 -window.windowController returns nil, the two messages are sent to the windowController
 ivar instead.
 
 The reason the ivar is not used all the time is because when an SSYLabelledTextField object is
 unarchived after a -deepCopy of it is stored in SSYAlertView's configurations stack, the
 windowController ivar will be the old window controller (which is the old SSYAlertView).
 The old SSYAlertView was retained, so it won't crash, but the message goes to a defunct,
 no-longer-visible SSYAlertView and thus, again, has no effect.
 
 Code implementing this detection and switching is in -validate.

 @param    secure  YES if the <i>value</i> field should be an NSSecureTextField,
 NO for a plain NSTextField
 @param    validationSelector  Either NULL, or a selector to which NSString must respond and
 return an NSNumber.&nbsp; The -boolValue of the NSNumber should indicate whether
 or not its receiver is a <i>valid</i> entry for the returned SSYLabelledTextField instance.&nbsp; 
 This selector may take 0 or 1 argument of type id.&nbsp; If this parameter is NULL, no
 validation will be performed.
 @param    validationObject  An optional argument to the validationSelector.&nbsp; If the
 validationSelector takes no arguments, pass nil.
 @param    windowController  The receiver's window controller to which validation
 messages will be sent.&nbsp; If the receiver is being installed into an SSYAlert,
 this would be that SSYAlert object.&nbsp; See method details for explanation of why this is needed.
 @param    displayedKey  The string to be set in the <i>key</i> or <i>label</i> field.
 @param    displayedValue  The initial string to be set in the <i>value</i> field, or nil to
 set an empty string.
 @param    editable  YES if the <i>value</i> field should be editable, NO otherwise.
 @param    errorMessage  An error message which will be sent as the argument of
 a message -setWhyDisabled:to the returned instance's window's window controller, if it responds.
 @result   The instance, autoreleased.
 */
+ (SSYLabelledTextField*)labelledTextFieldSecure:(BOOL)secure
							  validationSelector:(SEL)validationSelector
								validationObject:(id)validationObject
								windowController:(id)windowController
									displayedKey:(NSString*)displayedKey
								  displayedValue:(NSString*)displayedValue
										editable:(BOOL)editable
									errorMessage:(NSString*)errorMessage ;

/*!
 @brief    Resizes the height of the receiver to accomodate the current text values,
 subject to allowsShrinking

 @param    allowShrinking  YES if the height is allowed to be reduced.  If this parameter
 is NO, and less height than the current height is required, this invocation will not reduce
 the height but will instead leave empty space.
*/
- (void)sizeHeightToFitAllowShrinking:(BOOL)allowShrinking ;


@end

