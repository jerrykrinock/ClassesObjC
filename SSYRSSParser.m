#import "SSYRSSParser.h"
#import "NSString+RSS.h"

NSString* const SSYRSSParserErrorDomain = @"SSYRSSParserErrorDomain" ;


@interface SSYRSSParser ()

@property (retain) NSData* data ;
@property (retain) NSError* error ;
@property (retain) NSMutableDictionary* headerItems ;
@property (retain) NSMutableArray* newsItems ;
@property (retain) NSString* version ;
@property (retain) NSMutableArray* currentElementLineage ;
@property (retain) NSMutableString* currentElementValue ;
@property (retain) NSMutableDictionary* currentItem ;

@end


@implementation SSYRSSParser

@synthesize data = m_data ;
@synthesize error = m_error ;
@synthesize headerItems = m_headerItems ;
@synthesize newsItems = m_newsItems ;
@synthesize version = m_version ;
@synthesize currentElementLineage = m_currentElementLineage ;
@synthesize currentElementValue = m_currentElementValue ;
@synthesize currentItem = m_currentItem ;

- (SSYRSSParser*)initWithData:(NSData*)data
                      error_p:(NSError**)error_p {
    if (data) {
        self = [super init] ;
        
        if (self) {
            [self setData:data] ;

            id object ;

            object = [[NSMutableDictionary alloc] init] ;
            [self setHeaderItems:object] ;
            [object release] ;
            
            object = [[NSMutableArray alloc] init] ;
            [self setNewsItems:object] ;
            [object release] ;
            
            object = [[NSMutableArray alloc] init] ;
            [self setCurrentElementLineage:object] ;
            [object release] ;
            
            object = [[NSMutableString alloc] init] ;
            [self setCurrentElementValue:object] ;
            [object release] ;
            
            object = [[NSMutableDictionary alloc] init] ;
            [self setCurrentItem:object] ;
            [object release] ;
            
            NSXMLParser* parser = [[NSXMLParser alloc] initWithData:data] ;
            [parser setDelegate:self] ;
            [parser setShouldResolveExternalEntities:YES] ;
            [parser parse] ;
            [parser release] ;
            
            if ([self error]) {
                [self release] ;
                self = nil ;
                if (error_p) {
                    *error_p = [self error] ;
                }
            }
        }
    }
    
    return self ;
}

- (void) dealloc {
    [m_data release] ;
    [m_error release] ;
	[m_headerItems release] ;
	[m_newsItems release] ;
	[m_version release] ;
    [m_currentElementLineage release] ;
    [m_currentElementValue release] ;
    [m_currentItem release] ;
	
	[super dealloc] ;
}


#pragma mark * NSXMLParser Delegate Methods

-(void)     parser:(NSXMLParser*)parser
   didStartElement:(NSString*)elementName
      namespaceURI:(NSString*)namespaceURI
     qualifiedName:(NSString*)qualifiedName
        attributes:(NSDictionary*)attributes {
    [[self currentElementLineage] addObject:elementName] ;
    if ([[self currentElementLineage] isEqualToArray:@[@"rss"]]) {
        [self setVersion:[attributes objectForKey:@"version"]] ;
    }
}

- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qualifiedName {
    if ([elementName isEqualToString:[[self currentElementLineage] lastObject]]) {
        [[self currentElementLineage] removeLastObject] ;
        NSString* value ;
        if ([[self currentElementLineage] isEqualToArray:@[@"rss", @"channel", @"item"]]) {
            value = [[self currentElementValue] copy] ;
            [[self currentItem] setObject:value
                                   forKey:elementName] ;
            [value release] ;
        }
        else if ([[self currentElementLineage] isEqualToArray:@[@"rss", @"channel"]]) {
            if ([elementName isEqualToString:@"item"]) {
                NSDictionary* currentItem = [[self currentItem] copy] ;
                [[self newsItems] addObject:currentItem] ;
                [currentItem release] ;
                [[self currentItem] removeAllObjects] ;
            }
            else {
                value = [[self currentElementValue] copy] ;
                [[self headerItems] setObject:value
                                       forKey:elementName] ;
                [value release] ;
            }
        }
        [[self currentElementValue] setString:@""] ;
    }
    else {
        [self setError:[NSError errorWithDomain:SSYRSSParserErrorDomain
                                           code:672902
                                       userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                 @"Element start/end mismatch", NSLocalizedDescriptionKey,
                                                 [[self currentElementLineage] lastObject], @"Start",
                                                 elementName, @"End",
                                                 nil]]] ;
        [parser abortParsing] ;
    }
}

- (void)  parser:(NSXMLParser*)parser
 foundCharacters:(NSString*)string {
    [[self currentElementValue] appendString:string] ;
}

- (NSData*)         parser:(NSXMLParser*)parser
 resolveExternalEntityName:(NSString*)name
                  systemID:(NSString*)systemID {
    return nil ;
}

- (void)     parser:(NSXMLParser*)parser
 parseErrorOccurred:(NSError*)parserError {
    NSError* error = [NSError errorWithDomain:SSYRSSParserErrorDomain
                                         code:672901
                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                               @"Error occurred while parsing RSS data", NSLocalizedDescriptionKey,
                                               [NSNumber numberWithInteger:(long)[[self data] length]], @"Data Byte Count",
                                               parserError, NSUnderlyingErrorKey,
                                               nil]] ;
    [self setError:error] ;
}

@end