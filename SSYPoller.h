#import <Cocoa/Cocoa.h>


@interface SSYPoller : NSObject {
}

/*!
 @brief    Blocks the thread and repeatedly invokes a given invocation until
 it returns YES

 @param    invocation  The invocation used to determine whether or not this
 method should return YES.  This invocation must return a BOOL.
 @param    initialBackoff  
 @param    backoffFactor  
 @param    maxBackoff  
 @param    timeout  
 @param    timeLimit  
 @param    debugLabel  
 @param    error_p  If not NULL and if an error occurs, upon return,
           will point to an error object encapsulating the error.
 @result   YES if the invocation returned YES before the timeout occurred,
 otherwise NO
*/
+ (BOOL)waitUntilInvocation:(NSInvocation*)invocation
			 initialBackoff:(NSTimeInterval)initialBackoff
			  backoffFactor:(float)backoffFactor
				 maxBackoff:(NSTimeInterval)maxBackoff
					timeout:(NSTimeInterval)timeout
				  timeLimit:(NSTimeInterval)timeLimit
				 debugLabel:(NSString*)debugLabel
					error_p:(NSError**)error_p ;

@end
