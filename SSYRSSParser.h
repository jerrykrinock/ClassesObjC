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
}

- (SSYRSSParser*)initWithData:(NSData*)data
                      error_p:(NSError**)error ;
- (NSDictionary*)headerItems ;
- (NSMutableArray*)newsItems ;
- (NSString*)version ;
- (CFStringEncoding)encoding ;

@end


#if 11
@interface SSYRSSParser (Testing)

@end

@implementation SSYRSSParser (Testing)
+ (NSData*)testData {
    NSString* string =
    @"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
    @"<rss version=\"2.0\">"
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
    NSLog(@"Parsed version: %@", [parser version]) ;
    NSLog(@"Parsed encoding: %ld", (long)[parser encoding]) ;
    NSLog(@"Parsed header items:\n%@", [parser headerItems]) ;
    NSLog(@"Parsed news items:\n%@", [parser newsItems]) ;
}

@end

#endif