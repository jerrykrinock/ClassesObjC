#import <Cocoa/Cocoa.h>


@interface NSString (FirefoxQuicksearch)

/*!
 @brief    To fix a stupid thing that happens when opening a Firefox
 "quicksearch" URL

 @details  
 @result   
*/
- (NSString*)stringByFixingFirefoxQuicksearch ;

@end


@interface SSWebBrowsing : NSObject {

}

+ (NSString*)defaultBrowserDisplayName ;

+ (NSString*)defaultBrowserBundleIdentifier ;

/*!
 @brief    

 @details  
 @param    url  
 @param    browserBundleIdentifier  bundle identifier of browser to
 be used.  Pass nil to use the user's default browser.
 @param    activate  
*/
+ (void)browseToURLString:(NSString*)url
  browserBundleIdentifier:(NSString*)browserBundleIdentifier
				 activate:(BOOL)activate ;

/*!
 @brief    

 @details  Downloads the favicon from the internet
 @param    domain  
 @result   
*/
+ (NSImage*)faviconForDomain:(NSString*)domain ;

@end
