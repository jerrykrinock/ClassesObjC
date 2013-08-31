#import "SSYDocChildObject.h"
#import "BkmxGlobals.h"
#import "SSYDooDooUndoManager.h"

@implementation SSYDocChildObject

- (BkmxDoc*)document {
	BkmxDoc* document ;
	@synchronized(self) {
		document = [[m_document retain] autorelease] ;
	}
	return document ;
}

- (void)setDocument:(BkmxDoc *)document {
	@synchronized(self) {
		m_document = document ;
	}
}

- (id)initWithDocument:(BkmxDoc*)document_ {
	self = [super init];

	if (self != 0)  {		
		[self setDocument:document_] ;
	}
	
	return self;
}

@end