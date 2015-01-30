#import "SSYKeychainQuery.h"

/*!
 @brief    Error code specific to SSYKeychain that can be returned in NSError objects.
 For codes returned by the operating system, refer to SecBase.h for your
 platform.
 */
typedef NS_ENUM(OSStatus, SSYKeychainErrorCode) {
    /* Some of the arguments were invalid. */
    SSYKeychainErrorBadArguments = -1001,
};

/*! SSYKeychain error domain */
extern NSString *const kSSYKeychainErrorDomain;


/*!
 @brief    A class of class methods for accessing items in the user's OS X or
 iOS Keychain
 
 @details  This class is a fork of SSKeychain by Sam Soffes,
 https://github.com/soffes/SSKeychain/tree/master/SSKeychain, which in turn
 was inspired by EMKeychain and SDKeychain (both of which are now gone).  Sam's
 SSKeychain is hard-wired to only support "generic" class keychain items.
 In this fork of SSKeychainQuery, I have
 
 • Added support for other classes of keychain items, Internet in particular.
 In doing so, I added much of my own code from my "version 1" SSYKeychain class,
 using Sam's code to replace the parts of my code which used older and now
 deprecated SecKeychainXxxxx functions
 • Made friendly to manual reference counting targets by supporting the NO_ARC
 compiler directive
 • Added more documentation, particularly to fill some holes in Apple's
 documentation
 
 Item Classes
 
 Item classes are defined by Apple as one of the strings enumerated in
 SetItem.h > kSecClass.  At this time (10.10), you can see there are five
 types listed (lines 60-64).  This corresponds roughly to the "Kind" column in
 the Keychain Access app.  Most items, including those whose "Kind" is one of
 the following:
 
 • application password
 • Internet Connect
 • Airport base station password
 • MobileMe password
 • iTunes Store password
 
 are in fact "generic" items, kSecClassGenericPassword.  Items whose "Kind"
 is "Internet password" are in fact kSecClassInternetPassword.
 
 All queries require a class.  Passing itemClass = nil causes a default value,
 kSecClassGenericPassword, to be used.
 
 Item Attributes
 
 Item Attributes means a dictionary containing the attributes of a keychain
 item.  The keys in such a dictionary will be from the list of several dozen
 given in Apple's Keychain Services Reference > Attribute Item Keys, except that
 you may get a key "class", which I think is supposed to be "kcls", symbolized
 by kSecAttrKeyClass, and I think this is a bug in Keychain Services.
 
 For convenience in debugging, the Attribute Item Keys in OS X 10.10.2 have
 been dumped below.  Of course, you should use the constants and not the values
 because the latter are an undocumented implementation detail.
 
 kSecAttrAccessible = pdmn
 kSecAttrCreationDate = cdat
 kSecAttrModificationDate = mdat
 kSecAttrDescription = desc
 kSecAttrComment = icmt
 kSecAttrCreator = crtr
 kSecAttrType = type
 kSecAttrLabel = labl
 kSecAttrIsInvisible = invi
 kSecAttrIsNegative = nega
 kSecAttrAccount = acct
 kSecAttrService = svce
 kSecAttrGeneric = gena
 kSecAttrSecurityDomain = sdmn
 kSecAttrServer = srvr
 kSecAttrProtocol = ptcl
 kSecAttrAuthenticationType = atyp
 kSecAttrPort = port
 kSecAttrPath = path
 kSecAttrSubject = subj
 kSecAttrIssuer = issr
 kSecAttrSerialNumber = slnr
 kSecAttrSubjectKeyID = skid
 kSecAttrPublicKeyHash = pkhh
 kSecAttrCertificateType = ctyp
 kSecAttrCertificateEncoding = cenc
 kSecAttrKeyClass = kcls
 kSecAttrApplicationLabel = klbl
 kSecAttrIsPermanent = perm
 kSecAttrApplicationTag = atag
 kSecAttrKeyType = type
 kSecAttrKeySizeInBits = bsiz
 kSecAttrEffectiveKeySize = esiz
 kSecAttrCanEncrypt = encr
 kSecAttrCanDecrypt = decr
 kSecAttrCanDerive = drve
 kSecAttrCanSign = sign
 kSecAttrCanVerify = vrfy
 kSecAttrCanWrap = wrap
 kSecAttrCanUnwrap = unwp
 kSecAttrAccessGroup = agrp
 
 You will never see most of those keys.  The keys I found when dumping my OS X
 Keychain of of 114 items, prefixed by their number of occurrences, is:
 
 114 kSecAttrModificationDate = mdat
 114 kSecAttrLabel = labl
 114 class (should be kSecAttrKeyClass = kcls ??)
 114 kSecAttrCreationDate = cdat
 111 kSecAttrService = svce
 111 kSecAttrAccount = acct
 32 kSecAttrCreator = crtr
 28 kSecAttrDescription = desc
 10 kSecAttrGeneric = gena
 5 kSecAttrKeyType = type
 4 kSecAttrComment = icmt
 */
@interface SSYKeychain : NSObject

#pragma mark - Classic methods

/*!
 @brief    Returns a string containing the password for a given service name,
 account name, and item class, or `nil` if the Keychain doesn't have a password
 for the given parameters.
 
 @param class   The class of the target keychain item, any of the constant
 strings enumerated under SetItem.h > kSecClass.  If you pass nil, defaults to
 kSecClassGenericPassword.  Less commonly, use kSecClassInternetPassword.
 */
+ (NSString*)passwordForService:(NSString*)serviceName
                        account:(NSString*)account
                          class:(NSString*)itemClass
                        error_p:(NSError*__autoreleasing*)error_p ;

/*!
 @brief    Deletes from the user's keychain any password matching a given
 service name, account name and item class
 
 @param class   See class documentation.  If you pass nil, defaults to
 kSecClassGenericPassword.  Less commonly, use kSecClassInternetPassword.
 
 @result  YES if successful, otherwise NO
 */
+ (BOOL)deletePasswordForService:(NSString*)serviceName
                         account:(NSString*)account
                           class:(NSString*)itemClass
                         error_p:(NSError*__autoreleasing*)error_p ;

/*!
 @brief    Sets a password in the Keychain for a given service name, account
 name and item class
 
 @result  YES if successful, otherwise NO
 */
+ (BOOL)setPassword:(NSString*)password
         forService:(NSString*)serviceName
            account:(NSString*)account
              class:(NSString*)itemClass
            error_p:(NSError*__autoreleasing*)error_p ;

/*!
 @brief    Returns attributes of all items in the user's keychain, of a given
 single class
 
 @param    class  See "Item Class" in the class documentation.  There is no wild
 card.  If you pass nil here, the class kSecClassGenericPassword is assumed.
 
 @result    An array, in unspecified order, of Item Attributes, one for each
 item found, or nil if no items were found to match the given specifications.
 See "Item Attributes" in the class documentation for more information.
 */
+ (NSArray*)allItemsOfClass:(NSString*)itemClass ;

/*!
 @brief    Returns attributes of all Internet class (kSecClassInternetPassword)
 items in the user's keychain
 
 @param  hostName  A name which appears in the "Name" column of the Keychain
 Access app, (for "Internet password" items).
 
 @result    An array, in unspecified order, of Item Attributes, one for each
 item found, or nil if no items were found to match the given specifications.
 See "Item Attributes" in the class documentation for more information.
 */
+ (NSArray*)allInternetItemsForHost:(NSString*)hostName ;

/*!
 @brief    Returns attributes of all generic class (kSecClassGenericPassword)
 items in the user's keychain
 
 @param  serviceName  A name which appears in the "Name" column of the Keychain
 Access app, (for Generic items).
 
 @result    An array, in unspecified order, of Item Attributes, one for each
 item found, or nil if no items were found to match the given specifications.
 See "Item Attributes" in the class documentation for more information.
 */
+ (NSArray*)allGenericItemsForService:(NSString*)serviceName ;

/*!
 @brief    Returns the array of account names which have internet passwords in
 the user's keychain for a given host.
 
 @details  If none found, returns an empty array.  If search fails to
 complete, returns nil.
 
 @param    host  A hostname for which account names will be searched.
 Example: @"google.com".
 */
+ (NSArray*)accountNamesForHost:(NSString*)host
                        service:(NSString*)serviceName
                          class:(NSString*)itemClass
                        error_p:(NSError**)error_p ;

/*!
 @brief    Same as accountNamesForHost:service:class:error_p:, except also
 searches for keychain items of the given host with given subdomains.
 
 @details  The hosts searched will be the given host, plus the given host
 prefixed by each of the possible subdomains and ".".  For example, if you pass
 host="google.com" and possibleSubdomains=@[@"www", @"my"], there will be three
 hosts searched: google.com, www.google.com and my.google.com.  Recommended
 subdomains are subdomains are "www", "my", "login", "mobile".
 */
+ (NSArray*)accountNamesForHost:(NSString*)host
                        service:(NSString*)serviceName
                          class:(NSString*)itemClass
             possibleSubdomains:(NSArray*)possibleSubdomains
                        error_p:(NSError**)error_p ;

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
 @param    possibleSubdomains  An array of strings, each of which are possible
 subdomains which will be prepended to the host with a "." when searching for
 the password.  May be nil or empty to search only the given host.
 @param    domain  The "security domain" within the host.  Usually, this is nil.
 @param    keychainitemRef  Upon return, pointer to a SecKeychainItemRef if a
 password was found.  Pass NULL if you don't need this.
 */
+ (NSString*)internetPasswordUsername:(NSString*)username
                                 host:(NSString*)host
                   possibleSubdomains:(NSArray*)possibleSubdomains
                               domain:(NSString*)domain
                      keychainitemRef:(SecKeychainItemRef*)itemRef ;


#pragma mark - Configuration

#if __IPHONE_4_0 && TARGET_OS_IPHONE
/*!
 Returns the accessibility type for all future passwords saved to the Keychain.
 
 @result Returns the accessibility type.
 
 The return value will be `NULL` or one of the "Keychain Item Accessibility
 Constants" used for determining when a keychain item should be readable.
 
 @see setAccessibilityType
 */
+ (CFTypeRef)accessibilityType;

/*!
 @brief    Sets the accessibility type for all future passwords saved to the Keychain.
 
 @param accessibilityType One of the "Keychain Item Accessibility Constants"
 used for determining when a keychain item should be readable.
 
 If the value is `NULL` (the default), the Keychain default will be used.
 
 @see accessibilityType
 */
+ (void)setAccessibilityType:(CFTypeRef)accessibilityType;
#endif

@end
