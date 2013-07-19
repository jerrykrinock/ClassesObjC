#import "SSYNetServiceResolver.h"

NSString* const SSYNetServiceResolverDidFinishNotification = @"SSYNetServiceResolverDFi" ;
NSString* const SSYNetServiceResolverDidFailNotification = @"SSYNetServiceResolverDFa" ;
NSString* const SSYNetServiceResolverDidStopNotification = @"SSYNetServiceResolverDSt" ;

@interface SSYNetServiceResolver ()

@property SSYNetServiceResolverState state ;
@property (retain) NSNetService* service ;
@property (retain) NSError* error ;

@end


@implementation SSYNetServiceResolver

@synthesize state ;
@synthesize service ;
@synthesize error ;


- (void) dealloc {
	[service release] ;
	[error release] ;
	
	[super dealloc];
}

- (id) initWithService:(NSNetService*)service_
			   timeout:(NSTimeInterval)timeout {
	self = [super init] ;
	if (self != nil) {
		[service_ setDelegate:self] ;
		[service_ resolveWithTimeout:timeout] ;
		
		[self setService:service_] ;

	}
	return self ;
}

- (void)netServiceDidResolveAddress:(NSNetService*)service {
	[self setState:SSYNetServiceResolverStateDone] ;
	[[NSNotificationCenter defaultCenter] postNotificationName:SSYNetServiceResolverDidFinishNotification
														object:self] ;
}

- (void)netService:(NSNetService*)service_
	 didNotResolve:(NSDictionary *)errorInfo {
	NSError* error_ = [NSError errorWithDomain:NSNetServicesErrorDomain
										  code:[[errorInfo objectForKey:NSNetServicesErrorCode] integerValue]
									  userInfo:[NSDictionary dictionaryWithObject:service_
																		   forKey:@"service"]] ;
	[self setError:error_] ;
	[self setState:SSYNetServiceResolverStateFailed] ;
	[[NSNotificationCenter defaultCenter] postNotificationName:SSYNetServiceResolverDidFailNotification
														object:self] ;
}

- (void)netServiceDidStop:(NSNetService*)sender {
	[self setState:SSYNetServiceResolverStateStopped] ;
	[[NSNotificationCenter defaultCenter] postNotificationName:SSYNetServiceResolverDidStopNotification
														object:self] ;
}

@end