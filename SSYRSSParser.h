#import <Cocoa/Cocoa.h>
#import <CoreFoundation/CoreFoundation.h>

extern NSString* const SSYRSSParserErrorDomain ;

/*!
 @brief    A class for parsing RSS feeds
 
 @detail   I made this as a pretty much drop-in replacement for Brent Simmons'
 'RSS' class which he published in year 2002, and which was based on the
 now-deprecated CFXMLParser.  This class is based on NSXMLParser instead.
 */
@interface SSYRSSParser : NSObject <NSXMLParserDelegate> {
    NSData* m_data ;
    NSError* m_error ;
	NSMutableDictionary* m_headerItems ;
	NSMutableArray* m_newsItems ;
	NSString* m_version ;
    NSMutableArray* m_currentElementLineage ;
    NSMutableString* m_currentElementValue ;
    NSMutableDictionary* m_currentItem ;
}

/*!
 @brief    Designated initializer for SSYRSS class
 
 @detail   Synchronously parses .
 */
- (SSYRSSParser*)initWithData:(NSData*)data
                      error_p:(NSError**)error ;
- (NSMutableDictionary*)headerItems ;
- (NSMutableArray*)newsItems ;
- (NSString*)version ;

@end


#if 11
@interface SSYRSSParser (Testing)
+ (void)test ;
@end

@implementation SSYRSSParser (Testing)
+ (NSData*)testData {
    NSString* string =
    @"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
    @"<rss version=\"2.02\">"
    @"<channel>"
    @"<title>RSS Title</title>"
    @"<description>This is an example of an RSS feed</description>"
    @"<link>http://www.example.com/main.html</link>"
    @"<lastBuildDate>Mon, 06 Sep 2010 00:01:00 +0000 </lastBuildDate>"
    @"<pubDate>Sun, 06 Sep 2009 16:20:00 +0000</pubDate>"
    @"<ttl>1800</ttl>"
    
    @"<item>"
    @"<title>Example entry 1</title>"
    @"<description>Here is some text containing an interesting description.</description>"
    @"<link>http://www.example.com/blog/post/1</link>"
    @"<guid isPermaLink=\"false\">7bd204c6-1655-4c27-aeee-53f933c53900</guid>"
    @"<pubDate>Sun, 06 Sep 2009 16:20:00 +0000</pubDate>"
    @"</item>"
    
    @"<item>"
    @"<title>Example entry 2</title>"
    @"<description>Here is some text containing an interesting description.</description>"
    @"<link>http://www.example.com/blog/post/2</link>"
    @"<guid isPermaLink=\"false\">8bd204c6-1655-4c27-aeee-53f933c5395f</guid>"
    @"<pubDate>Sun, 06 Sep 2009 17:20:00 +0000</pubDate>"
    @"</item>"
    
    @"</channel>"
    @"</rss>" ;
    return [string dataUsingEncoding:NSUTF8StringEncoding] ;
}


+ (void)test {
    NSError* error ;
    SSYRSSParser* parser = [[SSYRSSParser alloc] initWithData:[self testData]
                                                      error_p:&error] ;
    printf("*** Parsed version: %s\n", [[[parser version] description] UTF8String]) ;
    printf("*** Parsed header items:\n%s\n", [[[parser headerItems] description] UTF8String]) ;
    printf("*** Parsed news items:\n%s\n", [[[parser newsItems] description] UTF8String]) ;
    [parser release] ;
}

#if 0
***** Expected result from +test : *****
********************************************************************************
*** Parsed version: 2.02
*** Parsed header items:
{
    description = "This is an example of an RSS feed";
    lastBuildDate = "Mon, 06 Sep 2010 00:01:00 +0000 ";
    link = "http://www.example.com/main.html";
    pubDate = "Sun, 06 Sep 2009 16:20:00 +0000";
    title = "RSS Title";
    ttl = 1800;
}
*** Parsed news items:
(
 {
     description = "Here is some text containing an interesting description.";
     guid = "7bd204c6-1655-4c27-aeee-53f933c53900";
     link = "http://www.example.com/blog/post/1";
     pubDate = "Sun, 06 Sep 2009 16:20:00 +0000";
     title = "Example entry 1";
 },
 {
     description = "Here is some text containing an interesting description.";
     guid = "8bd204c6-1655-4c27-aeee-53f933c5395f";
     link = "http://www.example.com/blog/post/2";
     pubDate = "Sun, 06 Sep 2009 17:20:00 +0000";
     title = "Example entry 2";
 }
 )
********************************************************************************
#endif

@end

#endif
