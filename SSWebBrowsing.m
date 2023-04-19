#import "SSWebBrowsing.h"
#import "NSBundle+MainApp.h"

@implementation NSString (FirefoxQuicksearch)

+ (CFURLRef)sampleHttpUrl {
    return (__bridge CFURLRef)[NSURL URLWithString:@"http://xx.xx"] ;
}

- (NSString*)stringByFixingFirefoxQuicksearch {
	NSString* output ;
	
	if ([self hasSuffix:@"%s"])
	{
		// This is one of Firefox' QuickSearches 
		// For examaple: "Type "dict <word>" in the location bar to perform a dictionary look-up"
		// -URLWithString will fail with this, I suppose because the % at the end of its url is not allowed per some RFC.
		// So, first we replace %s with our app name,
		NSMutableString* temp = [self mutableCopy] ;
		[temp replaceOccurrencesOfString:@"%s"
							  withString:[[NSBundle mainAppBundle] objectForInfoDictionaryKey:@"CFBundleName"]
								 options:NSBackwardsSearch
								   range:NSMakeRange(0, [temp length])] ;
		output =  [NSString stringWithString:temp] ;
		// I tried removing with query (which wasn't easy because NSURL wouldn't initWithString until
		// I first replaced %s with the app name).  But this caused an "Internal Server Error" at
		// answers.com, either with or without the ? query delimiter character.
#if !__has_feature(objc_arc)
		[temp release];
#endif
	}
	else {
		output = self ;
	}
	
	return output ;
}

@end


@implementation SSWebBrowsing

+ (CFURLRef)sampleHttpUrl {
    return (__bridge CFURLRef)[NSURL URLWithString:@"http://xx.xx"] ;
}

+ (NSURL*)defaultBrowserUrl {
    NSURL* answer = (NSURL*)CFBridgingRelease(LSCopyDefaultApplicationURLForURL([self sampleHttpUrl],
                                                                                kLSRolesViewer,
                                                                                NULL));
#if !__has_feature(objc_arc)
    [answer autorelease];
#endif
    return answer;
}

+ (NSString*)defaultBrowserDisplayName {
	CFErrorRef error = nil ;

	// Get browser's URL
    NSURL *defaultBrowserURL = [self defaultBrowserUrl];
	NSString* name = nil ;
	if (!error && defaultBrowserURL) {
		name = [[NSFileManager defaultManager] displayNameAtPath:[defaultBrowserURL path]] ;
		// Remove suffix ".app":
		if ([name hasSuffix:@".app"]) {
			// This was not necessary in Mac OS 10.3.
			name = [name substringToIndex:([name length] - 4)] ;
		}
	}
	if (!name) {
		name = @"??" ;
	}
    
	return name ;
}

+ (NSString*)defaultBrowserBundleIdentifier {
    CFURLRef browserUrl = (__bridge CFURLRef)(CFBridgingRelease(LSCopyDefaultApplicationURLForURL(
                                                                                                  [self sampleHttpUrl],
                                                                                                  kLSRolesViewer,
                                                                                                  NULL)));
                                            
	// Get path (NSString*)
    NSString* path = [(__bridge NSURL*)browserUrl path] ;
#if !__has_feature(objc_arc)
    if (browserUrl) {
        CFRelease(browserUrl) ;
    }
#endif
	
	// Get bundle
	NSBundle* bundle = nil ;
	if (path) {
		bundle = [NSBundle bundleWithPath:(NSString*)path] ;
	}
	
	// Get bundleIdentifier
	NSString* bundleIdentifier = nil ;
	if (bundle) {
		bundleIdentifier = [bundle bundleIdentifier] ;
	}
	else {
		NSLog(@"Internal Error 324-2563.  %@", path) ;
	}
	
	if (!bundleIdentifier) {
		NSLog(@"Internal Error 324-4785.  %@", bundle) ;
		bundleIdentifier = @"" ;
	}

	return bundleIdentifier ;
}


+ (void)browseToURLString:(NSString*)urlString
  browserBundleIdentifier:(NSString*)browserBundleIdentifier
				 activate:(BOOL)activate {
    NSWorkspaceOpenConfiguration* configuration = [NSWorkspaceOpenConfiguration new];
    if (!activate) {
        configuration.activates = NO;
	}
	
	if (!browserBundleIdentifier) {
		// Documentation for openURLs:withAppBundleIdentifier:options:additionalEventParamDescriptor:launchIdentifiers:
		// says that the app in the "default system binding" will be used if argument withAppBundleIdentifier is
		// an empty string.  However, it was found that this is not in general the desired default web browser!
		// It is instead the user's "open with" for .html files, which some users may have incorrectly set
		// to a non-web-browser application such as Preview or BBEdit.  Fixed in Bookdog 4.3.13:
		browserBundleIdentifier = [self defaultBrowserBundleIdentifier] ;
	}
	
	NSURL* url = nil ;
	if (urlString) {
		urlString = [urlString stringByFixingFirefoxQuicksearch] ;
		url = [NSURL URLWithString:urlString] ;
	}
	
	if (url) {
		NSArray* urls = [NSArray arrayWithObject:url] ;
        NSURL* browserUrl = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:browserBundleIdentifier];
        [[NSWorkspace sharedWorkspace] openURLs:urls
                                  withApplicationAtURL:browserUrl
                                            configuration:configuration
                                        completionHandler:NULL];
	}
	else {
        /* If this is a regular, foreground, dock-resident GUI app … */
        if ([NSApp activationPolicy] == NSApplicationActivationPolicyRegular) {
            /* This happens if we are passed an invalid URL such as a
             JavaScript bookmarklet, for example…
             javascript:var%20wRWMain1=window.open('','RefWorksBookmark');d=document;i='AddToRWScript';if(d.getElementById(i))RWAddToRW1();else{s=d.createElement('script');s.type='text/javascript';s.src='http://www.refworks.com/refworks/include/addtorw.asp';s.id=i;d.getElementsByTagName('head')[0].appendChild(s);}void(0);  */
            NSBeep();
        }
	}

#if !__has_feature(objc_arc)
    [configuration release];
#endif
}

+ (NSImage*)faviconForDomain:(NSString*)domain {
	NSString* urlString = [[NSString alloc] initWithFormat:
						   @"http://%@/favicon.ico", domain] ;	
	NSImage* favicon = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:urlString]] ;
#if !__has_feature(objc_arc)
	[urlString release];
    [favicon autorelease];
#endif
    
	return favicon;
}	

@end
