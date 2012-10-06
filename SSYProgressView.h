@class SSYRolloverButton ;

extern NSString* const constKeyStaticConfigInfo ;
extern NSString* const constKeyPlainText ;
extern NSString* const constKeyHyperText ;
extern NSString* const constKeyTarget ;
extern NSString* const constKeyActionValue ;


/*!
 @brief    A control showing a text field, optional progress bar and
 optional cancel button, all lined up horizontally.

 @details
 
 TERMINOLOGY
 
 When the progress bar is present, the string in the text
 field is referred to as the 'verb', since generally it tells the user
 what is being done.&nbsp; For example, the verb may be set to
 @"Processing" or @"Downloading". 
 
 The cancel button appears as a small red octagon "stop sign".
 
 RESIZING BEHAVIOR
 
 SSYProgressView maintains a constant overall width unless you
 change its frame.  You control whether or not the split between the
 text and progress bar changes to accomodate changes in text.
 See -setVerb:resize: and -setProgressBarWidth:
 
 THREAD SAFETY
 
 This class is thread-safe in the sense that you can invoke its
 exposed methods from any thread.  Of course, if you, for
 example, increment progress from two different tasks, the progress
 on your progress bar will be jumping between the two, etc.  
 If such behavior is possible in your application,
 you should implement some kind of arbitration controller and
 interpose it as a front-end to this class.
 
 BINDINGS SUPPORT
 
 Some bindings support is provided.  See methods
 -setStaticConfigInfo: and 
 
 PREVENTS EXCESSIVE PROGRESS BAR DRAWING
 
 Another feature is that the -incrementDoubleValueByObject:, 
 -incrementDoubleValueBy:, and -setDoubleValue: methods are
 throttled so that they will not redraw unless more than
 PROGRESS_UPDATE_PERIOD = 0.1 sec has elapsed since the 
 previous drawing.  So, even if your loop iteration time is
 very small, you can invoke these methods every time and not
 worry about slowing your process down due to too much drawing.
 (Run such a loop, then redefine PROGRESS_UPDATE_PERIOD to a
 few microseconds, retest and you'll see what I mean.)
 Why doesn't Apple build such a throttle into
 NSProgressIndicator?
*/
@interface SSYProgressView : NSControl {
	NSProgressIndicator* _progBar ;
	NSProgressIndicator* m_spinner ;
	NSTextField* _textField ;
	SSYRolloverButton* _hyperButton ;
	SSYRolloverButton* _cancelButton ;
	NSInteger progBarLimit ;
	NSTimeInterval nextProgressUpdate ;
	NSMutableArray* completions ;
	NSDate* completionsLastStartedShowing ;
	
	// When we get a message to setDoubleValue:, incrementDoubleValueBy:,
	// or incrementDoubleValueByObject:, we only actually set the progress
	// bar if enough time has elapsed since the last setting.&nbsp; So,
	// for incrementing, we keep track of it in this instance variable
	// which is always incremented when we get one of these messages.
	double progressValue ;
}

/*!
 @brief    Sets the verb and optionally resizes its text field

 @details  If newVerb takes more horizontal space to draw than the
 current verb and resize is NO, the text will be truncated at the
 head and an ellipsis inserted per NSLineBreakByTruncatingHead.
 
 @param    newVerb  The new verb
 @param    resize  YES to allow the verb's text field's width to
 increase or decrease to fit the new verb
*/
- (void)setVerb:(NSString*)newVerb
		 resize:(BOOL)resize ;

/*!
 @brief    Override of base class method which sets the string
 in the text field and clearing all other subviews.
*/
- (void)setStringValue:(NSString*)string ;

/*!
 @brief    Sets the width of the progress bar.

 @details  This is typically used when setVerb:resize:NO will
 subsequently be invoked, to keep a fixed progress bar size
 while different text is shown.
 @param    width  The desired width in points.
*/
- (void)setProgressBarWidth:(CGFloat)width ;

/*!
 @brief    Sets whether or not the receiver has a 'cancel' button,
 and its target and action.

 @details  If target and action are nil and NULL, the button will be
 hidden and covered by other subviews.
 @param    target  The target which will receive a message when
 the user clicks the 'cancel' button.
 @param    action  The message that will be sent when
 the user clicks the 'cancel' button.
*/
- (void)setHasCancelButtonWithTarget:(id)target
							  action:(SEL)action ;

/*!
 @brief    Returns the -maxValue of the receiver's progress bar, or
 0.0 if the receiver does not have a progress bar
*/
- (double)maxValue ;

/*!
 @brief    Sets the receiver to show a determinate progress bar,
 or making the existing progress bar determinate,  and sets its
 maximum value.

 @details  This message is ordinarily sent at before beginning
 a task.&nbsp;  It also resets the internal record of the last time the
 progress bar was updated in the user interface, so that the next
 time its value is changed, it will be immediately redrawn.
 */
- (void)setMaxValue:(double)value ;

/*!
 @brief    Sets the receiver to show a progress bar, and sets
 it to be determinate or indeterminate.
*/
- (void)setIndeterminate:(BOOL)yn ;

/*!
 @brief    Sets the receiver to show a progress bar, and sets
 its doubleValue (the progress value).
*/
- (void)setDoubleValue:(double)value ;

/*!
 @brief    Sets the receiver to show a progress bar, and increments
 its doubleValue (the progress value) by a given value.
*/
- (void)incrementDoubleValueBy:(double)value ;

/*!
 @brief    Sets the receiver to show a progress bar, and increments
 its doubleValue (the progress value) by a given value wrapped in
 an NSNumber.
 */
- (void)incrementDoubleValueByObject:(NSNumber*)value ;

/*!
 @brief    Moves the text rightward enough to insert a spinning
 progress indicator and starts it spinning.

 @details  No-op if the receiver already has started spinning.
*/
- (void)startSpinning ;

/*!
 @brief    Undoes the action of -startSpinning.
 
 @details  No-op if the receiver is not currently spinning.
 */
- (void)stopSpinning ;

/*!
 @brief    Removes or hides all three subviews
*/
- (void)clearAll ;

/*!
 @brief    Sets the receiver to have a progress bar, specified as
 determinate or indeterminate, localizes a given verb, appends
 an ellipsis and sets the result as the receiver's verb.
 
 @details  Also resets the internal record of the last time the
 progress bar was updated in the user interface, so that the next
 time its value is changed, it will be immediately redrawn.
*/
- (void)setIndeterminate:(BOOL)indeterminate
	 withLocalizableVerb:(NSString*)localizableVerb ; 

/*!
 @brief    Sets the receiver to have a progress bar, specified as
 determinate or indeterminate, with a given verb, appends
 an ellipsis and sets the result as the receiver's verb.
 */
- (void)setIndeterminate:(BOOL)indeterminate
	   withLocalizedVerb:(NSString*)localizableVerb ; 

/*!
 @brief    Sets the receiver to display only text, followed on the
 right by an optional blue hyperText button

 @details  The progress bar and cancel button are not shown after
 this message executes.
 
 @param    text  The string to be displayed at the left of the
 text field, or nil if no such text is desired.
 @param    hyperText  The blue hypertext to be displayed on the
 right, or nil if no such hypertext is desired.
 @param    target  The object which will receive a message when the
 user clicks the hypertext.
 @param    action  The message which will be sent when the
 user clicks the hypertext.  
*/
- (void)setText:(NSString*)text
	  hyperText:(NSString*)hyperText
		 target:(id)target
		 action:(SEL)action ;

/*!
 @brief    Returns the text currently being displayed by the
 receiver's text field.
*/
- (NSString*)text ;

/*!
 @brief    Commands the receiver to display a localized message
 of the form "Completed <task>".

 @details  If this message is received again, completed tasks
 will be shown as:
    "Completed <verb1> (<result1>), <verb2> (<result2>)", etc.,
 including any prior task which has not yet been displayed for a
 total of COMPLETION_SHOW_TIME.
 
 You may interrupt the showing of completions sending a different
 configuration message to SSYProgressView.  For example, to
 temporarily show a progress bar, you may send
 -sendIndeterminate:withLocalizedVerb:.  After the progress bar
 is no longer needed, you may restore the previously-showing
 completion, without adding any new completion, by sending this
 message with both arguments nil.
 
 @param    verb  A localized verb, the task that was completed,
 or nil (see Details).
 @param    result  Additional description of what was done,
 often a number.  May be nil if a result is not desired or 
 not applicable to this particular verb.
*/
- (void)showCompletionVerb:(NSString*)verb
					result:(NSString*)result ;

/*!
 @brief    A Cocoa-bindable wrapper for setText:hyperText:target:action.

 @param    info  A dictionary containing the parameters to
 be passed in to setText:hyperText:target:action.&nbsp; Values for the
 following keys will be used:
 *  constKeyPlainText     for setText:
 *  constKeyHyperText     for hyperText:
 *  constKeyTarget        for target:
 *  constKeyActionValue   for action:
 Keys should be omitted for values which are nil or NULL.
 The value for constKeyActionValue should be wrapped using
 -[NSValue valueWithPointer:].
 */
- (void)setStaticConfigInfo:(NSDictionary*)info ;

@end


/* Here is how to make a "Show Inspector"/"Hide Inspector" hyperlink:
 [inspectorStatus bind:constKeyStaticConfigInfo
 toObject:[NSApp delegate]
 withKeyPath:@"inspectorStatus"
 options:nil] ;
 
 // Above, object:nil because there are many tables in the Dupes Viewe that we need
 // to monitor, as well as Content's Outline View.

 // Key to which the "Show/Hide Inspector" SSYProgressField is bound
 - (NSDictionary*)inspectorStatus {
 NSString* hyperText = nil ;
 id target = nil ;
 NSValue* actionValue = nil ;
 
 if ([self inspectorShowing]) {
 hyperText = [NSString localizeFormat:@"hideApp%@",
 [NSString localize:@"inspector"]] ;
 target = self ;
 actionValue = [NSValue valueWithPointer:@selector(inspectorClose:)] ;
 }
 else {
 hyperText = [NSString localizeFormat:@"showX",
 [NSString localize:@"inspector"]] ;
 target = self ;
 actionValue = [NSValue valueWithPointer:@selector(inspector:)] ;
 }
 
 NSMutableDictionary* dic = [[NSMutableDictionary alloc] init] ;
 [dic setObject:hyperText forKey:constKeyHyperText] ;
 [dic setObject:target forKey:constKeyTarget] ;
 [dic setObject:actionValue forKey:constKeyActionValue] ;
 
 NSDictionary* answer = [dic copy] ;
 [dic release] ;
 
 return [answer autorelease] ;
 }
 
 + (NSSet *)keyPathsForValuesAffectingInspectorStatus {
 return [NSSet setWithObjects:
 @"inspectorShowing",
 nil] ;	
 }
*/