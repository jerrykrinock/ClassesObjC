#import <Cocoa/Cocoa.h>

@class Bkmslf ;

@interface SSYDocChildObject : NSObject {
	Bkmslf* m_document ; 
}

- (id)initWithDocument:(Bkmslf*)document ;

// Weak reference, not retained, to avoid retain cycles
@property (assign) Bkmslf* document ;

@end
