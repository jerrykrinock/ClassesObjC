#import <Cocoa/Cocoa.h>


/*!
 @brief    Manages a multitude of managed object contexts for an application.

 @details  Provides managed object contexts of the volatile in-memory and/or
 nonvolatile sqlite type, identifying them later with an <i>identifier</i>
 and, later, given a managed object context created by this class, identifying
 its <i>owner</i>, an id which was given when the managed object context was
 created. Also searches through the application's NSPersistentDocuments to 
 find the NSPersistentDocument <i>owner</i> if a managed object context for
 which the owner is desired turns out to not be one of this class's creations.
 This class itself is instantiated as an app-wide
 singleton and no public instance methods are available.
 */
@interface SSYMOCManager : NSObject {
	NSMutableDictionary* inMemoryMOCDics ;
	NSMutableDictionary* sqliteMOCDics ;
	NSMutableDictionary* docMOCDics ;
}

/*!
 @brief    Returns whether or not a persistent (sqlite) store exists
 for a given identifier.

 @details  Because +managedObjectContextType::::: creates
 a new store if the one you ask for does not exist, you need to use this
 method to determine a store's existence.
 
 @param    identifier  The identifier of the desired store
 @result   YES if the store exists on disk, otherwise NO.
*/
+ (BOOL)sqliteStoreExistsForIdentifier:(NSString*)identifier ;

/*!
 @brief    Returns a new or pre-existing managed object context which will
 access a new or pre-existing store.

 @details  Provides managed objects in different contexts/stores, segregated from one another.
 If managed objects are created to be in one of several groups, and not often migrate
 migrate to other groups, it is better to store these in segragated stores like this
 rather than to throw them all in the same store and filter them during fetches with an
 identifying attribute.  The reason is that the identifying attribute will cause an extra
 subpredicate that will increase fetch times, or require post-fetch filtering which will add
 about the same execution time.
 
 This method searches the app-wide singleton for a managed object context of the required
 type and identifier and returns it if found.  Otherwise, a new store and managed object
 context are created, retaining with it the provided owner.  If a new managed object
 context must be created and the 'owner' parameter is nil, the owner will be set to NSApp.
 
 If a managed object context is created with nil 'owner', this is assumed to be a "temporary
 storage" or "cheap" moc for which undo support is not needed.  Its undoManager is set
 to nil.  Such a moc will execute more cheaply.
 
 This method retains a reference to the managed object context (in any of the three MOCDics).
 To avoid leaks or retain cycles, send a 
 -releaseManagedObjectContext: message whenever a managed object context returned from this
 method is no longer needed.
 @param    type  NSSQLiteStoreType or NSInMemoryStoreType.
 @param    owner  If a new managed object context must be created, an arbitrary object which
 will be retained as its <i>owner</i>. Otherwise, this parameter is ignored.
 @param    identifier  A unique identifier for the context/store, or nil to return
 a "common" managed object context/store of the given type for the application.
 If storeType is NSSQLiteStoreType, identifier must contain only characters that are valid
 in a filename. That means, I believe, in Mac OS X, no slashes (/) or colons (:).  
 This is because the identifier will be incorporated the name of an sqlite database
 file that will be created to support the new managed object context if necessary.
 @param    momdName  The baseName of the baseName.momd directory in 
 the application's Resources which contains the various versions of
 managed object models (.mom) files required to migrate an existing
 sqlite store.  This parameter is needed to perform multi-hop migration
 of existing sqlite stores by SSYPersistentDocumentMultiMigrator.
 If you do not wish to support multi-hop migration, you may pass nil
 and only Core Data's built-in single-hop automatic migration will
 be used.  For store types other than sqlite, this parameter is ignored.
 @param    error_p  If managed object context could not be created, points to an NSError
 on output. This should not occur for NSInMemoryStoreType, only NSSQLiteStoreType.
 @result   The new or pre-existing managed object context, or nil if one could not be created.
*/
+ (NSManagedObjectContext*)managedObjectContextType:(NSString*)storeType
											  owner:(id)owner
										 identifier:(NSString*)identifier
										   momdName:(NSString*)momdName
											error_p:(NSError**)error_p ;

/*!
 @brief    Adds a managed object context to the document managed object contexts
 managed by the shared MOC manager.

 @details  Do this so that the +ownerOfManagedObjectContext: method will work
 for the managed objects.
 
 This method retains the -document parameter until it receives a corresponding
 +releaseManagedObjectContext message, so be careful or you will create retain cycles.
 This method will, however, *replace* its record for a particular document if you later
 send this message again for the same document with a new or same managedObjectContext.
 @param    document  The document which owns the managed object context
 @param    managedObjectContext  The managed object context to be registered.
*/
+ (void)registerOwnerDocument:(NSPersistentDocument*)document
	   ofManagedObjectContext:(NSManagedObjectContext*)managedObjectContext ;

/*!
 @brief    Returns the owner of a given managed object context, or if it turns out to have not
 been created by this class, the NSPersistentDocument to which it belongs.

 @details  This method searches its instance data looking for the owner that was provided when
 a managed object context was returned by the receiver's -managedObjectContextType:::::.
  If none is found, then it seaches the application's NSDocumentController's
 -documents, looking for an NSPersistentDocument subclass which returns a -managedObjectContext
 that matches the given managedObjectCcontext. 
 @param    managedObjectContext  The managed object context for which the owner is desired.
 @result   The owner of the given managed object context, or nil if the given managed object
 context is not found in either in the receiver's instance data or as the -managedObjectContext of
 any document.</p>
 
 <p>Usage tip: To allow <i>managed objects</i> to access their "owners", subclass NSManagedObject
 and provide a method which returns
 [SSYMOCManager ownerOfManagedObjectContext:[self managedObjectContext]]. Then use this
 method to get the owner.</p>
*/
+ (id)ownerOfManagedObjectContext:(NSManagedObjectContext*)managedObjectContext ;

/*!
 @brief    Removes a managed object context returned by -managedObjectContextType:::::
 from the receiver's instance's data.

 @details  This method releases the receiver's retain count on the managed object
 context, if the receiver has a record of it. Send a this message whenever a
 managed object context returned by -managedObjectContextType::::: is no longer
 needed, in order to avoid memory leaks in your program.  To avoid retain cycles,
 don't do it in -dealloc.  Put it in a method which runs prior to -dealloc.
 It is OK to send this message more than once; further invocations will no-op.
 @param    managedObjectContext  The managed object context to be removed.
 @return  YES if an entry with the given managed object context was found and removed,
 otherwise NO. 
*/
+ (BOOL)releaseManagedObjectContext:(NSManagedObjectContext*)managedObjectContext ;

/*!
 @brief    Deletes the local store file on disk for an sqlite store with a given
 identifier

 @details  This is useful in "Trash the Cache" or similar operations.
*/
+ (void)removeSqliteStoreForIdentifier:(NSString*)identifier ;

/*!
 @brief    Returns the URL of an sqlite store with a given
 identifier, without regard to whethe or not it exists in
 the filesystem.

 @details  An internal method, exposed here because it is
 sometimes useful for troubleshooting.
*/
+ (NSURL*)sqliteStoreURLWithIdentifier:(NSString*)identifier ;

+ (BOOL)isInMemoryMOC:(NSManagedObjectContext*)moc ;
+ (BOOL)isSqliteMOC:(NSManagedObjectContext*)moc ;
+ (BOOL)isDocMOC:(NSManagedObjectContext*)moc ;

#if DEBUG
+ (void)logDebugCurrentSqliteMocs ;
#endif

@end
