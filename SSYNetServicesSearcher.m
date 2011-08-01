#import "SSYNetServicesSearcher.h"
#import "NSArray+SimpleMutations.h"
#import "NSDictionary+SimpleMutations.h"

NSString* const SSYNetServicesSearcherDidFindDomainNotification = @"SSYNetServicesSearcherDFD" ;
NSString* const SSYNetServicesSearcherDidFindServiceNotification = @"SSYNetServicesSearcherDFS" ;
NSString* const SSYNetServicesSearcherDidFinishNotification = @"SSYNetServicesSearcherDFi" ;
NSString* const SSYNetServicesSearcherDidFailNotification = @"SSYNetServicesSearcherDFa" ;

@interface SSYNetServicesSearcher ()

@property (retain) NSDictionary* targets ;
@property SSYNetServicesSearcherState state ;
@property (retain) NSMutableArray* domains ;
@property (retain) NSMutableArray* services ;
@property (retain) NSMutableArray* targetTypesForCurrentDomain ;
@property (retain) NSNetServiceBrowser* browser ;
@property (retain) NSError* error ;

@end


@implementation SSYNetServicesSearcher

@synthesize targets ;
@synthesize state ;
@synthesize domains ;
@synthesize services ;
@synthesize targetTypesForCurrentDomain ;
@synthesize browser ;
@synthesize error ;

- (void) dealloc {
	[targets release] ;
	[browser release] ;
	[domains release] ;
	[services release] ;
	[targetTypesForCurrentDomain release] ;
	[error release] ;
	
	[super dealloc];
}

- (id) initWithTargets:(NSDictionary*)targets_ {
	self = [super init] ;
	if (self != nil) {
		[self setTargets:targets_] ;
		domains = [[NSMutableArray alloc] init] ;
		services =[[NSMutableArray alloc] init] ;
		
		// Create browser
		browser = [[NSNetServiceBrowser alloc] init] ;
		[browser setDelegate:self] ;
		
		// Begin search for domains
		[browser searchForRegistrationDomains] ;
		[self setState:SSYNetServicesSearcherStateSearchingForDomains] ;
	}
	return self;
}

/*
- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)netServiceBrowser {
	// New search has begun.
	// I don't seem to have any use for this.
}
*/


- (void)searchForServicesInNextDomain {
	if ([[self domains] count] < 1) {
		[self setState:SSYNetServicesSearcherStateDone] ;
		[[NSNotificationCenter defaultCenter] postNotificationName:SSYNetServicesSearcherDidFinishNotification
															object:self] ;
	}
	else {
		NSString* domain = [[self domains] objectAtIndex:0] ;
		[[self domains] removeObjectAtIndex:0] ;
		
		if ([[[self targets] allKeys] indexOfObject:domain] != NSNotFound) {
			NSArray* types = [[self targets] objectForKey:domain] ;
			if ([types count] < 1) {
				[[self domains] removeObjectAtIndex:0] ;
				[self searchForServicesInNextDomain] ;
			}
			else {
				// This domain is one of our targets, and it has at least
				// one more target type which we've not searched for yet.
				
				// Get the next type and remove it from our targets
				NSString* type = [types objectAtIndex:0] ;
				types = [types arrayByRemovingObjectAtIndex:0] ;
				[self setTargets:[[self targets] dictionaryBySettingValue:types
																   forKey:domain]] ;
				
				// Search this domain for this type.
				
				// One little thing they don't tell you in the NSNetServiceBrowser
				// documentation is this little fact I found in a listserv archive:
				// "NSNetServiceBrowsers can only do one thing at a time, really -
				// if you want to search for services of a given type within the
				// domain you just found, you should create a new NSNetServiceBrowser
				// for that domain, and start -that- searching on the domain."
				[browser stop] ;
				[browser release] ;
				browser = [[NSNetServiceBrowser alloc] init] ;
				[browser setDelegate:self] ;
				// Otherwise, it quits immediately with error NSNetServicesActivityInProgress
				
				// Ok, we're ready to do the next search.
				[browser searchForServicesOfType:type
										inDomain:domain] ;
			}
		}
		else {
			[self searchForServicesInNextDomain] ;
		}
	}
}


- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser
			didFindDomain:(NSString *)domainName
			   moreComing:(BOOL)moreDomainsComing {
	[[self domains] addObject:domainName] ;
	[[NSNotificationCenter defaultCenter] postNotificationName:SSYNetServicesSearcherDidFindDomainNotification
														object:self] ;
	if (!moreDomainsComing) {
		[self setState:SSYNetServicesSearcherStateSearchingForServices] ;
		[self searchForServicesInNextDomain] ;
	}
}

- (void)netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser
		   didFindService:(NSNetService*)netService
			   moreComing:(BOOL)moreServicesComing {
	[[self services] addObject:netService] ;
	[[NSNotificationCenter defaultCenter] postNotificationName:SSYNetServicesSearcherDidFindServiceNotification
														object:self] ;
	if (!moreServicesComing) {
		[self searchForServicesInNextDomain] ;
	}
}

- (void)netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser
			 didNotSearch:(NSDictionary*)errorInfo {
	NSError* error_ = [NSError errorWithDomain:NSNetServicesErrorDomain
										  code:[[errorInfo objectForKey:NSNetServicesErrorCode] intValue]
									  userInfo:[NSDictionary dictionaryWithObject:[self domains]
																		   forKey:@"Domains found so far"]] ;
	[self setError:error_] ;
	[self setState:SSYNetServicesSearcherStateFailed] ;
	[[NSNotificationCenter defaultCenter] postNotificationName:SSYNetServicesSearcherDidFailNotification
														object:self] ;
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser*)netServiceBrowser {
	[self setState:SSYNetServicesSearcherStateStopped] ;
}

@end