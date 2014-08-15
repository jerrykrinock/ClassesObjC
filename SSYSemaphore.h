#import <Cocoa/Cocoa.h>

extern __attribute__((visibility("default"))) NSString* SSYSemaphoreErrorDomain ;

__attribute__((visibility("default"))) @interface SSYSemaphorePidKey : NSObject {
    pid_t m_pid ;
    NSString* m_key ;
}

@property (assign) pid_t pid ;
@property (copy) NSString* key ;

+ (NSString*)pidStringForPid:(NSInteger)pid ;

+ (SSYSemaphorePidKey*)pidKeyWithPid:(pid_t)pid
                                 key:(NSString*)key ;
@end

/*!
 @brief    Useful in running exclusive processes.
 
 @details  Note that SSYSemaphores are not identified with the process
 that acquired them.  This is by design, so that it is possible
 for one process to acquire a semaphore, pass the key to another
 process, terminate, and then the other process clears the
 semaphore.  The danger of this is that SSYSemaphore therefore
 keeps no knowledge of the acquiring process, and if the
 acquiring process terminates unexpectedly, and then another
 process wants the semaphore, SSYSemaphore will *not* check
 and see if the first process is still running, judge that
 it may have crashed and give the semaphore to the other process.
 Other processes will be prevented from acquiring the semaphore.
 SSYSemaphore features a time limit (timeLimit) to mitigate this
 danger.
 
 SSYSemaphore is implemented by writing a process identifier (pidd) and an
 arbitrary user-defined key into an "info file".
 
 Simultaneous access to the info file is limited to one contending process
 by a "lock file", as described in these links…
 • http://stackoverflow.com/questions/2053679/how-do-i-recover-a-semaphore-when-the-process-that-decremented-it-to-zero-crashe
 •  http://charette.no-ip.com:81/programming/2010-01-13_PosixSemaphores/index.html
 Those links also explain why I use the "lock file" idea instead of named
 POSIX semaphores.  (Briefly, named POSIX semaphores are not cleaned up by
 OS X if their owning processes crash, which causes a logjam until the
 user logs out and back in.
 
 When using this class, [NSApp delegate] must conform to protocol
 SSYAppSupporter.
 */
__attribute__((visibility("default"))) @interface SSYSemaphore : NSObject {
}

/*!
 @brief    Attempts to acquire exclusively the receiver's system
 semaphore, blocking and retrying up to its timeout.
 
 @details  Send this message before beginning a task which needs exclusive
 access to system resources guarded by the semaphore.
 
 Begins by setting the receiver's current backoff, a private attribute, to its
 initial backoff.  Then begins attempts...
 
 If the receiver's system semaphore cannot be obtained, sleeps for the
 receiver's current backoff, multiplies the backoff by the backoff factor,
 limits the backoff to the max backoff, and repeats this until either the
 semaphore is obtained or the receiver's timeout is exceeded.
 
 @param    forPid  A process identifier of the process which will be registered
 in the semaphore if it is acquired, and which will result in success in
 acquiring the semaphore if the semaphore is currently registered with this 
 identifier.  You can think of this as the "leasee" of the semaphore.  This
 method will succeed in obtaining the semaphore not only if the semaphore is
 currently vacant, but also if the requesting would-be leasee is already the
 leasee.
 @param    timeout  The time interval after which lockError_p will give up and
 return NO if it cannot acquire its receiver's system semaphore.
 @param    timeLimit  The period of time which the previous
 semaphore acquisition is allowed to retain the semaphore,
 after which this method will succeed and rudely overwrite
 the semaphore.  This is intended to be a fail-safe mechanism
 in case an acquiring process terminates unexpectedly without
 either clearing the semaphore or passing the key on to another
 process which should clear the semaphore.
 @param    error_p  Upon return, if an error occurs, points to a
 relevant NSError*.  If a timeout occurred, the error
 code will be ETIME.  Pass NULL if you don't want the error.
 @result    YES if the semaphore was obtained.
 NO if the timeout was exceeded, or some other unrecoverable
 eror occurred.
 
*/
+ (BOOL)acquireWithKey:(NSString*)acquireKey
				setKey:(NSString*)newKey
                forPid:(pid_t)forPid
		initialBackoff:(NSTimeInterval)initialBackoff
		 backoffFactor:(CGFloat)backoffFactor
			maxBackoff:(NSTimeInterval)maxBackoff
			   timeout:(NSTimeInterval)timeout
			 timeLimit:(NSTimeInterval)timeLimit 
			   error_p:(NSError**)error_p ;

/*!
 @brief    

 @details  Send this message to relinquish the semaphore
 after a task requiring exclusive access to system resources
 guarded by the semaphore has completed.
 @result  YES if the receiver owned a semaphore which was
 relinquished; NO if the receiver did not own a semaphore and
 there was nothing to relinquish.
*/
+ (BOOL)clearError_p:(NSError**)error_p ;

/*!
 @brief    Returns the pid key with which the currently-active
 semaphore was created, or nil if the semaphore is currently
 available, and, optionally, clears the semaphore if its
 age exceeds a given time limit
 @param    timeLimit  The period of time which the previous
 semaphore acquisition is allowed to retain the semaphore,
 after which this method will invoke +clearError_p: to clear
 the semaphore and return nil.  This is intended to be a
 fail-safe mechanism.  Use it if you want to clear an expired
 semaphore.

 If a timeLimit of 0.0 is passed, the age of the semaphore is
 ignored and it will not be cleared.
 */
+ (SSYSemaphorePidKey*)currentPidKeyEnforcingTimeLimit:(NSTimeInterval)timeLimit ;

/*!
 @brief    Returns the path in the filesystem to a file which will be touched
 and whose data is the currently-active key, in UTF8 encoding

 @details  This is handy if you want to, for example, monitor
 semaphore activity with a kqueue.
 
 @result   The path.  This method always returns the same string,
 as long as the Application Support folder for the app does
 not move.  If the semaphore is currently inactive, the returned
 path is that of a file which does not exist.
*/
+ (NSString*)infoPath ;

@end


#if 0

/*
TEST CODE FOR THIS CLASS

 Build one of these tools, then doubleclick it two or more times.  Each time
 it will open a Terminal window and launch a process.  Position the Terminal
 windows to see all, then watch and listen to them contend for the semaphore.
*/

#import "SSYSemaphore.h"
#import <Carbon/Carbon.h>
#import <unistd.h>

void seedRandomNumberGenerator() {
    double fseed = [[NSDate date] timeIntervalSinceReferenceDate] ;
    //    Remove integer part to base it on the current fraction of a second
    fseed -= (int)fseed ;
    //    0 <= fseed < 1.0
    fseed *= 0x7fffffff ;
    int seed = (int)fseed ;
    //    0 <= seed <= 2^31-1
    srandom(seed) ;
}

float randomPeriod(float min, float max) {
    float intervalMilliseconds = (max - min)*1000 ;
    int randomMilliseconds = random() % (int)intervalMilliseconds ;
    return min + randomMilliseconds/1000.0 ;
}

@interface Doer : NSObject {
    int nWorks ;
    NSString* m_key ;
}

@property (retain) NSString* key ;

@end


@implementation Doer

@synthesize key = m_key ;

+ (NSString*)sharedTextFilePath {
    NSString* path = NSHomeDirectory() ;
    path = [path stringByAppendingPathComponent:@"Desktop"] ;
    path = [path stringByAppendingPathComponent:@"SemaphoreTestFile.txt"] ;
    return path ;
}

- (void)dealloc {
    [m_key release] ;
    
    [super dealloc] ;
}

- (void)doWork {
    NSError* error = nil  ;
    
    BOOL ok = [SSYSemaphore acquireWithKey:[self key]
                                    setKey:[self key]
                                    forPid:[[NSProcessInfo processInfo] processIdentifier]
                            initialBackoff:1.0
                             backoffFactor:1.35
                                maxBackoff:10.0
                                   timeout:15.0
                                 timeLimit:30.0
                                   error_p:&error] ;
    if (ok) {
        [[NSSound soundNamed:@"Tink"] play] ;  // beginning work
        NSLog(@"Got semaphore, working for %@", [self key]) ;
        ok = [[self key] writeToFile:[[self class] sharedTextFilePath]
                          atomically:YES
                            encoding:NSUTF8StringEncoding
                               error:&error] ;
        
        if (!ok) {
            NSLog(@"Error 182-9282: %@", error) ;
        }
        
        sleep(randomPeriod(1.0, 2.0)) ; // Time required to do work
        nWorks++ ;
        
        error = nil ;
        NSString* readKey = [[NSString alloc] initWithContentsOfFile:[[self class] sharedTextFilePath]
                                                            encoding:NSUTF8StringEncoding
                                                               error:&error] ;
        
        if (![readKey isEqualToString:[self key]]) {
            // Another process must have written to the shared text file path
            // while we were holding the semaphore.  If this ever happens,
            // there is a BUG in SSYSemaphore.  The whole idea of SSYSemaphore
            // is to prevent such collisions!
            NSLog(@"COLLISION!!  Expected:%@  Read:%@", [self key], readKey) ;
            [[NSSound soundNamed:@"Submarine"] play] ;
        }
        
        [readKey release] ;
        
        if (error) {
            NSLog(@"Error 183-9383: %@", error) ;
        }
        
        
        NSLog(@"Work done.  Clearing semaphore.") ;
        [[NSSound soundNamed:@"Pop"] play] ;  // ending work
        [SSYSemaphore clearError_p:NULL] ;
        sleep(randomPeriod(0.2, 2.0)) ; // Rest after work, give other processes a chance
    }
    else {
        if ([error code] == ETIME) {
            // Timed out
            NSLog(@"Retries timed out.  Do some recovery??") ;
        }
        else if (error) {
            // Some unexpected error
            NSLog(@"Error 184-9484: %@", [error description]) ;
        }
        [[NSSound soundNamed:@"Basso"] play] ;
    }
    
    // Wait a random time and then try more work
    [NSTimer scheduledTimerWithTimeInterval:randomPeriod(2, 5)
                                     target:self
                                   selector:@selector(doWork)
                                   userInfo:nil
                                    repeats:NO] ;
}

@end


int main(int argc, const char *argv[]) {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init] ;
    seedRandomNumberGenerator() ;
    Doer* doer = [[Doer alloc] init] ;
    int bytes = 0 ;
    for (int i=0; i<4; i++) {
        int byte = (int)random() ;
        // For readability, use only lowercase ASCII characters a-z:
        byte = (byte % 26) + 97 ;
        bytes += (byte << 8*i) ;
    }
    NSData* data = [NSData dataWithBytes:&bytes
                                  length:sizeof(int)] ;
    NSString* key = [[NSString alloc] initWithData:data
                                          encoding:NSASCIIStringEncoding] ;
    NSLog(@"Key for this tool: %@", key) ;
    [doer setKey:key] ;
    [key release] ;
    [doer doWork] ;
    
    [[NSRunLoop currentRunLoop] run] ;
    
    [pool release] ;
    return 0 ;
}

#endif
