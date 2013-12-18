#import "SSYPersistentDocumentMultiMigrator.h"
#import "NSFileManager+SomeMore.h"
#import "NSString+LocalizeSSY.h"
#import "NSError+InfoAccess.h"
#import "NSString+MorePaths.h"
#import "NSDocument+SyncModDate.h"
#import "NSError+Recovery.h"
#import "NSBundle+MainApp.h"
#import "NSDocument+SSYAutosaveBetter.h"


NSString* const SSYPersistentDocumentMultiMigratorErrorDomain = @"SSYPersistentDocumentMultiMigratorErrorDomain" ;
NSString* const SSYPersistentDocumentMultiMigratorDidBeginMigrationNotification = @"SSYPersistentDocumentMultiMigratorDidBeginMigrationNotification" ;
NSString* const SSYPersistentDocumentMultiMigratorDidEndMigrationNotification = @"SSYPersistentDocumentMultiMigratorDidEndMigrationNotification" ;

@implementation SSYPersistentDocumentMultiMigrator

+ (void)addUpdateCheckRecoveryToInfo:(NSMutableDictionary*)errorInfo {
	[errorInfo setObject:[NSNumber numberWithBool:YES]
				  forKey:SSYRecoveryAttempterIsAppDelegateErrorKey] ;
	NSArray* recoveryOptions = [NSArray arrayWithObjects:
								[NSString localize:@"checkForUpdate"],
								[NSString localize:@"cancel"],
								nil] ;
	[errorInfo setObject:[NSString localize:@"checkUpdateDo"]
				  forKey:NSLocalizedRecoverySuggestionErrorKey] ;
	[errorInfo setObject:recoveryOptions
				  forKey:NSLocalizedRecoveryOptionsErrorKey] ;
}

#if 0
#warning Simulating model version not available
#define SIMULATE_MODEL_VERSION_NOT_AVAILABLE 1
#endif

+ (BOOL)migrateIfNeededStoreAtUrl:(NSURL*)url
					 storeOptions:(NSDictionary*)storeOptions
						storeType:(NSString*)storeType
						 momdName:(NSString*)momdName
						 document:(NSDocument*)document
						  error_p:(NSError**)error_p {
	// Create newStoreOptions, which is old storeOptions with NSMigratePersistentStoresAutomaticallyOption added.
	NSMutableDictionary *newStoreOptions ;
	if (storeOptions == nil) {
		newStoreOptions = [NSMutableDictionary dictionary];
	}
	else {
		newStoreOptions = [[storeOptions mutableCopy] autorelease] ;
	}
	[newStoreOptions setObject:[NSNumber numberWithBool:YES]
						forKey:NSMigratePersistentStoresAutomaticallyOption] ;
	
	// Stuff we'll use throughout this method
	BOOL ok = YES ;
	BOOL didPostNotification = NO ;
	NSString* documentPath = [url path] ;
	NSInteger errorCode = 0 ;
	NSError* underlyingError = nil ;
	NSMutableDictionary* errorInfo = [NSMutableDictionary dictionary] ;
	
	NSURL* destempUrl = nil ; 	// destemp means "destination/temporary"
	
	// Get store metadata for the document to be opened.
    // If the file indicated at url will not load, Core Data will log an
    // "error" here.  I @tryed to @catch exceptions, but got nothing.
    // Oh well, just ignore it.
	NSDictionary *storeMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:nil
																							 URL:url 
																						   error:&underlyingError] ;  
	if (!storeMetadata) {
		// Besides being invoked when opening an existing document,
		// -[NSPersistentDocument configurePersistentStoreCoordinatorForURL:ofType:modelConfiguration:storeOptions:error:]
		// is also invoked by -[NSPersistentDocument writeSafelyToURL:ofType:forSaveOperation:error:] when
		// creating a *new* document.  If there's no metadata, we concluded that's what's happened
		// in this case, and therefore we no-op.
		goto end ;
	}
	
	// Read the "VersionInfo" plist.
	NSString* momdPath = [[NSBundle mainAppBundle] pathForResource:momdName
														 ofType:@"momd"] ;
	NSBundle* modelBundle = [NSBundle bundleWithPath:momdPath] ;
	if (!modelBundle) {
		errorCode = SSYPersistentDocumentMultiMigratorErrorCodeNoModelBundle ;
		[errorInfo setValue:momdPath
					 forKey:@"momd path"] ;
		goto end ;
	}
	NSString* plistPath = [modelBundle pathForResource:@"VersionInfo"
												ofType:@"plist"] ;
	NSData* plistData = [NSData dataWithContentsOfFile:plistPath] ;
	if (!modelBundle) {
		errorCode = SSYPersistentDocumentMultiMigratorErrorCodeNoModelVersionPlist ;
		[errorInfo setValue:plistPath
					 forKey:@"plist path"] ;
		goto end ;
	}
	NSString* errorString = nil ;
	NSDictionary* versionInfo = [NSPropertyListSerialization propertyListFromData:plistData 
																 mutabilityOption:NSPropertyListImmutable
																		   format:NULL
																 errorDescription:&errorString] ;
	if (!versionInfo) {
		errorCode = SSYPersistentDocumentMultiMigratorErrorCodeNoVersionInfoInPlist ;
		[errorInfo setValue:errorString
					 forKey:NSLocalizedDescriptionKey] ;
		goto end ;
	}
	
	// Extract from plist the current model version.
	NSString* currentModelVersionName = [versionInfo objectForKey:@"NSManagedObjectModel_CurrentVersionName"] ;
	if (!currentModelVersionName) {
		errorCode = SSYPersistentDocumentMultiMigratorErrorCodeNoCurrentVersionName ;
		goto end ;
	}
	
	// Extract from plist an array of all model versions.
	NSDictionary* versionDic = [versionInfo objectForKey:@"NSManagedObjectModel_VersionHashes"] ;
	NSArray* modelVersionNames = [versionDic allKeys] ;
	// I suppose that modelVersionNames could be nil if there was only one version,
	// so we won't test that for error here
	
	// Get managed object model of current model version and see if it works.
	NSString* modelPath = [modelBundle pathForResource:currentModelVersionName
												ofType:@"mom"] ;
	NSManagedObjectModel* currentModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath: modelPath]] ;
	ok = [currentModel isConfiguration:nil
		   compatibleWithStoreMetadata:storeMetadata] ;
	[currentModel release] ;
#if SIMULATE_MODEL_VERSION_NOT_AVAILABLE
	ok = NO ;
#endif
	if (ok) {
		goto end ;
	}
	
	NSLog(@"Beginning migration for %@", documentPath) ;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:SSYPersistentDocumentMultiMigratorDidBeginMigrationNotification
														object:url] ;
	didPostNotification = YES ;	
	
	NSFileManager* fileManager = [NSFileManager defaultManager] ;
	
	// For each other model version, get managed object model and send it
	// -isConfiguration:compatibleWithStoreMetadata:, until you find one that
	// is compatible with the document.
	NSManagedObjectModel* sourceModel = nil ;
	NSString* sourceModelVersionName = nil ;
	
	for (sourceModelVersionName in modelVersionNames) {
		NSString* modelPath = [modelBundle pathForResource:sourceModelVersionName
													ofType:@"mom"] ;
		sourceModel = [[[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:modelPath]] autorelease] ;
		ok = [sourceModel isConfiguration:nil
			  compatibleWithStoreMetadata:storeMetadata] ;
		if (ok) {
			NSLog(@"Found compatible sourceModel: '%@'", sourceModelVersionName) ;
			break ;
		}
		sourceModel = nil ;
	}		
	if (!sourceModel) {
		errorCode = SSYPersistentDocumentMultiMigratorErrorCodeNoSourceModel ;
		[errorInfo setValue:url
					 forKey:@"URL"] ;

		// Additional error info added in BookMacster version 1.3.19…

		[errorInfo setValue:storeMetadata
					 forKey:@"Store Metadata"] ;

		NSDictionary* versionHashesDic = [storeMetadata objectForKey:NSStoreModelVersionHashesKey] ;
		// Defensive programming against corrupt files…
		if ([versionHashesDic respondsToSelector:@selector(allKeys)]) {
			[errorInfo setValue:[versionHashesDic allKeys]
						 forKey:@"Version Hashes Keys"] ;
		}
		
		NSString* path = [url path] ;
        NSDate *modificationDate = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL] objectForKey:NSFileModificationDate] ;
		[errorInfo setValue:modificationDate
					 forKey:@"Store Modification Date"] ;
		
		// Rename the bad store so this error will not recur
		// Also added in BookMacster verison 1.3.19
		NSString* extension = [path pathExtension] ; // Should be "sql"
		NSString* newPath = [path stringByDeletingPathExtension] ;
		newPath = [newPath stringByAppendingPathExtension:@"unreadable"] ;
		newPath = [newPath stringByAppendingPathExtension:extension] ;
		[[NSFileManager defaultManager] moveItemAtPath:path
												toPath:newPath
												 error:NULL] ;

		goto end ;
	}
	
	destempUrl = [NSURL fileURLWithPath:[documentPath stringByAppendingPathExtension:@"temp"]] ;
	NSString* destempPath ;
	
	BOOL firstStage = YES ;
	while (YES) {
		destempPath = [destempUrl path] ;
		
		// Send +[NSMappingModel mappingModelFromBundles:forSourceModel:destinationModel:]
		// with different destination models until you get a mapping model.  Call the
		// successful destination the destinModel.
		NSManagedObjectModel* destinModel = nil ;
		NSMappingModel* mappingModel = nil ;
		NSArray* bundles = [NSArray arrayWithObject:[NSBundle mainAppBundle]] ;
		NSString* destinModelVersionName = nil ;
		for (destinModelVersionName in modelVersionNames) {
			NSString* modelPath = [modelBundle pathForResource:destinModelVersionName
														ofType:@"mom"] ;
#if SIMULATE_MODEL_VERSION_NOT_AVAILABLE
#else
			destinModel = [[[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:modelPath]] autorelease] ;
			mappingModel = [NSMappingModel mappingModelFromBundles:bundles
													forSourceModel:sourceModel
												  destinationModel:destinModel] ;
#endif
			if (!destinModel) {
				errorCode = SSYPersistentDocumentMultiMigratorErrorCodeNoDestinModel ;
				[errorInfo setValue:modelPath
							 forKey:@"modelPath"] ;
				[self addUpdateCheckRecoveryToInfo:errorInfo] ;
				break ;
			}
			
			if (mappingModel) {
				NSLog(@"Found mapping model for mapping '%@' -> '%@'",
					  sourceModelVersionName,
					  destinModelVersionName) ;
				break ;
			}
			destinModel = nil ;
		}		
		if (!mappingModel) {
			errorCode = SSYPersistentDocumentMultiMigratorErrorCodeNoMappingModel ;
			[errorInfo setValue:sourceModelVersionName
						 forKey:@"sourceModelVersionName"] ;
			[self addUpdateCheckRecoveryToInfo:errorInfo] ;
			break ;
		}
		
		
		// Create a NSMigrationManager with sourceModel, destinModel.
		NSMigrationManager* migrationManager = [[[NSMigrationManager alloc] initWithSourceModel:sourceModel
																			  destinationModel:destinModel] autorelease] ;
		
		ok = [fileManager removeIfExistsItemAtPath:destempPath
										   error_p:&underlyingError] ;
		if (!(ok)) {
			errorCode = SSYPersistentDocumentMultiMigratorErrorCodeCouldNotRemoveOldFile ;
			[errorInfo setValue:destempPath
						 forKey:@"destempPath"] ;
			goto end ;
		}
		
        // Fix in BookMacster 1.18.1, for Mac OS X 10.6
        BOOL isInViewingMode = NO ;
        if ([document respondsToSelector:@selector(isInViewingMode)]) {
            isInViewingMode = [document ssy_isInViewingMode] ;
        }
#if 0
        // Fix 20130610 - Does not work.
        BOOL isWritable = [[NSFileManager defaultManager] isWritableFileAtPath:[url absoluteString]] ;
        if (isInViewingMode) {
            NSString* fileNameExtension = [[url absoluteString] pathExtension] ;
            NSString* writablePath = [[[NSFileManager defaultManager] temporaryFilePath] stringByAppendingPathExtension:fileNameExtension] ;
            ok = [[NSFileManager defaultManager] copyItemAtPath:[url absoluteString]
                                                         toPath:writablePath
                                                          error:&underlyingError] ;
            if (!ok) {
                errorCode = SSYPersistentDocumentMultiMigratorErrorCodeCouldNotCopyUnwriteableFile ;
                [errorInfo setValue:writablePath
                             forKey:@"Writable Path"] ;
                [errorInfo setValue:[url absoluteString]
                             forKey:@"Source Path"] ;
                goto end ;
            }
            
            url = [NSURL fileURLWithPath:writablePath] ;
            [document setFileURL:url] ;
        }
#endif
#if MAC_OS_X_VERSION_MAX_ALLOWED > 1060
        if (isInViewingMode) {
            [newStoreOptions setObject:[NSNumber numberWithBool:YES]
                                forKey:NSReadOnlyPersistentStoreOption] ;
        }
#endif
             
        // Do the migration, creating a new file at destempUrl.
		// Because the Core Data Model Versioning and Data Migration Programming Guide
		// indicates that this method reads the whole store into memory, and this
		// could be a lot, we use a local autorelease pool, transferring any
		// underlyingError into the regular pool before releasing the local pool.
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init] ;
		ok = [migrationManager migrateStoreFromURL:url
											  type:storeType
										   options:newStoreOptions
								  withMappingModel:mappingModel
								  toDestinationURL:destempUrl
								   destinationType:storeType
								destinationOptions:newStoreOptions
											 error:&underlyingError] ;
		[underlyingError retain] ;
		[pool release] ;
		[underlyingError autorelease] ;
		
		if (!(ok)) {
			errorCode = SSYPersistentDocumentMultiMigratorErrorCodeMigrationFailed ;
			[errorInfo setValue:sourceModelVersionName
						 forKey:@"Source Model Version Name"] ;
			[errorInfo setValue:underlyingError
						 forKey:@"Underlying Error"] ;
			break ;
		}
		
		// Migration succeeded.
		NSLog(@"Migration succeeded") ;
		
		// If this is the first migration stage, rename the original file
		// by adding a tilde to its filename (tildefy).  If this is not the
		// first migration stage, delete the file so that we can subsequently
		// rename the migration output to it.
		if (firstStage) {
			firstStage = NO ;
			NSString *tildefiedDocumentPath = [documentPath tildefiedPath] ;
			
			ok = [fileManager copyItemAtPath:documentPath
									  toPath:tildefiedDocumentPath
									   error:&underlyingError] ;
			if (!(ok)) {
				errorCode = SSYPersistentDocumentMultiMigratorErrorCodeCouldNotCopyFile ;
				[errorInfo setValue:documentPath
							 forKey:@"documentPath"] ;
				[errorInfo setValue:tildefiedDocumentPath
							 forKey:@"tildefiedDocumentPath"] ;
				break ;		
			}
			NSLog(@"Moved original file to %@", tildefiedDocumentPath) ;
		}
		
		// Rename destin file so that it is now the documentPath file
		ok = [fileManager swapUrl:destempUrl
						  withUrl:url
						  error_p:&underlyingError] ;
		if (!(ok)) {
			errorCode = SSYPersistentDocumentMultiMigratorErrorCodeCouldNotSwapFile ;
			[errorInfo setValue:destempUrl
						 forKey:@"destempUrl"] ;
			[errorInfo setValue:url
						 forKey:@"url"] ;
		}
		
		// If destinModel is current model version, break out because we're done!
		if ([destinModelVersionName isEqualToString:currentModelVersionName]) {
			NSLog(@"Up to current version now") ;
			break ;
		}
		
		// Not done yet.  
		// Get ready for next stage migration, in which the
		// new source is now the old destination.
		sourceModel = destinModel ;
		sourceModelVersionName = destinModelVersionName ;
		
		// Start over again for next stage migration
	}		
	
	ok = [fileManager removeIfExistsItemAtPath:destempPath
									   error_p:&underlyingError] ;
	if (!(ok)) {
		errorCode = SSYPersistentDocumentMultiMigratorErrorCodeCouldNotRemoveTempFile ;
		[errorInfo setValue:destempPath
					 forKey:@"destempPath"] ;
		goto end ;
	}	
	
	// The following was added in BookMacster 1.3.1 after I noticed that if a
	// just-migrated document was edited and then saved, a warning sheet would
	// appear.  The warning sheet is the dreaded "This document's file has been
	// changed by another application since you opened or saved it."
	// In this posting, 
	// http://stackoverflow.com/questions/380076/manual-core-data-schema-migration-without-document-changed-warning
	// I found a two-part solution.  The first part was to use FSExchangeObjects,
	// which I was already doing (see swapUrl:withUrl:error_p:).  The second
	// part is to set the document's file modification date…
	[document syncFileModificationDate] ;
		
end:
	if (didPostNotification) {
		[[NSNotificationCenter defaultCenter] postNotificationName:SSYPersistentDocumentMultiMigratorDidEndMigrationNotification
															object:url] ;
	}
	
	if (errorCode != 0) {
		ok = NO ;
		if (error_p) {
			NSString* desc = [NSString stringWithFormat:
							  @"%@\n\n%@",
							  [NSString localize:@"versionFileNoRead"],
							  [url path]] ;
			[errorInfo setObject:desc
						  forKey:NSLocalizedDescriptionKey] ;
			
			if (underlyingError) {
				[errorInfo setValue:underlyingError
							 forKey:NSUnderlyingErrorKey] ;
			}
			
			*error_p = [NSError errorWithDomain:SSYPersistentDocumentMultiMigratorErrorDomain
										   code:errorCode
									   userInfo:errorInfo] ;
		}
	}
	
	return ok ;
}

@end