#import "SSYMOCManager.h"
#import "NSString+MorePaths.h"
#import "NSString+LocalizeSSY.h"
#import "NSError+SSYAdds.h"
#import "NSBundle+MainApp.h"
#import "SSYPersistentDocumentMultiMigrator.h"
#import "NSManagedObjectContext+Cheats.h"

NSString* const constKeyMOC = @"moc" ;
NSString* const constKeyOwner = @"owr" ;
NSString* const constKeyStoreUrl = @"sturl" ;


// This is a singleton, but not a "true singletons", because
// I didn't bother to override
//    +allocWithZone:
//    -copyWithZone: 
//    -retain
//    -retainCount
//    -release
//    -autorelease
static SSYMOCManager* sharedMOCManager = nil ;

#if DEBUG

@interface NSCountedSet (SSYMOCManagerHelp)

- (NSString*)shortDescription ;

@end

@implementation NSCountedSet (SSYMOCManagerHelp)

- (NSString*)shortDescription {
	NSMutableString* desc = [NSMutableString string] ;
	for (id object in self) {
		[desc appendFormat:
		 @"%@ [%d],",
		 [object shortDescription],
		 [self countForObject:object]] ;
	}

	// Delete the trailing comma
	if ([desc length] > 0) {
		[desc deleteCharactersInRange:NSMakeRange([desc length] - 1, 1)] ;
	}
	else {
		[desc appendString:@"<Empty Set>"] ;
	}

	return [[desc copy] autorelease] ;
}

@end

#endif


@interface SSYMOCManager (PrivateHeader)

@end

/*
 + (void)fileManager:(NSFileManager *)manager willProcessPath:(NSString *)path {
 NSLog(@"[%@ %s]:855 ", [self class], _cmd) ;
 }
 
 + (BOOL)fileManager:(NSFileManager *)manager shouldProceedAfterError:(NSDictionary *)errorInfo {
 NSLog(@"[%@ %s]:1011 errorInfo: %@", [self class], _cmd, errorInfo) ;
 return NO ;
 }
 */

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
		case NSAlertDefaultReturn:;
			// "Move"
			NSString* oldPath = [[[error userInfo] objectForKey:constKeyStoreUrl] path] ;
			NSString* oldFilename = [oldPath lastPathComponent] ;
			NSString* oldBaseFilename = [oldFilename stringByDeletingPathExtension] ;
			NSString* extension = [oldFilename pathExtension] ;
			NSString* newFilename = [NSString stringWithFormat:
									 @"%@-Unreadable-%@",
									 [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"],
									 oldBaseFilename] ;
			// We used CFBundleExecutable instead of CFBundleName to get an unlocalized app name.
			newFilename = [newFilename stringByAppendingPathExtension:extension] ;
			NSString* newPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"] ;
			newPath = [newPath stringByAppendingPathComponent:newFilename] ;
			NSLog(@"Moving database file \n   oldPath: %@\n   newPath: %@", oldPath, newPath) ;
			// In case the user already did this, movePath:toPath:handler requires
			// that the destination not already exist, so we must "remove" it first.
			NSFileManager* fm = [NSFileManager defaultManager] ;

#if (MAC_OS_X_VERSION_MAX_ALLOWED < 1060) 
			[fm removeFileAtPath:newPath
						 handler:nil] ;
			BOOL ok = [fm movePath:oldPath
							toPath:newPath
						   handler:nil] ;
#else
			[fm removeItemAtPath:newPath
						   error:NULL] ;
			BOOL ok = [fm moveItemAtPath:oldPath
								  toPath:newPath
								   error:NULL] ;
#endif
			// Since the old corrupted file is gone, +[SSYMOCManager addPersistentStoreWithType:::::]
			// will create a new file the next time it is invoked.  Problem should be solved.
			break ;
		default:
			ok = NO ;
	}
}

+ (NSURL*)sqliteStoreURLWithIdentifier:(NSString*)identifier {
	NSString* filename ;
	if (!identifier) {
		identifier = @"Shared" ;
	}
	filename = [identifier stringByAppendingPathExtension:@"sql"] ;
	NSString* path = [[NSString applicationSupportFolderForThisApp] stringByAppendingPathComponent:filename] ;
    NSURL* url = [NSURL fileURLWithPath:path] ;
	return url ;
}

+ (BOOL)sqliteStoreExistsForIdentifier:(NSString*)identifier {
	NSURL* url = [self sqliteStoreURLWithIdentifier:identifier] ;
	return [[NSFileManager defaultManager] fileExistsAtPath:[url path]] ;
}

+ (NSPersistentStoreCoordinator*)persistentStoreCoordinatorType:(NSString*)storeType
													 identifier:(NSString*)identifier
													   momdName:(NSString*)momdName
														error_p:(NSError**)error_p {
	NSPersistentStore* persistentStore = nil ;
	
	NSArray* bundles = [NSArray arrayWithObject:[NSBundle mainBundle]] ;
	NSManagedObjectModel* mergedMOM = [NSManagedObjectModel mergedModelFromBundles:bundles] ;
	NSPersistentStoreCoordinator* newPSC = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mergedMOM] ;

	if ([storeType isEqualToString:NSSQLiteStoreType]) {
		NSURL* url = [self sqliteStoreURLWithIdentifier:identifier] ;
		// i.e file://localhost/Users/jk/Library/Application%20Support/BookMacster/BookMacster.sql
		
		NSFileManager* fm = [NSFileManager defaultManager] ;

		// An undocumented fact about addPersistentStoreWithType:configuration:URL:options:error:
		// is that if the parent folder does not exist, the method will fail to create a
		// persistent store with no explanation.  So we make sure it exists
		NSString* parentPath = [[url path] stringByDeletingLastPathComponent] ;
		BOOL isDirectory ;
		BOOL fileExists = [fm fileExistsAtPath:parentPath isDirectory:&isDirectory] ;
		BOOL ok = YES ;
		if (fileExists && !isDirectory) {
			// Someone put a file where our directory should be
			ok = [fm removeItemAtPath:parentPath
								error:error_p] ;
		}
		
		NSError* error = nil ;
		if (ok && ((fileExists && !isDirectory) || !fileExists)) {
			// Create parent directory
#if (MAC_OS_X_VERSION_MAX_ALLOWED < 1060) 
			ok = [fm createDirectoryAtPath:parentPath
								attributes:nil] ;
#else
			ok = [fm createDirectoryAtPath:parentPath
			   withIntermediateDirectories:YES
								attributes:nil
									 error:&error] ;
#endif
}
	   
	   if (!ok) {
		   NSString* msg = [NSString stringWithFormat:
							@"Could not create directory at path %@",
							parentPath] ;
		   NSLog(@"%@", msg) ;
		   if (error_p) { 
			   *error_p = [SSYMakeError(95745, msg) errorByAddingUnderlyingError:error];
		   }
	   }
	   
	   if (ok) {	
		   NSDictionary* options ;
		   if (momdName) {
			   // Using Multi-Hop Migration
			   ok = [SSYPersistentDocumentMultiMigrator migrateIfNeededStoreAtUrl:url
																	 storeOptions:nil
																		storeType:NSSQLiteStoreType
																		 momdName:momdName
																		 document:nil
																		  error_p:error_p] ;
			   options = nil ;
		   }
		   else {
			   // Using Core Data's built-in Single-Hop Migration only
			   options = [NSDictionary dictionaryWithObjectsAndKeys:
						  [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
						  nil] ;
		   }
		   
		   if (ok) {
			   // Add persistent store to it
			   persistentStore = [newPSC addPersistentStoreWithType:NSSQLiteStoreType
													  configuration:nil
																URL:url
															options:nil
															  error:error_p] ;
#if 0
#warning Simulating a bad store to test error handling
			   persistentStore = nil ;
			   *error_p = SSYMakeError(12345, @"Can't use this stinkin' store") ;
			   NSLog(@"61745: Store set to nil for testing") ;
#endif
			   if (!persistentStore) {
				   BOOL fileExists = [fm fileExistsAtPath:[url path]] ;
				   if (fileExists) {
					   // If we did not get a store but file exists, must be a corrupt file.
					   NSString* msg = [NSString stringWithFormat:@"Click 'Move' to move the unreadable database\n%@\nto your desktop and start a new database.  The item properties in your old database will not be available to %@.",
										[url path],
										[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"]] ;
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
			   NSError* moveError = nil ;
			   BOOL movedOk = [[NSFileManager defaultManager] moveItemAtPath:originalPath
																	  toPath:tildefiedPath
																	   error:&moveError] ;
			   if (!movedOk) {
				   // The following error may be expected, because depending on how
				   // bad the subject file is, sometimes Core Data may have already
				   // subject file Foo.sql to Foo.unreadable.sql.  In this case,
				   // the error will be NSCocoaErrorDomain Code=4 "The file “Logs.sql” doesn’t exist."
				   NSLog(@"Warning 245-0492.  Error moving %@ to %@ : %@ userInfo: %@ ", originalPath, tildefiedPath, moveError, [moveError userInfo]) ;
			   }
		   }
	   }
   }
   else if ([storeType isEqualToString:NSInMemoryStoreType]) {
	   persistentStore = [newPSC addPersistentStoreWithType:NSInMemoryStoreType
											  configuration:nil
														URL:nil
													options:nil
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
																						 error_p:error_p] ;
		if (coordinator) {
			managedObjectContext = [[NSManagedObjectContext alloc] init] ;
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
			highestUsed = MAX(highestUsed, [number intValue]) ;
		}
		key = [NSNumber numberWithInt:(highestUsed+1)] ;
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

- (BOOL)releaseManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
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

- (BOOL)releaseManagedObjectContext:(NSManagedObjectContext*)managedObjectContext {
	BOOL didDo = NO ;
	didDo = [self releaseManagedObjectContext:managedObjectContext
								inDictionary:[self inMemoryMOCDics]] ;
	if (!didDo) {
		didDo = [self releaseManagedObjectContext:managedObjectContext
									inDictionary:[self sqliteMOCDics]] ;
	}
	
	if (!didDo) {
		didDo = [self releaseManagedObjectContext:managedObjectContext
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
											error_p:(NSError**)error_p {
	NSManagedObjectContext* moc = [[self sharedMOCManager] managedObjectContextType:type
																			  owner:owner
																		 identifier:identifier
																		   momdName:momdName
																			error_p:error_p] ;
	return moc ;
}

+ (id)ownerOfManagedObjectContext:(NSManagedObjectContext*)managedObjectContext {
	return [[self sharedMOCManager] ownerOfManagedObjectContext:managedObjectContext] ;
}

+ (BOOL)releaseManagedObjectContext:(NSManagedObjectContext*)managedObjectContext {
	return [[self sharedMOCManager] releaseManagedObjectContext:managedObjectContext] ;
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
// Because our method +persistentStoreCoordinatorType:identifier:momdName:error_p: always creates
// a new persistent store coordinator and always adds exactly one persistent
// store to it, we can just grab its first (and only) store.