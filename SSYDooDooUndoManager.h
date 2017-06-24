#import <Cocoa/Cocoa.h>
#import "GCUndoManager.h"

extern NSString* const SSYUndoManagerWillEndUndoGroupNotification ;
extern NSString* const SSYUndoManagerDocumentWillCloseNotification ;
extern NSString* const SSYUndoManagerDocumentDidOpenNotification ;

/*!
 @brief    Self-explanatory from the name
*/
extern NSString* const SSYUndoManagerDidCloseUndoGroupNotification ;

/*!
 @brief    A notification which you should post if you plan to use
 -beginAutoEndingUndoGrouping.  See class documentation for details.

 @details  The notification object should be the undo manager
 (SSYDooDooUndoManager) of the document about to be saved.  The
 userInfo is ignored.
*/
extern NSString* const SSYUndoManagerDocumentWillSaveNotification ;


/*!
 @brief    A subclass of NSUndoManager which should be used in
 Core Data applications to circumvent Core Data's penchant for
 closing your undo groupings before you want them to be closed,
 resulting in the user having to click Edit > Undo (with no
 action name in the title) several times before anything happens.
 
 @details  To use this subclass, execute the following code
 in the -init method of your NSPersistentDocument subclass:
 >   SSYDooDooUndoManager* undoManager = [SSYDooDooUndoManager doodooUndoManagerWithDocument:self] ;
 >   [[self managedObjectContext] setUndoManager:undoManager] ; 
 >   [self setUndoManager:undoManager] ;
 Note: Those two re-settings are necessary because, at this point,
 both the persistent document and its undo manager have already
 been initted with with the default NSUndoManager.
 
 To avoid compiler warnings when you send messages declared in 
 this subclass to your persistent document's -undoManager,
 override it thus:.
 > - (SSYDooDooUndoManager*)undoManager {
 >  	return (SSYDooDooUndoManager*)[super undoManager] ;
 > }
 
 If you plan to use SSYDooDooUndoManager's 
 -beginAutoEndingUndoGrouping method, you should always send
 SSYUndoManagerDocumentWillSaveNotification just prior to
 sending saveToURL:ofType:forSaveOperation:error: because that is
 the method which sends -updateChangeCount:NSChangeCleared.  The
 recommended idiom is to override saveToURL:ofType:forSaveOperation:error:
 if your NSDocument subclass, like this:
> - (BOOL)saveToURL:(NSURL *)absoluteURL
>			ofType:(NSString *)typeName
>  forSaveOperation:(NSSaveOperationType)saveOperation
>             error:(NSError **)outError {
>    [[NSNotificationCenter defaultCenter] postNotificationName:SSYUndoManagerDocumentWillSaveNotification
>                                                        object:[self undoManager]] ;
>    return [super saveToURL:absoluteURL
>                     ofType:typeName
>           forSaveOperation:saveOperation
>                      error:outError] ;
> }
 SSYDooDooUndoManager makes use of this in two ways:
 (1)  If automatic ending of an undo group was previously scheduled
      by -beginAutoEndingUndoGrouping, it cancels the 
      scheduled ending and instead ends the group immediately.
      The reason for this is that -endUndoGrouping sends a
      notification which causes Cocoa to send the document 
      -updateChangeCount:NSChangeDone, which would re-dirty your
      document.  This is not common, but will occur in case your application
      supports some type(s) of "change XXX and then save" operation which completes in a
      single run loop iteration.  (This would be even less common for Lion
      apps since you'd use Lion's built-in Auto Save instead.)
 (2)  It removes the coalescing lock so that -beginAutoEndingUndoGrouping
      will work again the next time it is invoked.
 
 Note that if your document is a subclass of NSPersistentDocument,
 and your SDK is macOS 10.6 or later, you could rewrite SSYDooDooUndoManager
 to use SSYUndoManagerDocumentWillSaveNotification instead, and then you wouldn't
 need to send SSYUndoManagerDocumentWillSaveNotification.
 
 Finally, send SSYUndoManagerDocumentWillCloseNotification.
*/

// Flip this on if you would like to try with NSUndoManager instead
// of GCUndoManager
#if 0
#warning Using NSUndoManager instead of GCUndoManager
#define UNDO_MANAGER_BASE_CLASS NSUndoManager
#else
#define UNDO_MANAGER_BASE_CLASS GCUndoManager
#endif

@interface SSYDooDooUndoManager : UNDO_MANAGER_BASE_CLASS {
	NSInteger nLivingManualGroups ;
	NSInteger nLivingAutoEndingGroups ; // This should always be 0 or 1
	NSManagedObjectContext* m_managedObjectContext ;
}

/*!
 @brief    Gets a newSSYDooDooUndoManager instance and assigns it
 to a given document and its managed object context.

 @details  The document is required for three reasons:
 * The returned SSYDooDooUndoManager instance is set as its undo manager.
 * The returned SSYDooDooUndoManager instance is set as its 
 managed object context's undo manager.
 * The returned SSYDooDooUndoManager begins observing it for
 SSYUndoManagerDocumentWillSaveNotification.
 * A weak reference to the document's undo manager is kept
 in order to -processPendingChanges before ending an undo group.
 
 Although the document could possibly be obtained by iterating
 through the shared NSDocumentController's documents, that will fail
 if you invoke this method during document initialization, before it
 has been added to NSDocumentController, which you usually do.
 
 Note that NSDocument creates an NSUndoManager and assigns it during
 its initialization.  Thus, the document you pass will probably already
 have an undo manager.  That's OK, though.  We just set our own
 instead, and the original NSUndoManager instance is discarded.
 
 We access the managed object context of the given document by
 sending -managedObjectContext to it.  If the document has never
 has never before had its managed object context accessed in this
 way, this will cause one to be created.  Thus, if your document
 did not have a managed object context prior to being passed to 
 this method, it will have one after this method executes.
 It needs one sooner or later anyhow.
 
 @param    document  The document to be associated with the new
 SSYDooDooUndoManager instance.
 @result   The new SSYDooDooUndoManager instance.  Typically, you
 don't need this.  You can always get it later by sending -undoManager
 to your document.
*/
+ (SSYDooDooUndoManager*)makeUndoManagerForDocument:(NSDocument*)document ;

/*!
 @brief    Begins an undo grouping which is highly resistant to
 being screwed up by Core Data and closes itself automatically.
 
 @details  This method will automatically end the undo grouping
 it creates some milliseconds after the current event loop cycles,
 ensuring that any model changes triggered by notifications will be
 included in it.
 
 This is the recommended method of beginning an undo grouping
 before performing a user-initiated change to the data model.
 It is typically invoked in a notification receiver method.
 The notifications are posted by implmenting and hooking in to
 custom setter methods which say: "Attribute xxx of object yyy
 is about to be changed."
*/
- (void)beginAutoEndingUndoGrouping ;

/*!
 @brief    Begins an undo grouping which is highly resistant to
 being screwed up by Core Data and you will close manually.

 @details  Use this method instead of -beginAutoEndingUndoGrouping
 if the event loop is allowed to cycle before all data model changes
 to be included in this group have been performed, for example, if work
 is done on other threads.
 
 You must close this group later by invoking -endManualUndoGrouping.
*/
- (void)beginManualUndoGrouping ;

/*!
 @brief    Closes an undo group opened by -beginManualUndoGrouping.
 Typically this may be done in a completion routine, after work has been
 done on other threads and returns to the main thread.
*/
- (void)endManualUndoGrouping ;

/*!
 @brief    Closes any autoending *and* manual undo groups which may be open.
 @result   The total number of autoending and manual groups closed
*/
- (NSInteger)endAnyUndoGroupings ;

/*!
 @brief    Override which (1) sends -processPendingChanges to the receiver's
 managed object context before invoking super and (2) posts an
 SSYUndoManagerDidCloseUndoGroupNotification after invoking super.
*/
- (void)endUndoGrouping ;

/*!
 @brief    Performs operations necessary to make the receiver act as the undo
 manager for a given document
 @details  You typically send this after initializing the receiver, if the
 receiver is to be the undo manager for a document.  This method does not
 associate a document's managed object context, if any. For Core Data documents,
 you must also -coupleToManagedObjectContext:.
 */
- (void)coupleToDocument:(NSDocument*)document ;

- (void)coupleToManagedObjectContext:(NSManagedObjectContext*)managedObjectContext ;

@end


