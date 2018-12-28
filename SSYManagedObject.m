#import "SSYManagedObject.h"
#import "SSYMOCManager.h"
#import "SSYIndexee.h"
#import "SSYDooDooUndoManager.h"
#import "NSSet+Identicalness.h"
#import "NSDocument+SyncModDate.h"
#import "NSObject+MoreDescriptions.h"
#import "NSBundle+MainApp.h"
#import "NSEntityDescription+SSYMavericksBugFix.h"
#import "NSObject+DoNil.h"
#import "BSManagedDocument.h"
/* BSManagedDocument is a open source replacement for NSPersistentDocument.
 It is recommended for any Core Data document-based app.
 https://github.com/jerrykrinock/BSManagedDocument
 */

// Public Notifications
NSString* const SSYManagedObjectWillUpdateNotification = @"SSYManagedObjectWillUpdateNotification" ;
NSString* const SSYManagedObjectWillFaultNotification = @"SSYManagedObjectWillFaultNotification" ;

// Keys inside Notification UserInfo Dictionaries
NSString* const constKeySSYChangedKey = @"BkmxKey" ;
NSString* const constKeyNewValue = @"BkmxNewValue" ;

NSString* const constKeyObserver = @"observer" ;
NSString* const constKeyObserverOptions = @"options" ;
NSString* const constKeyObserverContext = @"context" ;

@implementation SSYManagedObject

#if 0
#warning overrode willChangeValueForKey.  Do not ship this.
/*!
 @brief    In a Core Data document-based application, you
 often have the problem of the close button getting a dirty
 dot immediately after a new document is created or an old
 one loaded, or you just want to know what the hell is
 happening when you click "Undo" and nothing happens.
 Paste this code into the NSManagedObject subclass that you
 suspect may be changing, or even better, if you have a
 NSManagedObject parent class for all your subclasses
 paste it in there.  Activate the #if above, compile,
 and run your app so that the dot gets dirty.  Then click
 Undo until the dot becomes clean as you watch the console.
 Any changes to your model will be logged.
 
 @details  Thanks to Dave Fernandes for this idea!
 */
- (void)willChangeValueForKey:(NSString*)key {
	NSUndoManager* um = [[self managedObjectContext] undoManager] ;
	// Todo: Since NSUndoManager is not thread-safe, should create
	// an NSInvocation here and invoke these next two on main thread:
	BOOL isUndoing = [um isUndoing] ;
	BOOL isRedoing = [um isRedoing] ;
	if (isUndoing || isRedoing) {
		NSLog(@"%@ %@did changed value for key: %@",
			  [[self entity] name],
			  isUndoing ? @"un" : @"re",
			  key) ;
		// Optional: Put a breakpoint here and debug to see what caused it
		;
	}
	[super willChangeValueForKey:key];
}

- (void)willTurnIntoFault {
	NSUndoManager* um = [[self managedObjectContext] undoManager] ;
	BOOL isUndoing = [um isUndoing] ;
	BOOL isRedoing = [um isRedoing] ;
	if (isUndoing || isRedoing) {
		NSLog(@"%@ will turn into fault",
			  [[self entity] name]
			  //			  [self shortDescription]
			  ) ;
		// Optional: Put a breakpoint here and debug to see what caused it
		;
	}
	[super willTurnIntoFault];
}

- (void)prepareForDeletion {
	NSUndoManager* um = [[self managedObjectContext] undoManager] ;
	BOOL isUndoing = [um isUndoing] ;
	BOOL isRedoing = [um isRedoing] ;
	if (isUndoing || isRedoing) {
		NSLog(@"%@ will prepareForDeletion",
			  [[self entity] name]
			  //			  [self shortDescription]
			  ) ;
		// Optional: Put a breakpoint here and debug to see what caused it
		;
	}
	[super prepareForDeletion] ;
}

- (void)awakeFromInsert {
	[super awakeFromInsert];
	NSUndoManager* um = [[self managedObjectContext] undoManager] ;
	BOOL isUndoing = [um isUndoing] ;
	BOOL isRedoing = [um isRedoing] ;
	if (isUndoing || isRedoing) {
		NSLog(@"%@ did awakeFromInsert",
			  [[self entity] name]
			  //			  [self shortDescription]
			  ) ;
		// Optional: Put a breakpoint here and debug to see what caused it
		;
	}
}

- (void)awakeFromFetch {
	[super awakeFromFetch];
	NSUndoManager* um = [[self managedObjectContext] undoManager] ;
	BOOL isUndoing = [um isUndoing] ;
	BOOL isRedoing = [um isRedoing] ;
	if (isUndoing || isRedoing) {
		NSLog(@"%@ did awakeFromFetch",
			  [[self entity] name]
			  //			  [self shortDescription]
			  ) ;
		// Optional: Put a breakpoint here and debug to see what caused it
		;
	}
}

#endif

+ (NSString*)entityNameForClass:(Class)class {
	return [NSStringFromClass(class) stringByAppendingString:@"_entity"] ;
}

#if 0
#define TEST_STACK_OVERFLOW_QUESTION_19626858 1
// See https://stackoverflow.com/questions/19626858/over-optimization-bug-in-10-9-core-data-entity-description-methods
#endif

+ (NSEntityDescription*)entityDescription {
    // This method was rewritten for BookMacster 1.19.2, to work around a
    // bug in macOS 10.9.  See
    // http://stackoverflow.com/questions/19626858/over-optimization-bug-in-10-9-core-data-entity-description-methods
    
	NSArray* bundles = [NSArray arrayWithObject:[NSBundle mainAppBundle]] ;
	NSManagedObjectModel* mom = [NSManagedObjectModel mergedModelFromBundles:bundles] ;
    NSString* entityName = [self entityNameForClass:self] ;

#if TEST_STACK_OVERFLOW_QUESTION_19626858
    NSPersistentStoreCoordinator* psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom] ;
	NSManagedObjectContext* moc = [[NSManagedObjectContext alloc] init] ;
	[moc setPersistentStoreCoordinator:psc] ;
	[psc release] ;
	NSEntityDescription* old1EntityDescription = [NSEntityDescription entityForName:[self entityNameForClass:self]
														 inManagedObjectContext:moc] ;
    NSDictionary* entitiesByName = [mom entitiesByName] ;
    NSEntityDescription* old2EntityDescription = [entitiesByName objectForKey:entityName] ;
    NSLog(@"ebn returns a %@", [entitiesByName className]) ;
    NSLog(@"oldEntityDesc1 = %p for %@", old1EntityDescription, entityName) ;
    NSLog(@"oldEntityDesc2 = %p for %@", old2EntityDescription, entityName) ;
	[moc release] ;
#endif
    
    NSDictionary* entities = [[NSDictionary alloc] initWithDictionary:[mom entitiesByName]] ;
    NSEntityDescription* entityDescription = [entities objectForKey:entityName] ;
#if TEST_STACK_OVERFLOW_QUESTION_19626858
    NSLog(@"new EntityDesc = %p for %@", entityDescription, [self entityNameForClass:self]) ;
#endif
    if (!entityDescription) {
        NSLog(@"Internal Error 561-3831 for %@", entityName) ;
    }
    [entities release] ;
    
	return entityDescription ;
}


- (NSString*)uniqueAttributeKey {
	return nil ;
}

/* Needs to be fixed:
 "Subclasses should invoke super’s implementation before performing their own validation,
 and should combine any error returned by super’s implementation with their own (see Validation)."
 // This checks for uniqueness of the uniqueAttributeKey
// If no value for uniqueAttributeKey, validates YES.
// Therefore, if you expect it to validate during initial creation, 
// this method must be re-invoked ^after^ uniqueAttributeKey has been 
// set to the potentially nonunique value.
- (BOOL)validateForInsert:(NSError **)error {	
	BOOL valid = YES ;
	NSString* uniqueAttributeKey = [self uniqueAttributeKey] ;
	if (uniqueAttributeKey) {
		id uniqueAttributeValue = [self valueForKeyPath:uniqueAttributeKey] ;
		if (uniqueAttributeValue) {
			NSManagedObjectContext* managedObjectContext = [self managedObjectContext] ;
			[super validateForInsert:error] ;
			if (*error) {
				goto end ;
			}
			
			NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init] ;
			[fetchRequest setEntity:[NSEntityDescription SSY_entityForName:[[self entity] name]
											    	inManagedObjectContext:managedObjectContext]] ;
			[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(%K == %@) AND (SELF != %@)",
				uniqueAttributeKey, uniqueAttributeValue, self]] ;
			NSArray* conflictingObjects = [managedObjectContext executeFetchRequest:fetchRequest
																			  error:error];
			[fetchRequest release] ;
			if (*error) {
				goto end ;
			}
			
			valid = ([conflictingObjects count] == 0) ;			
		}
	}
	
end:;
	
	return valid ;
}
 */

- (id)owner {
	return [SSYMOCManager ownerOfManagedObjectContext:[self managedObjectContext]] ;
}

- (id)allocOwner {
    id owner;
    @autoreleasepool {
        owner = [SSYMOCManager ownerOfManagedObjectContext:[self managedObjectContext]];
        [owner retain];
    }

    return owner;
}

- (BOOL)isAvailable {
	if ([self isDeleted]) {
		return NO ;	
	}
	
	NSManagedObjectContext* context = [self managedObjectContext] ;
	if (context == nil) {
		return NO ;
	}
	
	/* The next two tests are probably unnecessary.  I wrote to David Riggle:
	 Why do you check for the object ID?  Have you ever seen an object
	 which passed the first two tests (not isDeleted, has MOC), but then
	 didn't have an objectID?  How could that happen?
	 David Riggle replied:
	 I don't know if all those tests are necessary. I did show the method to a
	 Core Data engineer at WWDC one year and he thought it looked OK.
	 */
	
	NSManagedObjectID* objectID = [self objectID] ;
	if (objectID == nil) {
		NSLog(@"Warning 623-5825 Thanx D. Riggle!") ;
		return NO ;
	}

	NSManagedObject* object = [context objectRegisteredForID:objectID] ;
	if (!object) {
		NSLog(@"Warning 623-5852 Thanx D. Riggle!") ;
		return NO ;
	}

	return YES ;
}

- (NSString*)availabilityDescription {
    NSMutableString* availability = [NSMutableString new];

    if ([self isFault]) {
        [availability appendString:@"N"];
    } else {
        [availability appendString:@"Y"];
    }

    if ([self isDeleted]) {
        [availability appendString:@"N"];
    } else {
        [availability appendString:@"Y"];
    }

    NSManagedObjectContext* context = [self managedObjectContext] ;
    if (context == nil) {
        [availability appendString:@"N"];
    } else {
        [availability appendString:@"Y"];
    }

    NSManagedObjectID* objectID = [self objectID] ;
    if (objectID == nil) {
        [availability appendString:@"NN"];
    } else {
        [availability appendString:@"Y"];

        NSManagedObject* object = [context objectRegisteredForID:objectID] ;
        if (!object) {
            [availability appendString:@"N"];
        } else {
            [availability appendString:@"Y"];
        }
    }

    NSString* answer = [availability copy];

#if !__has_feature(objc_arc)
    [availability release];
    [answer autorelease];
#endif

    return answer;
}

- (NSString*)objectUriMakePermanent:(BOOL)makePermanent
						   document:(NSPersistentDocument*)document {
	NSManagedObjectID* objectID = [self objectID] ;
	if ([objectID isTemporaryID]) {
		if (makePermanent) {
			NSError* error = nil ;
			BOOL ok = [[self managedObjectContext] obtainPermanentIDsForObjects:[NSArray arrayWithObject:self]
																		  error:&error] ;
			
			if (document) {
				[document syncFileModificationDate] ;
			}
			objectID = [self objectID] ;
			if (!ok || [objectID isTemporaryID]) {
				NSLog(@"Internal Error 309-9200 Could not obtain permanent ID for %@ objectID=%@ ok=%hhd error=%@",
					  [self shortDescription],
					  objectID,
					  ok,
					  [error longDescription]) ;
			}
			
			if ([objectID isTemporaryID]) {
				objectID = nil ;
			}
		}
	}

	return [[objectID URIRepresentation] absoluteString] ;
}

- (void)setIndexedSetWithArray:(NSArray*)array
					 forSetKey:(NSString*)setKey {
	
	NSMutableSet* proxySet = [self mutableSetValueForKey:setKey] ;
	NSSet* newSet = [NSSet setWithArray:array] ;
	if ([newSet isIdenticalToSet:proxySet]) {
		return ;
	}
	
	[proxySet intersectSet:newSet] ;
	if ([newSet isIdenticalToSet:proxySet]) {
		// This was added in BookMacster 1.11, after I found that -[NSMutableSet unionSet:]
		// will stupidly add members to a set that are already in the set.  In the case
		// of a managed object this, this invokes _PFInvokeMutationMethodForEachMemberOfSet,
		// which in turn invokes -[Agent add<Foo>Object:], which if I have overridden that
		// with a custom setter as in the case of -[Agent addTriggersObject:], will
		// post notifications etc. indicating that a trigger has been added, which
		// is not true.  (I also fixed in in -[Agent addTriggersObject:], just for good
		// measure.)
		return ;
	}
	[proxySet unionSet:newSet] ;
	// My original code for doing the above was:
	//  [proxySet removeAllObjects] ;
	//  [proxySet addObjectsFromArray:array] ;
	// This looks like it does the same thing, but note that
	// it will trigger a pair of extraneous KVO notifications for
	// each object in the set that is not removed, as the object
	// is removed and then re-added.  The removal KVO notification
	// can cause observers to act as though an object was removed,
	// having undesired side effects.
	
	// Now that we've got the objects from the array into the
	// set, we set their indexes according to the way they were
	// in the array.
	// Prior to BookMacster 1.5, I did this at the
	// beginning of this method, which screwed things up if some
	// of newSet was a subset of proxySet.  The common elements
	// would have their indexes set to what they were supposed
	// to be *after* all was said and done, providing discontiguous
	// and duplicated indexes to -[NSMutableSet(Indexing) removeIndexedObject],
	// which operates on the assumption that indexes are contiguous
	// and not duplicated to begin with.
	NSInteger i = 0 ;
	for (NSObject <SSYIndexee> * object in array) {
		[object setIndex:[NSNumber numberWithInteger:i]] ;
		i++ ;
	}
}

- (void)postWillSetNewValue:(id)value
					 forKey:(NSString*)key {
    if (![NSObject isEqualHandlesNilObject1:[self valueForKey:key]
                            object2:value]) {
        // Extores do need the notification, to count changes, but they are not
        // undoable.  So we only begin an undo grouping if the owner is a BkmxDoc.
        if ([[self owner] isKindOfClass:[BSManagedDocument class]]) {
            // Note that beginAutoEndingUndoGrouping will coalesce for us.
            [(SSYDooDooUndoManager*)[[self owner] undoManager] beginAutoEndingUndoGrouping] ;
        }
        
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                              key, constKeySSYChangedKey,
                              value, constKeyNewValue,  // May be nil, so keep this last!
                              nil] ;
#if 0
#warning Logging postWillSetNewValue:forKey:
        NSLog(@"7120: Posting %@ with object: %@\nwith oldValue: %@\nwith info:\n%@",
              SSYManagedObjectWillUpdateNotification,
              [self shortDescription],
              [[self valueForKeyPath:key] shortDescription],
              [info shortDescription]) ;
#endif
        [[NSNotificationCenter defaultCenter] postNotificationName:SSYManagedObjectWillUpdateNotification
                                                            object:self
                                                          userInfo:info] ;
        /* In BookMacster version 1.3.19, I tried changing the above line to this…
         NSNotification* notification = [NSNotification notificationWithName:SSYManagedObjectWillUpdateNotification
         object:self
         userInfo:info] ;
         [[NSNotificationQueue defaultQueue] enqueueNotification:notification
         postingStyle:NSPostWhenIdle
         coalesceMask:(NSNotificationCoalescingOnName|NSNotificationCoalescingOnSender)
         forModes:nil] ;
         Indeed, the coalescing improved speed when deleting many starks of
         the same parent, by a factor of 2.77, because it was not necessary to
         re-index all of the siblings whenever one was removed.  However, it broke
         when, for example, dragging a stark from one BkmxDoc to another, because
         of the coalescing on sender (object=stark).  Since a new stark is created
         in this case, all of its attributes are changed from nil.  NSNotificationQueue
         selects one of these notifications to send.  The userInfo from all the other
         notifications is lost, which breaks the action of the -[BkmxDoc objectWillChangeNote:]
         which receives this notifications.  Chances are that it will find no change
         between newValue and oldValue, and thus do an early return. 
         I imagine there are many other test cases that would break also.*/
    }
}

- (void)logChangesForAllManagedObjectsInSameContext {
	NSError* error_ = nil ;
	
	NSFetchRequest* fetchRequest ;
	fetchRequest = [[NSFetchRequest alloc] init];
	NSManagedObjectContext* moc = [self managedObjectContext] ;
	NSArray* entityNames = [[[[moc persistentStoreCoordinator] managedObjectModel] entities] valueForKey:@"name"] ;
	NSUInteger nObjects = 0, nChanged = 0 ;
	for (NSString* entityName in entityNames) {
		NSEntityDescription* entity = [NSEntityDescription SSY_entityForName:entityName
                                                      inManagedObjectContext:moc] ;
		[fetchRequest setEntity:entity] ;
		NSArray* objects = [moc executeFetchRequest:fetchRequest
											  error:&error_] ;
		if (error_) {
			NSLog(@"Internal Error 576-4526 executing fetch request: %@", [error_ localizedDescription]) ;
		}
		nObjects += [objects count] ;
		
		for (NSManagedObject* object in objects) {
			NSDictionary* changedValues = [object changedValues] ;
			if ([changedValues count] > 0) {
				NSLog(@"Managed Object: %@\nHas Changes:\n%@",
					  object,
					  changedValues) ;
				nChanged++ ;
			}
		}
	}
	[fetchRequest release] ;
	NSLog(@"objects in moc: %ld total, %ld changed", (long)nObjects, (long)nChanged) ; 
}

- (void)breakRetainCycles {
	[[self managedObjectContext] refreshObject:self
								  mergeChanges:NO] ;
}

- (uint32_t)valuesHash {
	NSArray* attributeKeys = [[[self entity] attributesByName] allKeys] ;
	uint32_t valuesHash = 0 ;
	for (NSString* key in attributeKeys) {
#ifdef __LP64__
		uint32_t aHash = [[self valueForKey:key] hash] & 0x00000000ffffffff ;
#else
		uint32_t aHash = [[self valueForKey:key] hash] ;
#endif		
		valuesHash ^= aHash ;
	}
	
	return valuesHash ;
}

- (NSUInteger)countOfNonNilValues {
	NSUInteger count = 0 ;
	for (NSString* key in [self attributeKeys]) {
		if ([self valueForKey:key] != nil) {
			count++ ;
		}
	}
	
	return count ;
}

#if 0
#warning Testing snapshot events

+ (NSCountedSet*)awakenedObjects {
    if (!awakenedObjects) {
        awakenedObjects = [[NSCountedSet alloc] init] ;
        NSLog(@"awakenedObjects = %p", awakenedObjects) ;
    }
    
    return awakenedObjects ;
}

- (void)addAwakenedObject:(SSYManagedObject*)object {
    [[[self class] awakenedObjects] addObject:object] ;
}

- (void)removeAwakenedObject:(SSYManagedObject*)object {
    [[[self class] awakenedObjects] removeObject:object] ;
}

+ (void)logAwakenedObjects {
    NSCountedSet* awakenedObjects = [self awakenedObjects] ;
    for (id object in awakenedObjects) {
        printf("cnt=%02ld flt=%hhd del=%hhd rc=%ld %p %s\n",
               (long)[awakenedObjects countForObject:object],
               [object isFault],
               [object isDeleted],
               [object retainCount],
               object,
               [[object className] UTF8String]) ;
    }
}

- (void)awakeFromInsert {
    [self addAwakenedObject:self] ;
	[super awakeFromInsert] ;
}

- (void)awakeFromFetch {
    [self addAwakenedObject:self] ;
	[super awakeFromFetch];
}

- (void)willTurnIntoFault {
    [self removeAwakenedObject:self] ;
	[super willTurnIntoFault];
}

- (NSString*)eventDescriptionForFlags:(NSSnapshotEventType)flags {
    NSMutableString* eventsString = [[NSMutableString alloc] init] ;
    if ((flags & NSSnapshotEventUndoInsertion) != 0) {
        [eventsString appendString:@"+UndoInsert"] ;
    }
    if ((flags & NSSnapshotEventUndoDeletion) != 0) {
        [eventsString appendString:@"+UndoDelete"] ;
    }
    if ((flags & NSSnapshotEventUndoUpdate) != 0) {
        [eventsString appendString:@"+UndoUpdate"] ;
    }
    if ((flags & NSSnapshotEventRollback) != 0) {
        [eventsString appendString:@"+Rollback"] ;
    }
    if ((flags & NSSnapshotEventRefresh) != 0) {
        [eventsString appendString:@"+Refresh"] ;
    }
    if ((flags & NSSnapshotEventMergePolicy) != 0) {
        [eventsString appendString:@"+MergePolicy"] ;
    }
    
    NSEntityDescription* entityDescription = [[self class] entityDescription] ;
    NSArray* attributeKeys = [[entityDescription attributesByName] allKeys] ;
    
    NSInteger nonNils = 0 ;
    for (NSString* key in attributeKeys) {
        if ([self valueForKeyPath:key]) {
            nonNils++ ;
        }
    }
    
    NSString* answer = [[NSString alloc] initWithFormat:
                        @"%@ %ld/%ld values/keys %@",
                        [self className],
                        (long)nonNils,
                        (long)[attributeKeys count],
                        eventsString] ;
    [eventsString release] ;
    
    return [answer autorelease] ;
}

- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flags {
    NSLog(@"awakeSshot %p %@ %@", self, [self className], [self eventDescriptionForFlags:flags]) ;
    [super awakeFromSnapshotEvents:flags ] ;
}

#endif


#if 0
#warning Overrode SSYManagedObject -dealloc and -didTurnIntoFault for debug logging
- (void)dealloc {
	NSLog(@"dealloc %@ %p", [self className], self) ;
	[super dealloc] ;	
}
/*- (void)didTurnIntoFault {
	NSLog(@"didTurnIntoFault %@ %p", [self className], self) ;
	[super didTurnIntoFault] ;	
}
*/
#endif


@end
