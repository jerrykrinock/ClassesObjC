#import "SSYMojo.h"
#import "NSError+InfoAccess.h"
#import "NSError+MyDomain.h"
#import "SSYAlert.h"
#import "NSManagedObjectContext+Cheats.h"
#import "NSObject+MoreDescriptions.h"
#import "NSManagedObject+Debug.h"

// For debugging
#import "SSYMOCManager.h"


@implementation SSYMojo

@synthesize managedObjectContext = m_managedObjectContext ;
@synthesize entityName ;

- (id)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
						entityName:(NSString*)entityName_ {
	if (managedObjectContext && entityName_) {
		self = [super init] ;
		if (self != nil) {
			[self setManagedObjectContext:managedObjectContext] ;
			[self setEntityName:entityName_] ;
		}
	}
	else {
		// See http://lists.apple.com/archives/Objc-language/2008/Sep/msg00133.html ...
		[super dealloc] ;
		self = nil ;
	}
	
	return self ;
}

- (NSString*)description {
	return [NSString stringWithFormat:
			@"<%@ %p> entity=%@ store=%@",
			[self className],
			self,
			[self entityName],
			[[[self managedObjectContext] store1] longDescription]] ;
}

- (void)dealloc {
	[m_managedObjectContext release] ;
	[entityName release] ;
	
	[super dealloc];
}

- (NSArray*)objectsWithSubpredicates:(NSArray*)subpredicates
							   type:(NSCompoundPredicateType)type
							 error_p:(NSError**)error_p {	
	NSPredicate* compoundPredicate = nil ;
	if (subpredicates) {
		switch (type) {
			case NSAndPredicateType:				
				compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:subpredicates] ;
				break ;
			case NSOrPredicateType:
				compoundPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:subpredicates] ;
				break ;
			default:
				NSLog(@"Internal Error 842-0828.  NSCompoundPredicateType %ld not supported", (long)type) ;
		}
	}
	NSError* error = nil ;
	NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init] ;
	NSManagedObjectContext* managedObjectContext = [self managedObjectContext] ;
	NSArray* fetches = nil ;
	if (managedObjectContext) {
		[fetchRequest setEntity:[NSEntityDescription entityForName:[self entityName]  
											inManagedObjectContext:managedObjectContext]] ;
		if (compoundPredicate) {
			[fetchRequest setPredicate:compoundPredicate] ;
		}
		
		
		fetches = [managedObjectContext executeFetchRequest:fetchRequest
													  error:&error] ;
		if (error) {
			NSLog(@"Internal Error 487-2762: %@", [error longDescription]) ;
			if (error_p) {
				*error_p = error ;
			}
		}
	}
	[fetchRequest release] ;
	
	return fetches ; 
}

- (NSArray*)objectsWithPredicate:(NSPredicate*)predicate
						 error_p:(NSError**)error_p {
	NSArray* subpredicates ;
	if (predicate) {
		subpredicates = [NSArray arrayWithObject:predicate] ;
	}
	else {
		subpredicates = nil ;
	}
	NSArray* objects = [self objectsWithSubpredicates:subpredicates
											   type:NSAndPredicateType
											  error_p:error_p] ;
	return objects ;
}	

- (NSManagedObject*)objectWithPredicate:(NSPredicate*)predicate
								error_p:(NSError**)error_p {
	NSArray* fetches = [self objectsWithPredicate:predicate
										  error_p:error_p] ;
	NSManagedObject* finding = nil ;
	if ([fetches count] > 0) {
		finding = [fetches objectAtIndex:0] ;
	}
	
	return finding ;
}	

- (NSArray*)objectsWithDirectPredicateLeftExpression:(NSExpression*)lhs
									rightExpression:(NSExpression*)rhs
									   operatorType:(NSPredicateOperatorType)operatorType
											 error_p:(NSError**)error_p {
	NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression:lhs
																rightExpression:rhs
																	   modifier:NSDirectPredicateModifier
																		   type:operatorType
																		options:0] ;
	return [self objectsWithPredicate:predicate
							  error_p:error_p] ;
}

- (NSManagedObject*)objectWithDirectPredicateLeftExpression:(NSExpression*)lhs
											rightExpression:(NSExpression*)rhs
											   operatorType:(NSPredicateOperatorType)operatorType
													error_p:(NSError**)error_p {
	NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression:lhs
																rightExpression:rhs
																	   modifier:NSDirectPredicateModifier
																		   type:operatorType
																		options:0] ;
	return [self objectWithPredicate:predicate
							 error_p:error_p] ;
}

- (NSArray*)allObjectsError_p:(NSError**)error_p {
	NSError* error = nil ;
	
	NSFetchRequest* fetchRequest ;
	fetchRequest = [[NSFetchRequest alloc] init] ;
	NSManagedObjectContext* managedObjectContext = [self managedObjectContext] ;
	// The following was an interesting experiment.  In BookMacster 1.11, it caused
	// a "serious Core Data error" and also an error what looked like trying to bind
	// the Sync Log popup menu to a deallocated object in -[SSYArrayController selectFirstArrangedObject],
	// when it invoked -[NSArrayController removeSelectionIndexes:[self selectionIndexes]] ;
	// [managedObjectContext processPendingChanges] ;  // Do not do this
	
	[fetchRequest setEntity:[NSEntityDescription entityForName:[self entityName]  
										inManagedObjectContext:managedObjectContext]];
	// Since we didn't set a predicate in fetchRequest, we get all objects
	NSArray* allObjects = [managedObjectContext executeFetchRequest:fetchRequest
															  error:&error] ;
	if (error) {
		NSLog(@"Internal Error 915-1874 %@", [error localizedDescription]) ;
		if (error_p) {
			*error_p = error ;
		}
	}		
	[fetchRequest release] ;
	
	return allObjects ;
}

- (NSArray*)allObjects {
	NSError* error = nil ;
	NSArray* allObjects = [self allObjectsError_p:&error] ;
	if (error) {
		[SSYAlert alertError:error] ;
	}
	
	return allObjects ;
}

- (NSManagedObject*)freshObject {
	NSManagedObjectContext* moc = [self managedObjectContext] ;

	NSManagedObject* object = [NSEntityDescription insertNewObjectForEntityForName:[self entityName]
															inManagedObjectContext:moc] ;	
    // Added in BookMacster 1.16 to try and find a rare bug
    if (![[NSThread currentThread] isMainThread]) {
        NSLog(@"Internal Error 523-0024 %@\n%@",
              [self entityName],
              SSYDebugBacktraceDepth(8)) ;
    }

    return object ;
}

- (NSManagedObject*)objectWithID:(NSManagedObjectID*)objectID {
	return [[self managedObjectContext] objectWithID:objectID] ;
}

- (void)insertObject:(NSManagedObject*)object {
	[[self managedObjectContext] insertObject:object] ;
}

- (void)deleteObject:(NSManagedObject*)object {
	[[self managedObjectContext] deleteObject:object] ;
}

- (BOOL)deleteAllObjectsError_p:(NSError**)error_p {
	NSError* error = nil ;
	NSArray* allObjects = [self allObjectsError_p:&error] ;
	if (error) {
		if (error_p) {
			*error_p = error ;
		}
		goto end ;
	}
	
	NSManagedObjectContext* moc = [self managedObjectContext] ;
	for (NSManagedObject* object in allObjects) {
		[moc deleteObject:object] ;
	}
	
end:	
	return (error == nil) ;
}

- (BOOL)save:(NSError**)error_p {
    NSError* error = nil ;
    BOOL ok = NO ;
    @try {
        ok = [[self managedObjectContext] save:&error] ;
        // The following was added in BookMacster 1.12 because Cocoa error
        // 134030 error is sometimes received from users and, and I think it's
        // probably coming from here, but I want to prove it.  With this change,
        // 134030 will now be the underlying error.
        if (!ok) {
            error = [SSYMakeError(149034, @"Error saving local settings") errorByAddingUnderlyingError:error] ;
        }
    }
    @catch (NSException* exception) {
        ok = NO ;
        if (!error) {
            error = SSYMakeError(149035, @"Exception saving local settings") ;
        }
        error = [error errorByAddingUnderlyingException:exception] ;
    }

    if (error_p) {
        NSPersistentStore* store = [[self managedObjectContext] store1] ;
        error = [error errorByAddingUserInfoObject:[store description]
                                            forKey:@"Store"] ;
        error = [error errorByAddingUserInfoObject:[[store URL] path]
                                            forKey:@"Path"] ;
        *error_p = error ;
    }
    
	return ok ;
}

- (NSURL*)deleteFileError_p:(NSError**)error_p {
	NSManagedObjectContext* managedObjectContext = [self managedObjectContext] ;
	NSURL* storeUrl = [[managedObjectContext store1] URL] ;
	NSString* path = [storeUrl path] ;
	NSError* error = nil ;
	BOOL ok = [[NSFileManager defaultManager] removeItemAtPath:path
														 error:&error] ;
	if (!ok) {
		storeUrl = nil ;
		if (error_p) {
			*error_p = error ;
		}
	}		
	
	return storeUrl ;
}

@end