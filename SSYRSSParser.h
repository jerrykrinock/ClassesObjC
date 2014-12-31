#import <Cocoa/Cocoa.h>
#import <CoreFoundation/CoreFoundation.h>

extern NSString* const SSYRSSParserErrorDomain ;

@interface SSYRSSParser : NSObject <NSXMLParserDelegate> {
    NSData* m_data ;
    NSError* m_error ;
	NSDictionary* m_headerItems ;
	NSMutableArray* m_newsItems ;
	NSString* m_version ;
	NSStringEncoding m_encoding ;
    NSMutableArray* m_currentElementLineage ;
}

- (SSYRSSParser*)initWithData:(NSData*)data
                      error_p:(NSError**)error ;
- (NSDictionary*)headerItems ;
- (NSMutableArray*)newsItems ;
- (NSString*)version ;
- (NSStringEncoding)encoding ;

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
    @"<guid isPermaLink=\"false\">7bd204c6-1655-4c27-aeee-53f933c5395f</guid>"
    @"<pubDate>Sun, 06 Sep 2009 16:20:00 +0000</pubDate>"
    @"</item>"
    
    @"<item>"
    @"<title>Example entry 2</title>"
    @"<description>Here is some text containing an interesting description.</description>"
    @"<link>http://www.example.com/blog/post/1</link>"
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
    printf("*** Parsed encoding: %ld\n", (long)[parser encoding]) ;
    printf("*** Parsed header items:\n%s\n", [[[parser headerItems] description] UTF8String]) ;
    printf("*** Parsed news items:\n%s\n", [[[parser newsItems] description] UTF8String]) ;
    [parser release] ;
}

#if 0
***** Expected result from +test : *****
********************************************************************************
*** Parsed version: 2.02
*** Parsed encoding: 134217984
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
     guid = "7bd204c6-1655-4c27-aeee-53f933c5395f";
     link = "http://www.example.com/blog/post/1";
     pubDate = "Sun, 06 Sep 2009 16:20:00 +0000";
     title = "Example entry 1";
 },
 {
     description = "Here is some text containing an interesting description.";
     guid = "8bd204c6-1655-4c27-aeee-53f933c5395f";
     link = "http://www.example.com/blog/post/1";
     pubDate = "Sun, 06 Sep 2009 17:20:00 +0000";
     title = "Example entry 2";
 }
 )
********************************************************************************
#endif

@end

#endif
