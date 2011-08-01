#import <Cocoa/Cocoa.h>

@class SSYAlert ;

@interface SSYListPicker : NSObject {
	SSYAlert* m_alert ;
}


/*!
 @brief    Convenience method returning an auteleased listPicker
*/
+ (SSYListPicker*)listPicker ;

/*!
 @brief    Presents a window asking user to pick from
 a list of strings and returns the index set of the user's choices.

 @param    displayNames  The list of strings to be given the user as choices.
 @param    toolTips  An array of toolTip strings, and/or NSNull objects,
 corresponding by index to displayNames.  Number of objects in this array should equal
 the number in the displayNames array.  If no tooltips are desired, pass nil.  If
 tooltips are desired for only some choices, pass an array with NSNull objects
 at the indexes which have no tooltips.
 @param    message  Text to appear above the list.
 @param    allowMultipleSelection  Whether or not the list will allow multiple
 selections.&nbsp; If so, a paragraph instructing the user how to use the cmd key
 to make multiple selections.
 @param    allowEmptySelection  Whether or not the receiver requires a selection
 to be made before enabling the default button.
 @param    button1Title  Localized title of the default button.&nbsp; If nil,
 defaults to localized "OK"
 @param    button2Title  Localized title of the alternate button.&nbsp; If nil,
 defaults to localized "Cancel".  (The other/3rd button is localized "Clear Selection".)
 @param    initialPicks  Index Set of items to be initially selected (suggested)
 when the receiver is displayed
 @param    windowTitle  Localized title to appear in the receiver's title bar.&nbsp; If
 nil, the localized application name will appear.
 @param    alert  The alert in which to run..&nbsp;  If nil, will create an
 [SSYAlert alert].
 @param    runModal  Specifies whether or not to run the window as a modal session.
 @param    didEndTarget  An object to which the didEndSelector will be sent if and
 when the user clicks the default button.&nbsp; May be nil, but then you'd never
 find out what the user picked.
 @param    didEndSelector  The selector in the didEndTarget which the message which
 will be delivered to.&nbsp; If didEndTarget is not nil, must be a valid selector
 taking two arguments.&nbsp; The first argument delivered will be an NSIndexSet
 containing the indexes selected by the user.&nbsp;  This argument may be an empty
 index set, If the user selected no items and clicked the default button, but
 it will never be nil.&nbsp; The second argument delivered will be the
 didEndUserInfo, passed through.&nbsp;  
 @param    didEndUserInfo  An optional object which will be passed to the didEndTarget
 via the didEndEndSelector.
 @param    didCancelInvocation  An invocation which will be invoked if the user clicks
 the second button (the leftmost button).   May be nil, to invoke nothing.
 @result   The user's selection in terms of the display names, which may be an
 empty index set, or nil if the user clicked "Cancel"
*/
- (void)userPickFromList:(NSArray*)displayNames
				toolTips:(NSArray*)toolTips
		   lineBreakMode:(NSLineBreakMode)lineBreakMode
				 message:(NSString*)message
  allowMultipleSelection:(BOOL)allowMultipleSelection
	 allowEmptySelection:(BOOL)allowEmptySelection
			button1Title:(NSString*)button1Title
			button2Title:(NSString*)button2Title
			initialPicks:(NSIndexSet*)initialPicks
			 windowTitle:(NSString*)windowTitle
				   alert:(SSYAlert*)alert
				runModal:(BOOL)runModal
			didEndTarget:(id)didEndTarget
		  didEndSelector:(SEL)didEndSelector
		  didEndUserInfo:(id)didEndUserInfo
	 didCancelInvocation:(NSInvocation*)didCancelInvocation ;

@end
