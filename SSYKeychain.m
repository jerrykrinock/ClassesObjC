#import "SSYKeychain.h"
#import "NSError+InfoAccess.h"
#import "NSError+MyDomain.h"

NSString* const SSYKeychainItemRef = @"SSYKeychainItemRef" ;

@implementation SSYKeychain

/*!
 @brief    Searches the keychain for items matching given criteria
 and returns requested attribute(s)

 @param    searchRef  The search criteria.  If NULL, returns
 an empty array.
 @param    attributeInfo  The list of attributes which are desired
 from each found item.
 @result   Let N be the number of requested attributes from each
 found item, i.e. the number of elements in attributeInfo.  If
 N==1, returns an array of the attributes of the found items.
 If N>1, returns an array of dictionaries, one for each
 found item, and each dictionary contains N keys, NSNumbers whose
 unsigned long values are equal to the FourCharCode representing
 one of the requested attributes in the attributeInfo (one of
 the SecItemAttr enumerated values, for examples:
 kSecAccountItemAttr, kSecServiceItemAttr).
*/
+ (NSArray*)searchKeychainFor:(SecKeychainSearchRef)searchRef
				getAttributes:(SecKeychainAttributeInfo)attributeInfo {
	NSArray *output= nil ;
	NSMutableArray* results = [[NSMutableArray alloc] init] ;
	OSStatus status = noErr ;
	while (status == noErr) {
		SecKeychainItemRef itemRef = NULL ;
		status = SecKeychainSearchCopyNext (
											searchRef,
											&itemRef) ;
		
		if ((status == noErr) && (itemRef != NULL)) {
			// Note: -25300 = errSecItemNotFound.  I seem to get this both
			//  (a) when item cannot be found on first try
			//  (b) after all items have been found
			
			SecKeychainAttributeList *attributeList = NULL ;
			OSStatus attrResult = SecKeychainItemCopyAttributesAndData (
																		itemRef,
																		&attributeInfo,
																		NULL,
																		&attributeList,
																		NULL,
																		NULL) ;
			if (attrResult == noErr) {
				NSMutableDictionary* itemDic = nil ;
				if (attributeList->count > 1) {
					itemDic = [[NSMutableDictionary alloc] init] ;
				}

				NSInteger i ;
				for(i=0; i<attributeList->count; i++) {
					SecKeychainAttribute *attribute = &attributeList->attr[i];
					NSString* value = nil ;
					// Doug Mitchell is not sure if this will always be UTF8.
					// Oh well, if it's good enough for Apple, it's good enough for me.
					value = (NSString*)CFStringCreateWithBytes(NULL, 
															   (UInt8 *)attribute->data,
															   attribute->length,
															   kCFStringEncodingUTF8,
															   false) ;
					if (attributeList->count > 1) {
						[itemDic setObject:value
									forKey:[NSNumber numberWithInteger:(attribute->tag)]] ;
					}
					else {
						[results addObject:value] ;
					}
					CFRelease(value) ;
				}
				SecKeychainItemFreeAttributesAndData(attributeList, NULL) ;
				
				if (attributeList->count > 1) {
					[results addObject:[NSDictionary dictionaryWithDictionary:itemDic]] ;
				}
				
				[itemDic release] ;
			}
		}
	}
	
	output = [[results copy] autorelease] ;
	[results release] ;
	
	return output;
}

+ (NSArray*)allGenericItems {	
	OSStatus status ;
	
	SecKeychainSearchRef searchRef ;
	
	status = SecKeychainSearchCreateFromAttributes (
													NULL,
													kSecGenericPasswordItemClass,
													NULL,
													&searchRef) ;
	
	NSArray* output = nil ;	
	if (status == noErr) {
		UInt32 tags[2] = {kSecServiceItemAttr, kSecAccountItemAttr} ;
		UInt32 formats[2] = {0, 0} ;
		SecKeychainAttributeInfo attributeInfo ;
		attributeInfo.count = 2 ;
		attributeInfo.tag = tags ;
		attributeInfo.format = formats ; // See "/* I don't know what the format field is for */" in http://darwinsource.opendarwin.org/10.3/SecurityNssPkcs12-6/Source/pkcs12Keychain.cpp
		
		output = [self searchKeychainFor:searchRef
						   getAttributes:attributeInfo] ;
	}
	
	if (searchRef) {
		CFRelease(searchRef) ;
	}
	
	return output ;
}

+ (NSArray*)genericAccountsForServiceName:(NSString*)serviceName {	
	struct SecKeychainAttributeList* attributeListRef = NULL ;
	// If !serviceName, NULL searches for all services.
	if (serviceName) {
		const char *serviceNameC = [serviceName UTF8String] ;
		struct SecKeychainAttribute attribute ;
		attribute.tag = kSecServiceItemAttr ;
		// Being careful here because strlen(0) causes a crash
		attribute.length = serviceNameC ? strlen(serviceNameC) : 0 ;
		attribute.data = (void*)serviceNameC ;
		
		struct SecKeychainAttributeList attributeList ;
		attributeList.attr = &attribute ; // first (and in this case, only, item in array)
		attributeList.count = 1 ;
		attributeListRef = &attributeList ;
	}
	
	OSStatus status ;
	
	SecKeychainSearchRef searchRef ;
	
	status = SecKeychainSearchCreateFromAttributes (
													NULL,
													kSecGenericPasswordItemClass,
													attributeListRef,
													&searchRef) ;
	
	NSArray* output = nil ;	
	if (status == noErr) {
		// We want only one attribute, the account name
		// (Password must be retrieved with a separate function)
		UInt32 tags[1] = {kSecAccountItemAttr} ;
		SecKeychainAttributeInfo attributeInfo ;
		attributeInfo.count = 1 ;
		attributeInfo.tag = tags ;
		attributeInfo.format = NULL ; // See "/* I don't know what the format field is for */" in http://darwinsource.opendarwin.org/10.3/SecurityNssPkcs12-6/Source/pkcs12Keychain.cpp
		
		output = [self searchKeychainFor:searchRef
						   getAttributes:attributeInfo] ;
	}
	
	if (searchRef) {
		CFRelease(searchRef) ;
	}
	
	return output ;
}

+ (NSArray*)internetAccountsForHost:(NSString*)host {
	const char *hostC = [host UTF8String] ;
	
	struct SecKeychainAttribute attribute ;
	attribute.tag = kSecServerItemAttr ;
	// Being careful here because strlen(0) causes a crash
	attribute.length = hostC ? strlen(hostC) : 0 ;
	attribute.data = (void*)hostC ;
	
	struct SecKeychainAttributeList attributeList ;
	attributeList.attr = &attribute ; // first (and in this case, only, item in array)
	attributeList.count = 1 ;
	
	OSStatus status ;
	
	SecKeychainSearchRef searchRef ;
	
	status = SecKeychainSearchCreateFromAttributes (
													NULL,
													kSecInternetPasswordItemClass,
													&attributeList,
													&searchRef) ;
	
	NSArray* output = nil ;	
	if (status == noErr) {
		// We want only one attribute, the account name
		// (Password must be retrieved with a separate function)
		UInt32 tags[1] = {kSecAccountItemAttr} ;
		SecKeychainAttributeInfo attributeInfo ;
		attributeInfo.count = 1 ;
		attributeInfo.tag = tags ;
		attributeInfo.format = NULL ; // See "/* I don't know what the format field is for */" in http://darwinsource.opendarwin.org/10.3/SecurityNssPkcs12-6/Source/pkcs12Keychain.cpp
		
		output = [self searchKeychainFor:searchRef
						   getAttributes:attributeInfo] ;
	}
	
	if (searchRef) {
		CFRelease(searchRef) ;
	}
	
	return output ;
}	

+ (NSArray*)internetAccountsForHost:(NSString*)host
				 possibleSubdomains:(NSArray*)possibleSubdomains {
	NSArray* array = [self internetAccountsForHost:host] ;
	NSArray* moreAccounts ;
	NSString* alternativeHost ;
	for (NSString* subdomain in possibleSubdomains) {
		alternativeHost = [NSString stringWithFormat:
						   @"%@.%@",
						   subdomain,
						   host] ;
		moreAccounts = [self internetAccountsForHost:alternativeHost] ;
		array = [array arrayByAddingObjectsFromArray:moreAccounts] ;
	}
	
	return array ;
}

+ (NSString*)internetPasswordUsername:(NSString*)username
								  host:(NSString*)host
				   possibleSubdomains:(NSArray*)possibleSubdomains
							   domain:(NSString*)domain
					  keychainitemRef:(SecKeychainItemRef*)itemRef {

	NSString*  password = nil ;
	
	// Since the username will be converted to a C string, if it is empty,
	// it will look like a null string, since C strings are not objects.  Thus, 
	// stupid SecKeychainFindInternetPassword will think it is null, which
	// it interprets to mean "any account", and will return the first password it
	// finds for the given host and domain.  Assuming that no legitimate
	// account name will be an empty string, we should instead return nil in this
	// case.  The following if() accomplishes that:
	if (([username length] > 0)  && ([host length] > 0)) {
		const char *user = [username UTF8String] ;
		const char *dom = [domain UTF8String] ;
		void * passwordC = NULL ;
		UInt32 passwordLength = 0 ;
		
		struct SecKeychainAttribute attribute ;
		attribute.tag = kSecServerItemAttr ;

		// strlen(0) causes a crash but we've already checked that this length > 0
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
			attribute.length = strlen(hostC) ;
			attribute.data = (void*)hostC ;
			// strlen(0) causes a crash but we've already checked that [host length] > 0
			NSInteger lengthHost = hostC ? strlen(hostC) : 0 ;
			
			OSStatus findResult = SecKeychainFindInternetPassword (
				NULL, // default keychain
				lengthHost, // server name length
				hostC, // server name
				lengthDomain, // security domain length
				dom, // security domain
				lengthUser, // account name length
				user, // account name
				0, // path length
				NULL, // path
				0, // port
				0, // protocol
				// For some reason which I don't understand, if I pass kSecProtocolTypeHTTP
				// as the protocol, it will not find any of the google.com passwords
				// However, this problem does not occur with lists.apple.com.
				// Furthermore, passing protocol = 0 is not documented.  But it works.
				0, // authentication type
				&passwordLength, // password length
				& passwordC, // password
				itemRef
			) ;

			if (findResult == noErr) {
				 password = [[NSString alloc] initWithBytes: passwordC
													  length:passwordLength
													encoding:NSUTF8StringEncoding] ;
				[ password autorelease] ;
				SecKeychainItemFreeContent(NULL,  passwordC) ;
			}
		}
	
		[subdomains release] ;
	}	

	return password ;
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
			OSStatus addResult = SecKeychainAddInternetPassword (
																 NULL, // default keychain
																 lengthHost, // server name length
																 host, // server name
																 lengthDomain, // security domain length
																 dom, // security domain
																 lengthUser, // account name length
																 user, // account name
																 0, // path length
																 NULL, // path
																 port, // port
																 kSecProtocolTypeHTTP, // protocol
																 kSecAuthenticationTypeHTTPBasic, // authentication type
																 lengthNewPassword, // password length
																 pass, // password
																 NULL // item ref
																 ) ;
		
			success = (addResult == noErr) ;
		}
	}
	
	return success ;
}

+ (NSString*)genericPasswordServiceName:(NSString*)serviceName
							accountName:(NSString*)accountName
						keychainitemRef:(SecKeychainItemRef*)itemRef {
	
	NSString* password = nil ;
	
	// Since the accountName will be converted to a C string, if it is empty,
	// it will look like a null string, since C strings are not objects.  Thus, 
	// stupid SecKeychainFindGenericPassword will think it is null, which
	// it interprets to mean "any account", and will return the first password it
	// finds for the given service name.  Assuming that no legitimate
	// account name will be an empty string, we should instead return nil in this
	// case.  The following if() accomplishes that:
	if (([accountName length] > 0)  && ([serviceName length] > 0)) {
		const char *accountNameC = [accountName UTF8String] ;
		void *passwordC = NULL ;
		UInt32 passwordLength = 0 ;
		
		struct SecKeychainAttribute attribute ;
		attribute.tag = kSecServerItemAttr ;
		
		// strlen(0) causes a crash but here we know it's not 0
		NSInteger accountNameLength = strlen(accountNameC) ;
		
		const char* serviceNameC = [serviceName UTF8String] ;
		attribute.length = strlen(serviceNameC) ;
		attribute.data = (void*)serviceNameC ;
		NSInteger serviceNameLength = serviceNameC ? strlen(serviceNameC) : 0 ;
		
		OSStatus findResult = SecKeychainFindGenericPassword (
															  NULL, // default keychain
															  serviceNameLength, // server name length
															  serviceNameC, // service name
															  accountNameLength, // account name length
															  accountNameC, // account name
															  &passwordLength, // password length
															  &passwordC, // password
															  itemRef
															  ) ;
		
		if (findResult == noErr) {
			password = [[NSString alloc] initWithBytes:passwordC
												length:passwordLength
											  encoding:NSUTF8StringEncoding] ;
			[password autorelease] ;
			SecKeychainItemFreeContent(NULL, passwordC) ;
		}
	}	
	
	return password ;
}

+ (BOOL)addGenericPassword:(NSString*)password
			   serviceName:(NSString*)serviceName
			   accountName:(NSString*)accountName {
	BOOL success = NO ;
	
	if (password && serviceName && accountName) {
		const char *serviceNameC = [serviceName UTF8String] ;
		const char *accountNameC = [accountName UTF8String] ;
		const char *passwordC = [password UTF8String] ;
		SecKeychainItemRef itemRef ;
		
		NSString *currentPassword = [SSYKeychain genericPasswordServiceName:serviceName
																accountName:accountName
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
			NSInteger serviceNameLength = serviceNameC ? strlen(serviceNameC) : 0 ;
			NSInteger accountNameLength = accountNameC ? strlen(accountNameC) : 0 ;
			NSInteger passwordLength = passwordC ? strlen(passwordC) : 0 ;
			OSStatus addResult = SecKeychainAddGenericPassword (
																NULL, // default keychain
																serviceNameLength,
																serviceNameC,
																accountNameLength,
																accountNameC,
																passwordLength,
																passwordC,
																NULL
																);
			success = (addResult == noErr) ;
		}
	}
	
	return success ;
}

+ (BOOL)changeKeychainItemRef:(SecKeychainItemRef)itemRef
				  newPassword:(NSString*)password {
	BOOL success = NO ;
	
	if (password && itemRef) {
		const char *pass = [password UTF8String] ;
		OSErr status = SecKeychainItemModifyContent(itemRef, nil, strlen(pass), pass) ;
		success = (status == noErr)  ;
	}
	
	return success ;
}

+ (BOOL)deleteKeychainItemRef:(SecKeychainItemRef)itemRef
					  error_p:(NSError**)error_p {
	BOOL success = NO ;
	
	if (itemRef) {
		OSErr status = SecKeychainItemDelete(itemRef) ;
		if (status == noErr) {  // errSecSuccess is better for Mac OS 10.6+
			success = YES ;
		}
		else if (error_p) {
			NSString* errorString = (NSString*)SecCopyErrorMessageString(status, NULL) ;
			*error_p = SSYMakeError(status, errorString) ;
			*error_p = SSYMakeError(10389, @"Could not delete Keychain Item") ;
			*error_p = [*error_p errorByAddingUnderlyingError:SSYMakeError(status, errorString)] ;
            [errorString release] ;
		}
	}
	
	return success ;
}

+ (BOOL)deleteInternetPasswordForUsername:(NSString*)username
									 host:(NSString*)host {
	SecKeychainItemRef itemRef ;
	NSString* password = [self internetPasswordUsername:username
												   host:host
									 possibleSubdomains:nil
												 domain:nil
										keychainitemRef:&itemRef] ;
	BOOL ok = NO ;
	if (password) {
		ok = [self deleteKeychainItemRef:itemRef
								 error_p:NULL] ;
	}
	
	return ok ;
}


@end