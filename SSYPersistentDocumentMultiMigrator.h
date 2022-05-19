#import <Cocoa/Cocoa.h>

extern NSString* const SSYPersistentDocumentMultiMigratorErrorDomain ;

/*!
 @brief    Name of notification which is posted when beginning to migrate a document
 which is not compatible with the current version of the data model.

 @details  The notification object is the NSURL object of the store being migrated.
 This notification is always followed by SSYPersistentDocumentMultiMigratorDidEndMigrationNotification.
*/
extern NSString* const SSYPersistentDocumentMultiMigratorDidBeginMigrationNotification ;

/*!
 @brief    Name of notification which is posted when ending migration of a document
 which is not compatible with the current version of the data model.
 
 @details  The notification object is the NSURL object of the store being migrated.
 This notification is always preceded by SSYPersistentDocumentMultiMigratorDidBeginMigrationNotification.
 */
extern NSString* const SSYPersistentDocumentMultiMigratorDidEndMigrationNotification ;

#define SSYPersistentDocumentMultiMigratorErrorCodeNoModelBundle 315001
#define SSYPersistentDocumentMultiMigratorErrorCodeNoModelVersionPlist 315002
#define SSYPersistentDocumentMultiMigratorErrorCodeNoVersionInfoInPlist 315003
#define SSYPersistentDocumentMultiMigratorErrorCodeNoCurrentVersionName 315004
#define SSYPersistentDocumentMultiMigratorErrorCodeNoSourceModel 315006
#define SSYPersistentDocumentMultiMigratorErrorCodeNoDestinModel 315011
#define SSYPersistentDocumentMultiMigratorErrorCodeNoMappingModel 315012
#define SSYPersistentDocumentMultiMigratorErrorCodeCouldNotRemoveOldFile 315013
#define SSYPersistentDocumentMultiMigratorErrorCodeMigrationFailed 315014
#define SSYPersistentDocumentMultiMigratorErrorCodeCouldNotCopyFile 315015
#define SSYPersistentDocumentMultiMigratorErrorCodeCouldNotSwapFile 315016
#define SSYPersistentDocumentMultiMigratorErrorCodeCouldNotRemoveTempFile 315020
#define SSYPersistentDocumentMultiMigratorErrorCodeCouldNotCopyUnwriteableFile 315021
#define SSYPersistentDocumentMultiMigratorErrorCodeCouldNotRepermitUnwriteableFile 315022
#define SSYPersistentDocumentMultiMigratorErrorCodeUserCancelledUndisplayableRestore 315023

/*!
 @brief    DEPRECATED Class which provides a method automatically migrating
 persistent stores in Core Data document-based apps over multiple
 versions

 @details  *** DEPRECATION NOTICE ***
 SSYPersistentDocumentMultiMigrator is *** DEPRECATED *** because
 I had some trouble using this class in May 2022.  The trouble may be that
 SSYPersistentDocumentMultiMigrator does not support modern SQLite stores with
 write-ahead logging (-shm and -wal files).  I'm not sure because instead of
 troubleshooting it, I forked a modern example from another developer and
 replaced SSYPersistentDocumentMultiMigrator in my projects with the Swift code
 in this fork:
 
 https://github.com/jerrykrinock/CoreDataProgressiveMigration
 
 *** END OF DEPRECATION NOTICE ***
 
 Although earlier versions of this class played with apps using
 NSPersistentDocument, currently it requires that your app is using
 the open-source BSManagedDocument and not NSPersistentDocument.  There are
 many good reasons to do this, as explained here:
 https://github.com/jerrykrinock/BSManagedDocument
 If you really want to use the notoriously problematic NSPersistentDocument,
 your fork of this class would only differ in several lines. */
@interface SSYPersistentDocumentMultiMigrator : NSObject

/*!
 @brief    Wrapper around -[NSMigrationManager migrateStoreFromURL:type:options:withMappingModel:toDestinationURL:destinationType:destinationOptions:error:]
 which, unlike that method and unlike -[NSPersistentDocument configurePersistentStoreCoordinatorForURL:ofType:modelConfiguration:storeOptions:error:],
 is able to automatically migrate serially through multiple versions,
 requiring mapping models only between consecutive versions.

 @details  The advantage of this method over using configurePersistentStoreCoordinatorForURL:ofType:modelConfiguration:storeOptions:error:
 with option NSMigratePersistentStoresAutomaticallyOption
 is that when you add a new version N, you only need to write and
 test one mapping model instead of N-1.  The disadvantage is that,
 due to the serial migrations, opening really old documents can take
 a really long time.  We judge that to be acceptable since it
 should be rare, and better to have it work slowly than have
 it not work or work fast with bugs due to lack of testing.
 
 In addition to the managed object models explained below under
 the 'momdName' parameter, there should be in the app's Resources one
 Core Data mapping model (.cdm) file to map each non-current
 version to the next version.  Example: To handle versions 1, 2
 and 3, where 3 is the current version, two files are required,
 typically MyMappingModel1To2.cdm and MyMappingModel2To3.cdm.
 
 To use this method, in your NSPersistentDocument subclass,
 override configurePersistentStoreCoordinatorForURL:ofType:modelConfiguration:storeOptions:error:,
 as is done in MyDocument of Apple's MigratingDepartmentAndEmployees2 sample project.
 In your implementation, first invoke this method and check for error
 before invoking super configurePersistentStoreCoordinatorForURL:ofType:modelConfiguration:storeOptions:error:.
 The first two parameters passed to this method should be those passed
 to configurePersistentStoreCoordinatorForURL:ofType:modelConfiguration:storeOptions:error:.
 Also, when invoking super configurePersistentStoreCoordinatorForURL:ofType:modelConfiguration:storeOptions:error:,
 you do not need to add NSMigratePersistentStoresAutomaticallyOption to
 the store options, because at that point migration should no longer
 be necessary; this method will replaced the document file with a
 file that is already migrated up to the current version.
 
 Similar to the behavior of configurePersistentStoreCoordinatorForURL:ofType:modelConfiguration:storeOptions:error:,
 when migration is necessary this method will rename the old file by
 appending tilde characters to the name until it is unique in its
 parent directory, and overwrite the old path with the migrated file,
 without informing the user that this is being done. Intermediate
 files produce by intermediate-stage migrations appear only
 momentarily while this method is running.
 
 Requires macOS 10.5 or later.
 
 @param    url  The file url of the store which is to be migrated if
 needed
 @param    storeOptions  options which will be passed internally to
 -[NSMigrationManager migrateStoreFromURL:type:options:withMappingModel:toDestinationURL:destinationType:destinationOptions:error:]
 along with NSMigratePersistentStoresAutomaticallyOption.
 @param    storeType  One of the "Store Types" given in Apple's
 "NSPersistentStoreCoordinator Class Reference".  Example: NSSQLiteStoreType.
 @param    momdName  The baseName of the baseName.momd directory in 
 the application's Resources which contains the various versions of
 managed object models (.mom) files required to open any document
 url to be passed in the 'url' parameter.
 @param    document  The document, if any, being migrated.  This parameter is
 only needed to send -[NSDocument setFileModificationDate:] which
 we must do in order to avoid the warning sheet stating "This document's
 file has been changed by another application since you opened or saved
 it." which may appear if, after migrating, the user edits and then
 saves the document.  If the desired migration does not involve
 a document, you may pass nil.
 @param    error_p  If this method fails, error_p will point to
 an NSError object explaining the error which will be in the
 SSYPersistentDocumentMultiMigratorErrorDomain error domain.  There
 may be a root cause given in its userInfo for NSUnderlyingErrorKey.
 @result   YES if the store at the given url is now compatible
 with the current version of the managed object models given
 by momdName, otherwise NO.
*/
+ (BOOL)migrateIfNeededStoreAtUrl:(NSURL*)url
					 storeOptions:(NSDictionary*)storeOptions
						storeType:(NSString*)storeType
						 momdName:(NSString*)momdName
						 document:(NSDocument*)document
						  error_p:(NSError**)error_p ;

@end
