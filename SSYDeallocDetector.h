#import <Cocoa/Cocoa.h>


/*!
 @brief    An instance of this class will send a given invocation
 during its deallocation.

 @details  We leave the usage of this class to your imagination!
*/
@interface SSYDeallocDetector : NSObject {
}

@property (retain) NSInvocation* invocation ;
@property (retain) NSString* logMsg ;

+ (SSYDeallocDetector*)detectorWithInvocation:(NSInvocation*)invocation
                                       logMsg:(NSString*)logMsg ;

@end
