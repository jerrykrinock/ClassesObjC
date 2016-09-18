#import "SSYDooDooUndoManager.h"
#import "SSYMOCManager.h"

NSString* const SSYUndoManagerWillEndUndoGroupNotification = @"SSYUndoManagerWillEndUndoGroupNotification" ;
NSString* const SSYUndoManagerDocumentWillSaveNotification = @"SSYUndoManagerDocumentWillSaveNotification" ;
NSString* const SSYUndoManagerDocumentDidOpenNotification = @"SSYUndoManagerDocumentDidOpenNotification" ;
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

- (void)coupleToManagedObjectContext:(NSManagedObjectContext*)managedObjectContext {
    [managedObjectContext setUndoManager:(id)self] ;
    [self setManagedObjectContext:managedObjectContext] ;
}


- (void)coupleToDocument:(NSPersistentDocument*)document {
    //	[self setGroupsByEvent:NO] ;  // Causes all hell to break loose with Core Data.
    
    // We cast to an id since the compiler expects these to methods
    // to get something which inherits from NSUndoManager, which
    // GCUndoManager does not.
    [document setUndoManager:(id)self] ; // Causes moc to be created, which causes persisten store to be created ??
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(endAnyUndoGroupings:)
                                                 name:SSYUndoManagerDocumentWillSaveNotification
                                               object:document] ;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(endAnyUndoGroupings:)
                                                 name:SSYUndoManagerDocumentWillCloseNotification
                                               object:document] ;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self] ;
	
	[super dealloc] ;
}

+ (SSYDooDooUndoManager*)makeUndoManagerForDocument:(NSPersistentDocument*)document {
	SSYDooDooUndoManager* undoManager = [[SSYDooDooUndoManager alloc] init] ;
    [undoManager coupleToDocument:document] ;
    [undoManager coupleToManagedObjectContext:[document managedObjectContext]] ;
    [undoManager autorelease] ;
    return undoManager ;
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

#if 0
#warning Hokey Code
- (void)undo {
	id bkmxDoc = [SSYMOCManager ownerOfManagedObjectContext:[self managedObjectContext]] ;
	[bkmxDoc endEditing:nil] ;
	[super undo] ;
}
#endif

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
				   withObject:[NSNumber numberWithInteger:scheduledGroupSequenceNumber++]
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
		[self autoEndUndoGroupingSequenceNumber:[NSNumber numberWithInteger:-1]] ;
		result++ ;
	}
	
	return result ;
}

- (void)endAnyUndoGroupings:(NSNotification*)note {
	[self endAnyUndoGroupings] ;
}


@end
