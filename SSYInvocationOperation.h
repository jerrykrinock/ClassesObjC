#import <Cocoa/Cocoa.h>
#import "SSYOwnee.h"


/*!
 @brief    A subclass of NSInvocationOperation which adds
 conformance to the SSYOwnee protocol with a weakly-retain
 instance variable
*/
@interface SSYInvocationOperation : NSInvocationOperation <SSYOwnee> {
	id m_owner ;
}

- (id)initWithTarget:(id)target
			selector:(SEL)sel
			  object:(id)arg
			   owner:(id)owner ;

@end
