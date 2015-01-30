#import "SSYKeychainQuery.h"

@implementation SSYKeychainQuery

@synthesize account = _account ;
@synthesize service = _service ;
@synthesize label = _label ;
@synthesize server = _server ;
@synthesize passwordData = _passwordData ;

#if __IPHONE_3_0 && TARGET_OS_IPHONE
@synthesize accessGroup = _accessGroup ;
#endif

#ifdef SSYKeychain_SYNCHRONIZATION_AVAILABLE
@synthesize synchronizationMode = _synchronizationMode ;
#endif

#pragma mark - Public

- (id)init {
    self = [super init] ;
    if (self) {
        // Default class value for all queries
        [self setItemClass:(__bridge id)kSecClassGenericPassword] ;
    }
    
    return self ;
}

#if NO_ARC
- (void)dealloc {
    [_account release] ;
    [_service release] ;
    [_label release] ;
    [_server release] ;
    [_itemClass release] ;
#if __IPHONE_3_0 && TARGET_OS_IPHONE
    [_accessGroup release] ;
#endif
    [_passwordData release] ;
    
    [super dealloc] ;
}
#endif

- (BOOL)save:(NSError *__autoreleasing *)error {
    OSStatus status = SSYKeychainErrorBadArguments ;
    if (![self service] || ![self account] || ![self passwordData]) {
        if (error) {
            *error = [[self class] errorWithCode:status] ;
        }
        return NO ;
    }
    
    [self deleteItem:nil] ;
    
    NSMutableDictionary *query = [self query] ;
    [query setObject:[self passwordData] forKey:(__bridge id)kSecValueData] ;
    if ([self label]) {
        [query setObject:[self label] forKey:(__bridge id)kSecAttrLabel] ;
    }
    if ([self server]) {
        [query setObject:[self server] forKey:(__bridge id)kSecAttrServer] ;
    }
#if __IPHONE_4_0 && TARGET_OS_IPHONE
    CFTypeRef accessibilityType = [SSYKeychain accessibilityType] ;
    if (accessibilityType) {
        [query setObject:(__bridge id)accessibilityType forKey:(__bridge id)kSecAttrAccessible] ;
    }
#endif
    status = SecItemAdd((__bridge CFDictionaryRef)query, NULL) ;
    
    if (status != errSecSuccess && error != NULL) {
        *error = [[self class] errorWithCode:status] ;
    }
    
    return (status == errSecSuccess) ;
}


- (BOOL)deleteItem:(NSError *__autoreleasing *)error {
    OSStatus status = SSYKeychainErrorBadArguments ;
    if (![self service] || ![self account]) {
        if (error) {
            *error = [[self class] errorWithCode:status] ;
        }
        return NO ;
    }
    
    NSMutableDictionary *query = [self query] ;
#if TARGET_OS_IPHONE
    status = SecItemDelete((__bridge CFDictionaryRef)query) ;
#else
    CFTypeRef result = NULL ;
    [query setObject:@YES forKey:(__bridge id)kSecReturnRef] ;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result) ;
    if (status == errSecSuccess) {
        status = SecKeychainItemDelete((SecKeychainItemRef)result) ;
        CFRelease(result) ;
    }
#endif
    
    if (status != errSecSuccess && error != NULL) {
        *error = [[self class] errorWithCode:status] ;
    }
    
    return (status == errSecSuccess) ;
}


- (NSArray *)fetchAll:(NSError *__autoreleasing *)error {
    OSStatus status = SSYKeychainErrorBadArguments ;
    NSMutableDictionary *query = [self query] ;
    [query setObject:@YES
              forKey:(__bridge id)kSecReturnAttributes] ;
    [query setObject:(__bridge id)kSecMatchLimitAll
              forKey:(__bridge id)kSecMatchLimit] ;
    
    CFTypeRef result = NULL ;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result) ;
    if (status != errSecSuccess && error != NULL) {
        *error = [[self class] errorWithCode:status] ;
        return nil ;
    }
    
#if NO_ARC
    return [(NSArray*)result autorelease] ;
#else
    return (__bridge_transfer NSArray *)result ;
#endif
}


- (BOOL)fetch:(NSError *__autoreleasing *)error {
    OSStatus status = SSYKeychainErrorBadArguments ;
    if (![self service] || ![self account]) {
        if (error) {
            *error = [[self class] errorWithCode:status] ;
        }
        return NO ;
    }
    
    CFTypeRef result = NULL ;
    NSMutableDictionary *query = [self query] ;
    [query setObject:@YES
              forKey:(__bridge id)kSecReturnData] ;
    [query setObject:(__bridge id)kSecMatchLimitOne
              forKey:(__bridge id)kSecMatchLimit] ;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result) ;
    
    if (status != errSecSuccess) {
        if (error) {
            *error = [[self class] errorWithCode:status] ;
        }
        return NO ;
    }
    
#if NO_ARC
    [self setPasswordData:result] ;
    [(NSData*)result autorelease] ;
#else
    [self setPasswordData:(__bridge_transfer NSData*)result] ;
#endif
    return YES ;
}


#pragma mark - Accessors

- (void)setPasswordObject:(id<NSCoding>)object {
    [self setPasswordData:[NSKeyedArchiver archivedDataWithRootObject:object]] ;
}


- (id<NSCoding>)passwordObject {
    id<NSCoding> answer = nil ;
    if ([[self passwordData] length] > 0) {
        answer = [NSKeyedUnarchiver unarchiveObjectWithData:[self passwordData]] ;
    }
    return answer ;
}


- (void)setPassword:(NSString *)password {
    [self setPasswordData:[password dataUsingEncoding:NSUTF8StringEncoding]] ;
}


- (NSString *)password {
    if ([[self passwordData] length] > 0) {
        NSString* word = [[NSString alloc] initWithData:[self passwordData] encoding:NSUTF8StringEncoding] ;
#if NO_ARC
        [word autorelease] ;
#endif
        return word ;
    }
    return nil ;
}


#pragma mark - Synchronization Status

#ifdef SSYKeychain_SYNCHRONIZATION_AVAILABLE
+ (BOOL)isSynchronizationAvailable {
#if TARGET_OS_IPHONE
    // Apple suggested way to check for 7.0 at runtime
    // https://developer.apple.com/library/ios/documentation/userexperience/conceptual/transitionguide/SupportingEarlieriOS.html
    return floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1 ;
#else
    return floor(NSFoundationVersionNumber) > NSFoundationVersionNumber10_8_4 ;
#endif
}
#endif


#pragma mark - Private

- (NSMutableDictionary *)query {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:3] ;
    [dictionary setObject:[self itemClass]
                   forKey:(__bridge id)kSecClass] ;
    
    if ([self service]) {
        [dictionary setObject:[self service] forKey:(__bridge id)kSecAttrService] ;
    }
    
    if ([self account]) {
        [dictionary setObject:[self account] forKey:(__bridge id)kSecAttrAccount] ;
    }
    
    if ([self server]) {
        [dictionary setObject:[self server] forKey:(__bridge id)kSecAttrServer] ;
    }
    
#if __IPHONE_3_0 && TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
    if ([self accessGroup]) {
        [dictionary setObject:[self accessGroup] forKey:(__bridge id)kSecAttrAccessGroup] ;
    }
#endif
    
#ifdef SSYKeychain_SYNCHRONIZATION_AVAILABLE
    if ([[self class] isSynchronizationAvailable]) {
        id value ;
        
        switch ([self synchronizationMode]) {
            case SSYKeychainQuerySynchronizationModeNo: {
                value = @NO ;
                break ;
            }
            case SSYKeychainQuerySynchronizationModeYes: {
                value = @YES ;
                break ;
            }
            case SSYKeychainQuerySynchronizationModeAny: {
                value = (__bridge id)(kSecAttrSynchronizableAny) ;
                break ;
            }
        }
        
        [dictionary setObject:value forKey:(__bridge id)(kSecAttrSynchronizable)] ;
    }
#endif
    
    return dictionary ;
}


+ (NSError *)errorWithCode:(OSStatus) code {
    NSString *message = nil ;
    switch (code) {
        case errSecSuccess: return nil ;
        case SSYKeychainErrorBadArguments: message = NSLocalizedStringFromTable(@"SSYKeychainErrorBadArguments", @"SSYKeychain", nil) ; break ;
            
#if TARGET_OS_IPHONE
        case errSecUnimplemented: {
            message = NSLocalizedStringFromTable(@"errSecUnimplemented", @"SSYKeychain", nil) ;
            break ;
        }
        case errSecParam: {
            message = NSLocalizedStringFromTable(@"errSecParam", @"SSYKeychain", nil) ;
            break ;
        }
        case errSecAllocate: {
            message = NSLocalizedStringFromTable(@"errSecAllocate", @"SSYKeychain", nil) ;
            break ;
        }
        case errSecNotAvailable: {
            message = NSLocalizedStringFromTable(@"errSecNotAvailable", @"SSYKeychain", nil) ;
            break ;
        }
        case errSecDuplicateItem: {
            message = NSLocalizedStringFromTable(@"errSecDuplicateItem", @"SSYKeychain", nil) ;
            break ;
        }
        case errSecItemNotFound: {
            message = NSLocalizedStringFromTable(@"errSecItemNotFound", @"SSYKeychain", nil) ;
            break ;
        }
        case errSecInteractionNotAllowed: {
            message = NSLocalizedStringFromTable(@"errSecInteractionNotAllowed", @"SSYKeychain", nil) ;
            break ;
        }
        case errSecDecode: {
            message = NSLocalizedStringFromTable(@"errSecDecode", @"SSYKeychain", nil) ;
            break ;
        }
        case errSecAuthFailed: {
            message = NSLocalizedStringFromTable(@"errSecAuthFailed", @"SSYKeychain", nil) ;
            break ;
        }
        default: {
            message = NSLocalizedStringFromTable(@"errSecDefault", @"SSYKeychain", nil) ;
        }
#else
        default:
#if NO_ARC
            message = (NSString *)SecCopyErrorMessageString(code, NULL) ;
            [message autorelease] ;
#else
            message = (__bridge_transfer NSString *)SecCopyErrorMessageString(code, NULL) ;
#endif
#endif
    }
    
    NSDictionary *userInfo = nil ;
    if (message) {
        userInfo = @{ NSLocalizedDescriptionKey : message };
    }
    
    return [NSError errorWithDomain:kSSYKeychainErrorDomain code:code userInfo:userInfo] ;
}

@end
