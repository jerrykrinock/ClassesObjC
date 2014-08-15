#import "SSYSemaphore.h"
#import "NSFileManager+SomeMore.h"
#import "SSYOtherApper.h"
#import "NSBundle+SSYMotherApp.h"
#import "NSBundle+MainApp.h"
#import <fcntl.h>

NSString* SSYSemaphoreErrorDomain = @"SSYSemaphoreErrorDomain" ;

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
    if ([string length] < 6) {
        key = nil ;
    }
    else {
        key = [string substringFromIndex:6] ;
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
            [self key]] ;
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
    return [NSString stringWithFormat:
            @"%@ pid=%ld key=%@",
            [super description],
            (long)[self pid],
            [self key]] ;
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

+ (NSString*)semaphoreName {
    return @"SSYSemaphore" ;
}

+ (NSString*)semaphoreBasePath {
    NSString* path ;
    path = [[NSBundle mainAppBundle] applicationSupportPathForMotherApp] ;
    if (!path) {
        path = NSHomeDirectory() ;
    }
    path = [path stringByAppendingPathComponent:[@"." stringByAppendingString:[self semaphoreName]]] ;
	return path ;
}

+ (NSString*)infoPath {
    NSString* path = [self semaphoreBasePath] ;
    path = [path stringByAppendingString:@"-Info"] ;
	return path ;
}

+ (NSString*)lockPath {
    NSString* path = [self semaphoreBasePath] ;
    path = [path stringByAppendingString:@"-Lock"] ;
	return path ;
}

+ (int)lockMomentaryLock {
    const char* path = [[self lockPath] fileSystemRepresentation] ;
#if 0
    // Using code by Stéphane from this blog post
    // http://charette.no-ip.com:81/programming/2010-01-13_PosixSemaphores/index.html
    // This code has an issue.  Running the test code for a half hour or so,
    // the result with this code is: 2198 unique acquisitions, 26 dual
    // acqusitions (meaning that two contending processes request
    // -acquireWithKey:::::::: and both get returned YES.)  These "collisions"
    // typically occur when these requests occur within 10 milliseconds of each
    // other.
    int fileDescriptor = open(path,
                              O_RDWR      |   // open the file for both read and write access
                              O_CREAT     |   // create file if it does not already exist
                              O_CLOEXEC   ,   // close on execute
                              S_IRUSR     |   // user permission: read
                              S_IWUSR     );  // user permission: write
    
    lockf( fileDescriptor, F_TLOCK, 0 ) ; // lock the "semaphore"
#else
    // Using code by in answer by Raffi Khatchadourian in this thread:
    // http://stackoverflow.com/questions/2053679/how-do-i-recover-a-semaphore-when-the-process-that-decremented-it-to-zero-crashe
    // This code is good.  Running the test code for a couple hours,
    // the result with this code is: 5512 unique acquisitions, 0 dual
    // acquisitions.
    int fileDescriptor = open(
                              path,
                              O_CREAT | //create the file if it's not present.
                              O_WRONLY | //only need write access for the internal locking semantics.
                              O_EXLOCK, //use an exclusive lock when opening the file.
                              S_IRUSR | S_IWUSR) ; //permissions on the file, 600 here.
#endif
    return fileDescriptor ;
}

+ (void)relinquishMomentaryLock:(int)fileDescriptor {
    if (close(fileDescriptor) != 0) {
        NSLog(@"Internal Error 593-2101 %ld", (long)errno) ;
    }
    
    return ;
    /*
     
     */
}

+ (SSYSemaphorePidKey*)currentPidKeyEnforcingTimeLimit:(NSTimeInterval)timeLimit  {
	NSString* currentPidKeyString = nil ;
	BOOL overlimit ;
	if (timeLimit == 0.0) {
		overlimit = NO ;
	}
	else {
		NSTimeInterval timeSinceFileModified = -[[[NSFileManager defaultManager] modificationDateForPath:[self infoPath]] timeIntervalSinceNow] ;
        overlimit = (timeSinceFileModified > timeLimit) ;
	}
	
	if (overlimit) {
		// Current leasee has timed out
		[self clearError_p:NULL] ;
	}
	else {
		// Current leasee has not timed out
		currentPidKeyString = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:[self infoPath]]
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
	NSString* path = [self infoPath] ;
    SSYSemaphorePidKey* acquirePidKey = [SSYSemaphorePidKey pidKeyWithPid:forPid
                                                                      key:newKey] ;
    SSYSemaphorePidKey* currentPidKey = nil ;
	while ([(NSDate*)[NSDate date] compare:deadline] == NSOrderedAscending) {
        int momentaryLockFileDescriptor = [self lockMomentaryLock] ;
        if (momentaryLockFileDescriptor >= 0) {
            currentPidKey = [self currentPidKeyEnforcingTimeLimit:timeLimit] ;
            pid_t currentPid = [currentPidKey pid] ;
            SSYOtherApperProcessState currentProcessState = [SSYOtherApper stateOfPid:currentPid] ;
            BOOL requestorIsCurrentOwner = ((currentPid == forPid) && ([acquirePidKey isEqual:currentPidKey])) ;
            BOOL gotIt = NO ;
            if (
                (BOOL)(currentPidKey == nil)
                // semaphore is not in use or its time limit has expired
                ||
                (requestorIsCurrentOwner)
                ||
                (BOOL)(currentProcessState == SSYOtherApperProcessDoesNotExist)
                ||
                (BOOL)(currentProcessState == SSYOtherApperProcessStateZombie)
                ||
                (BOOL)(currentProcessState == SSYOtherApperProcessUnknown)
                ) {
                // semaphore is available
                if (!requestorIsCurrentOwner) {
                    NSString* newString = [acquirePidKey string] ;
                    [newString writeToFile:path
                                atomically:YES
                                  encoding:NSUTF8StringEncoding
                                     error:NULL] ;
                }
                
                gotIt = YES ;
            }
            
            [self relinquishMomentaryLock:momentaryLockFileDescriptor] ;
            if (gotIt) {
                return YES ;
            }
        }
        
        // semaphore is not available
        usleep( 1000000 * backoff ) ;
        backoff = backoff * backoffFactor ;
        backoff = MIN(backoff, maxBackoff) ;
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
	NSError* error = nil  ;
	BOOL ok = [[NSFileManager defaultManager] removeItemAtPath:[self infoPath]
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