#import <Cocoa/Cocoa.h>


/*!
 A couple methods for getting info about the user.
*/
@interface SSYUserInfo : NSObject {
}

/*!
 @brief    Returns first name, last name and primary email
 address of from the "me" entry in Address Book.
 
 @details  Warning!  Starting with macOS 10.8, invoking
 this method will produce an ugly, scary and vague dialog box
 asking the user if it is OK for your app to access their
 Contacts.  This method will block until the dialog is
 dismissed by the user.
*/
+ (void)fromAddressBookFirstName_p:(NSString**)ptrFirstName
						lastName_p:(NSString**)ptrLastName
						   email_p:(NSString**)ptrEmail ;

/*!
 @brief    Returns the string name, unix user ID (uid) and
 unix group ID (id) of the current console user.
 
 @details  Instead of this class, you should use NSUserName() or NSFullUserName()
 if they will meet your needs.
 
 The reason is that, according to Apple QA1133, the SCDynamicStoreCopyConsoleUser
 function used herein will "...likely that they will be formally deprecated
 in a future version of macOS".
 
 There is an alternative: getuid(2).  When I first tested this in 2008, I found
 that it was not reliable.  See
 http://www.cocoabuilder.com/archive/cocoa/174279-how-to-get-user-id-501-502-etc.html
 When I test it today, I find that it returns 501 as expected, even after I've
 recently executed a sudo in Terminal.  So, maybe the implementation of this method
 should be changed.
 
 @result   The string representation of the users's name
 @param    uid_p On return, a pointer to the user ID.  You may pass null if you
 do not want this.
 @param    gid_p On return, a pointer to the group ID.  You may pass null if you
 do not want this.
*/
+ (NSString*)consoleUserNameAndUid_p:(uid_t*)uid_p
							   gid_p:(gid_t*)gid_p ;

@end
