#import "SSYPoller.h"


@implementation SSYPoller

+ (BOOL)waitUntilInvocation:(NSInvocation*)invocation
			 initialBackoff:(NSTimeInterval)initialBackoff
			  backoffFactor:(float)backoffFactor
				 maxBackoff:(NSTimeInterval)maxBackoff
					timeout:(NSTimeInterval)timeout
				  timeLimit:(NSTimeInterval)timeLimit
				 debugLabel:(NSString*)debugLabel
					error_p:(NSError**)error_p {
	NSTimeInterval backoff = initialBackoff ;
	NSDate* deadline = [NSDate dateWithTimeIntervalSinceNow:timeout] ;
	BOOL clearToGo ;
	while ([(NSDate*)[NSDate date] compare:deadline] == NSOrderedAscending) {
		[invocation invoke] ;
		[invocation getReturnValue:&clearToGo] ;
		if (clearToGo) {
			return YES ;
		}
		else {
			usleep( 1000000 * backoff ) ;
			backoff = backoff * backoffFactor ;
			backoff = MIN(backoff, maxBackoff) ;
		}
	}
	
	// Timeout
	if (error_p) {
		NSString* msg = [NSString stringWithFormat:
						 @"Timeout %g secs exceeded waiting for %@",
						 timeout,
						 debugLabel // may be nil
						 ] ;
		*error_p = [NSError errorWithDomain:@"SSYPoller"
									   code:ETIME
								   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											 msg, NSLocalizedDescriptionKey,
											 debugLabel, @"Waiting for", // may be nil ;
											 nil]] ;
	}
	
	return NO ;
}

@end
