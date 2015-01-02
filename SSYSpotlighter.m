#import "SSYSpotlighter.h"

@interface SSYSpotlighter ()

@property (copy) NSString* searchKey ;
@property (assign) NSObject <SSYSpotlighterDelegate> * delegate ;
@property (retain) NSMetadataQuery *query;

@end


@implementation SSYSpotlighter

@synthesize searchKey = m_searchKey ;
@synthesize delegate = m_delegate ;
@synthesize query = m_query ;


- (id)initWithSearchKey:(NSString*)searchKey
               delegate:(NSObject <SSYSpotlighterDelegate> *)delegate {
    self = [super init] ;
    if (self) {
        [self setSearchKey:searchKey] ;
        [self setDelegate:delegate] ;
    }

    return self ;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self] ;
    [m_query removeObserver:self
                 forKeyPath:@"results"] ;

    [m_searchKey release] ;
    [m_query release] ;

    [super dealloc] ;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    NSUInteger currentResultsCount = [[self query] resultCount] ;
    NSMutableArray* newPaths = [[NSMutableArray alloc] init] ;
    for (NSUInteger i=m_resultsAlreadyReported; i<currentResultsCount; i++) {
        NSString* path = [[[self query] resultAtIndex:i] valueForKey:(NSString*)kMDItemPath] ;
        // Defensive programming
        if (path) {
            [newPaths addObject:path] ;
        }
    }
    NSArray* answer = [newPaths copy] ;
    [newPaths release] ;
    [[self delegate] spotlighter:self
                    didFindPaths:answer] ;
    [answer release] ;

    m_resultsAlreadyReported = currentResultsCount ;
}

- (void)queryNote:(NSNotification *)note {
    if ([[note name] isEqualToString:NSMetadataQueryDidFinishGatheringNotification]) {
        [[self query] stopQuery] ;
        [[self delegate] didFinishSpotlighter:self] ;
    }
}

- (void)start {
    if (![[NSThread currentThread] isMainThread]) {
        NSLog(@"SSYSpotlighter-NSMetadataQuery started on non-main thread.  This will not work.") ;
        return ;
    }
    NSMetadataQuery* query = [[[NSMetadataQuery alloc] init] autorelease] ;
    [self setQuery:query] ;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(queryNote:)
                                                 name:nil
                                               object:[self query]] ;
    
    [query addObserver:self
            forKeyPath:@"results"
               options:0
               context:NULL] ;
    
    // Create a compound predicate that searches for any keypath which has a value like the search key. This broadens the search results to include things such as the author, title, and other attributes not including the content. This is done in code for two reasons: 1. The predicate parser does not yet support "* = Foo" type of parsing, and 2. It is an example of creating a predicate in code, which is much "safer" than using a search string.
    NSUInteger options = (NSCaseInsensitivePredicateOption|NSDiacriticInsensitivePredicateOption) ;
    NSPredicate *pred = [NSComparisonPredicate
                         predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"*"]
                         rightExpression:[NSExpression expressionForConstantValue:[self searchKey]]
                         modifier:NSDirectPredicateModifier
                         type:NSLikePredicateOperatorType
                         options:options] ;
    
    // Exclude email messages and contacts
    NSPredicate* exclusionPredicate = [NSPredicate predicateWithFormat:@"(kMDItemContentType != 'com.apple.mail.emlx') && (kMDItemContentType != 'public.vcard')"];
    pred = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:
                                                               pred,
                                                               exclusionPredicate,
                                                               nil]] ;
    
    [query setPredicate:pred] ;
    [query startQuery] ;
}

@end
