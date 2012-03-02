#import "SSYSemaphore.h"
#import "NSFileManager+SomeMore.h"
#import "NSString+MorePaths.h"

@implementation SSYSemaphore

+ (NSString*)path {
	return [[NSString applicationSupportFolderForThisApp] stringByAppendingPathComponent:@".SSYSemaphore"] ;
}

+ (NSString*)currentKey  {
	return [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:[self path]]
								usedEncoding:NULL
									   error:NULL] ;
}


+ (BOOL)acquireWithKey:(NSString*)acquireKey
				setKey:(NSString*)newKey
		initialBackoff:(NSTimeInterval)initialBackoff
		 backoffFactor:(float)backoffFactor
			maxBackoff:(NSTimeInterval)maxBackoff
			   timeout:(NSTimeInterval)timeout
			 timeLimit:(NSTimeInterval)timeLimit 
			   error_p:(NSError**)error_p {
	NSTimeInterval backoff = initialBackoff ;
	NSDate* deadline = [NSDate dateWithTimeIntervalSinceNow:timeout] ;
	NSString* currentKey = nil ;
	NSString* path = [self path] ;
	while ([(NSDate*)[NSDate date] compare:deadline] == NSOrderedAscending) {
		currentKey = [self currentKey] ;
		BOOL requestorIsCurrentOwner = [acquireKey isEqualToString:currentKey] ;
		if (
			(!currentKey)
			// semaphore is not in use
			||
			(requestorIsCurrentOwner)
			||
			(-[[[NSFileManager defaultManager] modificationDateForPath:path] timeIntervalSinceNow] > timeLimit)	// current leasee has exceeded time limit (crashed?)
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
						 currentKey
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
	if (!ok && error_p) {
		*error_p = error ;
	}
	
	return ok ;
}

@end