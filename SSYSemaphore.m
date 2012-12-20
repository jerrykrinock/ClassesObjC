#import "SSYSemaphore.h"
#import "NSFileManager+SomeMore.h"
#import "NSString+MorePaths.h"
#import "SSYOtherApper.h"

@implementation SSYSemaphorePidKey

+ (pid_t)pidFromString:(NSString*)string {
    pid_t pid ;
    if ([string length] < 5) {
        pid = 0 ;
    }
    else {
        pid = (pid_t)[[string substringToIndex:5] integerValue] ;
    }
    
    return pid ;
}

+ (NSString*)keyFromString:(NSString*)string {
    NSString* key ;
    if ([string length] < 5) {
        key = nil ;
    }
    else {
        key = [string substringFromIndex:5] ;
    }
    
    return key ;
}

+ (NSString*)pidStringForPid:(NSInteger)pid {
	return [NSString stringWithFormat:@"%05ld", (long)pid] ;
}

- (NSString*)string {
	return [NSString stringWithFormat:
            @"%@:%@",
            [[self class] pidStringForPid:[self pid]],
            [self string]] ;
}

@synthesize pid = m_pid ;
@synthesize key = m_key ;

- (BOOL)isEqual:(SSYSemaphorePidKey*)otherPidKey {
    if ([otherPidKey pid] != [self pid]) {
        return NO ;
    }
    if (![[otherPidKey key] isEqualToString:[self key]]) {
        return NO ;
    }
    
    return YES ;
}

- (id)initWithPid:(pid_t)pid
              key:(NSString*)key {
    self = [super init] ;
    if (self) {
        [self setPid:pid] ;
        [self setKey:key] ;
    }
    
    return self ;
}

- (void)dealloc {
    [m_key release] ;
    [super dealloc] ;
}

- (NSString*)description {
    return [self string] ;
}

+ (SSYSemaphorePidKey*)pidKeyWithPid:(pid_t)pid
                     key:(NSString*)key {
    SSYSemaphorePidKey* instance = [[self alloc] initWithPid:pid
                                             key:key] ;
    return [instance autorelease] ;
}

+ (SSYSemaphorePidKey*)pidKeyWithString:(NSString*)pidKeyString {
    NSString* key = [self keyFromString:pidKeyString] ;
    pid_t pid = [self pidFromString:pidKeyString] ;
    return [self pidKeyWithPid:pid
                           key:key] ;
}

@end


@implementation SSYSemaphore

+ (NSString*)path {
	return [[NSString applicationSupportFolderForThisApp] stringByAppendingPathComponent:@".SSYSemaphore"] ;
}

+ (SSYSemaphorePidKey*)currentPidKeyEnforcingTimeLimit:(NSTimeInterval)timeLimit  {
	NSString* currentPidKeyString = nil ;
	BOOL overlimit ;
	if (timeLimit == 0.0) {
		overlimit = NO ;
	}
	else {
		NSTimeInterval timeSinceFileModified = -[[[NSFileManager defaultManager] modificationDateForPath:[self path]] timeIntervalSinceNow] ;
        overlimit = (timeSinceFileModified > timeLimit) ;
	}
	
	if (overlimit) {
		// Current leasee has timed out
		[self clearError_p:NULL] ;
	}
	else {
		// Current leasee has not timed out
		currentPidKeyString = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:[self path]]
										  usedEncoding:NULL
												 error:NULL] ;
	}

    SSYSemaphorePidKey* currentPidKey ;
    if (currentPidKeyString) {
        currentPidKey = [SSYSemaphorePidKey pidKeyWithString:currentPidKeyString] ;
    }
    else {
        currentPidKey = nil ;
    }
    
    return currentPidKey ;
}

+ (BOOL)acquireWithKey:(NSString*)acquireKey
				setKey:(NSString*)newKey
                forPid:(pid_t)forPid
		initialBackoff:(NSTimeInterval)initialBackoff
		 backoffFactor:(CGFloat)backoffFactor
			maxBackoff:(NSTimeInterval)maxBackoff
			   timeout:(NSTimeInterval)timeout
			 timeLimit:(NSTimeInterval)timeLimit 
			   error_p:(NSError**)error_p {
	NSTimeInterval backoff = initialBackoff ;
	NSDate* deadline = [NSDate dateWithTimeIntervalSinceNow:timeout] ;
	NSString* path = [self path] ;
    SSYSemaphorePidKey* acquirePidKey = [SSYSemaphorePidKey pidKeyWithPid:forPid
                                              key:newKey] ;
    SSYSemaphorePidKey* currentPidKey = nil ;
	while ([(NSDate*)[NSDate date] compare:deadline] == NSOrderedAscending) {
		currentPidKey = [self currentPidKeyEnforcingTimeLimit:timeLimit] ;
        pid_t currentPid = [currentPidKey pid] ;
        SSYOtherApperProcessState currentProcessState = [SSYOtherApper stateOfPid:currentPid] ;
		BOOL requestorIsCurrentOwner = ((currentPid == forPid) && ([acquirePidKey isEqual:currentPidKey])) ;
		if (
			(!currentPidKey)
			// semaphore is not in use or its time limit has expired
            ||
			(requestorIsCurrentOwner)
			||
            (currentProcessState == SSYOtherApperProcessDoesNotExist)
			||
            (currentProcessState == SSYOtherApperProcessStateZombie)
			||
            (currentProcessState == SSYOtherApperProcessUnknown)
			) {
			// semaphore is available
			if (!requestorIsCurrentOwner) {
				[newKey writeToFile:path
						 atomically:YES
						   encoding:NSUTF8StringEncoding
							  error:NULL] ;
			}

			return YES ;
		}
		else {
			// semaphore is not available
			usleep( 1000000 * backoff ) ;
			backoff = backoff * backoffFactor ;
			backoff = MIN(backoff, maxBackoff) ;
		}
	}
	
	// Timeout
	if (error_p) {
		NSString* msg = [NSString stringWithFormat:
						 @"Timeout %g secs exceeded attempting to acquire semaphore with old key %@ from %@",
						 timeout,
						 acquireKey, 
						 currentPidKey
						 ] ;
		*error_p = [NSError errorWithDomain:@"SSYSystemSemaphore"
									   code:ETIME
								   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											 msg, NSLocalizedDescriptionKey,
											 nil]] ;
	}
	
	return NO ;
}

+ (BOOL)clearError_p:(NSError**)error_p {
	NSError* error ;
	BOOL ok = [[NSFileManager defaultManager] removeItemAtPath:[self path]
														 error:&error] ;
    
    // The following false-alarm fix was added in BookMacster 1.12.6
    if (!ok) {
        if ([[error domain] isEqualToString:NSCocoaErrorDomain] && ([error code] == NSFileNoSuchFileError)) {
            // The .Semaphore file has already been removed, presumably
            // by some other actor.  This is not an error.
            ok = YES ;
            error = nil ;
        }
    }

    if (!ok && error_p) {
		*error_p = error ;
	}
	
	return ok ;
}

@end