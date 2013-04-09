#import <Cocoa/Cocoa.h>


/*!
 @brief    A more powerful replacement for some NSFileManager functions,
 which can present an authentication dialog and perform some actions with
 elevated permissions if necessary.

 @details  This class requires CPHTaskMaster, which in turn requires
 Mac OS X 10.6, to do anything useful.  If the deployment target
 (MAC_OS_X_VERSION_MIN_REQUIRED) is Mac OS X 10.5 or less,
 methods in this class will return an error if called upon to do
 anything that NSFileManager can't do.  The idea is that you
 can still use it in targets compiled with low deployment
 targets
*/
@interface SSYSuperFileManager : NSFileManager {
}


/*!
 @brief    Re-declaration to avoid compiler warnings when instantiating
 this class since superclass declaration of this method is declared
 to return the superclass, not id.
*/
+ (SSYSuperFileManager*)defaultManager ;

/*!
 @brief    Sets given permissions of a filesystem item at a given path,
 presenting an authentication dialog if necessary, and returning records
 of any permissions that were successfully changed
 
 @param    permission  The value of the BSD permissions to be set,
 typically a number such as octal 40777.  Remember that the compiler
 interprets a literal integer with a leading zero to be an octal number; 
 i.e. 040777 = 0x41FF = decimal 16895.
 @param    path  The path for which permissions should be changed
 @param    changedPermissions  If permissions were successfully changed,
 the given path will be added as a key to this dictionary, with a value
 equal to an NSNumber whose unsigned short value is the original permissions
 of the parent directory before they were changed.
 @param    error_p  Pointer to an NSError which, if permissions could not be
 changed , will point to an NSError instance explaining why
 permissions could not be changed.  Otherwise, this pointer will be
 untouched.
 @result   YES if the permissions were successfully changed.
 */
- (BOOL)setPermissions:(mode_t)permission
				 path:(NSString*)path
   changedPermissions:(NSMutableDictionary*)changedPermissions
			  error_p:(NSError**)error_p ;

/*!
 @brief    Sets permissions of one or more filesystem items, specified
 in a dictionary, presenting an authentication dialog if necessary.

 @details  
 @param    permissions  A dictionary of filesystem paths (keys) and
 their desired permissions (values).  The keys should be NSString
 objects, and the values NSNumber objects whose unsigned short value
 represents the desired permissions.  Note that the BSD permissions
 type mode_t is unsigned short.
 @param    error_p  Pointer to an NSError*, or nil.  If non-nil, and
 if an error occurred, will, upon exit, point to an NSError describing
 the problem.
 @result   YES if the operation was successful, otherwise NO
*/
- (BOOL)setBulkPermissions:(NSDictionary*)permissions
				   error_p:(NSError**)error_p ;

/*!
 @brief    Determines whether or not a file exists at a given path,
 asking for administrator authentication if necessary to access it.

 @details  Improved version of -fileExistsAtPath:isDirectory.&nbsp;
 While traversing the path, if unable to enter because of permissions,
 asks user for authentication and momentarily sets permissions to
 040777.  Restores all permissions to old values before
 returning.
 @param    isDirectory_p  Upon return, contains YES if path is a
 directory or if the final path element is a symbolic link that
 points to a directory, otherwise contains NO.&nbsp;   If path
 doesn’t exist, the return value is undefined.&nbsp;  Pass NULL
 if you do not need this information.
 @param    didElevate_p  Pointer which will, if not nil, upon return,
 point to a BOOL indicating whether or not it was necessary to
 ask the user for elevated permissions to perform the operation.
 Pass NULL if you do not need this information.
 @param    error_p  Pointer which will, upon return, if an error
 occured and said pointer is not NULL, point to an NSError
 describing said error.
 @result   YES if the path could be probed and was found to exist,
 otherwise NO.
*/
- (BOOL)fileExistsAtPath:(NSString*)path
		   isDirectory_p:(BOOL*)isDirectory
			didElevate_p:(BOOL*)didElevate_p
				 error_p:(NSError**)error_p ;

/*!
 @brief    Invokes -fileExistsAtPath:isDirectory_p:error_p
 with isDirectory_p set to NULL.
*/
- (BOOL)fileExistsAtPath:(NSString*)path
			didElevate_p:(BOOL*)didElevate_p
				 error_p:(NSError**)error_p ;


- (BOOL)canExecutePath:(NSString*)fullPath
			   groupID:(uid_t)groupID
				userID:(uid_t) userID ;

/*!
 @brief    

 @details  
 @param    path  
 @param    error_p  A pointer to an NSError instance, or nil if
 you're not interested in the error.  If you pass a pointer, and
 the requested result cannot be returned, will point to an
 NSError explaning the problem upon output.
 For efficiency in case you expect that a path may not exist
 and pass error_p = NULL, we don't create a local error.  If
 you pass a non-NULL error_p, it should point to nil (i.e.
 there should be no "pre-existing" error).
 
 @result   
*/
- (NSDate*)modificationDateForPath:(NSString*)path
						   error_p:(NSError**)error_p ;

@end
