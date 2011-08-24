#import <Cocoa/Cocoa.h>


extern NSString* const constKeySSYOperationQueueDoneTarget ;
extern NSString* const constKeySSYOperationQueueError ;
extern NSString* const constKeySSYOperationGroup ;

@class SSYOperation ;

/*!
 @brief    Name of a notification, enqueued on the main thread, when the
 number of tasks in the receiver's queue increases from 0.

 @details  The notification object is the -owner of the first
 operation in the queue, which may be nil if it was
 so set, or if this operation does not respond to selector
 -owner (as could happen if superclass methods were used to
 add the operation), then the notification object is the
 receiver.
 
 There is no userInfo dictionary.
 
 This notification is posted with style NSPostNow.
 (Neither NSPostASAP nor NSPostWhenIdle were not fast enough,
 for example, in BookMacster, because during a Save
 operation, for example, the run loop does not enter into
 the required wait state to post the notification until the
 Save is already complete to the hard disk.  If an Agent
 had a From Cloud trigger, this would fire its kqueue and the
 Worker would find the Agent to be uninhibited, and do its
 work, which is undesired.  At first, testing of NSPostASAP
 seemed like it was working but then we found that if the
 Save was preceded by an Import 30 seconds earlier, it was
 too late like NSPostWhenIdle.) 
*/
extern NSString* const SSYOperationQueueDidBeginWorkNotification ;

/*!
 @brief    Name of a notification, enqueued on the main thread, when the
 number of tasks in the receiver's queue decreases to 0.
 
 @details  The notification object is the -owner of the last
 operation which was in the queue, which may be nil if it was
 so set, or if this operation does not respond to selector
 -owner (as could happen if superclass methods were used to
 add the operation), then the notification object is the
 receiver.
 
 There is no userInfo dictionary.

 This notification is posted with style NSPostWhenIdle.
 */
extern NSString* const SSYOperationQueueDidEndWorkNotification ;

@interface SSYOperationQueue : NSOperationQueue {
	// Note that we do not enter the doneTarget, doneSelector and
	// doneThread as instance variables, because they may be different
	// for each group of operations entered with queueGroup:::::::::.
	// But the following instance variables are common to all groups...
	NSError* m_error ;	
	NSScriptCommand* m_scriptCommand ;
	id m_scriptResult ;
	NSMutableDictionary* m_errorRetryDic ;
	NSMutableArray* m_errorRetryKeys ;
	NSString* m_skipOperationsExceptGroup ;
}

/*!
 @brief    Compares the values, if any, for the keys constKeySSYOperationGroup
 between two given dictionaries and returns YES if they both have these keys
 and the keys are unequal (-isEqual:); otherwise returns NO.
 */
+ (BOOL)operationGroupsDifferInfo:(NSDictionary*)info
						otherInfo:(NSDictionary*)otherInfo ;

/*!
 @brief    Compares the values, if any, for the keys constKeySSYOperationGroup
 between two given dictionaries and returns YES if they both have these keys
 and the keys are equal (-isEqual:); otherwise returns NO.
 */
+ (BOOL)operationGroupsSameInfo:(NSDictionary*)info
					  otherInfo:(NSDictionary*)otherInfo ;

/*!
 @brief    My version of the +mainQueue which is only available in
 Mac OS 10.6 or later.  This works in Mac OS 10.5.

 @details  Could probably call this +mainQueue, but at one point
 I was worried about conflicting with Apple's +mainQueue at some
 future date when this is compiled with the 10.6 SDK.
*/
+ (SSYOperationQueue*)maenQueue ;

/*!
 @brief    Any error encountered during linked operations.
 
 @details  Sending this message with a non-nil argument will cause subsequent
 operations, except the doneTarget/doneSelector, to be skipped, and all
 operations after that to be cancelled, until the receiver's queue is
 emptied.  When the queue is emptied, this property is set to nil. 

 An augmented replica error will be available to the doneTarget/doneSelector as
 the value for info dictionary key constKeySSYOperationQueueError.  The
 augmentation is that the error's userInfo dictionary will include a value
 for the key constKeySSYOperationGroup copied from the operation passed to
 setError:.  You can use this key to avoid displaying the same error
 in the doneTarget/doneSelector of subsequent operation groups.

 Before the resumeExecutionWithResult: message is sent to the receiver's
 scriptError, if any, the scriptError's scriptErrorNumber and scriptErrorString
 will be set to, respectively, this error's code and its localizedDescription.
 */
- (NSError*)error ;

- (void)setError:(NSError*)error
  operationGroup:(NSString*)operationGroup ;

- (void)setError:(NSError*)error
	   operation:(SSYOperation*)operation ;
	
/*!
 @brief    A script command which, if set, will be sent a 
 -resumeExecutionWithResult: message after sending the final doneSelector
 to the doneTarget, if any, but only if the receiver's queue is
 empty; i.e. only if there are no more groups in the queue.
 
 @details  This instance variable is designed for "one shot" operation;
 after sending -resumeExecutionWithResult: to its scriptCommand,
 the receiver sets its scriptCommand to nil.
*/
@property (retain) NSScriptCommand* scriptCommand ;

/*!
 @brief    A result object which will be sent to the receiver's script
 command, if any, as the parameter of the resumeExecutionWithResult:
 message.
 */
@property (retain) id scriptResult ;


/*!
 @brief    The only group in the queue whose operations will not be
 skipped.

 @details  If, during the course of operations, you encounter an error
 which requires that the current group be completed but other groups
 be skipped, instead of setting an error, set this parameter to the
 current group.  This will cause other groups to be skipped.
 
 This parameter is automatically reset to nil when the receiver's 
 queue is emptied, so that in the future, no groups will be skipped.
*/
@property (copy) NSString* skipOperationsExceptGroup ;


/*!
 @brief    Message which should be sent in the -main function of 
 SSYOperation to enforce the operation of skipOperationsExceptGroup.

 @result   NO if the receiver's skipOperationsExceptGroup is not
 nil and is equal to the given group, or if the given group is nil.
 YES otherwise.
*/
- (BOOL)shouldSkipOperationsInGroup:(NSString*)group ;

/*!
 @brief    Executes a group of method selectors as operations in
 the queue of the receiver and adds the current invocation of this
 method to the receiver's errorRetryInvocation.

 @details  Each method selector will be manufactured into an
 SSYOperation.&nbsp; The recommended idiom is to write a category 
 of SSYOperation (which is itself a subclass of NSOperation), and
 implement the method selectors you need performed in that category.&nbsp; 
 The methods in the category must take no arguments and return void;
 data is passed in the SSYOperation's 'info' dictionary.

 The first selector/operation manufactured is made dependent on any
 pre-existing operations in the queue, so that none of them will start
 until all pre-existing operations have been finished.&nbsp; Because they
 are SSYOperations, subsequent operations will be no-op if any
 previous operation sets an error.&nbsp; However, the last operation,
 specified by the doneTarget and doneSelector, will execute even if there
 is an error.
 
 Typically, the doneThread, doneTarget and doneSelector arguments are
 used to return final results, and return and/or the error object.&nbsp; 
 Typically, the doneThread is the main thread.
 
 When adding the invocation to the errorRetryInvocations, a
 (mutable) *copy* of the parameter 'info' is used, so that changes to the
 given 'info' dictionary in the process of execution will not affect
 subsequent re-invocations.
 
 @param    group  An arbitrary name you provide for this new group.  If
 nil, [[NSDate date] description] will be generated and used.  Typically,
 a recognizable name is useful for debugging.  If you're not creative,
 consider using NSStringFromSelector(_cmd).  If the addon parameter is NO,
 and if the name given or generated or generated is not unique, a suffix
 of -<decimal number> will be added to make it so.
 The group (name) will be set into the receiver's info dictionary,
 so you should recover it from there if there is any possibility that
 the receiver needed to uniquify it with such a suffix.
 @param    addon  If YES, the given group (name) will not be checked
 for uniqueness.  Pass YES if you wish to add on more operations to
 an existing group which was created by a prior invocation of this method.
 @param    selectorNames  An array of the names of the method selectors
 to be executed, in the order in which they are to be executed.
 You must implement corresponding methods with each of these names
 in a category (class extension) of SSYOperation.
 @param    info  A mutable dictionary which the method selectors may access
 to get arguments and return values.  If an error occurs during execution of
 any of your method selectors, the error registered by your method selector
 will be returned as the value of the key constKeyLinkedOperationError in 
 this dictionary.
 @param    block  YES if you would like this method to block until all
 operations have been completed.  NO if you would like it to return
 immediately, after queueing the operations.&nbsp; This method simply sends 
 -waitUntilAllOperationsAreFinished to your <i>queue</i>.  Again, if you
 pass NO, remember to retain the arguments <i>queue</i> and <i>info</i>.
 @param    owner  An object which will be passed as the 'owner' to each of
 the SSYOperations which are manufactured by the receiver during execution
 of this method.  See -[SSYOperation initWithInfo:selector:owner:operationQueue:].
 @param    doneThread  The thread in which a message will be sent after
 the last operation in selectorNames is completed.  If doneThread is nil,
 the default thread assumed will be the currentThread (the thread on which
 performSelectorNames:::::::: is sent).&nbsp;  You may want to pass
 [NSThread mainThread].
 @param    doneTarget  The target object to which a message will be sent
 after the last operation in selectorNames is completed.  If doneTarget
 is nil, no such message will be sent.
 @param    doneSelector  The selector to which a message will be sent
 after the last operation in selectorNames is completed, even if there
 has been an error.  The doneSelector should take one parameter, to which
 will be passed the receiver's 'info'.  If doneSelector is nil, no such
 message will be sent.
 @param    holdForMore  This is very difficult to explain.  One of these
 days I should figure it out.
 */
- (void)queueGroup:(NSString*)group
			 addon:(BOOL)addon
	 selectorNames:(NSArray*)selectorNames
			  info:(NSMutableDictionary*)info
			 block:(BOOL)block
			 owner:(id)owner
		doneThread:(NSThread*)doneThread
		doneTarget:(id)doneTarget
	  doneSelector:(SEL)doneSelector
	   holdForMore:(BOOL)holdForMore ;		

/*!
 @brief    Returns an array containing invocations which will re-invoke
 any of your previous invocations of queueGroup:::::::::, ordered as they
 were originally invoked, and excluding any which have already completed
 all of their operations including the isDoneSelector, if any, and excluding
 any which were still pending when a prior group failed.

 @details  This method is useful if you can recover from an error by
 making adjustments and repeating the operations.  Your isDoneSelector
 will typically invoke an error presentation method, and then an
 attemptRecoveryFromError::… method.  If the user clicks a non-cancel
 recovery option, you make the adjustments and, to repeat the operations,
 simply invoke the invocations in the array returned by this method.  
 However, you must grab this array during your isDoneSelector, because after
 your isDoneSelector returns, the array you get will be empty, as explained below.
 Typically, after grabbing this array you process the contents into a single
 invocation of invocations, and add the resulting "errorRetryInvocation"
 to the -userInfo of your error object.
 
 After invoking your isDoneSelector, unless you passed holdForMore:YES,
 SSYOperationQueue will automatically make the following
 adjustments to its errorRetry invocations…  If
 the group succeeeded without setting an error, and if the group does
 not have holdForMore set YES, it will remove its error
 retry invocation from the receiver.
*/
- (NSInvocation*)errorRetryInvocationForGroup:(NSString*)group ;

- (void)performErrorRecovery ;

@end