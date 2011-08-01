extern NSString* const constSSYLoginItemsErrorDomain ;
extern NSInteger const SSYLoginItemsCouldNotResolveExistingItemErrorCode ;
extern NSInteger const SSYLoginItemsCouldNotResolveGivenItemErrorCode ;
extern NSInteger const SSYLoginItemsCouldNotCreateFileListErrorCode ;
extern NSInteger const SSYLoginItemsCouldNotInsertItemErrorCode ;
extern NSInteger const SSYLoginItemsCouldNotRemoveItemErrorCode ;
extern NSInteger const SSYLoginItemsCallerGaveNilPathErrorCode ;

/*!
 @brief    A Cocoa wrapper around LSSharedFileList for adding or removing Login Items.

 @details  SSYLoginItems.h/.c is an Obj-C wrapper on LSSharedFileList which provides some class methods to query, add and remove items from the user's "Login Items" in System Preferences.
 
 SSLoginItems.h/.c may be used in other projects.  Mac OS 10.5 and the CoreServices framework are required.
 
 QUICK START
 
 Run the demo project and follow the instructions in the console.  It will examine, add and remove items from your Login Items.  It will ask you to verify the results by examining your Login Items and then pressing return six times.
 
 BUGS
 
 When I run the program, I find two repeatable bugs:
 • In Test 1, Login Items that have the "Hidden" box checked are reported to have hidden=0.
 • In test 5, when the tool sets a Login Item with hidden=1, the "Hidden" box in Login Items does not get checked.
 
 I believe this is due to a bug in the LSSharedFileList API which I have entered into Apple Bug Reporter.  Problem ID 5901742
 
 30-Apr-2008 01:48 PM Jerry Krinock: 
 
 * SUMMARY The 'hidden' attribute for Login Items in the LSSharedList API has a disconnect with the reality. In more detail, when reading a Login Item, the 'hidden' attribute is read as 0, even if it is in fact '1', unless the 'hidden' attribute has been set by the LSSharedList API. In that case, it doesn't really set, but when you read it back with the API, it says that it is set, even though in fact it is not.
 
 * STEPS TO REPRODUCE Build and run the attached project. Follow the prompts shown in the the console.
 
 * EXPECTED RESULTS In all tests, the values read and written using the LSSharedList API and shown in the log should agree with what is shown in the System Preferences application.
 
 * ACTUAL RESULTS In Test #1, items which have the "Hide" box checked in System Preferences read from the API hidden=0. In Test #5, although the API set Safari to "Hide" and the API read it back as hidden=1, if you look in System Preferences you see that the "Hide" box is not checked. 
 
 REVISIONS:
 
 20090818: Bogus items in Login Items (which, I believe, are items for which the path has disappeared) are now ignored instead of causing an error to be returned and, later, a crash.
 20090819: I believe I fixed conceptual memory-management errors.  In some places, I was releasing the elements in the 'snapshot' array, in addition to releasing the array itself (which is correct), and compensating by retaining (but not always).  I'm still not sure that it's all correct, but it's better than it was.
 20090925: Removed dependency on NSError+SSYAdds.h/.m, added dependency on smaller NSError+LowLevel.h/.m
 20091125: Added Localized Failure Reason and Localized Recovery Suggestion to error with code 19584 which occurs if the user has a bogus Login Item.
 20100407: Made Localized Recovery Suggestion for error 19584 less confusing, and defined constants for all error codes.  Error 19584 is now SSYLoginItemsCouldNotResolveExistingItemErrorCode.
*/

@interface SSYLoginItems : NSObject

/*!
 @enum      SSYSharedFileListResult
 @brief		Results for some of the methods in the SSYLoginItems class
 */
enum SSYSharedFileListResult_enum {
	SSYSharedFileListResultFailed = -1,
	SSYSharedFileListResultNoAction = 0,
	SSYSharedFileListResultAdded,
	SSYSharedFileListResultRemoved,
	SSYSharedFileListResultLaunched,
	SSYSharedFileListResultQuit,
	SSYSharedFileListResultKilled,
	SSYSharedFileListResultSucceeded  // better to use one of the more specific values
} ;
typedef enum SSYSharedFileListResult_enum SSYSharedFileListResult ;

/*!
 @brief    Tests whether or not the file URL url is a Login Item for the current user

 @details  Returns answer as [*isLoginItem_p boolValue].  If it is, also
 returns whether or not it is hidden as [*hidden_p boolValue]
 @param    url  The file url of the item in question
 @param    isLoginItem_p  On output, if input is not NULL, will point to 
 an [NSNumber numberWithBool:] expressing whether or not the item in question is a Login Item
 for the current user.
 @param    hidden_p  On output, if input is not NULL, will point to an [NSNumber numberWithBool:]
 expressing whether or not the item in question is "Hidden"
 in Login Items
 @param    error_p  On output, if input is not NULL, if error occurred, will point to an
 NSError* expressing the error which occurred.
 @result   YES if operation was successful with no error, NO otherwise.
 */
+ (BOOL)isURL:(NSURL*)url
	loginItem:(NSNumber**)isLoginItem_p
	   hidden:(NSNumber**)hidden_p
		error:(NSError**)error_p  ;

/*!
 @brief    Adds file URL url as a Login Item at the end of the list for the current user

 @details  Also, sets its 'hidden' parameter according to [hidden boolValue]
 @param    url  The file url of the item to be added.
 @param    hidden  The "Hidden" attribute of the new login item will be set to reflect this input.
 @param    error_p  On output, if input is not NULL, if error occurred, will point to an
 NSError* expressing the error which occurred.
 @result   YES if operation was successful with no error, NO otherwise.
 */
+ (BOOL)addLoginURL:(NSURL*)url
			 hidden:(NSNumber*)hidden
			  error:(NSError**)error_p ;

/*!
 @brief    Removes file URL url as a Login Item for the current user
 @param    url  The file url of the item to be removed.
 @param    error_p  On output, if input is not NULL, if error occurred, will point to an
 NSError* expressing the error which occurred.
 @result   YES if operation was successful with no error, NO otherwise.
 */
+ (BOOL)removeLoginURL:(NSURL*)url
				 error:(NSError**)error_p ;

/*!
 @brief    Adds <i>or</i> removes an item to/from Login Items of current user

 @details  If path is not a Login Item for the current user and shouldBeLoginItem is
 YES, makes it a Login Item for the current user and also sets it hidden or
 not according to setHidden.
 If path is a Login Item for the current user and shouldBeLoginItem is NO,
 removes path from current user's Login items.
 If neither of the above, does nothing.
 @param    The  absolute path to the item which will be added or removed from Login Items.
 @param    shouldBeLoginItem  Whether the item should be a Login Item or not.
 @param    setHidden  If a new login item is set, whether or not it is set as Hidden.
 @param    error_p  On output, if input is not NULL, if error occurred, will point to an
 NSError* expressing the error which occurred.
 @result   If operation fails for some reason, returns SSYSharedFileListResultFailed
 If item at path was not found and added, returns SSYSharedFileListResultAdded.
 If item at path was found and removed, returns SSYSharedFileListResultRemoved.
 If none of the above occurred, returns SSYSharedFileListResultNoAction.
 */
+ (SSYSharedFileListResult)synchronizeLoginItemPath:(NSString*)path
									   shouldBeLoginItem:(BOOL)shouldBeLoginItem
											   setHidden:(BOOL)setHidden 
												   error:(NSError**)error_p ;

/*!
 @brief    Removes all Login Items for the current user which have a given name as last
 component of their path name, except those in a given path.

 @details  This method is useful to clear out login items referring to old
 versions, after the installation of a Login Item has been updated.  In this case,
 pass path as the latest version of the app to be launched.
 @param    name  Filename (last component of path name) used to qualify Login Items
 for removal.  The .extension part of this argument, if any, is ignored.
 @param    path  Login Items in this path will not be removed.
 @param    error_p  On output, if input is not NULL, if error occurred, will point to an
 NSError* expressing the error which occurred.
 @result   If operation fails for some reason, returns SSYSharedFileListResultFailed
 If one or more Login Items were removed, returns SSYSharedFileListResultRemoved.
 If zero Login Items were removed, returns SSYSharedFileListResultNoAction.
 */
+ (SSYSharedFileListResult)removeAllLoginItemsWithName:(NSString*)name
										   thatAreNotInPath:(NSString*)path
													  error:(NSError**)error_p ;

@end

