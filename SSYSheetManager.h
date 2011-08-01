#import <Cocoa/Cocoa.h>

/*!
 @brief    A class which manages a queue of sheets for windows,
 so that if you -beginSheet::::: on a window while a previously-
 begun sheet is still running modally, your new sheet will be
 enqueued for that window and run after the running sheet and
 previously-enqueued sheets have run.

 @details  From,
 http://developer.apple.com/documentation/Cocoa/Conceptual/Sheets/Tasks/UsingCascadingSheets.html#//apple_ref/doc/uid/20001046
 
 <i>Cocoa does not support the notion of cascading, or nested sheets.
 Per Apple Human Interface Guidelines, "when the user responds to
 a sheet, and another sheet for that document opens, the first
 sheet must close before the second one opens."<i>
 
 This class provides the mechanism needed to do that.
*/
@interface SSYSheetManager : NSObject {
	NSMutableDictionary* queues ;
}

/*!
 @brief    A wrapper around -[NSApp beginSheet:modalForWindow:modalDelegate:didEndSelector:contextInfo:].&nbsp;
 If the window is not already showing a sheet, this message is
 sent immediately.&nbsp;  Otherwise, it is converted to an
 invocation, enqueued and sent with the window is available.

 @details  For documentation of how the parameters work, see
 the documentation of
 -[NSApp beginSheet:modalForWindow:modalDelegate:didEndSelector:contextInfo:]
 and for further information:
 http://developer.apple.com/documentation/Cocoa/Conceptual/Sheets/Tasks/UsingCustomSheets.html#//apple_ref/doc/uid/20001290
*/
+ (void)enqueueSheet:(NSWindow*)sheet
	  modalForWindow:(NSWindow*)documentWindow
	   modalDelegate:(id)modalDelegate
	  didEndSelector:(SEL)didEndSelector
		 contextInfo:(void*)contextInfo ;

@end
