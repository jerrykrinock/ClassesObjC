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
 @brief    A class of class methods for accessing items in the user's macOS or
 iOS Keychain
 
 @details  This class is a fork of SSKeychain by Sam Soffes,
 https://github.com/soffes/SSKeychain/tree/master/SSKeychain, which in turn
 was inspired by EMKeychain and SDKeychain (both of which are now gone).  Prior
 to this version (2015 Jan), it was not a fork of SSKeychain, but was old and
 used many deprecated and/or difficult SecKeychain functions.  I have now gutted
 this class and replaced it with Sam's approach, based on his SSKeychainQuery,
 which uses only a few, modern SecKeychainXxxxx functions.
 
 Sam's SSKeychain is hard-wired to only support "generic" clase keychain items.
 In this fork of SSKeychainQuery, I have
 
 • Added support for other clases of keychain items, Internet in particular.
 • Made friendly to manual reference counting targets by adopting the NO_ARC
 compiler directive
 • Added more documentation, particularly to fill some holes in Apple's
 documentation.  That documetation follows here:
 
 Item Clases
 
 I mean "Item Classes", however I found that when I used `class:` as a
 parameter in an Objective-C method, Xcode 12 highlights 'class' as though
 it were an Objective-C keyword, and gives me warnings when processing
 header documentation that 'class' is not one of the parameters in the
 function, even after I fix them.  After fighting with it and losing for about
 20 minutes, I decided to change all references to this type of thing to the
 Spanish word 'clase' or its plural 'clases'.  This is actually better, I
 think, because as you will read below, 'clase' is not, as one might first
 think, a class in the Objective-C or Swift sense.
 
 Item clases are defined by Apple as one of the strings enumerated in
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
 is one of these kinds: 
 
 • Internet password
 • Web form password
 
 are in fact kSecClassInternetPassword.
 
 All queries require a clase.  Passing itemClase = nil causes a default value,
 kSecClassGenericPassword, to be used.
 
 User's Keychain
 
 This class only recognizes the user's keychain, whose name is typically the
 same as the user's unix short user name.  This is *not* the "Local Items"
 keychain.
 
 Access Control
 
 If you are not getting the passwords or items that you expect, it may be that
 the items do not allow your app to access.  Launch the Keychain Access app and
 "Get Info" > "Access Control" on any troublesome items.
 
 Name: Service vs. Host
 
 Keychain items of the Internet clase (kSecClassInternetPassword) have a host
 name, but not a service name.  In contrast, keychain
 items of the generic clase (kSecClassGenericPassword) have a service name, but
 not a host name.  A host name is, of course, for example google.com for
 example.  A service name may be any arbitrary string created by the app which
 stored it in the keychain, for its own purposes.
 
 The Keychain Access app appears to take advantage of the fact that one is
 nil by having only one column, 'Name", and using it for whichever is not nil,
 depending on the clase.  We do the same thing, with our 'servostName'
 parameter, which we interpret to be a host name when an item of Internet clase
 has been specified, and a service name otherwise.
 
 Item Attributes
 
 Item Attributes means a dictionary containing the attributes of a keychain
 item.  The keys in such a dictionary will be from the list of several dozen
 given in Apple's Keychain Services Reference > Attribute Item Keys, except that
 you may get a key "clase/class", which I think is supposed to be "kcls", symbolized
 by kSecAttrKeyClass, and I think this is a bug in Keychain Services.
 
 For convenience in debugging, the Attribute Item Keys in macOS 10.10.2 have
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
 
 You will never see most of those keys.  The keys I found when dumping my macOS
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

/*!
 @brief    Returns a string containing the password for a given service name,
 account name, and item clase, or `nil` if the Keychain doesn't have a password
 for the given parameters.
 
 @details  See "Name: Service vs. Host" in the class documentatotion.
 
 @param    servostName  Either a service name or a host name.
 
 @param    trySubhosts  An array of strings, each of which are possible
 subdomains which will be prepended to the host with a "." when searching for
 an internet password (clase=kSecClassInternetPassword.  Ignored if clase =
 kSecClassGenericPassword.  For example, if you pass servost="google.com" and
 trySubhosts=@[@"www", @"my"], there will be three hosts searched: google.com,
 www.google.com and my.google.com.  Recommended subdomains are subdomains are
 "www", "my", "login", "mobile", "account".  If nil, searches only the given
 servost.

 @param   clase  The clase of the target keychain item, any of the constant
 strings enumerated under SetItem.h > kSecClass.  If you pass nil, defaults to
 kSecClassGenericPassword.
 */
+ (NSString*)passwordForServost:(NSString*)servostName
                    trySubhosts:(NSArray*)trySubhosts
                        account:(NSString*)account
                          clase:(NSString*)itemClase
                        error_p:(NSError*__autoreleasing*)error_p ;

/*!
 @brief    Deletes from the user's keychain any item matching a given
 service name, account name and item clase
 
 @details  See "Name: Service vs. Host" in the class documentatotion.  This
 parameter is  interpreted to specify a host name when the 'clase' parameter is
 kSecClassInternetPassword, and a service name otherwise.
 
 A better name for this method might be deleteItemForServost…, since actually
 it deletes a keychain *item*.  But since the nearby methods use 'password', and
 since it is useless or maybe impossible to have a keychain item without a
 password, I use 'password'.
 
 @param    clase  See "Item Clase" in the class documentation.  There is no wild
 card.  If you pass nil here, the clase kSecClassGenericPassword is assumed.
 
 @result  YES if successful, otherwise NO
 */
+ (BOOL)deletePasswordForServost:(NSString*)servostName
                         account:(NSString*)account
                           clase:(NSString*)itemClase
                         error_p:(NSError*__autoreleasing*)error_p ;

/*!
 @brief    Sets a password in the Keychain for a given service name, account
 name and item clase
 
 @details  See "Name: Service vs. Host" in the class documentatotion.  This
 parameter is  interpreted to specify a host name when the 'clase' parameter is
 kSecClassInternetPassword, and a service name otherwise.
 
 @param    clase  See "Item Clase" in the class documentation.  There is no wild
 card.  If you pass nil here, the clase kSecClassGenericPassword is assumed.
 If the class is kSecClassGenericPassword, it will show up in the Keychain
 Access app with kind = "application password"
 
 @result  YES if successful, otherwise NO
 */
+ (BOOL)setPassword:(NSString*)password
         forServost:(NSString*)servostName
            account:(NSString*)account
              clase:(NSString*)itemClase
            error_p:(NSError*__autoreleasing*)error_p ;

/*!
 @brief    Returns attributes of all items in the user's keychain, of a given
 single clase
 
 @details  See "Name: Service vs. Host" in the class documentatotion.
 
 @param    clase  See "Item Clase" in the class documentation.  There is no wild
 card.  If you pass nil here, the clase kSecClassGenericPassword is assumed.
 
 @result    An array, in unspecified order, of Item Attributes, one for each
 item found, or nil if no items were found to match the given specifications.
 See "Item Attributes" in the class documentation for more information.
 */
+ (NSArray*)allItemsOfClase:(NSString*)itemClase ;

/*!
 @brief    Returns attributes of all Internet clase (kSecClassInternetPassword)
 items in the user's keychain
 
 @param  hostName  A name which appears in the "Name" column of the Keychain
 Access app, (for "Internet password" items).
 
 @result    An array, in unspecified order, of Item Attributes, one for each
 item found, or nil if no items were found to match the given specifications.
 See "Item Attributes" in the class documentation for more information.
 */
+ (NSArray*)allInternetItemsForHost:(NSString*)hostName ;

/*!
 @brief    Returns attributes of all generic clase (kSecClassGenericPassword)
 items in the user's keychain
 
 @param  serviceName  A name which appears in the "Name" column of the Keychain
 Access app, (for Generic items).
 
 @result    An array, in unspecified order, of Item Attributes, one for each
 item found, or nil if no items were found to match the given specifications.
 See "Item Attributes" in the class documentation for more information.
 */
+ (NSArray*)allGenericItemsForService:(NSString*)serviceName ;

/*!
 @brief    Returns the array of keychain items which have internet passwords in
 the user's keychain for a given clase and service or host
 
 @param    trySubhosts  An array of strings, each of which are possible
 subdomains which will be prepended to the host with a "." when searching for
 an internet password (class=kSecClassInternetPassword.  Ignored if class =
 kSecClassGenericPassword.  For example, if you pass servost="google.com" and
 trySubhosts=@[@"www", @"my"], there will be three hosts searched: google.com,
 www.google.com and my.google.com.  Recommended subdomains are subdomains are
 "www", "my", "login", "mobile", "account".  If nil, searches only the given
 servost.
 */
+ (NSArray*)accountNamesForServost:(NSString*)servostName
                       trySubhosts:(NSArray*)trySubhosts
                             clase:(NSString*)itemClase
                           error_p:(NSError**)error_p ;


#pragma mark - Configuration

#if __IPHONE_4_0 && TARGET_OS_IPHONE
/*!
 Returns the accessibility type for all future passwords saved to the Keychain.
 
 @result Returns the accessibility type
 
 The return value will be `NULL` or one of the "Keychain Item Accessibility
 Constants" used for determining when a keychain item should be readable.
 
 @see setAccessibilityType
 */
+ (CFTypeRef)accessibilityType ;

/*!
 @brief    Sets the accessibility type for all future passwords saved to the
 user's Keychain.
 
 @param accessibilityType One of the "Keychain Item Accessibility Constants"
 used for determining when a keychain item should be readable.
 
 If the value is `NULL` (the default), the Keychain default will be used.
 
 @see accessibilityType
 */
+ (void)setAccessibilityType:(CFTypeRef)accessibilityType ;
#endif

@end
