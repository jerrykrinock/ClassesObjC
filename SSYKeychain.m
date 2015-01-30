#import "SSYKeychain.h"

NSString *const kSSYKeychainErrorDomain = @"com.samsoffes.SSYKeychain";

#if __IPHONE_4_0 && TARGET_OS_IPHONE
static CFTypeRef SSYKeychainAccessibilityType = NULL ;
#endif

@implementation SSYKeychain

+ (NSString*)passwordForService:(NSString*)serviceName
                        account:(NSString*)account
                          class:(NSString*)itemClass
                        error_p:(NSError*__autoreleasing*)error_p {
    SSYKeychainQuery *query = [[SSYKeychainQuery alloc] init] ;
    [query setService:serviceName] ;
    [query setAccount:account] ;
    if (itemClass) {
        [query setItemClass:itemClass] ;
    }
    [query fetch:error_p] ;
    NSString* password = [query password] ;
#if NO_ARC
    [query release] ;
#endif
    return password ;
}

+ (BOOL)deletePasswordForService:(NSString*)serviceName
                         account:(NSString*)account
                           class:(NSString*)itemClass
                         error_p:(NSError*__autoreleasing*)error_p {
    SSYKeychainQuery *query = [[SSYKeychainQuery alloc] init] ;
    [query setService:serviceName] ;
    [query setAccount:account] ;
    if (itemClass) {
        [query setItemClass:itemClass] ;
    }
    BOOL ok = [query deleteItem:error_p] ;
#if NO_ARC
    [query release] ;
#endif
    return ok ;
}

+ (BOOL)setPassword:(NSString*)password
         forService:(NSString*)serviceName
            account:(NSString*)account
              class:(NSString*)itemClass
            error_p:(NSError*__autoreleasing*)error_p {
    SSYKeychainQuery *query = [[SSYKeychainQuery alloc] init] ;
    [query setService:serviceName] ;
    [query setAccount:account] ;
    [query setPassword:password] ;
    if (itemClass) {
        [query setItemClass:itemClass] ;
    }
    
    BOOL ok = [query save:error_p] ;
#if NO_ARC
    [query release] ;
#endif
    return ok ;
}

+ (NSArray*)allItemsForHost:(NSString*)hostName
                    service:(NSString*)serviceName
                      class:(NSString*)itemClass {
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
#if NO_ARC
    [query release] ;
#endif
    return answer ;
}

+ (NSArray*)allItemsOfClass:(NSString*)itemClass {
    return [self allItemsForHost:nil
                         service:nil
                           class:itemClass] ;
}

+ (NSArray*)allInternetItemsForHost:(NSString*)hostName {
    return [self allItemsForHost:hostName
                         service:nil
                           class:(NSString*)kSecClassInternetPassword] ;
}

+ (NSArray*)allGenericItemsForService:(NSString*)serviceName {
    return [self allItemsForHost:nil
                         service:serviceName
                           class:(NSString*)kSecClassGenericPassword] ;
}

+ (NSArray*)accountNamesForHost:(NSString*)host
                        service:(NSString*)serviceName
                          class:(NSString*)itemClass
                        error_p:(NSError**)error_p {
    SSYKeychainQuery* keychainQuery = [[SSYKeychainQuery alloc] init] ;
    [keychainQuery setItemClass:(NSString*)kSecClassInternetPassword] ;
    [keychainQuery setServer:host] ;
    [keychainQuery setService:serviceName] ;
    NSError* error = nil ;
    NSArray* items = [keychainQuery fetchAll:&error] ;
    [keychainQuery release] ;
    NSArray* accountNames = [items valueForKey:(NSString*)kSecAttrAccount] ;
    if (error && error_p) {
        *error_p = error ;
    }
    
    return accountNames ;
}

+ (NSArray*)accountNamesForHost:(NSString*)host
                        service:(NSString*)serviceName
                          class:(NSString*)itemClass
             possibleSubdomains:(NSArray*)possibleSubdomains
                        error_p:(NSError**)error_p {
    NSError* error = nil ;
    NSArray* array = [self accountNamesForHost:host
                                       service:serviceName
                                         class:itemClass
                                       error_p:&error] ;
    if (!error) {
        NSArray* moreAccounts ;
        NSString* alternativeHost ;
        for (NSString* subdomain in possibleSubdomains) {
            alternativeHost = [NSString stringWithFormat:
                               @"%@.%@",
                               subdomain,
                               host] ;
            moreAccounts = [self accountNamesForHost:alternativeHost
                                             service:serviceName
                                               class:itemClass
                                             error_p:&error] ;
            array = [array arrayByAddingObjectsFromArray:moreAccounts] ;
            if (error) {
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

+ (NSString*)internetPasswordUsername:(NSString*)username
                                 host:(NSString*)host
                   possibleSubdomains:(NSArray*)possibleSubdomains
                               domain:(NSString*)domain
                      keychainitemRef:(SecKeychainItemRef*)itemRef {
    
    NSString*  password = nil ;
    
    /* Since the username will be converted to a C string, if it is empty,
     it will look like a null string, since C strings are not objects.  Thus,
     stupid SecKeychainFindInternetPassword will think it is null, which
     it interprets to mean "any account", and will return the first password
     ig finds for the given host and domain.  Assuming that no legitimate
     account name will be an empty string, we should instead return nil in
     this case.  The following if() accomplishes that: */
    if (([username length] > 0)  && ([host length] > 0)) {
        const char *user = [username UTF8String] ;
        const char *dom = [domain UTF8String] ;
        void * passwordC = NULL ;
        UInt32 passwordLength = 0 ;
        
        struct SecKeychainAttribute attribute ;
        attribute.tag = kSecServerItemAttr ;
        
        /*strlen(0) causes a crash but we've already checked that this
         length > 0 */
        NSInteger lengthUser = strlen(user) ;
        NSInteger lengthDomain = dom ? strlen(dom) : 0 ;
        
        NSMutableArray* subdomains = [[NSMutableArray alloc] init] ;
        [subdomains addObject:@""] ;
        if (possibleSubdomains) {
            [subdomains addObjectsFromArray:possibleSubdomains] ;
        }
        for (NSString* subdomain in subdomains) {
            NSString* hostWithSub = host ;
            if ([subdomain length] > 0) {
                hostWithSub = [NSString stringWithFormat:
                               @"%@.%@",
                               subdomain,
                               host] ;
            }
            
            const char *hostC = [hostWithSub UTF8String] ;
            attribute.length = (UInt32)strlen(hostC) ;
            attribute.data = (void*)hostC ;
            /* strlen(0) causes a crash but we've already checked that
             [host length] > 0 */
            NSInteger lengthHost = hostC ? strlen(hostC) : 0 ;
            
            OSStatus status ;
            status = SecKeychainFindInternetPassword (
                                                      NULL, // default keychain
                                                      (UInt32)lengthHost, // server name length
                                                      hostC, // server name
                                                      (UInt32)lengthDomain, // security domain length
                                                      dom, // security domain
                                                      (UInt32)lengthUser, // account name length
                                                      user, // account name
                                                      0, // path length
                                                      NULL, // path
                                                      0, // port
                                                      0, // protocol
                                                      /* For some reason which I don't understand, if I pass kSecProtocolTypeHTTP
                                                       as the protocol, it will not find any of the google.com passwords
                                                       However, this problem does not occur with lists.apple.com.
                                                       Furthermore, passing protocol = 0 is not documented.  But it works. */
                                                      0, // authentication type
                                                      &passwordLength, // password length
                                                      & passwordC, // password
                                                      itemRef
                                                      ) ;
            if (status == noErr) {
                password = [[NSString alloc] initWithBytes: passwordC
                                                    length:passwordLength
                                                  encoding:NSUTF8StringEncoding] ;
#if NO_ARC
                [password autorelease] ;
#endif
                SecKeychainItemFreeContent(NULL,  passwordC) ;
            }
        }
        
#if NO_ARC
        [subdomains release] ;
#endif
    }
    
    return password ;
}

+ (BOOL)changeKeychainItemRef:(SecKeychainItemRef)itemRef
                  newPassword:(NSString*)password {
    BOOL success = NO ;
    
    if (password && itemRef) {
        const char *pass = [password UTF8String] ;
        OSErr status = SecKeychainItemModifyContent(itemRef, nil, (UInt32)strlen(pass), pass) ;
        success = (status == noErr)  ;
    }
    
    return success ;
}

+ (BOOL)addInternetPassword:(NSString*)password
                   username:(NSString*)username
                        url:(NSURL*)url
                     orHost:(NSString*)host
                     domain:(NSString*)domain {
    BOOL success = NO ;
    
    NSString* hostString = host ;
    NSNumber* portNumber = nil ;
    if (url) {
        if (!hostString) {
            hostString = [url host] ;
        }
        portNumber = [url port] ;
    }
    
    if (hostString && username && password) {
        const char *host = [hostString UTF8String] ;
        const char *user = [username UTF8String] ;
        const char *pass = [password UTF8String] ;
        const char *dom = [domain UTF8String] ;
        UInt16 port = [portNumber shortValue] ;
        SecKeychainItemRef itemRef ;
        
        NSString *currentPassword = [SSYKeychain internetPasswordUsername:username
                                                                    host:hostString
                                                      possibleSubdomains:nil
                                                                  domain:domain
                                                         keychainitemRef:&itemRef] ;
        
        if (currentPassword) {
            if ([currentPassword isEqualToString:password]) {
                success = YES ;
            }
            else {
                success = [self changeKeychainItemRef:itemRef
                                          newPassword:password] ;
            }
        }
        else {
            // We qualify these since strlen(0) causes a crash
            NSInteger lengthHost = host ? strlen(host) : 0 ;
            NSInteger lengthUser = user ? strlen(user) : 0 ;
            NSInteger lengthDomain = dom ? strlen(dom) : 0 ;
            NSInteger lengthNewPassword = pass ? strlen(pass) : 0 ;
            OSStatus status = SecKeychainAddInternetPassword (
                                                              NULL, // default keychain
                                                              (UInt32)lengthHost, // server name length
                                                              host, // server name
                                                              (UInt32)lengthDomain, // security domain length
                                                              dom, // security domain
                                                              (UInt32)lengthUser, // account name length
                                                              user, // account name
                                                              0, // path length
                                                              NULL, // path
                                                              port, // port
                                                              kSecProtocolTypeHTTP, // protocol
                                                              kSecAuthenticationTypeHTTPBasic, // authentication type
                                                              (UInt32)lengthNewPassword, // password length
                                                              pass, // password
                                                              NULL // item ref
                                                              ) ;
            success = (status == noErr) ;
        }
    }
    
    return success ;
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
