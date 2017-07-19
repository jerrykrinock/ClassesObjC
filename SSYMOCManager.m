#import "SSYMOCManager.h"
#import "NSError+Recovery.h"
#import "NSError+MyDomain.h"
#import "NSString+MorePaths.h"
#import "NSString+LocalizeSSY.h"
#import "NSError+InfoAccess.h"
#import "NSBundle+MainApp.h"
#import "SSYPersistentDocumentMultiMigrator.h"
#import "NSManagedObjectContext+Cheats.h"
#import "NSError+DecodeCodes.h"
#import "NSObject+MoreDescriptions.h"
#import "BkmxBasis.h"
#import "NSBundle+SSYMotherApp.h"
#import "NSBundle+MainApp.h"
#import "NSDictionary+SimpleMutations.h"
#import "NSPersistentStoreCoordinator+PatchRollback.h"


NSString* const constKeyMOC = @"moc" ;
NSString* const constKeyOwner = @"owr" ;
NSString* const constKeyStoreUrl = @"sturl" ;

#if 0
#define SIMULATE_BAD_STORE 1
static BOOL didSimulateBadStoreOnce = NO;
#endif

// This is a singleton, but not a "true singletons", because
// I didn't bother to override
//    +allocWithZone:
//    -copyWithZone: 
//    -retain
//    -retainCount
//    -release
//    -autorelease
static SSYMOCManager* sharedMOCManager = nil ;


@interface SSYMOCManager (PrivateHeader)

@end

@implementation SSYMOCManager

+ (SSYMOCManager*)sharedMOCManager {
    @synchronized(self) {
        if (!sharedMOCManager) {
            sharedMOCManager = [[self alloc] init] ; 
        }
    }
	
	// No autorelease.  This sticks around forever.
    return sharedMOCManager ;
}

- (NSMutableDictionary*)inMemoryMOCDics {
	if (!inMemoryMOCDics) {
		inMemoryMOCDics = [[NSMutableDictionary alloc] init] ;
	}
	
	return inMemoryMOCDics ;
}

- (NSMutableDictionary*)sqliteMOCDics {
	if (!sqliteMOCDics) {
		sqliteMOCDics = [[NSMutableDictionary alloc] init] ;
	}
	
	return sqliteMOCDics ;
}

- (NSMutableDictionary*)docMOCDics {
	if (!docMOCDics) {
		docMOCDics = [[NSMutableDictionary alloc] init] ;
	}
	
	return docMOCDics ;
}

- (void)attemptRecoveryFromError:(NSError*)error
					 recoveryOption:(NSUInteger)recoveryOption
						delegate:(id)dontUseThis
			  didRecoverSelector:(SEL)useInvocationFromInfoDicInstead
					 contextInfo:(void*)contextInfo {
	error = [error deepestRecoverableError] ;
	switch(recoveryOption) {
		case NSAlertFirstButtonReturn:;
			// "Move"
			NSString* oldPath = [[[error userInfo] objectForKey:constKeyStoreUrl] path] ;
			NSString* oldFilename = [oldPath lastPathComponent] ;
			NSString* oldBaseFilename = [oldFilename stringByDeletingPathExtension] ;
			NSString* extension = [oldFilename pathExtension] ;
			NSString* newFilename = [NSString stringWithFormat:
									 @"%@-Unreadable-%@",
									 [[NSBundle mainAppBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"],
									 oldBaseFilename] ;
			// We used CFBundleExecutable instead of CFBundleName to get an unlocalized app name.
			newFilename = [newFilename stringByAppendingPathExtension:extension] ;
			NSString* newPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"] ;
			newPath = [newPath stringByAppendingPathComponent:newFilename] ;
			NSLog(@"Moving database file \n   oldPath: %@\n   newPath: %@", oldPath, newPath) ;
			// In case the user already did this, movePath:toPath:handler requires
			// that the destination not already exist, so we must "remove" it first.
			NSFileManager* fm = [NSFileManager defaultManager] ;

            NSError* error = nil ;
			[fm removeItemAtPath:newPath
						   error:NULL] ;
			BOOL ok = [fm moveItemAtPath:oldPath
								  toPath:newPath
								   error:&error] ;
            if (!ok) {
                NSLog(@"Error in %s: %@", __PRETTY_FUNCTION__, error) ;
            }

			// Since the old corrupted file is gone, +[SSYMOCManager addPersistentStoreWithType:::::]
			// will create a new file the next time it is invoked.  Problem should be solved.
			break ;
	}
}

+ (NSString*)directoryOfSqliteMOCs {
    NSBundle* mainAppBundle = [NSBundle mainAppBundle] ;
    return [mainAppBundle applicationSupportPathForMotherApp] ;
}

+ (NSURL*)sqliteStoreURLWithIdentifier:(NSString*)identifier {
	NSString* filename ;
	if (!identifier) {
		identifier = @"Shared" ;
	}
	filename = [identifier stringByAppendingPathExtension:SSYManagedObjectContextPathExtensionForSqliteStores] ;
	NSString* path = [[self directoryOfSqliteMOCs] stringByAppendingPathComponent:filename] ;
    NSURL* url = nil ;
    if (path) {
        // Above if() was added in BookMacster 1.19 to eliminate crash in case
        // the app's Application Suppport folder is trashed while Worker is
        // watching one or more files in it for changes.
        url = [NSURL fileURLWithPath:path] ;
    }

	return url ;
}

+ (BOOL)sqliteStoreExistsForIdentifier:(NSString*)identifier {
	NSURL* url = [self sqliteStoreURLWithIdentifier:identifier] ;
	return [[NSFileManager defaultManager] fileExistsAtPath:[url path]] ;
}

+ (NSPersistentStoreCoordinator*)persistentStoreCoordinatorType:(NSString*)storeType
													 identifier:(NSString*)identifier
													   momdName:(NSString*)momdName
                                                        options:(NSDictionary*)options
                                           nukeAndPaveIfCorrupt:(BOOL)nukeAndPaveIfCorrupt
														error_p:(NSError**)error_p {
	NSPersistentStore* persistentStore = nil ;
	
	NSArray* bundles = [NSArray arrayWithObject:[NSBundle mainAppBundle]] ;
	NSManagedObjectModel* mergedMOM = [NSManagedObjectModel mergedModelFromBundles:bundles] ;
	NSPersistentStoreCoordinator* newPSC = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mergedMOM] ;

	if ([storeType isEqualToString:NSSQLiteStoreType]) {
		NSURL* url = [self sqliteStoreURLWithIdentifier:identifier] ;
		// i.e file://localhost/Users/jk/Library/Application%20Support/BookMacster/BookMacster.sql
		
		NSFileManager* fm = [NSFileManager defaultManager] ;
		BOOL ok = YES ;

		// An undocumented fact about addPersistentStoreWithType:configuration:URL:options:error:
		// is that if the parent folder does not exist, the method will fail to create a
		// persistent store with no explanation.  So we make sure it exists
		NSString* parentPath = [[url path] stringByDeletingLastPathComponent] ;

        if (!parentPath) {
            ok = NO ;
        }
        
		BOOL isDirectory = NO ;
		BOOL fileExists = NO ;
        
        if (ok) {
            [fm fileExistsAtPath:parentPath isDirectory:&isDirectory] ;
            if (fileExists && !isDirectory) {
                // Someone put a file where our directory should be
                ok = [fm removeItemAtPath:parentPath
                                    error:error_p] ;
            }
        }

		NSError* error = nil ;
		if (ok && ((fileExists && !isDirectory) || !fileExists)) {
			// Create parent directory
			ok = [fm createDirectoryAtPath:parentPath
			   withIntermediateDirectories:YES
								attributes:nil
									 error:&error] ;
		}
	   
		if (!ok) {
			NSString* msg = [NSString stringWithFormat:
							 @"Could not create directory at %@",
							 parentPath] ;
            error = [SSYMakeError(95745, msg) errorByAddingUnderlyingError:error] ;
            NSLog(@"%@", error) ;
			if (error_p) {
				*error_p = error ;
            }
		}
		
		if (ok) {
            if (momdName) {
			   // Using Multi-Hop Migration
			   ok = [SSYPersistentDocumentMultiMigrator migrateIfNeededStoreAtUrl:url
																	 storeOptions:options
																		storeType:NSSQLiteStoreType
																		 momdName:momdName
																		 document:nil
																		  error_p:error_p] ;
		   }
		   else {
			   // Using Core Data's built-in Single-Hop Migration only
               NSDictionary* moreOption = [NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                           nil] ;
               if (options) {
                   options = [options dictionaryByAddingEntriesFromDictionary:moreOption] ;
               }
               else {
                   options = moreOption ;
               }
		   }
		   
            // Here is where option journal_mode gets used
            if (ok) {
                // Add persistent store to it
                persistentStore = [newPSC addPersistentStoreWithType:NSSQLiteStoreType
                                                       configuration:nil
                                                                 URL:url
                                                             options:options
                                                               error:error_p] ;
#if SIMULATE_BAD_STORE
                if (!didSimulateBadStoreOnce) {
                    persistentStore = nil ;
                    NSString* simulatedErrorDescription = [NSString stringWithFormat:
                                                           @"Can't use this stinkin' store at\n%@",
                                                           url.path];
                    *error_p = SSYMakeError(12345, simulatedErrorDescription) ;
                    NSLog(@"61745: Simulating bad store at %@", url.path);
                    didSimulateBadStoreOnce = YES;
                }
#endif
			   if (!persistentStore) {
				   BOOL fileExists = [fm fileExistsAtPath:[url path]] ;
				   if (fileExists) {
                       if (nukeAndPaveIfCorrupt) {
                           // If we did not get a store but file exists, must be a corrupt file.
                           [fm removeItemAtURL:url
                                         error:NULL];
                           persistentStore = [newPSC addPersistentStoreWithType:NSSQLiteStoreType
                                                                  configuration:nil
                                                                            URL:url
                                                                        options:options
                                                                          error:error_p] ;
                       }

                       if (!persistentStore) {
                           NSString* msg = [NSString stringWithFormat:@"Click 'Move' to move the unreadable database\n%@\nto your desktop and start a new database.  The item properties in your old database will not be available to %@.",
                                            [url path],
                                            [[NSBundle mainAppBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"]] ;
                           // We used CFBundleExecutable instead of CFBundleName to get an unlocalized app name.
                           if (error_p) {
                               *error_p = [*error_p errorByAddingLocalizedRecoverySuggestion:msg] ;
                               NSArray* recoveryOptions = [NSArray arrayWithObjects:
                                                           [NSString localize:@"move"],
                                                           [NSString localize:@"cancel"],
                                                           nil] ;
                               *error_p = [*error_p errorByAddingLocalizedRecoveryOptions:recoveryOptions] ;
                               *error_p = [*error_p errorByAddingRecoveryAttempter:[self sharedMOCManager]] ;
                               *error_p = [*error_p errorByAddingUserInfoObject:url
                                                                         forKey:constKeyStoreUrl] ;
                           }
                       }
				   }
				   else {
					   NSString* msg = [NSString stringWithFormat:
										@"Could not create persistent store file at path %@",
										[url absoluteString]] ;
					   NSLog(@"%@", msg) ;
					   if (error_p) { 
						   *error_p = SSYMakeError(51298, msg) ;
					   }
				   }
			   }
		   }
		   else if ([*error_p involvesCode:SSYPersistentDocumentMultiMigratorErrorCodeNoSourceModel
									domain:SSYPersistentDocumentMultiMigratorErrorDomain]) {
			   NSString* originalPath = [url path] ;
			   NSString* tildefiedPath = [originalPath tildefiedPath] ;
			   BOOL movedOk = [[NSFileManager defaultManager] moveItemAtPath:originalPath
																	  toPath:tildefiedPath
																	   error:NULL] ;
			   if (!movedOk) {
				   // This may happen in two situations that I know of…
				   // 1.  If the subject file is really bad, sometimes Core Data may have already
				   //     moved subject file Foo.sql to Foo.unreadable.sql.  In this case,
				   //     the error will be NSCocoaErrorDomain Code=4 "The file “Logs.sql” doesn’t exist."
				   // 2.  If the subject file did not exist to begin with.
				   // In either case, moveITemAtPath::: will return an error with
				   // Domain=NSCocoaErrorDomain Code=4, containing an underlying error with
				   // Error Domain=NSPOSIXErrorDomain Code=2.  We ignore it, don't even ask for it.
			   }
		   }
	   }
   }
   else if ([storeType isEqualToString:NSInMemoryStoreType]) {
	   persistentStore = [newPSC addPersistentStoreWithType:NSInMemoryStoreType
											  configuration:nil
														URL:nil
													options:options
													  error:error_p] ;
	   
	   if (!persistentStore) {
		   NSLog(@"Internal Error 535-1498.  Failed to create inMemory persistent store") ;
	   }
   }
	
	if (!persistentStore) {
		// If persistentStore could not be added, we don't want the
		// newPSC to be returned because it won't work
		[newPSC release] ;
		newPSC = nil ;
	}
	
	return [newPSC autorelease] ;
}

- (NSManagedObjectContext*)managedObjectContextType:(NSString*)type
											  owner:(id)owner_
										 identifier:(NSString*)identifier
										   momdName:(NSString*)momdName
                                            options:(NSDictionary*)options
                               nukeAndPaveIfCorrupt:(BOOL)nukeAndPaveIfCorrupt
											error_p:(NSError**)error_p {
	NSManagedObjectContext* managedObjectContext = nil ;
    NSMutableDictionary* mocDics = nil ;
    if ([type isEqualToString:NSInMemoryStoreType]) {
		mocDics = [self inMemoryMOCDics] ;
	}
	else if ([type isEqualToString:NSSQLiteStoreType]) {
		mocDics = [self sqliteMOCDics] ;
	}

	if (!identifier) {
		identifier = @"CommonData" ;
	}
	
	NSDictionary* mocDic = [mocDics objectForKey:identifier] ;
	managedObjectContext = [mocDic objectForKey:constKeyMOC] ;
	
	if (!managedObjectContext) {
		NSPersistentStoreCoordinator* coordinator = [[self class] persistentStoreCoordinatorType:type
																					  identifier:identifier
																						momdName:momdName
                                                                                         options:options
                                                                            nukeAndPaveIfCorrupt:nukeAndPaveIfCorrupt
																						 error_p:error_p] ;
		if (coordinator) {
            managedObjectContext = [[NSManagedObjectContext alloc] init] ;
            // NSLog(@"Created for %@ moc %p on thread %p isMain=%hhd", identifier, managedObjectContext, [NSThread currentThread], [[NSThread currentThread] isMainThread]) ;
			[managedObjectContext setPersistentStoreCoordinator:coordinator] ;
			if (!owner_) {
				// A no-owner moc is a "cheap" moc.
				[managedObjectContext setUndoManager:nil] ;
				
				// Give it the default owner
				owner_ = NSApp ;
			}
			NSDictionary* mocDic = [NSDictionary dictionaryWithObjectsAndKeys:
									managedObjectContext, constKeyMOC,
									owner_, constKeyOwner,
									nil] ;
			[mocDics setObject:mocDic
						forKey:identifier] ;
			
			[managedObjectContext release] ; // balances +alloc, above
            ;
		}
	}
	
	return managedObjectContext ;
}

+ (void)registerOwnerDocument:(NSPersistentDocument*)document
	   ofManagedObjectContext:(NSManagedObjectContext*)managedObjectContext {
	NSMutableDictionary* mocDics = [[self sharedMOCManager] docMOCDics] ;

	// Check for an existing entry for this owner.  To make sure we
	// replace it, we'll use the same key.
	NSNumber* key = nil ;
	for (NSNumber* aKey in mocDics) {
		NSDictionary* mocDic = [mocDics objectForKey:aKey] ;
		if ([mocDic objectForKey:constKeyOwner] == document) {
			key = aKey ;
			break ;
		}
	}
	
	if (key == nil) {
		// We need an arbitrary but unique key
		NSInteger highestUsed = 0 ;
		for (NSNumber* number in mocDics) {
			highestUsed = MAX(highestUsed, [number integerValue]) ;
		}
		key = [NSNumber numberWithInteger:(highestUsed+1)] ;
	}
	
	NSDictionary* mocDic = [NSDictionary dictionaryWithObjectsAndKeys:
							managedObjectContext, constKeyMOC,
							document, constKeyOwner,
							nil] ;
	
	[mocDics setObject:mocDic
				forKey:key] ;
}


- (id)ownerOfManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
					 inDictionary:(NSDictionary*)dictionary {
	for (NSString* identifier in dictionary) {
		NSDictionary* mocDic = [dictionary objectForKey:identifier] ;
		if ([mocDic objectForKey:constKeyMOC] == managedObjectContext) {
			return [mocDic objectForKey:constKeyOwner] ;
		}
	}
	
	return nil ;
}

- (id)ownerOfManagedObjectContext:(NSManagedObjectContext*)managedObjectContext {
	id answer = [self ownerOfManagedObjectContext:managedObjectContext
									 inDictionary:[self inMemoryMOCDics]] ;
	
	if (!answer) {
		answer = [self ownerOfManagedObjectContext:managedObjectContext
									  inDictionary:[self sqliteMOCDics]] ;
	}
	
	if (!answer) {
		answer = [self ownerOfManagedObjectContext:managedObjectContext
									  inDictionary:[self docMOCDics]] ;
	}
	
	return answer ;
}

- (void)destroyManagedObjectContextWithIdentifier:(NSString*)identifier {
	if (identifier) {
        [[self inMemoryMOCDics] removeObjectForKey:identifier] ;
        [[self sqliteMOCDics] removeObjectForKey:identifier] ;
        [[self docMOCDics] removeObjectForKey:identifier] ;
    }
}

- (BOOL)destroyManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
					   inDictionary:(NSMutableDictionary*)dictionary {
	NSString* removeeIdentifier = nil ;
	for (NSString* identifier in dictionary) {
		NSDictionary* mocDic = [dictionary objectForKey:identifier] ;
		if ([mocDic objectForKey:constKeyMOC] == managedObjectContext) {
			removeeIdentifier = identifier ;
			break ;
		}
	}
	
	if (removeeIdentifier) {
		[dictionary removeObjectForKey:removeeIdentifier] ;
	}

	return (removeeIdentifier != nil) ;
}	

- (BOOL)destroyManagedObjectContext:(NSManagedObjectContext*)managedObjectContext {
	BOOL didDo = NO ;
	didDo = [self destroyManagedObjectContext:managedObjectContext
								inDictionary:[self inMemoryMOCDics]] ;
	if (!didDo) {
		didDo = [self destroyManagedObjectContext:managedObjectContext
									inDictionary:[self sqliteMOCDics]] ;
	}
	
	if (!didDo) {
		didDo = [self destroyManagedObjectContext:managedObjectContext
									inDictionary:[self docMOCDics]] ;
	}

	return didDo ;
}

- (void) dealloc {
    [inMemoryMOCDics release] ;
    [sqliteMOCDics release] ;
    [docMOCDics release] ;
	
	[super dealloc] ;
}

+ (NSManagedObjectContext*)managedObjectContextType:(NSString*)type
											  owner:(id)owner
										 identifier:(NSString*)identifier
										   momdName:(NSString*)momdName
                        useLegacyRollbackJournaling:(BOOL)useLegacyRollbackJournaling
                               nukeAndPaveIfCorrupt:(BOOL)nukeAndPaveIfCorrupt
											error_p:(NSError**)error_p {
    NSDictionary* options = nil ;
    if ([type isEqualToString:NSSQLiteStoreType]) {
        if (useLegacyRollbackJournaling) {
            options = [NSPersistentStoreCoordinator dictionaryByAddingSqliteRollbackToDictionary:nil] ;
        }
    }

	NSManagedObjectContext* moc = [[self sharedMOCManager] managedObjectContextType:type
																			  owner:owner
																		 identifier:identifier
																		   momdName:momdName
                                                                            options:options
                                                               nukeAndPaveIfCorrupt:nukeAndPaveIfCorrupt
																			error_p:error_p] ;
	return moc ;
}

+ (id)ownerOfManagedObjectContext:(NSManagedObjectContext*)managedObjectContext {
	return [[self sharedMOCManager] ownerOfManagedObjectContext:managedObjectContext] ;
}

+ (BOOL)destroyManagedObjectContext:(NSManagedObjectContext*)managedObjectContext {
	return [[self sharedMOCManager] destroyManagedObjectContext:managedObjectContext] ;
}

+ (void)destroyManagedObjectContextWithIdentifier:(NSString*)identifier {
	[[self sharedMOCManager] destroyManagedObjectContextWithIdentifier:identifier] ;
}

+ (void)removeSqliteStoreForIdentifier:(NSString*)identifier {
	NSURL* url = [self sqliteStoreURLWithIdentifier:identifier] ;
	[[NSFileManager defaultManager] removeItemAtPath:[url path]
											   error:NULL] ;
}


+ (BOOL)moc:(NSManagedObjectContext*)moc
	isInDic:(NSDictionary*)dic {
	// The outer key is the serial number assigned in -registerOwnerDocument::
	// The pointer to the moc is a value for the inner key constKeyMoc
	for (NSNumber* number in dic) {
		if ([[dic objectForKey:number] objectForKey:constKeyMOC] == moc) {
			return YES ;
		}
	}
	
	return NO ;
}

+ (BOOL)isInMemoryMOC:(NSManagedObjectContext*)moc {
	return [self moc:moc
			 isInDic:[[self sharedMOCManager] inMemoryMOCDics]] ;
}

+ (BOOL)isSqliteMOC:(NSManagedObjectContext*)moc {
	return [self moc:moc
			 isInDic:[[self sharedMOCManager] sqliteMOCDics]] ;
}

+ (BOOL)isDocMOC:(NSManagedObjectContext*)moc {
	return [self moc:moc
			 isInDic:[[self sharedMOCManager] docMOCDics]] ;
}



#if DEBUG
+ (void)logDebugCurrentSqliteMocs {
	NSDictionary* sqliteMOCDics = [[self sharedMOCManager] sqliteMOCDics] ;
	NSLog(@"Listing of SSYManaged SQLite MOCs") ;
	for (NSString* identifier in sqliteMOCDics) {
		NSManagedObjectContext* moc = [[sqliteMOCDics objectForKey:identifier] objectForKey:constKeyMOC] ;
		id owner = [[sqliteMOCDics objectForKey:identifier] objectForKey:constKeyOwner] ;
		NSCountedSet* stats = [[NSCountedSet alloc] init] ;
		for (NSManagedObject* object in [moc registeredObjects]) {
			NSString* entityName = [[object entity] name] ;
			[stats addObject:entityName] ;
		}
		NSLog(@"   moc %p owned by %@ at %@\n      Object Counts: %@",
			  moc,
			  [owner shortDescription],
			  [[[[moc store1] URL] path] lastPathComponent],
			  [stats shortDescription]) ;
		[stats release] ;
	} 
}
#endif
@end

// Note 1.
// Because our method +persistentStoreCoordinatorType:::::: always creates
// a new persistent store coordinator and always adds exactly one persistent
// store to it, we can just grab its first (and only) store.
