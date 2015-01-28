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
 @details  In OS X 10.10, there is some kind of bug, either in NSWorkspace or
 more likely in Safari, which causes -[NSWorkspace openURLs:::::] to fail (and
 indeed return NO) if you rapid-fire too it quickly.  Experimenting on my 2013
 13 inch MacBook Air, opening 13 URLs in Safari, I find that a 50-100
 millisecond delay is necessary between invocations of this method to avoid
 failures.  To be safe, I recommend using 500 milliseconds; since web pages
 generally take way longer than that to load, user experience is not affected.

 @param    browserBundleIdentifier  bundle identifier of browser to
 be used.  Pass nil to use the user's default browser.
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
