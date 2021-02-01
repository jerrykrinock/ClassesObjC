#import <Cocoa/Cocoa.h>

@class SSYWrappingCheckbox ;

enum {
	SSYAlertIconNoIcon,          /*!<  Alert will have no icon */
    SSYAlertIconInformational,   /*!<  Alert will be app icon with no badge */
    SSYAlertIconWarning,         /*!<  Alert will be app icon with yellow warning badge */
	SSYAlertIconCritical,        /*!<  Alert will be app icon with red critical badge */
} ;

enum SSYAlertMode_enum {
    SSYAlertModeNonBlocking,
    SSYAlertModeModalSession,
    SSYAlertModeModalDialog
};
typedef enum SSYAlertMode_enum SSYAlertMode ;

/*!
 @details  Classic layout is commonly used when button1 = OK, button2 = cancel
 and button3 = alternate.  It looks like this:
 
 | [2]           [3]  [1] |
 
 Right to left layout is what it says
 
 |     [4]  [3]  [2]  [1] |
 
 which reflects Apple's current descriptions of NSAlertFirstButtonReturn,
 NSAlertSecondButtonReturn, NSAlertThirdButtonReturn
 */
enum SSYAlertButtonLayout_enum {
    SSYAlertButtonLayoutClassic,
    SSYAlertButtonLayoutRightToLeft,
};
typedef enum SSYAlertButtonLayout_enum SSYAlertButtonLayout ;

/*!
 @brief    These are an addition to Apple's anonymous enumeration containing
 NSAlertFirstButtonReturn, NSAlertSecondButtonReturn, NSAlertThirdButtonReturn
 and NSAlertErrorReturn.
 
 @details  These values are reflected in the 'Sheep Systems Suite'
 AppleScript terminology.  Any changes you make here should be reflected
 in there.
*/
enum SSYAlertRecovery_enum {
    SSYAlertRecoveryThereWasNoError          = 99,
	SSYAlertRecoverySucceeded		         = 100,
	SSYAlertRecoveryFailed                   = 101,
	SSYAlertRecoveryNotAttempted             = 102,
	SSYAlertRecoveryAttemptedAsynchronously  = 103,
	SSYAlertRecoveryErrorIsHidden            = 104,
	SSYAlertRecoveryUserCancelledPreviously  = 105,
    SSYAlertRecoveryInternalError            = 106,
    SSYAlertFirstButtonReturn                = NSAlertFirstButtonReturn,  // 1000
    SSYAlertSecondButtonReturn               = NSAlertSecondButtonReturn, // 1001
    SSYAlertThirdButtonReturn                = NSAlertThirdButtonReturn,  // 1002
    SSYAlertFourthButtonReturn               = 1003
} ;
typedef enum SSYAlertRecovery_enum SSYAlertRecovery ;

enum SSYAlertRecoveryApplescriptCode_enum {
    SSYAlertRecoveryAppleScriptCodeThereWasNoError          = 'Nerr',
	SSYAlertRecoveryAppleScriptCodeSucceeded		        = 'ReSx',
	SSYAlertRecoveryAppleScriptCodeFailed                   = 'ReFa',
	SSYAlertRecoveryAppleScriptCodeNotAttempted             = 'NoAt',
	SSYAlertRecoveryAppleScriptCodeAttemptedAsynchronously  = 'AtAs',
	SSYAlertRecoveryAppleScriptCodeErrorIsHidden            = 'ErHd',
	SSYAlertRecoveryAppleScriptCodeUserCancelledPreviously  = 'UsCn'	
} ;
typedef enum SSYAlertRecoveryApplescriptCode_enum SSYAlertRecoveryAppleScriptCode ;

/*!
 @brief    Key used in the contextInfo sent to attemptRecoveryFromError:::::
 to access an invocation which should be invoked upon successful recovery.
*/
extern NSString* const SSYAlertDidRecoverInvocationKey ;

/*!
 @brief    Key to an optional string value in user defaults which causes
 the "Contact Support | Email" life-preserver button to appear when
 errors are presented, and to which support emails are addressed.
*/
extern NSString* const SSYAlert_ErrorSupportEmailKey ;

/*!
 @brief    A notification which is posted whenever one of the methods
 of this class begins to present an error.

 @details  The notification object is the error which is being presented.
 This notification will be posted even for errors for which
 [gSSYErrorDisplayManager shouldHideError:error] returns NO. 
*/
extern NSString* const SSYAlertDidProcessErrorNotification ;

/*!
 @brief    The subclass of NSWindow created by SSYAlert.  The interface
 is exposed so that you can get the checkbox state after an SSYAlert is closed,
 without setting dontGoAwayUponButtonClicked to YES
 
 @details  Typically, in a -didEndSheet:returnCode:contextInfo: callback
 on a sheet whose window controller is an SSYAlert alert, the SSYAlert may
 already be gone and [sheet windowController] will return nil.  So you can't
 get control values from the window controller.  This class allows you to get
 control states from the window directly.
 */
@interface SSYAlertWindow : NSWindow

- (NSInteger)checkboxState ;

@end

/*!
 @brief    The SSYErrorRecoveryAttempting informal protocol is a 
 replacement for Cocoa's NSErrorRecoveryAttempting informal protocol
 which has a different name for the second parameter of the two methods,
 reflecting the fact that we don't give the user more than three
 recovery options.

 @details  The SSYErrorRecoveryAttempting informal protocol provides methods
 that allow your application to attempt to recover from an error.  One of
 these methods is invoked when an NSError object is displayed by
 -[SSYAlert alertError:] that specifies the implementing object as the error
 recoveryAttempter.
 
 SSYAlert first checks to see if your recovery attempter responds to
 attemptRecoveryFromError:recoveryOption:delegate:didRecoverSelector:contextInfo:
 and sends that message if it does.  If not, SSYAlert checks to see if your
 recovery attempter responds to attemptRecoveryFromError:recoveryOption:
 and sends that message if it does.  If not, no recovery is attempted.
*/
@interface NSObject (SSYErrorRecoveryAttempting)

/*!
 @details  Note that this is different from Apple's method
 attemptRecoveryFromError:optionIndex:delegate:didRecoverSelector:contextInfo:
 in the 'recoveryOption' parameter.
 @param    error  The error to be recovered from
 @param    recoveryOption  Should be one of NSAlertFirstButtonReturn,
 NSAlertSecondButtonReturn, or NSAlertAlternate return.  Note that this is
 different from Apple's method
 attemptRecoveryFromError:optionIndex:delegate:didRecoverSelector:contextInfo:
 in which the analagous optionIndex parameter can be any nonnegative integer.
*/
- (void)attemptRecoveryFromError:(NSError *)error
				  recoveryOption:(NSUInteger)recoveryOption
						delegate:(id)delegate
			  didRecoverSelector:(SEL)didRecoverSelector
					 contextInfo:(void *)contextInfo ;

/*!
 @details  Note that this is different from Apple's method
 attemptRecoveryFromError:optionIndex:delegate:didRecoverSelector:contextInfo:
 in the 'recoveryOption' parameter.
 @param    recoveryOption  Should be one of NSAlertFirstButtonReturn,
 NSAlertSecondButtonReturn, or NSAlertThirdButton return.  Note that this is
 different from Apple's method
 attemptRecoveryFromError:optionIndex:delegate:didRecoverSelector:contextInfo:
 in which the analagous optionIndex parameter can be any nonnegative integer.
*/
- (BOOL)attemptRecoveryFromError:(NSError *)error
				  recoveryOption:(NSUInteger)recoveryOption ;

@end

@protocol SSYAlertErrorHideManager

/*!
 @brief    Method which is invoked by SSYAlert's +alertError,
 +alertError:::::, -alertError: and -alertError::::: methods
 to determine whether the error they are given should be
 displayed or no-op.

 @details  If error is nil, this method should return YES
*/
- (BOOL)shouldHideError:(NSError*)error ;

@end

extern NSObject <SSYAlertErrorHideManager> * gSSYAlertErrorHideManager ;


/*!
 @brief    This class provides a "shared" (singleton) alert dialog which is similar to Apple's NSRunXXXXAlert but
 has additional features.

 <p>
 The basic look is similar to Apple's alert prior in macOS 10.15 and earlier.&nbsp; There are two columns, left and right.&nbsp;
 The left column may have, from top to bottom:
 <ul>
 <li>  An icon</li>
 <li>  A "Help" button (with a question-mark)</li>
 <li>  A "Support" button (with a life-preserver)</li>
 </ul>
 and the right column may have, from top to bottom:
 <ul>
 <li>  A "title".&nbsp; This is like a "paragraph" title, at the top of the window's
 content view, not to be confused with the window title.</li>
 <li>  A progress bar</li>
 <li>  A "small text" text view.&nbsp; This is for displaying message details.</li>
 <li>  An arbitrary number of "other subviews".&nbsp; If you want the height of the
 other subview to vary with its content, override the -sizeHeightToFitAllowShrinking
 which is implemented as a no-op in category NSView (HeightSizableToFit).&nbsp;
 Two ready-made such views are provided in the SSYAlert framework:
	 <ul>
	 <li>  An editable text field with a label above it (SSYLabelledTextField)</li>
	 <li>  A popup button with a label above it (SSYLabelledPopUp)</li>
	 </ul>
 </li>
 <li>  A checkbox which is a text-wrapping SSYWrappingCheckbox.</li>
 <li>  0 to 3 buttons.</li>
 <li>  Ability to re-use the alert, for example, to avoid
 </ul>
 </p>
 
 @detail
 <p>
 The additional features are:
 <ul>
 <li>  Optional progress bar</li>
 <li>  Optional checkbox which may be used for stuff like "Don't show this again".</li>
 <li>  Optional invocation which, if set, will be invoked after the alert is dismissed if its checkbox is checked.</li>
 <li>  Optional Help button.</li>
 <li>  Optional Support button</li>
 <li>  Optional text field(s).</li>
 <li>  Optional popup menu(s).</li>
 <li>  Can be run as a regular non-modal window, modal session, or modal dialog.</li>
 <li>  Same alert can be reconfigured on the fly to show progress of cascaded or nested processes, which looks much better than having alerts rapidly appear and disappear.</li>
 <li>  Provides a replacement for -[NSError presentError:].  Use +alertError: or +alertError:::::</li>
 <li>  User resizeable (so far implemented only for sheets, but with a little code could work be added for dialogs)</li>
 </ul>
 </p>
 
 <p>Clicking the "Support" button creates a new email message to designated support
 email address.  The email body contains a long description of the error passed unless
 the error's long description is too long.  In that case, data is written to a text
 file on the Desktop and a modal dialog appears advising the user to review, zip,
 and attach the file.
 
 <p>
 Alerts similar to NSRunXXXAlert and -[NSError presentError:] can be run using one of 
 the "all in one" class methods.&nbsp; For more complicated alerts, use this idiom:
 </p>
 <p>
 <ol>
 <li>Get an alert using +alert.</li>
 <li>Send configuration messages to show the desired title, message, progress
 bar, checkbox, other subviews, buttons, whatever you want.</li>
 <li>To run as a non-modal window, set a clickTarget, clickSelector and optional clickObject.&nbsp;
 Then, send -show.&nbsp; <i>Then</i>, send -display.
 </li>
 <li>To run as modal dialog or modal session, -runModalDialog or -runModalSession.&nbsp;
 (These methods invoke -display for you.)</li>
 <li>If running a modal session, send -modalSessionRunning in your modal session loop.</li>
 <li>To end a modal session without causing alert to go away, -endModalSession.</li>
 <li>To get results from a non-modal window, implement clickSelector in your clickTarget.</li>
 <li>Normally, no memory management is required.  An SSYAlert instance will be
 retained by the class until the -goAway message executes, after any completion handler or didEndSelector has run.</li>
 </ol>
 </p>
 
 <p>
 In addition to invoking -goAway explicitly, several other events cause -goAway to be invoked automatically.
 Note that the first one listed here is the normal, common way for an alert to be dismissed,
 while the last three handle edge cases in which the alert is never displayed to begin with, 
 or is abnormally removed from the screen.
 <ul>
 <li>User clicks one of the buttons along the bottom while property dontGoAwayUponButtonClicked is at its default value of NO (which causes the -goAway message to execute).</li>
 <li>The instance receives a -alertError: message passing a nil error
 <li>The instance receives a -alertError: message passing an error for which [gSSYAlertErrorHideManager shouldHideError:error] returns YES.
 <li>The instance' window is a sheet, and the sheet parent window is closed (programaticallly), or another window becomes key..</li>
 </ul>
 </p>
 
<p>
 UPDATE 2017-04-10  Re-using alerts as described in this section is no longer
 recommended.  One reason is that the flicker referred to does not occur in
 recent updates of macOS.  Another reason is given later.

 By default, SSYAlert closes its window and itself is no longer retained by
 SSYWindowHangout when the user clicks a button.  If you want to present another
 alert immediately after that, you can avoid the flicker of having one window
 disappear and another appear by re-using the same SSYAlert.  The following
 code snipper shows how to do that.
 
 SSYAlert alert = [SSYAlert alert] ;

 // So that we can re-use this alert…
 [alert setDontGoAwayUponButtonClicked:YES] ;
 
 // First use
 [alert setSmallText:firstMessage] ;
 ... other confguration messasges
 [alert display] ;
 [alert runModalDialog] ;
 NSInteger alertReturn = [alert alertReturn] ;
 ... do whatever
 
 // Re-use
 [alert cleanSlate] ;
 [alert setSmallText:firstMessage] ;
 ... other confguration messasges
 [alert display] ;
 [alert runModalDialog] ;
 NSInteger alertReturn = [alert alertReturn] ;
 ... do whatever
 
 // Done.  But with dontGoAwayUponButtonClicked = YES, SSYAlert does not go away
 // automatically.
 [alert goAway] ;
</p>

 
 <p>
 SSYAlert's alertError:XXX methods provide a back door with which display of certain
 errors may be inhibited.  This is useful if you want to use NSError to indicate
 conditions which will cause your app to take some action under certain conditions
 but not have these errors displayed to the user.  Originally, I preferred to do
 this by adding a "hide" key to the error's userInfo dictionary, but this concept
 broke when I tried to hide errors that were passed through AppleScript.  In
 NSAppleScript class documentation > Constants > Error Dictionary Keys, note
 that all you get is the error's code and a few strings.  So now we do it this way
 instead.  If you would like to hide certain errors, instantiate an object which
 implements the SSYAlertErrorHideManager formal protocol, and assign this object
 to the global variable gSSYAlertErrorHideManager.  If you do not assign anything
 to gSSYAlertErrorHideManager, no errors will be hidden.
 </p>
 <p>
 Notes
 </p> 
 <ol>
 <li>
 As of the commit of 2013-09-20, because SSYAlert objects are deallocced
 when their window is closed, the practice of re-using an SSYAlert, which was
 carried since we had the +sharedAlert, is now discouraged and may result in
 Internal Error 624-9218, for example, if you send -alertError: to an SSYAlert
 instance whose window is closed and nil, or Internal Error 624-9229 if you
 send -runModalDialog: to an SSYAlert instance whose window is closed and nil.
 </li>
 <li>
 One time I tried to "nest" modal sessions and got unpredictable behavior and crashes.&nbsp; 
 I'm not if this is legal or makes sense and recommend against it.
 </li>
 <li>Although the clickTarget, clickSelector and clickObject often necessary when
 using the SSYAlert instance as a non-modal window, you can also use them to
 to provide an additional target/action when using it as, for example, a
 document-modal sheet if the document is occupying the modal delegate and 
 didEndSelector to do the generic cleanup.
 </li>
 <li>For safety in projects that have both foreground application and background
 worker target products, its instance method -init checks if NSApp is non-nil
 and also whether or not the process is an LSUIElement.  If either is
 true, -init returns nil and consequently this entire class becomes a no-op.
 Actually, it also deallocs super and there may be some danger in this.
 See notes in the implementation.
 </li>
 
 
 
 </ol>
 */
@interface SSYAlert : NSWindowController <NSWindowDelegate> {
	// Subviews, all created programatically
    NSImageView* icon ;
	NSProgressIndicator* progressBar ;
    NSTextView* titleTextView ;
    NSScrollView* smallTextScrollView ;
    NSTextView* smallTextView ;
	NSButton* helpButton ;
	NSButton* supportButton ;
	SSYWrappingCheckbox* checkbox ;
	NSButton* button1 ;
    NSButton* button2 ;
    NSButton* button3 ;
    NSButton* button4 ;
	NSString* _helpAddress ;
	NSError* errorPresenting ;
	NSImageView* iconInformational ;
    NSImageView* iconWarning ;
	NSImageView* iconCritical ;
	NSButton* buttonPrototype ;
	NSString* wordAlert ;
	NSString* m_whyDisabled ;
	NSInvocation* m_checkboxInvocation ;
	
	BOOL m_isEnabled ;
	BOOL isVisible ;
	NSInteger nDone ;
	NSInteger m_alertReturn ;
	CGFloat m_rightColumnMinimumWidth ;
	CGFloat m_rightColumnMaximumWidth ;
	BOOL allowsShrinking ;
	BOOL m_dontAddOkButton ;
	NSInteger titleMaxChars ;
	NSInteger smallTextMaxChars ;
	id clickTarget ;
	SEL clickSelector ;
	id clickObject ;
	BOOL isDoingModalDialog ;
	NSModalSession modalSession ;
	NSPoint windowTopCenter ;
	BOOL progressBarShouldAnimate ;
	BOOL m_dontGoAwayUponButtonClicked ;
	NSTimeInterval nextProgressUpdate ;
	
	NSMutableArray* otherSubviews ;
}

#pragma mark * Simple Accessors

/*!
 @brief    Provides direct access to the receiver's progress
 bar for special purposes.
 
 @details  See documentation of methods
 -setIndeterminate:, -setMaxValue:, -setDoubleValue: to learn
 why it is better to use those indirect methods instead.
 This getter may be used, carefully, for special purposes.
 */
@property (retain, readonly) NSProgressIndicator* progressBar ;

/*!
 @brief    Provides direct access to the receiver's title text
 view for special purposes.
 
 @details  Normally, use -setTitleText.&nbsp; This getter
 may be used, carefully, for special purposes.
 */
@property (retain, readonly) NSTextView* titleTextView ;

/*!
 @brief    Provides direct access to the receiver's small text
 view for special purposes.
 
 @details  Normally, use -setSmallText.&nbsp; This getter
 may be used, carefully, for special purposes.
 */
@property (retain, readonly) NSTextView* smallTextView ;

/*!
 @brief    Sets whether or not the receiver's default button, button 1,
 nominally the "OK" button, is enabled.&nbsp; If not set, default
 value is YES.&nbsp;  Validation can be performed in other subviews
 and fed back here to en/disable the "OK" button, along with 
 the optional tooltip whyDisabled.
 */
@property (assign) BOOL isEnabled ;

/*!
 @brief    A tooltip shown on the receiver's default button, button 1.
 If set to nil, the tooltip is removed.
 */
@property (copy) NSString* whyDisabled ;

/*!
 @brief    Indicates which button was last clicked
 
 @details  Use this to get the button-clicked result in cases where you
 did not use one of the +runModalDialog... or +alertError... methods.
 Ordinarily, you will not set this property because it will be set
 internally when the user clicks a button.  However, if you are
 dismissing the alert programatically, you may need to set this in order
 to specify which didEndSelector runs.
 @result   Same as Apple's alert returns:
 <ul>
 <li>If button 1 (right) was clicked, NSAlertFirstButtonReturn.</li>
 <li>If button 2 (middle) was clicked, NSAlertSecondButtonReturn.</li>
 <li>If button 3 (left) was clicked, NSAlertThirdButtonReturn.</li>
 </ul>
 */
@property (assign) NSInteger alertReturn ;

/*!
 @brief    Returns YES if the receiver is currently in the midst of
 a modal dialog, otherwise NO.
*/
@property (assign, readonly) BOOL isDoingModalDialog ;

/*!
 @brief    Sets the mininum width of the right column
 of the receiver.
 
 @details  Note that this sets only the minimum.&nbsp; If required
 to accomodate the text on the buttons or checkbox, 
 the right column may be wider than set here.
 
 If left at the default value of 0.0, during layout the SSYAlert will
 try and find the subview in the hierarchy that has the longest
 -string or -stringValue.&nbsp;  I say "try" because I'm not sure it
 will find everything -- it recurses through -subviews and -documentView.
 Anyhow, when it gets the longest string length, it calculates
 rightColumnMinimumWidth from it to give a nice-looking aspect ratio for
 this subview, also subject to a minimum value of 250 points and a
 maximum value of 500 points.
 */
@property (assign) CGFloat rightColumnMinimumWidth ; 

/*!
 @brief    Sets the maximum width of the right column
 of the receiver.
 */
@property (assign) CGFloat rightColumnMaximumWidth ; 

/*!
 @brief    Sets both rightColumnMinimumWidth and 
 rightColumnMinimumWidth to a given value, effectively
 fixing the right column width to that value.
*/
- (void)setRightColumnWidth:(CGFloat)width ;

/*!
 @brief    Sets whether or not the titleTextView, smallTextView, and
 otherSubview heights are allowed to shrink if their content is reduced.
 
 @details  If text is going to be changed repeatedly, it does not look
 good for the window height to change every time, so you send this
 message with NO to keep that from happening.
 
 If you never send this message, the setting remains at its default
 value of YES.
 
 This method does not control whether or not the window as a whole
 shrinks or not.&nbsp; So, if you want the window to remain the same size,
 you must also not add or remove subviews.&nbsp; Reminder: -setTitleText:nil
 and -setSmallText:nil will remove these respective subviews.
 */
@property (assign) BOOL allowsShrinking ;

/*!
 @brief    Sets maximum number of characters, after which the title will be nicely truncated.
 
 @details  Truncation occurs by inserting an ellipsis 2/3 of the way through.&nbsp; If this method is never invoked, defaults to 500.
 */
@property (assign) NSInteger titleMaxChars ;

/*!
 @brief    Sets maximum number of characters, after which the smallText will be nicely truncated.
 
 @details  Truncation occurs by inserting an ellipsis 2/3 of the way through.&nbsp; If this method is never invoked, defaults to 1500.
 */
@property (assign) NSInteger smallTextMaxChars ;

/*!
 @brief    Optional target which will receive the clickSelector message
 when a button is clicked.

 @details  This property is typically used when using the SSYAlert
 instance as a regular non-modal window, but you can also use it
 to provide an additional target/action.
*/
@property (retain) id clickTarget ;

/*!
 @brief    The selector in the clickTarget which will receive a
 message when a button is clicked.
 
 @details  This property is typically used when using the SSYAlert 
 instance as a regular non-modal window, but you can also use it
 to provide an additional target/action.  The selector signature
 must take a single parameter, in which will be passed the
 sending SSYAlert.
*/
@property (assign) SEL clickSelector ;

/*!
 @brief    An optional object which will be retained by the SSYAlert
 instance.

 @details  This is typically used to pass information to the 
 clickTarget.  To recover the clickObject, send -clickObject to
 the SSYAlert instance which is passed via the clickSelector.
*/
@property (retain) id clickObject ;

/*!
 @brief    An optional invocation will be invoked after the alert
 is dismissed if its checkbox is checked.
 
 @details  This is handy if you want to put an SSYAlert into an
 invocation for later display.
 */
@property (retain) NSInvocation* checkboxInvocation ;

/*!
 @brief    Starts and stops animation of the receiver's progress bar.
 
 @details  Use this method instead of sending a message to the 
 progress bar directly.&nbsp; It's a long story.
 */
@property (assign) BOOL progressBarShouldAnimate ;

/*!
 @brief    Provides direct access to the receiver's otherSubviews.
 
 @details  Useful to retrieve values that user has entered into
 controls in otherSubviews.
 */
@property (retain, readonly) NSMutableArray* otherSubviews ;

/*!
 @brief    Whether or not to put CONTROL_VERTICAL_SPACING points of vertical
 space between each otherSubview
 @details  The default value is NO, meaning that space *is* put.  This is only
 for space *between* successive otherSubview subviews.  If the receiver has less
 than two otherSubview subviews, this parameter has no effect.
 */
@property BOOL noSpaceBetweenOtherSubviews ;

/*!
 @brief    If YES, indicates that the receiver should not -goAway
 when a button is clicked

 @details  The default value is NO.
 This property  was added in BookMacster 1.9.3.
*/
@property (assign) BOOL dontGoAwayUponButtonClicked ;

/*!
 @brief    Specfies how to lay out the buttons during -doooLayout
 @details  Default value is SSYAlertButtonLayoutClassic.
 */
@property SSYAlertButtonLayout buttonLayout ;


#pragma mark * Class Methods returning Constants

/*!
 @brief    Returns the font used in the receiver's title text

 @details  May be used to create other subviews with same "look".
*/
+ (NSFont*)titleTextFont ;

/*!
 @brief    Returns the font used in the receiver's small text
 
 @details  May be used to create other subviews with same "look".
 */
+ (NSFont*)smallTextFont ;

/*!
 @brief    Returns the height of the receiver's title text view,
 when it showing a single line of text.
 
 @details  May be used to create other subviews with same "look".
 */
+ (CGFloat)titleTextHeight ;

/*!
 @brief    Returns the height of the receiver's small text view,
 when it showing a single line of text.
 
 @details  May be used to create other subviews with same "look".
 */
+ (CGFloat)smallTextHeight ;

/*!
 @brief    Returns the localized string "Contact Support | Email"
*/
+ (NSString*)contactSupportToolTip ;

#pragma mark * Public Methods Creating and Getting SSYAlert Instances

/*!
 @brief    Designated initializer for the SSYAlert class.

 @result   An initialized instance of SSYAlert.
*/
- (id)init ;

/*!
 @brief    Convenience method for returning an autoreleased SSYAlert, or
 nil for non-GUI apps.
 
 @details  Use this when you want a new SSYAlert instance, such as you
 would to run as a sheet on a document.&nbsp;  But, if [NSApp delegate]
 returns nil, then this method returns nil.&nbsp;  The idea is that you
 can use this in both GUI and non-GUI helper tools.&nbsp;  This assumes
 that a GUI app will have a delegate assigned to its NSApp but a non-GUI
 helper tool will not.&nbsp;
 */
+ (SSYAlert*)alert ;


/*!
 @brief    A utility method which other error-sending mechanisms may
 use to access the support email address used by SSYAlert.
 
 @result   An email address
*/
+ (NSString*)supportEmailString ;
/*!
 @brief    A utility method which other error-sending mechanisms may
 use to send a support email address like SSYAlert does.
*/
+ (void)supportError:(NSError*)error ;

/*!
 @brief    Causes the receiver to display an error.
 
 @details  An improved version of Apple's -presentError: modal dialog.
 Looks nicer than -presentError:, in my opinion.&nbsp; Not all boldface.
 
 If error is nil, or if [gSSYErrorDisplayManager shouldHideError:error]
 returns YES, or if the error's domain is NSCocoaErrorDomain and its code
 is NSUserCancelledError this method simply returns NSAlertErrorReturn and posts an
 SSYAlertDidProcessErrorNotification, unless the error -isOnlyInformational:
 
 If the error returns a -localizedFailureReason, presents that in the smallText 
 following a localized label "Possible reason for Error:".
 
 If the error returns a -localizedRecoverySuggestion, presents that in the small text
 folowing a localized label "Suggestion to Fix this Error:".
 
 If the error returns a -localizedRecoveryOptions, which should be an array of 0-3 strings,
 the string(s) in this array will be the title(s) of the button(s) in the dialog.&nbsp; 
 The first string will be the title of the right-most and default button, the second will
 be the right button, and the third will be the center button.&nbsp; Note that this works
 like SSYAlert and NSAlert, and not like Apple's -presentError methods which can present
 an unlimited number of buttons starting from right to left and moving to the left.
 
 If an email address string has been given in the Info.plist key SSYAlert_SupportEmail, the
 dialog will have a "support" button (as described elsewhere) targetting this email.
 
 After the user clicks the first, second or third button,
 <ul>
 <li>If a non-nil recovery attempter is obtained when sending
 -[NSError openRecoveryAttempterForRecoveryOption:error_p:]
 to the error's -deepestRecoverableError, this recovery attempter will be sent one of
 the two messages in the NSErrorRecoveryAttempting protocol to which it responds.
 Because we feel that it produces a better user experience, the sheet-producing method,
 attemptRecoveryFromError:::::, will be tested first for a response, and the message
 sent if the recovery attempter does respond.  If the recovery attempter does not
 respond, the alert-window-producing method, attemptRecoveryFromError:: will be tested
 for a response, and the message sent if it does respond.  In either case, the recovery
 options will be presented.</li>
 <li>If sending -[NSError openRecoveryAttempterForRecoveryOption:error_p:] to the
 error produces nil, this method will return a value depending on which button was
 clicked, as explained in documentation for the 'alertReturn' property.</li>
 </ul>
 
 This method also posts an SSYAlertDidProcessErrorNotification, unless 
 the error -isOnlyInformational.
  
 @param    error  The error to be presented, or nil.
 @result   If recovery was not attempted, will be NSAlertFirstButtonReturn,
 NSAlertSecondButtonReturn, or NSAlertThirdButtonReturn depending on whether
 user clicked the first, second, or third button from the right.
 If recovery was attempted, result will be SSYAlertRecoverySucceeded,
 SSYAlertRecoveryFailed, or SSYAlertRecoveryAttemptedAsynchronously.
 */
- (SSYAlertRecovery)alertError:(NSError*)error ;

- (void)alertError:(NSError*)error
          onWindow:(NSWindow*)window
 completionHandler:(void(^)(NSModalResponse returnCode))completionHandler ;

/*!
 @brief    Invokes -alertError: on the application's shared alert.
*/ 
+ (SSYAlertRecovery)alertError:(NSError*)error ;

/*!
 @brief    Creates an alert sheet on a given window and displays a given
 error.  Warning, I was going to use this method but did not.  It has
 never been tested.
 
 @details  Most of this method's behavior follows that of +alertError:.
 
 If error is nil, or if [gSSYErrorDisplayManager shouldHideError:error]
 returns YES, or if the error's domain is NSCocoaErrorDomain and its code
 is NSUserCancelledError this method simply posts an
 SSYAlertDidProcessErrorNotification, unless the error -isOnlyInformational:
 
 This method also posts an SSYAlertDidProcessErrorNotification, unless 
 the error -isOnlyInformational.
 
 @param    error  The error to be presented, or nil
 @param    sheetParent  The window upon which to attach the sheet
 @param    modalDelegate  The object which will receive and must respond to
 the didEndSelector, or nil if you want the receiver to handle it.  If the
 receiver handles it, its alertReturn will be set to the NSAlertReturn value
 corresponding to the button clicked by the user.
 @param    didEndSelector  The selector which will be sent to the modal
 delegate if it is not nil.  Must match the signature with signature of
 sheetDidEnd:(NSWindow *)returnCode:(NSInteger)contextInfo:(void*).&nbsp; Also,
 to make the sheet go away, the didEndSelector must send -orderOut: to the
 'sheet' argument it receives.
 @param    contextInfo  Pointer to data which will be returned as the
 third element of the didEndSelector
 */
+ (void)alertError:(NSError*)error
		  onWindow:(NSWindow*)sheetParent
	 modalDelegate:(id)modalDelegate
	didEndSelector:(SEL)didEndSelector
	   contextInfo:(void*)contextInfo ;

/*!
 @brief    Runs a modal dialog with a message and 1-3 buttons

 @details  Blocks the current thread.
 
 You should pass 0-3 button title arguments.
 
 This method also posts an SSYAlertDidProcessErrorNotification, unless 
 the error -isOnlyInformational.
  
 Note: If one had a need, one could add a `resizeable` parameter to this method
 and it should work, since -doooLayout now supports resizeability.

 @param    title  The window title or nil.&nbsp; If nil, title will
 be set to localized "Alert".
 @result   Indicates button clicked by user: NSAlertFirstButtonReturn,
 NSAlertSecondButtonReturn or NSAlertThirdButtonReturn
 */
+ (NSInteger)runModalDialogTitle:(NSString*)title
                         message:(NSString*)msg
                         buttons:(NSString*)button1Title, ... ;

/*!
 @brief    Runs a modal dialog with a message and 1-3 buttons
 
 @details  Blocks the current thread.
 Note: If one had a need, one could add a `resizeable` parameter to this method
 and it should work, since -doooLayout now supports resizeability.
 @param    title  The window title or nil.&nbsp; If nil, title will
 be set to localized "Alert".
 @param    buttonsArray  An array of 0-3 strings which will become
 the titles of buttons 1-3.  If this parameter is nil or an
 empty array, dialog will have 1 button titled as localized "OK".
 @result   Indicates button clicked by user: NSAlertFirstButtonReturn,
 NSAlertSecondButtonReturn or NSAlertThirdButtonReturn
 */
+ (NSInteger)runModalDialogTitle:(NSString*)title
                         message:(NSString*)msg
                    buttonsArray:(NSArray*)buttonsArray ;


#pragma mark * Public Methods For Setting Views

/*!
 @brief    Removes all subviews in the receiver and sets settings to default values::
 <ul>
 <li>allowsShrinking = YES</li>
 <li>isEnabled = YES</li>
 <li>self.isVisible = YES</li>
 <li>self.progressBarShouldAnimate</li>
 </ul> 
*/
- (void)cleanSlate ;

/*!
 @brief    Sets whether or not the receiver observes for a window other than
 its own to become key, and when so sends itself a -goAway message
 
 @details  Provides a loosely-coupled self-cleanup mechanism so that the
 receiver's window does not annoy the user.  Value is NO by default.
 */
- (void)setGoAwayWhenAnotherWindowBecomesKey:(BOOL)yn ;

/*!
 @brief    Sets the title of the receiver's window

 @details  If not set, or set to nil, window title defaults to mainBundle's
 CFBundleName (which should be the localized name of the app)
*/
- (void)setWindowTitle:(NSString*)title ;

/*!
 @brief    Sets whether or not the receiver shows a progress bar
*/
- (void)setShowsProgressBar:(BOOL)showsProgressBar ;

/*!
 @brief    The text that appears in boldface near the top of the receiver
 window's content view.  It is not the window title.
*/
@property (copy) NSString* titleText;


/*!
 @brief    Sets the receiver's Title Text to the localized word "Alert", stolen from NSGetAlertPanel

 @details  Title Text appears in boldface near the top of the receiver
 window's content view.&nbsp; It is not the window title.
*/
- (void)setTitleToDefaultAlert ; 

/*!
 @brief    The the text that appears in the window under the Title Text.
*/
@property (copy) NSString* smallText;

/*!
 @brief    Sets the icon which will appear in the receiver
 @param    iconStyle  Pass one of the constants SSYAlertIconNoIcon,
 SSYAlertIconInformational, SSYAlertIconWarning or SSYAlertIconCritical
*/
- (void)setIconStyle:(NSInteger)iconStyle ;

/*!
 @brief    Turns off the default behavior of the receiver to add an
 "OK" button if no button titles have been set before running as a
 modal sheet or modal dialog.
 
 @details  Use this if you want the receiver to have no buttons.
*/
- (void)setDontAddOkButton ;

/*!
 @brief    Sets the title of the (rightmost) "default" button, the
 one whose key equivalent is \\r.
 @param    title  The desired button title, or nil.
*/
- (void)setButton1Title:(NSString*)title ;

/*!
 @brief    Sets the title of button 2
 
 @details  Passing title as nil will remove the button.
 @param    title  The desired button title, or nil.
 */
- (void)setButton2Title:(NSString*)title ;  // key equivalent is escape

/*!
 @brief    Sets the title of button 3
 
 @details  Passing title as nil will remove the button.
 @param    title  The desired button title, or nil.
 */
- (void)setButton3Title:(NSString*)title ;

/*!
 @brief    Sets the title of button 4
 
 @details  Passing title as nil will remove the button.
 @param    title  The desired button title, or nil.
 */
- (void)setButton4Title:(NSString*)title ;

/*!
 @brief    En/Disables Button 1, if it exists

 @details  This method does not create the button.
 During configuration, therefore, you must setButton1Title:
 and then -display the receiver before sending this
 message, or it will have no effect.
*/
- (void)setButton1Enabled:(BOOL)enabled ;

/*!
 @brief    En/Disables Button 2, if it exists
 
 @details  This method does not create the button.
 During configuration, therefore, you must setButton2Title:
 and then -display the receiver before sending this
 message, or it will have no effect.
 */
- (void)setButton2Enabled:(BOOL)enabled ;

/*!
 @brief    En/Disables Button 3, if it exists
 
 @details  This method does not create the button.
 During configuration, therefore, you must setButton3Title:
 and then -display the receiver before sending this
 message, or it will have no effect.
 */
- (void)setButton3Enabled:(BOOL)enabled ;

/*!
 @brief    En/Disables Button 4, if it exists
 
 @details  This method does not create the button.
 During configuration, therefore, you must setButton4Title:
 and then -display the receiver before sending this
 message, or it will have no effect.
 */
- (void)setButton4Enabled:(BOOL)enabled ;

/*!
 @brief    Adds or removes a round question mark help button from the
 receiver's window, and sets the location of a resource which will be
 displayed when the user clicks that button.  Sets the anchor in the application's Help Book which will
 be displayed in Help Viewer when the user clicks the question-mark
 "Help" button in the receiver's window.

 @param    helpAddress  The desired Help location, or nil to remove the Help
 button.  When the user clicks the receiver's Help button, if this value
 begins with "http" and can be parsed to a URL, the resource it locates will
 be displayed in the default web browser.  Otherwise, the value will be
 considered to be an anchor in the application's Help Book, and the resource
 at that anchor will be dislayed in Apple Help Viewer.
*/
- (void)setHelpAddress:(NSString*)helpAddress ;

- (NSString*)helpAddress ;

/*!
 @brief    Sets the title of the checkbox which will appear above the row of
 buttons at the bottom, in the right column of the receiver.

 @details  Passing title as nil will remove the checkbox.
*/
- (void)setCheckboxTitle:(NSString*)title ;

/*!
 @brief    Adds an "other subview" to the receiver.

 @details  An "other subview" is placed near the middle
 of the receiver's right column.
 @param    index  You may pass NSNotFound to add it as the next item after the
 last one.
*/
- (void)addOtherSubview:(NSView*)subview
				atIndex:(NSInteger)index ;


/*!
 @brief    Returns a text view which looks like the receiver's 
 smallTextView

 @details  Use this method to get a (additional) smallTextView(s)
 which look like the receiver's built-in smallTextView.&nbsp;  You
 may add this view in the desired position using
 -addOtherSubview:atIndex:.
*/
- (NSTextView*)smallTextViewPrototype ;
/*!
 @brief    Sets the receiver's progress bar animation to be
 indeterminate or not.

 @details  This also sets the progress bar to use threaded animation.
 @param    indeterminate  YES to make the animation indeterminate.
*/
- (void)setIndeterminate:(BOOL)indeterminate ;

/*!
 @brief    Sets the maximum value of the receiver's progress bar

 @param    maxValue  The maximum value to be set  
*/
- (void)setMaxValue:(double)maxValue ;

/*!
 @brief    Sets the double value of the receiver's progress bar

 @details  Will also display new value, if the previous display triggered
 by invoking this method was more than .05 seconds ago.

 @param    newValue  The new double value to be set
*/
- (void)setDoubleValue:(double)newValue ;


/*!
 @brief    Invokes -setDoubleValue: with an value argument
 equal to the current value plus an increment.
 
 @details  The increment may be negative.
 @param    increment  The increment to be added
*/
- (void)incrementDoubleValueBy:(double)increment ;

/*!
 @brief    Invokes -setDoubleValue: with an object argument
 equal to the current value plus an increment.
 
 @details  The increment may be negative.
 @param    increment  An NSNumber of a double whose value
 is the increment to be added
 */
- (void)incrementDoubleValueByObject:(NSNumber*)increment ;

/*!
 @brief    Sets the text alignment of the receiver's small
 text field

 @param    alignment  The alignment to be set
*/
- (void)setSmallTextAlignment:(NSTextAlignment)alignment ;
	
/*!
 @brief    Sets the state of the receiver's checkbox.

 @param    state  The state to be set.
 */
- (void)setCheckboxState:(NSControlStateValue)state ;
	
	
# pragma mark * Layout

/*!
 @brief    Lays out all of the subviews.
 
 @details  This method must be invoked after adding, removing, or
 changing size of any subview.

 Name of this method has been designed to avoid confusion and/or
 conflict with Cocoa's -doLayout method.
 */
- (void)doooLayout ;

- (void)doLayoutError:(NSError*)error ;

/*!
 @brief    If the receiver's window is visible, lays out all of the
 subviews, makes it the key window and orders it to the front.&nbsp; 
 Otherwise, orders the window out.

 @details  This method, or -doooLayout, must be invoked after adding,
 removing, or changing size of any subview.
*/
- (void)display ;

/*!
 @brief    Returns whether or not the receiver's window is visible.
*/
- (BOOL)isVisible ;

#pragma mark Modal Dialog and Modal Session Control

/*!
 @brief    Runs the receiver on a sheet as a modal session and returns
 immediately, running an optional invocation (target+selector+contextInfo)
 later if you send -[NSWindow endSheet:] or -[NSWindow endSheet:modalResponse:]
 to the host window

 @details  Although this method cleverly wraps Apple's new block-based method 
 with an invocation to maintain backward compatibility, and should thus continue
 to work until Apple gets tired of blocks and moves on to some other new fad,
 we recommend using the new direct method
 -runModalSheetOnWindow:resizeable:completionHandler: instead of this old one.
 
 If the receiver has not had any button titles yet, and if the receiver has not
 had dontAddOkButton set, this method adds a default "OK" button before
 displaying the sheet.
 
 @param    docWindow  The document window to which to attach the sheet.
 @param    resizeable  Pass YES to make the sheet resizeable larger by the
 user.  Resizing smaller is is always disabled because SSYAlert is laid out
 by -doooLayout to the minimum workable size.
 @param    modalDelegate  The object which will receive and must respond to
 the didEndSelector, or nil if you want the receiver to handle it.  If the
 receiver handles it, its alertReturn will be set to the NSAlertReturn value
 corresponding to the button clicked by the user.
 @param    didEndSelector  The selector which will be sent to the modal
 delegate if it is not nil.  Must match the signature with signature of
 didEndSheet:(NSWindow *)returnCode:(NSInteger)contextInfo:(void*).
 @param    contextInfo  Pointer to data which will be returned as the
 third element of the didEndSelector.
*/
- (void)runModalSheetOnWindow:(NSWindow*)docWindow
                   resizeable:(BOOL)resizeable
				modalDelegate:(id)modalDelegate
			   didEndSelector:(SEL)didEndSelector
				  contextInfo:(void*)contextInfo ;

/*!
 @brief    Runs the receiver on a sheet as a modal session and returns
 immediately
 
 @details  If the receiver has not had any button titles yet, and if the
 receiver has not had dontAddOkButton set, this method adds a default "OK"
 button before displaying the sheet.
 
 @param    docWindow  The document window to which to attach the sheet.
 @param    resizeable  Pass YES to make the sheet resizeable larger by the
 user.  Resizing smaller is is always disabled because SSYAlert is laid out
 by -doooLayout to the minimum workable size.
 @param    handler  Block which will run when the sheet ends
 */
- (void)runModalSheetOnWindow:(NSWindow*)docWindow
                   resizeable:(BOOL)resizeable
            completionHandler:(void (^)(NSModalResponse returnCode))handler ;

/*!
 @brief    Runs the receiver as a modal dialog.

 @details  The only way to end a modal dialog is for the user
 to click a button.&nbsp; If the alert does not currently have a button 1,
 this method will add a button 1 before displaying.&nbsp; The title
 of the added button will be [NSString localize:@"OK"].
 
 In most cases, you should configure subviews as desired and then
 invoke -display before invoking this method.
 
 This method blocks until the user clicks a button.&nbsp;  You may then
 retrieve the return value by reading the property 'alertReturn'.
 */
- (void)runModalDialog ;

/*!
 @brief    Runs the receiver as a modal session.

 @details  If a modal session is already running, this does nothing.
 
 In most cases, you should configure subviews as desired and then
 invoke -display before invoking this method.
 */
- (void)runModalSession ;

/*!
 @brief    Ends a modal session.

 @details  If a modal session is not running, this method does nothing.

 Note that a <i>modal session</i> is similar to but not the same
 as a modal dialog.
*/
- (void)endModalSession ;


/*!
 @brief    Ends any modal session that might be running and closes it.
*/
- (void)goAway ;


#pragma mark * Obtaining Output

/*!
 @brief    Invokes -runModalSession on the modal session, if any, and
 returns whether or not the receiver is running a modal session.
*/
- (BOOL)modalSessionRunning ;  


/*!
 @brief    Returns the state of the receiver's checkbox

 @details  Message is forwarded directly to the checkbox.
 @result   NSControlStateValueOn, NSControlStateValueOff or NSControlStateValueMixed
*/
- (NSControlStateValue)checkboxState ;

@end


/*
 Test code for the new scrollable Small Text:
 
 NSMutableString* junk = [NSMutableString new] ;
 for (NSInteger i=0; i<20; i++) {
 [junk appendFormat:@"%zd. Just a few lines here!\n", i] ;
 }
 
 SSYAlert* alert ;
 
 alert = [SSYAlert new] ;
 [alert setTitleText:NSLocalizedString(@"Import Results", nil)] ;
 [alert setRightColumnMinimumWidth:620] ;
 [alert setIconStyle:SSYAlertIconInformational] ;
 [alert setSmallText:junk] ;
 [alert doooLayout] ;
 [alert runModalDialog] ;
 #if !__has_feature(objc_arc)
 [alert release] ;
 #endif
 
 [junk deleteCharactersInRange:NSMakeRange(0, junk.length)] ;
 for (NSInteger i=0; i<200; i++) {
 [junk appendFormat:@"%zd. A lot of lines now!\n", i] ;
 }
 
 alert = [SSYAlert new] ;
 [alert setTitleText:NSLocalizedString(@"Import Results", nil)] ;
 [alert setRightColumnMinimumWidth:620] ;
 [alert setIconStyle:SSYAlertIconInformational] ;
 [alert setSmallText:junk] ;
 [alert doooLayout] ;
 [alert runModalDialog] ;
 #if !__has_feature(objc_arc)
 [alert release] ;
 #endif
 
 Test code for doDamageControl
 
 SSYAlert* alert ;
 
 alert = [SSYAlert new] ;
 [alert setTitleText:NSLocalizedString(@"Do the buttons fall off the screen?", nil)] ;
 [alert setHelpAddress:@"fooHelp"] ;
 [alert setButton1Title:@"Button 1"] ;
 [alert setButton2Title:@"Button 2"] ;
 [alert setButton3Title:@"Button 3"] ;
 [alert setButton4Title:@"Button 4"] ;
 [alert setCheckboxTitle:@"Check me?"] ;
 // 100 buttons should be enough to overfill any display height.
 for (NSInteger i=0; i<33; i++) {
 NSTextField* textField = [[NSTextField alloc] initWithFrame:NSMakeRect(0,0,25,100)] ;
 textField.stringValue = [NSString stringWithFormat:@"Text Field %ld", (long)i] ;
 [alert addOtherSubview:textField
 atIndex:NSNotFound] ;
 }
 [alert doooLayout] ;
 [alert runModalDialog] ;
 #if !__has_feature(objc_arc)
 [alert release] ;
 #endif
 
*/
