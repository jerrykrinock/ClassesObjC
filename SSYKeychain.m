#import "SSYKeychain.h"

NSString *const kSSYKeychainErrorDomain = @"SSYKeychainErrorDomain";

#if __IPHONE_4_0 && TARGET_OS_IPHONE
static CFTypeRef SSYKeychainAccessibilityType = NULL ;
#endif

@implementation SSYKeychain

+ (NSString*)passwordForServost:(NSString*)servostName
                    trySubhosts:(NSArray*)trySubhosts
                        account:(NSString*)account
                          clase:(NSString*)itemClass
                        error_p:(NSError*__autoreleasing*)error_p {
    SSYKeychainQuery *query = [[SSYKeychainQuery alloc] init] ;
    [query setAccount:account] ;
    if (itemClass) {
        [query setItemClass:itemClass] ;
    }
    NSMutableArray* subs = [[NSMutableArray alloc] init] ;
    [subs addObject:@""] ;
    if ([query itemClass] == (NSString*)kSecClassInternetPassword) {
        if (trySubhosts) {
            [subs addObjectsFromArray:trySubhosts] ;
        }
    }
    else {
        [query setService:servostName] ;
    }

    NSError* error = nil ;
    NSString* password = nil ;
    for (NSString* subdomain in subs) {
        NSString* hostWithSub = servostName ;
        if ([subdomain length] > 0) {
            hostWithSub = [NSString stringWithFormat:
                           @"%@.%@",
                           subdomain,
                           servostName] ;
        }
        [query setServer:hostWithSub] ;
        NSError* thisError = nil ;
        [query fetch:error_p] ;
        if (!error && thisError) {
            error = thisError ;
        }
        password = [query password] ;
        if (password) {
            break ;
        }
    }
    
#if !__has_feature(objc_arc)
    [subs release] ;
    [query release] ;
#endif
    if (error && error_p) {
        (*error_p = error) ;
    }
    return password ;
}

+ (BOOL)deletePasswordForServost:(NSString*)servostName
                         account:(NSString*)account
                           clase:(NSString*)itemClass
                         error_p:(NSError*__autoreleasing*)error_p {
    SSYKeychainQuery *query = [[SSYKeychainQuery alloc] init] ;
    if (itemClass) {
        [query setItemClass:itemClass] ;
    }
    if ([query itemClass] == (NSString*)kSecClassInternetPassword) {
        [query setServer:servostName] ;
    }
    else {
        [query setService:servostName] ;
    }
    [query setAccount:account] ;

    BOOL ok = [query deleteItem:error_p] ;
#if !__has_feature(objc_arc)
    [query release] ;
#endif
    return ok ;
}

+ (BOOL)setPassword:(NSString*)password
         forServost:(NSString*)servostName
            account:(NSString*)account
              clase:(NSString*)itemClass
            error_p:(NSError*__autoreleasing*)error_p {
    SSYKeychainQuery *query = [[SSYKeychainQuery alloc] init] ;
    if (itemClass) {
        [query setItemClass:itemClass] ;
    }
    if ([query itemClass] == (NSString*)kSecClassInternetPassword) {
        [query setServer:servostName] ;
    }
    else {
        [query setService:servostName] ;
    }
    [query setAccount:account] ;
    [query setPassword:password] ;
    
    BOOL ok = [query save:error_p] ;
#if !__has_feature(objc_arc)
    [query release] ;
#endif
    return ok ;
}

+ (NSArray*)allItemsForHost:(NSString*)hostName
                    service:(NSString*)serviceName
                      clase:(NSString*)itemClass {
    SSYKeychainQuery *query = [[SSYKeychainQuery alloc] init] ;
    if (hostName) {
        [query setServer:hostName] ;
    }
    if (serviceName) {
        [query setService:serviceName] ;
    }
    if (itemClass) {
        [query setItemClass:itemClass] ;
    }
    
    NSArray* answer = [query fetchAll:nil] ;
#if !__has_feature(objc_arc)
    [query release] ;
#endif
    return answer ;
}

+ (NSArray*)allItemsOfClase:(NSString*)itemClass {
    return [self allItemsForHost:nil
                         service:nil
                           clase:itemClass] ;
}

+ (NSArray*)allInternetItemsForHost:(NSString*)hostName {
    return [self allItemsForHost:hostName
                         service:nil
                           clase:(NSString*)(NSString*)kSecClassInternetPassword] ;
}

+ (NSArray*)allGenericItemsForService:(NSString*)serviceName {
    return [self allItemsForHost:nil
                         service:serviceName
                           clase:(NSString*)kSecClassGenericPassword] ;
}

+ (NSArray*)accountNamesForServost:(NSString*)servostName
                             clase:(NSString*)itemClass
                           error_p:(NSError**)error_p {
    SSYKeychainQuery *query = [[SSYKeychainQuery alloc] init] ;
    if (itemClass) {
        [query setItemClass:itemClass] ;
    }
    if ([query itemClass] == (NSString*)kSecClassInternetPassword) {
        [query setServer:servostName] ;
    }
    else {
        [query setService:servostName] ;
    }

    NSError* error = nil ;
    NSArray* items = [query fetchAll:&error] ;
#if !__has_feature(objc_arc)
    [query release] ;
#endif
    NSArray* accountNames = [items valueForKey:(NSString*)kSecAttrAccount] ;
    if (error && error_p) {
        *error_p = error ;
    }
    
    return accountNames ;
}

+ (NSArray*)accountNamesForServost:(NSString*)servostName
                       trySubhosts:(NSArray*)trySubhosts
                             clase:(NSString*)itemClass
                           error_p:(NSError**)error_p {
    NSError* error = nil ;
    NSArray* array = [self accountNamesForServost:servostName
                                            clase:itemClass
                                          error_p:&error] ;
    if (!array) {
        array = [NSMutableArray array] ;
    }
    if (!error || [error code] == errSecItemNotFound) {
        NSArray* moreAccounts = nil ;
        NSString* aHost ;
        for (NSString* subhost in trySubhosts) {
            aHost = [NSString stringWithFormat:
                               @"%@.%@",
                               subhost,
                               servostName] ;
            moreAccounts = [self accountNamesForServost:aHost
                                                  clase:itemClass
                                                error_p:&error] ;
            array = [array arrayByAddingObjectsFromArray:moreAccounts] ;
            if (error && ([error code] != errSecItemNotFound)) {
                if (error_p) {
                    *error_p = error ;
                }
                break ;
            }
        }
    }
    else if (error_p) {
        *error_p = error ;
    }
    
    return array ;
}

#if __IPHONE_4_0 && TARGET_OS_IPHONE
+ (CFTypeRef)accessibilityType {
    return SSYKeychainAccessibilityType ;
}

+ (void)setAccessibilityType:(CFTypeRef)accessibilityType {
    CFRetain(accessibilityType) ;
    if (SSYKeychainAccessibilityType) {
        CFRelease(SSYKeychainAccessibilityType) ;
    }
    SSYKeychainAccessibilityType = accessibilityType ;
}
#endif

@end
