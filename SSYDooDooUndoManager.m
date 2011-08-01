#import "SSYDooDooUndoManager.h"

NSString* const SSYUndoManagerWillEndUndoGroupNotification = @"SSYUndoManagerWillEndUndoGroupNotification" ;
NSString* const SSYUndoManagerDocumentWillSaveNotification = @"SSYUndoManagerDocumentWillSaveNotification" ;
NSString* const SSYUndoManagerDocumentWillCloseNotification = @"SSYUndoManagerDocumentWillCloseNotification" ;
NSString* const SSYUndoManagerDidCloseUndoGroupNotification = @"SSYUndoManagerDidCloseUndoGroupNotification" ;

static NSInteger scheduledGroupSequenceNumber = 1 ;

@interface SSYDooDooUndoManager () 

@property (assign) NSManagedObjectContext* managedObjectContext ;

@end


@implementation SSYDooDooUndoManager

#if DEBUG
- (NSInteger)nLivingAutoEndingGroups {
	return nLivingAutoEndingGroups ;
}
- (NSInteger)nLivingManualGroups {
	return nLivingManualGroups ;
}
#endif

@synthesize managedObjectContext = m_managedObjectContext ;

- (id)initWithDocument:(NSPersistentDocument*)document {
	self = [super init] ;
	if (self != nil) {
		NSAssert(document != nil, @"SSYDooDooUndoManager got no document") ;
		
	//	[self setGroupsByEvent:NO] ;  // Causes all hell to break loose with Core Data.

		// We cast to an id since the compiler expects these to methods
		// to get something which inherits from NSUndoManager, which 
		// GCUndoManager does not.
		[document setUndoManager:(id)self] ;
		[[document managedObjectContext] setUndoManager:(id)self] ;
		
		[self setManagedObjectContext:[document managedObjectContext]] ;

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(endAnyUndoGroupings:)
													 name:SSYUndoManagerDocumentWillSaveNotification
												   object:document] ;
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(endAnyUndoGroupings:)
													 name:SSYUndoManagerDocumentWillCloseNotification
												   object:document] ;
	}

	return self ;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self] ;
	
	[super dealloc] ;
}

+ (SSYDooDooUndoManager*)makeUndoManagerForDocument:(NSPersistentDocument*)document {
	return [[[SSYDooDooUndoManager alloc] initWithDocument:document] autorelease] ;
}

- (void)beginManualUndoGrouping {
	if ([self isUndoRegistrationEnabled]) {
		nLivingManualGroups++ ;
		[self beginUndoGrouping] ;
	}
}

- (void)beginUndoGrouping {
	[super beginUndoGrouping] ;
}

- (void)endUndoGrouping {
	[[self managedObjectContext] processPendingChanges] ;
	[super endUndoGrouping] ;
	[[NSNotificationCenter defaultCenter] postNotificationName:SSYUndoManagerDidCloseUndoGroupNotification
														object:self];
}

- (void)endManualUndoGrouping {
	if (nLivingManualGroups > 0) {
		nLivingManualGroups-- ;
		[self endUndoGrouping] ;
	}
}

- (void)beginAutoEndingUndoGrouping {
	if (
		(nLivingAutoEndingGroups == 0)
		&&
		![self isUndoing]
		&&
		![self isRedoing]
		&&
		[self isUndoRegistrationEnabled]
		) {
		[self performSelector:@selector(autoEndUndoGroupingSequenceNumber:)
				   withObject:[NSNumber numberWithInt:scheduledGroupSequenceNumber++]
				   afterDelay:0.01] ;
		// It is important that we set our state variable before
		// beginning the undo grouping, because sometimes -beginUndoGrouping
		// could immediately cause another -beginAutoEndingUndoGrouping
		// to be received; i.e. this method can be re-entered before it ends.
		nLivingAutoEndingGroups++ ;
		
		[self beginUndoGrouping] ;
	}
}

- (void)autoEndUndoGroupingSequenceNumber:(NSNumber*)number {
	[[NSNotificationCenter defaultCenter] postNotificationName:SSYUndoManagerWillEndUndoGroupNotification
														object:self] ;
	nLivingAutoEndingGroups-- ;
	[self endUndoGrouping] ;
}

- (NSInteger)endAnyUndoGroupings {	
	NSInteger i ;
	NSInteger result = 0 ;
	for (i=0; i<nLivingManualGroups; i++) {
		[self endManualUndoGrouping] ;
		result++ ;
	}

	if (nLivingAutoEndingGroups > 0) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self] ;
		[self autoEndUndoGroupingSequenceNumber:[NSNumber numberWithInt:-1]] ;
		result++ ;
	}
	
	return result ;
}

- (void)endAnyUndoGroupings:(NSNotification*)note {
	[self endAnyUndoGroupings] ;
}


@end