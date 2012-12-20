#import <Cocoa/Cocoa.h>

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
 
 SSYSemaphore is implemented by writing a .SSYSemaphore file to
 the application's Application Support folder.  Thinking about this,
 here on 20120302, I wonder why I didn't write (and synchronize)
 a key into BookMacster's User Defaults instead.  It doesn't
 really matter, though.  Actually, it may be fewer lines of code
 this way because writing a file is only one line of code but
 writing and synchronizing user defaults is two lines of code.
 Also, a file is more visible for debugging than a user default.
 Most of the code in this implementation is for checking timeouts.
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
 
 If the receiver's system semaphore cannot be obtained because it already exists
 exclusively on the system, sleeps for the receiver's current backoff,
 multiplies the backoff by the backoff factor, limits the backoff to the max
 backoff, and repeats this until either the semaphore is obtained or the
 receiver's timeout is exceeded.
 
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
 @brief    Returns the path in the filesystem to a file whose
 data is the currently-active key, in UTF8 encoding

 @details  This is handy if you want to, for example, monitor
 semaphore activity with a kqueue.
 
 @result   The path.  This method always returns the same string,
 as long as the Application Support folder for the app does
 not move.  If the semaphore is currently inactive, the returned
 path is that of a file which does not exist.
*/
+ (NSString*)path ;

@end


/* TEST CODE FOR THIS CLASS

 // Build one of these tools, then doubleclick it three times.  Position the 
 // three Terminal windows to see all, then watch and listen to them
 // compete for the semaphore.
 
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
 
 - (void)dealloc {
 [m_key release] ;
 
 [super dealloc] ;
 }
 
 - (void)doWork {
 NSError* error ;
 
 BOOL ok = [SSYSemaphore acquireWithKey:[self key]
 setKey:[self key]
 initialBackoff:1.0
 backoffFactor:1.35
 maxBackoff:10.0
 timeout:15.0
 timeLimit:30.0
 error_p:&error] ;
 if (ok) {
 [[NSSound soundNamed:@"Tink"] play] ;  // beginning work
 NSLog(@"Got semaphore.  Starting work.") ;
 
 sleep(randomPeriod(3, 7)) ; // Time required to do work
 nWorks++ ;
 
 NSLog(@"Work done.  Clearing semaphore.") ;
 [[NSSound soundNamed:@"Pop"] play] ;  // ending work
 [SSYSemaphore clearError_p:NULL] ;		
 }
 else {
 if ([error code] == ETIME) {
 // Timed out
 NSLog(@"Retries timed out.  Do some recovery??") ;
 }
 else {
 // Some unexpected error
 NSLog(@"%@", [error description]) ;
 }
 [[NSSound soundNamed:@"Basso"] play] ;
 }
 
 // Wait a random time and then try more work
 [NSTimer scheduledTimerWithTimeInterval:randomPeriod(5, 7)
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
 int bytes = random() ;
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
 
 
 
 */