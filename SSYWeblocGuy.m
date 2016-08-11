#import "SSYWeblocGuy.h"

/* Prior to 2016-08-10, this class did not have a proper state machine for
 parsing the XML expected in a .webloc file.  I just took the last string that
 was parsed.  This worked because there are only two strings in the file:
    <key>URL</key>
    <string>http://www.example.com</string>
 and the second one was the one I wanted.  And so I marked a TODO to fix
 this someday.
 
 Now, it is fixed, but I'm no sure if it is better or worse.  The goal is to
 future-proof in case Apple changes the .webloc format.  But after looking at
 this state machine, I'm not sure it's really any more future proof.  It is
 definitely less cheesy.  Oh, well, the old code is in git if I want to go back.
 */

typedef enum {
    SSYWeblocParserStateZero,
    SSYWeblocParserStateInPlist,
    SSYWeblocParserStateInDict,
    SSYWeblocParserStateParsingAKey,
    SSYWeblocParserStateParsingUrlString,
    SSYWeblocParserStateGotAllWeNeed
} SSYWeblocParserState ;


@interface SSYWeblocGuy ()

@property (retain) NSMutableString* stringBeingParsed ;
@property (assign) SSYWeblocParserState parserState ;

@end


@implementation SSYWeblocGuy

- (void)dealloc {
    [_stringBeingParsed release] ;
    
    [super dealloc] ;
}

- (void)    parser:(NSXMLParser*)parser
   didStartElement:(NSString*)elementName
	  namespaceURI:(NSString*)namespaceURI
	 qualifiedName:(NSString*)qualifiedName
		attributes:(NSDictionary*)attributeDict {
    if ((_parserState == SSYWeblocParserStateZero) && [elementName isEqualToString:@"plist"]) {
        _parserState = SSYWeblocParserStateInPlist ;
    }
    else if ((_parserState == SSYWeblocParserStateInPlist) && [elementName isEqualToString:@"dict"]) {
        _parserState = SSYWeblocParserStateInDict ;
    }
    else if ((_parserState == SSYWeblocParserStateInDict) && [elementName isEqualToString:@"key"]) {
        _parserState = SSYWeblocParserStateParsingAKey ;
    }
    else if ((_parserState == SSYWeblocParserStateParsingUrlString) && [elementName isEqualToString:@"string"]) {
        if ([self.stringBeingParsed isEqualToString:@"URL"]) {
            _parserState = SSYWeblocParserStateParsingUrlString ;
            [self.stringBeingParsed setString:@""] ;
        }
    }
}

- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName {
    if ((_parserState == SSYWeblocParserStateParsingAKey) && [elementName isEqualToString:@"key"]) {
        _parserState = SSYWeblocParserStateParsingUrlString ;
    }
    if ((_parserState == SSYWeblocParserStateParsingUrlString) && [elementName isEqualToString:@"string"]) {
        _parserState = SSYWeblocParserStateGotAllWeNeed ;
    }
}

- (void)  parser:(NSXMLParser*)parser
 foundCharacters:(NSString*)string {
    if ((_parserState ==SSYWeblocParserStateParsingAKey) || (_parserState == SSYWeblocParserStateParsingUrlString)) {
        /* I have not investigated why this method gets invoked with 
         string = @"\n" in between the real strings.  I just filter them out… */
        [[self stringBeingParsed] appendString:[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]] ;
    }
}

- (void)     parser:(NSXMLParser*)parser
 parseErrorOccurred:(NSError*)error {
    NSLog(@"Found error in XML: %@", error) ;
}

- (NSDictionary*)filenameAndUrlFromWeblocFileAtPath:(NSString*)path {
    NSString* url = nil ;
    if ([path.pathExtension isEqualToString:@"webloc"]) {
        NSData* data = [NSData dataWithContentsOfFile:path] ;
        
        /* The .webloc files produced by Safari 9.0 (macOS 10.11) or later
         are .plist files.  Look for that first. */
        NSDictionary* dic = [NSPropertyListSerialization propertyListWithData:data
                                                                      options:0
                                                                       format:NULL
                                                                        error:NULL] ;
        url = [dic objectForKey:@"URL"] ;

        if (!url) {
            /* We are parsing a .webloc file produced by Safari 5 - 8, which
             uses XML format. */
            if (data.length > 0) {
                NSXMLParser* parser = [[NSXMLParser alloc] initWithData:data] ;
                [parser setDelegate:self] ;
                self.parserState = SSYWeblocParserStateZero ;
                NSMutableString* stringBeingParsed = [NSMutableString new] ;
                self.stringBeingParsed = stringBeingParsed ;
                [stringBeingParsed release] ;
                [parser parse] ;
                /* Note: -parse is synchronous and will not return until the parsing
                 is done or aborted. */
                [parser release] ;
                
                url = [self.stringBeingParsed copy] ;
                [url autorelease] ;
                self.stringBeingParsed = nil ;
            }
        }
    }
    
    NSDictionary* answer ;
    if (url.length > 0) {
        NSString* filename = [[path lastPathComponent] stringByDeletingPathExtension] ;
        answer = [NSDictionary dictionaryWithObjectsAndKeys:
                  [filename stringByDeletingPathExtension], @"filename",
                  url, @"url",
                  nil] ;
    }
    else {
        answer = nil ;
    }
    
    return answer ;
}

+ (NSDictionary*)filenameAndUrlFromWeblocFileAtPath:(NSString*)path {
    SSYWeblocGuy* instance = [[SSYWeblocGuy alloc] init] ;
    NSDictionary* answer = [instance filenameAndUrlFromWeblocFileAtPath:path] ;
    [instance release] ;
    
    return answer ;
}

- (NSArray*)weblocFilenamesAndUrlsInPaths:(NSArray*)paths {
	NSMutableArray* filenamesAndURLs = [NSMutableArray array] ;
	
	for (NSString* path in paths) {
        NSDictionary* filenameAndUrl = [self filenameAndUrlFromWeblocFileAtPath:path] ;
        if (filenameAndUrl) {
            [filenamesAndURLs addObject:filenameAndUrl] ;
        }
    }
	
	if ([filenamesAndURLs count])
		return [[[NSArray alloc] initWithArray:filenamesAndURLs] autorelease] ;
	else
		return nil ;	
}

+ (NSArray*)weblocFilenamesAndUrlsInPaths:(NSArray*)paths {
    SSYWeblocGuy* instance = [[SSYWeblocGuy alloc] init] ;
    NSArray* answer = [instance weblocFilenamesAndUrlsInPaths:paths] ;
    [instance release] ;
    
    return answer ;
}

@end
