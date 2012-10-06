#import <Cocoa/Cocoa.h>
#import <semaphore.h>

/*!
 @brief    Cocoa wrapper around the Darwin system semaphore 
 facility which is declared in semaphore.h.
 
 @details  Buggy.  If a process crashes after locking but before
 relinquishing a semaphore, that semaphore will be hung
 forever.&nbsp;  We need a forceRelinquish method which
 would call sem_unlink(name) unconditionally.  See:
 http://lists.apple.com/archives/darwin-kernel/2009/Mar/msg00067.html
*/
@interface SSYSystemSemaphore : NSObject {
	NSString* name ;
	sem_t* descriptor ;
	BOOL gotSemaphore ;
	NSTimeInterval initialBackoff ;
	CGFloat backoffFactor ;
	NSTimeInterval maxBackoff ;
	NSTimeInterval timeout ;
}

@property (copy) NSString* name ;
@property sem_t* descriptor ;
@property BOOL gotSemaphore ;
@property NSTimeInterval initialBackoff ;
@property CGFloat backoffFactor ;
@property NSTimeInterval maxBackoff ;
@property NSTimeInterval timeout ;

/*!
 @brief    Returns a process-wide shared system semaphore

 @details  Since I've been engineering for 30 years and just
 had a use for one of these, I figured one would be enough
 in many cases.&nbsp;   Useful, for example, if an entire process
 needs to acquire an exclusive semaphore before doing its work.
*/
+ (SSYSystemSemaphore*)sharedSemaphore ;

/*!
 @brief    Configures a system semaphore

 @details  Send this message to configure a system semaphore
 before sending any other messages to it.
 @param    name_  A name for the system semaphore
 @param    backoff_  The time interval for which -lockError_p
 will sleep before retrying if it is not able to acquire the
 its named system semaphore.&nbsp;  Normally, you set this
 to the expected time that it might take another user to
 relinquish the system semaphore.
 @param    timeout_  The time interval after which lockError_p
 will give up and return NO if it cannot acquire its receiver's
 system semaphore
 */
- (void)setName:(NSString*)name_
 initialBackoff:(NSTimeInterval)initialBackoff_
  backoffFactor:(CGFloat)backoffFactor_
	 maxBackoff:(NSTimeInterval)maxBackoff_
		timeout:(NSTimeInterval)timeout_ ;

/*!
 @brief    Attempts to exclusively the receiver's system semaphore,
 blocking and retrying up to its timeout.
 
 @details  Send this message before beginning a task which
 needs exclusive access to system resources guarded by the
 semaphore.
 
 Begins by setting the receiver's current backoff, a private
 attribute, to its initial backoff.  Then begins attempts...
 
 If the receiver's system semaphore cannot be obtained
 because it already exists exclusively on the system, sleeps for
 the receiver's current backoff, multiplies the backoff by the
 backoff factor, limits the backoff to the max backoff,  and
 repeats this until either the semaphore is obtained or the
 receiver's timeout is exceeded.
 
 @param    error_p  Upon return, if an error occurs, points to a
 relevant NSError*.&nbsp;  If a timeout occurred, the error
 code will be ETIME.&nbsp;  Pass NULL if you don't want the error.
 @result    YES if the semaphore was obtained.&nbsp;
 NO if the timeout was exceeded, or some other unrecoverable
 eror occurred.
 
*/
- (BOOL)lockError_p:(NSError**)error_p ;

/*!
 @brief    

 @details  Send this message to relinquish the semaphore
 after a task requiring exclusive access to system resources
 guarded by the semaphore has completed.
 @param    error_p  
 @result   
*/
- (BOOL)relinquishError_p:(NSError**)error_p ;
@end
