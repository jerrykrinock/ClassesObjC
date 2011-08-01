#import <Security/Security.h>

/*!
 @brief    A constant which may be used to key, for example, an NSValue object
 wrapping a SecKeychainItemRef structure if, for example, you need to pass it
 in a dictionary, for example, in the userInfo of an NSError object
*/
extern NSString* const SSYKeychainItemRef ;

@interface SSYKeychain : NSObject {
}

/*!
 @brief    Returns an array giving the service names and
 account names of all generic items in the user's keychain.

 @details  "Generic" is the word used in Keychain Services
 Reference.  When viewing items in the Keychain Access
 application, "generic" items are those whose "Kind" is
 "application password".
 @result   Returns an array of dictionaries, one for each
 found item.  Each dictionary contains 2 keys, NSNumbers
 whose unsigned long values are equal to the two FourCharCodes
 kSecServiceItemAttr, kSecAccountItemAttr.  The value for
 each key is either the service name or account name as
 indicated by the key.
*/
+ (NSArray*)allGenericItems ;

/*!
 @brief    Returns the array of account names for the generic items
 in the user's keychain which have a given service name.
 
 @details  "Generic" is the word used in Keychain Services
 Reference.  When viewing items in the Keychain Access
 application, "generic" items are those whose "Kind" is
 "application password".

 If none found, returns an empty array.  If search fails to
 complete, returns nil.
 
 @param    serviceName  A service name for which account names will be
 searched.  If nil, will return account names for all generic items
 (which may useless, having an account name without knowing the
 service it lives on, but, oh well).
 */
+ (NSArray*)genericAccountsForServiceName:(NSString*)serviceName ;

/*!
 @brief    Returns the array of account names which have internet passwords in 
 the user's keychain for a given host.
 
 @details  If none found, returns an empty array.  If search fails to
 complete, returns nil.
 
 @param    host  A hostname for which account names will be searched.
 Example: @"google.com".
 */
+ (NSArray*)internetAccountsForHost:(NSString*)host ;

/*!
 @brief    Same as internetAccountsForHost:, except also searches for
 keychain items of the given host with given subdomains.
 
 @details  The host and each of the possible subdomains given will be
 joined with ".".  If you don't know the host you're dealing with,
 suggested possible subdomains are "www", "my", and "login".
 */
+ (NSArray*)internetAccountsForHost:(NSString*)host
				 possibleSubdomains:(NSArray*)possibleSubdomains ;

/*!
 @brief    Adds a generic password for a given account name and
 service name.
 
 @details  "Generic" is the term used in Keychain Services
 Reference.  When viewing items in the Keychain Access
 application, "generic" items are those whose "Kind" is
 "application password".

 If password already exists for given username and host,
 overwrites it.
 
 @result   YES if the password was added or already exists in the keychain
 as specified.  NO if an error occurred.
 */
+ (BOOL)addGenericPassword:(NSString*)password
			   serviceName:(NSString*)serviceName
			   accountName:(NSString*)accountName ;

/*!
 @brief    Returns a generic password from the keychain for a service name
 and account name.
 
 @details  If password for given service name and account name is not found, will return nil.
 If either service name or account name are nil or empty strings, will return nil.
 @param    keychainitemRef  Upon return, pointer to a SecKeychainItemRef if a
 password was found.  Pass NULL if you don't need this, which is usually the
 case.
 */
+ (NSString*)genericPasswordServiceName:(NSString*)serviceName
							accountName:(NSString*)accountName
						keychainitemRef:(SecKeychainItemRef*)itemRef ;

/*!
 @brief    Adds an internet password for a given username and
 host in a given domain.
 
 @details  If password already exists for given username and host,
 overwrites it.
 @param    url  If given, will extract the host and port if any from this NSURL
 and will ignore the 'host' parameter.
 @param    host  If 'url' is not given, the host for which the password will
 be added.  Example: @"google.com".
 @param    domain  A string representing the security domain which will be
 passed to Apple's SecKeychainFindInternetPassword().  Hint:  Try nil ;)
 @result   YES if the password was added or already exists in the keychain
 as specified.  NO if an error occurred.
*/
+ (BOOL)addInternetPassword:(NSString*)password
				   username:(NSString*)username
						url:(NSURL*)url
					 orHost:(NSString*)host
					 domain:(NSString*)domain ;

/*!
 @brief    Returns an internet password from the keychain for a given host, username
 and domain.
 
 @details  If password for given username, host and domain is not found, will return nil.
 If either username or host are nil or empty strings, will return nil.
 @param    host  A hostname for which account names will be searched.
 Example: @"google.com".
 @param    host  If 'url' is not given, the host for which the password will
 be added.  Example: @"google.com".
 @param    possibleSubdomains  An array of strings, each of which are possible
 subdomains which will be prepended to the host with a "." when searching for
 the password.  May be nil or empty to search only the given host.
 @param    keychainitemRef  Upon return, pointer to a SecKeychainItemRef if a
 password was found.  Pass NULL if you don't need this.
*/
+ (NSString*)internetPasswordUsername:(NSString*)username
								 host:(NSString*)host
				   possibleSubdomains:(NSArray*)possibleSubdomains
							   domain:(NSString*)domain
					  keychainitemRef:(SecKeychainItemRef*)itemRef ;

/*!
 @brief    Changes the password for a given SecKeychainItemRef

 @details  Since you usually don't know the SecKeychainItemRef, you'll
 use +addInternetPassword::::: instead of this method.

 @result   YES if the operation succeeded, otherwise NO.
*/
+ (BOOL)changeKeychainItemRef:(SecKeychainItemRef)itemRef
				  newPassword:(NSString*)password ;

/*!
 @brief    Deletes a given SecKeychainItemRef in the Mac OS X Keychain.

 @param    error_p  Pointer which will, upon return, if an error
 occurred and said pointer is not NULL, point to an NSError
 describing said error.
 @result   YES if the method executed without error, otherwise NO.
 */
+ (BOOL)deleteKeychainItemRef:(SecKeychainItemRef)itemRef
					  error_p:(NSError**)error_p ;

/*!
 @brief    Attempts to find a password for a given username and host
 in the Mac OS X Keychain, and deletes the entry if found.
 
 @result   YES if the entry was found and deleted, otherwise NO.
 */
+ (BOOL)deleteInternetPasswordForUsername:(NSString*)username
									 host:(NSString*)host ;

@end
