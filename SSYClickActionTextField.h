#import <Cocoa/Cocoa.h>

/*!
 @brief    A text field which will sends its target/action message
 when it is clicked.
 
 @details  Useful if you are using this to display static text
 in a control and want the behavior to be like a checkbox
 implemented with NSButton; i.e., clicking the text toggles the
 checkbox the same as if you clicked the checkbox.
 */
@interface SSYClickActionTextField : NSTextField {
	
}

@end
