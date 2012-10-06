#import "SSYMachaphore.h"

static SSYMachaphore* sharedMachaphore = nil ;

@implementation SSYMachaphore

@synthesize name ;
@synthesize port = m_port ;
@synthesize initialBackoff ;
@synthesize backoffFactor ;
@synthesize maxBackoff ;
@synthesize timeout ;

- (void)setName:(NSString*)name_
 initialBackoff:(NSTimeInterval)initialBackoff_
  backoffFactor:(CGFloat)backoffFactor_
	 maxBackoff:(NSTimeInterval)maxBackoff_
		timeout:(NSTimeInterval)timeout_ {
	[self setName:name_] ;
	[self setInitialBackoff:initialBackoff_] ;
	[self setBackoffFactor:backoffFactor_] ;
	[self setMaxBackoff:maxBackoff_] ;
	[self setTimeout:timeout_] ;
}

+ (SSYMachaphore*)sharedMachaphore {
	@synchronized(self) {
        if (!sharedMachaphore) {
            sharedMachaphore = [[self alloc] init] ;
        }
    }
	
	// No autorelease.  This sticks around forever.
    return sharedMachaphore ;
}

- (void)dealloc {
	[name release] ;
	[m_port release] ;
	
	[super dealloc] ;
}

- (BOOL)lockError_p:(NSError**)error_p {
	NSTimeInterval backoff = [self initialBackoff] ;
	NSDate* deadline = [NSDate dateWithTimeIntervalSinceNow:[self timeout]] ;
	while ([(NSDate*)[NSDate date] compare:deadline] == NSOrderedAscending) {
		[self setPort:[NSPort port]] ;
		if ([[NSPortNameServer systemDefaultPortNameServer] registerPort:[self port]
																	name:[self name]]) {
			// Got machaphore
			return YES ;
		}
		else {
			// machaphore is not available
			usleep( 1000000 * backoff ) ;
			backoff = backoff * [self backoffFactor] ;
			backoff = MIN(backoff, [self maxBackoff]) ;
		}
	}
	
	// Timeout
	if (error_p) {
		NSString* msg = [NSString stringWithFormat:
						 @"Timeout %g secs exceeded attempting to acquire '%@'",
						 [self timeout],
						 [self name]
						 ] ;
		*error_p = [NSError errorWithDomain:@"SSYSystemMachaphore"
									   code:ETIME
								   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											 msg, NSLocalizedDescriptionKey,
											 nil]] ;
	}
	
	return NO ;
}

- (BOOL)relinquish {
	NSPort* port = [self port] ;
	if (port) {
		[port invalidate] ;
		[self setPort:nil] ;
		return YES ;
	}
	
	return NO ;
}

@end
