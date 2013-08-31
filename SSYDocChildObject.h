#import <Cocoa/Cocoa.h>

@class BkmxDoc ;

@interface SSYDocChildObject : NSObject {
	BkmxDoc* m_document ; 
}

/*
 @details  It is very important that someone counter this assignment by
 sending us a setDocument:nil sometime between the time we find out that the
 document is closing and the time that the document deallocs.
 */
- (id)initWithDocument:(BkmxDoc*)document ;

// Weak reference, not retained, to avoid retain cycles
@property (assign) BkmxDoc* document ;

@end
