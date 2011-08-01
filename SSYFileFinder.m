#import "SSYFileFinder.h"

@implementation SSYFileFinder

@synthesize callbackTarget ;
@synthesize query ;

- (id)initWithPredicate:(NSPredicate*)predicate
		 callbackTarget:(id)callbackTarget_
	   callbackSelector:(SEL)callbackSelector_ {
    if (self = [super init]) {
        self.query = [[[NSMetadataQuery alloc] init] autorelease] ;
		self.callbackTarget = callbackTarget_ ;
		callbackSelector = callbackSelector_ ;
        
        // To watch results send by the query, add an observer to the NSNotificationCenter
        [[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(queryNotification:)
													 name:nil
												   object:self.query] ;
        
        // We want the items in the query to automatically be sorted by the file system name.
		// This way, we don't have to do any special sorting
        [self.query setSortDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:(id)kMDItemFSName
																							 ascending:YES] autorelease]]] ;
        // So that we'll get that callback
        [self.query setDelegate:self] ;
        
		// Set predicate to query and start searching
		[self.query setPredicate:predicate] ;           		
		[self.query startQuery] ; 
    }
    return self ;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [query release] ;
	[callbackTarget release] ;
	
    [super dealloc];
}

- (void)queryNotification:(NSNotification *)notification {
    if ([[notification name] isEqualToString:NSMetadataQueryDidFinishGatheringNotification]) {
		NSArray* results = [[notification object] results] ;
		NSMutableArray* paths = [NSMutableArray array] ;
		for (NSMetadataItem* item in results) {
			[paths addObject:[item valueForAttribute:(id)kMDItemPath]] ;		
		}
		[[self callbackTarget] performSelector:callbackSelector
									withObject:[NSArray arrayWithArray:paths]] ;
		// Now, self-destruct
		[self release] ;
	}
}


+ (void)findPathsWithPredicate:(NSPredicate*)predicate
			   callbackTarget:(id)callbackTarget
			 callbackSelector:(SEL)callbackSelector {
	[[SSYFileFinder alloc] initWithPredicate:predicate
							  callbackTarget:callbackTarget
							callbackSelector:callbackSelector] ;
	// This instance will release itself, in -queryNotification, when the
	// NSMetadataQueryDidFinishGatheringNotification notification is received.
}

+ (void)findPathsWithFilename:(NSString*)filename
			   callbackTarget:(id)callbackTarget
			 callbackSelector:(SEL)callbackSelector {
	NSPredicate* predicate = [NSComparisonPredicate
							  predicateWithLeftExpression:[NSExpression expressionForKeyPath:(NSString*)kMDItemDisplayName]
							  rightExpression:[NSExpression expressionForConstantValue:filename]
							  modifier:NSDirectPredicateModifier
							  type:NSEqualToPredicateOperatorType
							  options:0] ;
	[self findPathsWithPredicate:predicate
				  callbackTarget:callbackTarget
				callbackSelector:callbackSelector] ;
}

@end
