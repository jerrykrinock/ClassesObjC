#import <Cocoa/Cocoa.h>

/*!
 @brief    Uses a Mach port as a semaphore.  Useful
 in running exclusive processes.
 
 @details  This is much easier and better than using
 the methods in semaphore.h.  See http://lists.apple.com/archives/darwin-kernel/2009/Mar/msg00067.html
 
 On 2009 Apr 01, at 19:33, Quinn "The Eskimo" of Apple wrote
 in list Darwin-kernel@lists.apple.com:
 
 When using Mach ports like this, you have to be very careful about
 bootstrap namespaces.  Each process inherits a reference to a
 bootstrap namespace, meaning that which namespace it registers in
 depends on how it was launched. A port registration will only fail
 if the conflicting process is in the same namespace.  This may or
 may not be what you want. 
 
 TN2083 has all the gory details.
 
 Jerry: Thanks, Quinn.  I believe I'm OK since my mutually-exclusive
 processes are all current-user agents launched by launchd to
 fulfill tasks in ~/Library/LaunchAgents.  So, I am obeying the
 "rules to remember" in TN2083, and they should all be in the
 same namespace.
 */
@interface SSYMachaphore : NSObject {
	NSString* name ;
	NSPort* m_port ;
	NSTimeInterval initialBackoff ;
	CGFloat backoffFactor ;
	NSTimeInterval maxBackoff ;
	NSTimeInterval timeout ;
}

@property (copy) NSString* name ;
@property (retain) NSPort* port ;
@property NSTimeInterval initialBackoff ;
@property CGFloat backoffFactor ;
@property NSTimeInterval maxBackoff ;
@property NSTimeInterval timeout ;

/*!
 @brief    Returns a process-wide shared system machaphore

 @details  I figured one would be enough in most cases.&nbsp;
 Useful, for example, if an entire process needs to acquire
 an exclusive semaphore before doing its work.
*/
+ (SSYMachaphore*)sharedMachaphore ;

/*!
 @brief    Configures a system machaphore

 @details  Send this message to configure a system machaphore
 before sending any other messages to it.
 @param    name_  A name for the system machaphore
 @param    backoff_  The time interval for which -lockError_p
 will sleep before retrying if it is not able to acquire the
 its named system machaphore.&nbsp;  Normally, you set this
 to the expected time that it might take another user to
 relinquish the system machaphore.
 @param    timeout_  The time interval after which lockError_p
 will give up and return NO if it cannot acquire its receiver's
 system machaphore.
 */
- (void)setName:(NSString*)name_
 initialBackoff:(NSTimeInterval)initialBackoff_
  backoffFactor:(CGFloat)backoffFactor_
	 maxBackoff:(NSTimeInterval)maxBackoff_
		timeout:(NSTimeInterval)timeout_ ;

/*!
 @brief    Attempts to acquire exclusively the receiver's system
 machaphore, blocking and retrying up to its timeout.
 
 @details  Send this message before beginning a task which
 needs exclusive access to system resources guarded by the
 machaphore.
 
 Begins by setting the receiver's current backoff, a private
 attribute, to its initial backoff.  Then begins attempts...
 
 If the receiver's system machaphore cannot be obtained
 because it already exists exclusively on the system, sleeps for
 the receiver's current backoff, multiplies the backoff by the
 backoff factor, limits the backoff to the max backoff,  and
 repeats this until either the machaphore is obtained or the
 receiver's timeout is exceeded.
 
 @param    error_p  Upon return, if an error occurs, points to a
 relevant NSError*.&nbsp;  If a timeout occurred, the error
 code will be ETIME.&nbsp;  Pass NULL if you don't want the error.
 @result    YES if the machaphore was obtained.&nbsp;
 NO if the timeout was exceeded, or some other unrecoverable
 eror occurred.
 
*/
- (BOOL)lockError_p:(NSError**)error_p ;

/*!
 @brief    

 @details  Send this message to relinquish the machaphore
 after a task requiring exclusive access to system resources
 guarded by the machaphore has completed.
 @result  YES if the receiver owned a machaphore which was
 relinquished; NO if the receiver did not own a machaphone and
 there was nothing to relinquish.
*/
- (BOOL)relinquish ;


@end


/* TEST CODE FOR THIS CLASS

 // Build one of these tools, then doubleclick it three times.  Position the 
 // three Terminal windows to see all, then watch and listen to them
 // compete for the machaphore.
 
 #import "SSYMachaphore.h"
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
 }
 
 @end
 
 @implementation Doer
 
 - (void)doWork {
 NSError* error ;
 
 BOOL ok = [[SSYMachaphore sharedMachaphore] lockError_p:&error] ;
 if (ok) {
 [[NSSound soundNamed:@"Tink"] play] ;  // beginning work
 
 sleep(randomPeriod(3, 7)) ; // Time required to do work
 nWorks++ ;
 
 if (nWorks > 2000) {
 // Crash
 NSLog(@"1073: Will crash now.") ;
*(char*)0 = 0 ;
}

NSLog(@"Work done.  Relinquishing machaphore.") ;
[[NSSound soundNamed:@"Pop"] play] ;  // ending work
[[SSYMachaphore sharedMachaphore] relinquish] ;		
}
else {
	if ([error code] == ETIME) {
		// Timed out
		NSLog(@"Retries timed out.  Do some recovery??") ;
	}
	else {
		// Some unexpected error
		NSLog([error description]) ;
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
	[[SSYMachaphore sharedMachaphore] setName:@"SSYSem1"
							   initialBackoff:1.0
								backoffFactor:1.35
								   maxBackoff:10.0
									  timeout:15.0] ;
	
	Doer* doer = [[Doer alloc] init] ;
	[doer doWork] ;
	
	[[NSRunLoop currentRunLoop] run] ;
	
	[pool release] ;
	return 0 ;
}

 */