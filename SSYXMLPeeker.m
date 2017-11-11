#import "SSYXMLPeeker.h"
#import "SSY_ARC_OR_NO_ARC.h"

@interface SSYXMLPeeker ()

@property (retain) NSMutableString* parsedValue ;
@property (retain) NSString* targetElement ;
@property (retain) NSError* error ;

@end


@implementation SSYXMLPeeker

@synthesize parsedValue = m_parsedValue ;
@synthesize targetElement = m_targetElement ;
@synthesize error = m_error ;

#if !__has_feature(objc_arc)
- (void)dealloc {
    [m_parsedValue release] ;
    [m_targetElement release] ;
    [m_error release] ;
	
	[super dealloc] ;
}
#endif

- (NSString*)stringValueOfElement:(NSString*)targetElement
                      XMLFilePath:(NSString*)path {
    NSURL* url = [NSURL fileURLWithPath:path] ;
    NSXMLParser* parser = [[NSXMLParser alloc] initWithContentsOfURL:url] ;
    [parser setDelegate:self] ;
    [self setTargetElement:targetElement] ;
    [self setError:nil] ;
    
    [parser parse] ;
    // Note that -parse is synchronous and will not return until the parsing
    // is done or aborted.

    
#if !__has_feature(objc_arc)
    [parser release] ;
#endif
    return [self parsedValue] ;
}

+ (NSString*)stringValueOfElement:(NSString*)targetElement
                      XMLFilePath:(NSString*)path
                          error_p:(NSError**)error_p {
    SSYXMLPeeker* peeker = [[self alloc] init] ;
    NSString* answer = [peeker stringValueOfElement:targetElement
                                        XMLFilePath:path] ;
    if (error_p) {
        *error_p = [peeker error] ;
    }
    
#if !__has_feature(objc_arc)
    [peeker release] ;
#endif
    
    return answer ;
}


#pragma mark * NSXMLParser Delegate Methods

- (void)    parser:(NSXMLParser*)parser
   didStartElement:(NSString*)elementName
	  namespaceURI:(NSString*)namespaceURI
	 qualifiedName:(NSString*)qualifiedName
		attributes:(NSDictionary*)attributeDict {
    if ([elementName isEqualToString:[self targetElement]]) {
        NSMutableString* emptyString = [[NSMutableString alloc] init] ;
        [self setParsedValue:emptyString] ;
#if !__has_feature(objc_arc)
        [emptyString release] ;
#endif
    }
}

- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName {
    if ([elementName isEqualToString:[self targetElement]]) {
        [parser abortParsing] ;
        // When we send -abortParsing, NSXMLParser invokes -parser:parseErrorOccurred:,
        // announcing the abortion as an error, when of course it is not an error.
        // And by some magic it does not do this synchronously but does so *after*
        // this method returns.  So [self setError:nil] at this point does not
        // clear the error.  We therefore do this kludge instead:
        if (![self error]) {
            m_ignoreError = YES ;
        }
    }
}

- (void)  parser:(NSXMLParser*)parser
 foundCharacters:(NSString*)string {
    if ([self parsedValue]) {
        /* For some reason, this method is invoked by the parser when it parses
         elements that don't have string values, and the value of 'string' is
         a single line feed.  We now filter those out. */
        string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ;
        [[self parsedValue] appendString:string] ;
    }
}

- (void)     parser:(NSXMLParser*)parser
 parseErrorOccurred:(NSError*)error {
    if (!m_ignoreError) {
        [self setError:error] ;
    }
}

@end
