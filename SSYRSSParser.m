#import "SSYRSSParser.h"
#import "NSString+RSS.h"

NSString* const SSYRSSParserErrorDomain = @"SSYRSSParserErrorDomain" ;
#if 0
#define titleKey @"title"
#define linkKey @"link"
#define descriptionKey @"description"
#endif


@interface SSYRSSParser ()

@property NSData* data ;
@property NSError* error ;
@property NSDictionary* headerItems ;
@property NSMutableArray* newsItems ;
@property NSString* version ;
@property NSStringEncoding encoding ;

@end


@implementation SSYRSSParser

@synthesize data = m_data ;
@synthesize error = m_error ;
@synthesize headerItems = m_headerItems ;
@synthesize newsItems = m_newsItems ;
@synthesize version = m_version ;
@synthesize encoding = m_encoding ;

- (SSYRSSParser*)initWithData:(NSData*)data
                      error_p:(NSError**)error_p {
    if (data) {
        self = [super init] ;
        
        if (self) {
            [self setData:data] ;
            
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
	
	[super dealloc] ;
}


#pragma mark * NSXMLParser Delegate Methods

-(void)     parser:(NSXMLParser*)parser
   didStartElement:(NSString*)elementName
      namespaceURI:(NSString*)namespaceURI
     qualifiedName:(NSString*)qualifiedName
        attributes:(NSDictionary*)attributes {
    /*SSYDBL*/ NSLog(@"didStart") ;
    /*SSYDBL*/ NSLog(@"    elementName: %@", elementName) ;
    /*SSYDBL*/ NSLog(@"   namespaceURI: %@", namespaceURI) ;
    /*SSYDBL*/ NSLog(@"  qualifiedName: %@", qualifiedName) ;
    /*SSYDBL*/ NSLog(@"     attributes: %@", attributes) ;
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