#import <Cocoa/Cocoa.h>


/*!
 @brief    An instance of this class will send a given invocation
 during its deallocation.

 @details  We leave the usage of this class to your imagination!
*/
@interface SSYDeallocDetector : NSObject {
	NSInvocation* m_invocation ;
}

@property (retain) NSInvocation* invocation ;

+ (SSYDeallocDetector*)detectorWithInvocation:(NSInvocation*)invocation ;

@end
