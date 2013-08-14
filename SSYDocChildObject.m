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

	// During document opening, during -viewDidMoveToWindow, this class 
	// will be sent an -initWithDocument: with argument nil.
	// If that were passed to the following method as the object: argument,
	// we would get notifications when ^any^ document closed.  We only
	// want notifications when ^our^ document closes.  Thus, the following if()...
	if (document != nil) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(docWillClose:)
													 name:SSYUndoManagerDocumentWillCloseNotification
												   object:document] ;
	}
}

- (id)initWithDocument:(BkmxDoc*)document_ {
	self = [super init];

	if (self != 0)  {		
		[self setDocument:document_] ;
	}
	
    /*SSYDBL*/ NSLog(@"Initted %@", self) ;
	return self;
}

- (void)dealloc {
	
	[super dealloc] ;
}

- (void)docWillClose:(NSNotification*)note {
	[[NSNotificationCenter defaultCenter] removeObserver:self] ;

	// To keep from crashing, in particular if I am a Broker, because
	// my timers will keep invoking gotHeaders: and other methods
	// which send messages to _doc as responses are received.
	[self setDocument:nil] ;
}

@end