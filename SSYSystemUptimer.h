#import <Foundation/Foundation.h>

extern NSString* const SSYSystemUptimerErrorDomain;
extern NSInteger const SSYSystemUptimerSystemCommandFailedErrorCode;
extern NSInteger const SSYSystemUptimerCouldNotParseSystemResponse;

__attribute__((visibility("default"))) @interface SSYSystemUptimer : NSObject

/*!
 @brief    Returns the last date at which the system woke from sleep

 @details

 @param    error_p  Pointer which will, upon return, if an error
 occurred and said pointer is not NULL, point to an NSError
 describing said error.
 */
+ (NSDate*)lastWakeFromSleepError_p:(NSError**)error_p ;

@end
