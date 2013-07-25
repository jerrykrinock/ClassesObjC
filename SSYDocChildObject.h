#import <Cocoa/Cocoa.h>

@class BkmxDoc ;

@interface SSYDocChildObject : NSObject {
	BkmxDoc* m_document ; 
}

- (id)initWithDocument:(BkmxDoc*)document ;

// Weak reference, not retained, to avoid retain cycles
@property (assign) BkmxDoc* document ;

@end
