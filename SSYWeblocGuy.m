#import "SSYWeblocGuy.h"

@interface SSYWeblocGuy ()

@property (retain) NSMutableString* xmlString ;

@end


@implementation SSYWeblocGuy

@synthesize xmlString = m_xmlString ;

- (void)dealloc {
    [m_xmlString release] ;
    
    [super dealloc] ;
}

- (void)    parser:(NSXMLParser*)parser
   didStartElement:(NSString*)elementName
	  namespaceURI:(NSString*)namespaceURI
	 qualifiedName:(NSString*)qualifiedName
		attributes:(NSDictionary*)attributeDict {
	if ([elementName isEqualToString:@"string"]) {
		// The contents are collected in parser:foundCharacters:.
		m_accumulatingUrl = YES ;
		// The mutable string needs to be reset to empty.
		[[self xmlString] setString:@""] ;
	}
}

- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName {
    m_accumulatingUrl = NO ;
}

- (void)  parser:(NSXMLParser*)parser
 foundCharacters:(NSString*)string {

    if (m_accumulatingUrl) {
        // If the current element is one whose content we care about, append 'string'
        // to the property that holds the content of the current element.
        //
        [[self xmlString] appendString:string] ;
    }
}

#if 0
- (void)     parser:(NSXMLParser*)parser
 parseErrorOccurred:(NSError*)error {
    //NSLog(@"Found error in XML: %@", error) ;
}
#endif

- (NSArray*)weblocFilenamesAndUrlsInPaths:(NSArray*)paths {
	NSMutableArray* filenamesAndURLs = [NSMutableArray array] ;
	
	for (NSString* path in paths) {
		NSString* url = nil ;
        
        NSData* data = [NSData dataWithContentsOfFile:path] ;
        if (data) {
            NSXMLParser* parser = [[NSXMLParser alloc] initWithData:data] ;
            [parser setDelegate:self] ;
            NSMutableString* xmlString = [[NSMutableString alloc] init] ;
            [self setXmlString:xmlString] ;
            [xmlString release] ;
            
            [parser parse] ;
            // Note that -parse is synchronous and will not return until the parsing
            // is done or aborted.
            [parser release] ;
            
            url = [self xmlString] ;
            
            // Not really necessary, but for resource usage efficiency we
            // release xmlString here instead of in -dealloc…
            [self setXmlString:nil] ;
        }
        
        if (url) {
			NSString* filename = [[path lastPathComponent] stringByDeletingPathExtension] ;
			
			NSDictionary* filenameAndURL = [NSDictionary dictionaryWithObjectsAndKeys:
											filename, @"filename",
											url, @"url",
											nil] ;
			
			[filenamesAndURLs addObject:filenameAndURL] ;
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
