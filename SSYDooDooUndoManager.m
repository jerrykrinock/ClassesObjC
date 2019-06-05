#import "SSYDooDooUndoManager.h"
#import "SSYMOCManager.h"

#import "BSManagedDocument.h"
/* BSManagedDocument is a open source replacement for NSPersistentDocument.
 It is recommended for any Core Data document-based app.
 https://github.com/jerrykrinock/BSManagedDocument
 */

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

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self] ;
	
	[super dealloc] ;
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
