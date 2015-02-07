#import <Foundation/Foundation.h>
#import <Security/Security.h>

#if __IPHONE_7_0 || __MAC_10_9
// Keychain synchronization available at compile time
#define SSYKeychain_SYNCHRONIZATION_AVAILABLE 1
#endif

#ifdef SSYKeychain_SYNCHRONIZATION_AVAILABLE
typedef NS_ENUM(NSUInteger, SSYKeychainQuerySynchronizationMode) {
    SSYKeychainQuerySynchronizationModeAny,
    SSYKeychainQuerySynchronizationModeNo,
    SSYKeychainQuerySynchronizationModeYes
} ;
#endif

/*!
 @brief  Object for querying and changing items in the OS X or iOS Keychain,
 doing the heavy lifting for SSYKeychain which has an easier interface and is
 recommended as a wrapper
 
 @details  This class is a fork of SSKeychainQuery by Sam Soffes,
 https://github.com/soffes/SSKeychain/tree/master/SSKeychain, which in turn
 is based on code written by by Caleb Davenport on 3/19/13.  SSKeychainQuery is
 hard-wired to only support "generic" class keychain items.  In this fork of
 SSKeychainQuery, I have
 
 • Added support for other classes of keychain items, Internet in particular
 • Re-declared as methods a couple of properties which, in my opinion, were not
 really properties and I found this confusing
 • Made friendly to manual reference counting targets by supporting the NO_ARC
 compiler directive
 */
@interface SSYKeychainQuery : NSObject

/** kSecAttrAccount */
@property (nonatomic, copy) NSString *account ;

/** kSecAttrService */
@property (nonatomic, copy) NSString *service ;

/** kSecAttrLabel */
@property (nonatomic, copy) NSString *label ;

/** kSecAttrServer
 This is used for internet passwords (itemClass = kSecClassInternetPassword).
 It is shown in the `name` column of the Keychain Access app. */
@property (nonatomic, copy) NSString *server ;

/** kSecAttrClass
 You may set this to any of the constant strings enumerated under SetItem.h >
 kSecClass.  This property is initialized to a default value of
 kSecClassGenericPassword. */
@property (nonatomic, copy) NSString *itemClass ;

#if __IPHONE_3_0 && TARGET_OS_IPHONE
/** kSecAttrAccessGroup (only used on iOS) */
@property (nonatomic, copy) NSString *accessGroup ;
#endif

#ifdef SSYKeychain_SYNCHRONIZATION_AVAILABLE
/** kSecAttrSynchronizable */
@property (nonatomic) SSYKeychainQuerySynchronizationMode synchronizationMode ;
#endif

/** Root storage for password information */
@property (nonatomic, copy) NSData *passwordData ;

/*!
 @brief  Convenience accessor for the receiver's `passwordData` property,
 transformed by NSKeyedArchiver or NSKeyedUnarchiver
 */
- (id<NSCoding>)passwordObject ;
- (void)setPasswordObject:(id<NSCoding>)passwordObject ;

/*!
 @brief  Convenience accessor for the receiver's `passwordData` property,
 transformed by UTF8 string encoding */
- (NSString*)password ;
- (void)setPassword:(NSString*)password ;

/*!
 @brief  Deletes any existing items in the user's keychain which match the
 receiver's current properties (other than password data), and then sets a new
 item with all of the receiver's current properties
 
 @param error Populated should an error occur.
 
 @result `YES` if saving was successful, `NO` otherwise
 */
- (BOOL)save:(NSError **)error ;

/*!
 @brief  Deletes any existing items in the user's keychain which match the
 receiver's current properties (other than password data)
 
 @param error Populated should an error occur.
 
 @result `YES` if saving was successful or if no item matching the receiver's
 properties was found ("nothing to do"), `NO` otherwise.
 */
- (BOOL)deleteItem:(NSError **)error ;


/*!
 @brief  Returrns all keychain items that match the receiver's account, service,
 and access group properties.
 
 @details  The value of the receiver's `passwordData` is ignored by ths method.
 Returns nil if an error occurs.
 
 @param error Populated should an error occur.
 
 @result  An array of dictionaries that represent all "generic" items in the
 user's keychain that match the receiver's current non-nil properites, or `nil`
 should an error occur
 
 @details  The order of the items is unspecified.
 */
- (NSArray *)fetchAll:(NSError **)error ;

/*!
 @details  Fetches the user's keychain a password which matches the receiver's
 current properties, ignoring the current `passwordData` property, and sets the
 receiver's `passwordData` to the result
 
 @param error Populated should an error occur.
 
 @result `YES` if fetching was successful, `NO` otherwise.
 */
- (BOOL)fetch:(NSError**)error ;

#ifdef SSYKeychain_SYNCHRONIZATION_AVAILABLE
/*!
 @brief  Returns a boolean indicating if keychain synchronization is available
 on the device at runtime. The #define SSYKeychain_SYNCHRONIZATION_AVAILABLE is
 only for compile time. If you are checking for the presence of synchronization,
 you should use this method.
 
 @result  A value indicating if keychain synchronization is available
 */
+ (BOOL)isSynchronizationAvailable ;
#endif

@end
