#import "SSYSystemSemaphore.h"

static SSYSystemSemaphore* sharedSemaphore = nil ;

@implementation SSYSystemSemaphore

+ (void)setError_p:(NSError**)error_p
		 withErrno:(NSInteger)semErrno {
	if (!error_p) {
		return ;
	}
	
	NSString* errDesc = nil ;
	switch (semErrno) {
		case EACCES:
			errDesc = @"The required permissions (for reading and/or writing) are denied for the given flags; or O_CREAT is specified, the object does not exist, and permission to create the semaphore is denied." ;
			break;
		case EEXIST:
			errDesc = @"O_CREAT and O_EXCL were specified and the semaphore exists." ;
			break;
		case EINTR:
			errDesc = @"The sem_open() operation was interrupted by a signal." ;
			break;
		case EINVAL:
			errDesc = [NSString stringWithFormat:
					   @"The shm_open() operation is not supported; or O_CREAT is specified and value exceeds SEM_VALUE_MAX = %ld.",
					   (long)SEM_VALUE_MAX] ;
			break;
		case EMFILE:
			errDesc = @"The process has already reached its limit for semaphores or file descriptors in use." ;
			break;
		case ENAMETOOLONG:
			errDesc = @"Requested name exceeded SEM_NAME_LEN characters." ;
			break;
		case ENFILE:
			errDesc = @"Too many semaphores or file descriptors are open on the system." ;
			break;
		case ENOENT:
			errDesc = @"O_CREAT is not set and the named semaphore does not exist." ;
			break;
		case ENOSPC:
			errDesc = @"O_CREAT is specified, the file does not exist, and there is insufficient space available to create the semaphore." ;
			break;
		default:
			errDesc = @"Unknown errno" ;
	}
	
	*error_p = [NSError errorWithDomain:@"SSYSystemSemaphore"
								   code:semErrno
							   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
										 errDesc, NSLocalizedDescriptionKey,
										 nil]] ;
}

@synthesize name ;
@synthesize descriptor ;
@synthesize gotSemaphore ;
@synthesize initialBackoff ;
@synthesize backoffFactor ;
@synthesize maxBackoff ;
@synthesize timeout ;

// Returns YES if either got semaphore or could not get semaphore because it is exclusively in use. 
// Returns NO if unrecoverable error
- (BOOL)tryLockError_p:(NSError**)error_p {
	sem_t* descriptor_ ;
	const char* name_ = [[self name] UTF8String] ;
	// Create a semaphore with an initial value of 1 if it does not exists
	// or just open the existing semaphore if it does.
	descriptor_ = sem_open(
						   name_,      // name
						   O_CREAT,    // create if does not exist
						   S_IRWXU,    // permissions (rwx by user)
						   1           // Set to value 1 = "in use", only if one is created
						   ) ;
	if (descriptor_ == SEM_FAILED) {
		// Unexpected error
	}
	else {
		NSInteger failed = sem_trywait(descriptor_) ;
		if (failed == 0) {
			// Got semaphore
			[self setDescriptor:descriptor_] ;
			[self setGotSemaphore:YES] ;
			return YES ;
		}
		else {
			if (errno == EAGAIN) {
				// Normal error when exclusive semaphore is not available
				return YES ;
			}
			else {
				// Unexpected error
			}
		}
	}

	// Unexpected error
	[[self class] setError_p:error_p
				   withErrno:errno] ;
	
	return NO ;
}

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

+ (SSYSystemSemaphore*)sharedSemaphore {
	@synchronized(self) {
        if (!sharedSemaphore) {
            sharedSemaphore = [[self alloc] init] ;
        }
    }
	
	// No autorelease.  This sticks around forever.
    return sharedSemaphore ;
}

- (void)dealloc {
	[name release] ;
	
	[super dealloc] ;
}

- (BOOL)lockError_p:(NSError**)error_p {
	[self setGotSemaphore:NO] ;
	NSTimeInterval backoff = [self initialBackoff] ;
	NSDate* deadline = [NSDate dateWithTimeIntervalSinceNow:[self timeout]] ;
	while ([(NSDate*)[NSDate date] compare:deadline] == NSOrderedAscending) {
		if ([self tryLockError_p:error_p]) {
			if ([self gotSemaphore]) {
				// Got semaphore
				return YES ;
			}
			else {
				// Semaphore is not available
				usleep( 1000000 * backoff ) ;
				backoff = backoff * [self backoffFactor] ;
				backoff = MIN(backoff, [self maxBackoff]) ;
			}
		}
		else {
			// Unrecoverable error
			return NO ;
		}
	}
	
	// Timeout
	if (error_p) {
		NSString* msg = [NSString stringWithFormat:
						 @"Timeout %g secs exceeded attempting to acquire '%@'",
						 [self timeout],
						 [self name]
						 ] ;
		*error_p = [NSError errorWithDomain:@"SSYSystemSemaphore"
									   code:ETIME
								   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											 msg, NSLocalizedDescriptionKey,
											 nil]] ;
	}
	
	return NO ;
}

/*
 sem_close() must be called once for every prior sem_open(), at which point
 the semaphore is deleted from memory and its descriptor is invalidated.
 */

 - (BOOL)relinquishError_p:(NSError**)error_p {	
	if (![self gotSemaphore]) {
		if (error_p) {
			*error_p = [NSError errorWithDomain:@"SSYSystemSemaphore"
										   code:ESRCH
									   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
												 @"Not got semaphore, can't relinquish", NSLocalizedDescriptionKey,
												 nil]] ;
		}
		
		return NO ;
	}
	
	NSInteger failed = NO ;
	
	failed = sem_post([self descriptor]);
	if (failed) {
		NSLog(@"Error unlocking") ;
		[[self class] setError_p:error_p
					   withErrno:errno] ;
		return NO ;
	}

	failed = sem_close([self descriptor]) ;
	if (failed) {
		NSLog(@"Error closing") ;
		[[self class] setError_p:error_p
					   withErrno:errno] ;
		return NO ;
	}

	return YES ;
}

@end