struct SSYModelChangeCounts_struct {
	NSInteger added ;
	NSInteger updated ;
	NSInteger moved ;
	NSInteger slid ;
	NSInteger deleted ;
} ;
typedef struct SSYModelChangeCounts_struct SSYModelChangeCounts ;

/*!
 @brief    Enumeration of the different types of changes which can be applied
 to a model object.
 
 @details  Similar to NSKeyValueChangeKindKey enumeration, except
 we added things that Apple left out which are needed for
 describing undoable actions, etc.
 
 The order of the elements is such that the most important changes
 have lower values (higher priority).  This is important to set
 the correct change type in -[Stange tryNewChangeType:].
 */
enum SSYModelChangeAction_enum {   // Examples:
	// DO NOT CHANGE THE VALUES OF THESE because they are in users' Diaries databases!
	SSYModelChangeActionReplace       =  10,  // was1 0 "Undo/Redo Replace myFoo1 with myFoo2"
	SSYModelChangeActionRemove        =  20,  // was1 1 "Undo/Redo Delete object myFoo"
	SSYModelChangeActionMerge         =  30,  // was1 2 "Undo/Redo Merge objects myFoo"
	SSYModelChangeActionInsert        =  40,  // was1 3 "Undo/Redo Insert object myFoo"
	SSYModelChangeActionCancel        =  45,  // Insertion which was cancelled by a deletion before all changes completed
	SSYModelChangeActionMosh          =  48,  // was1 did not exist.  Item was both moved and modified
	SSYModelChangeActionSlosh         =  49,  // was1 did not exist.  Item was both slid and modified (Was part of Mosh until BookMacster 1.9
	SSYModelChangeActionModify        =  50,  // was1 6 "Undo/Redo Change myBar of object myFoo"
	SSYModelChangeActionMove          =  60,  // was1 4 "Undo/Redo Move object myFoo"
	SSYModelChangeActionSlide         =  70,  // was1 5 "Undo/Redo Slide object myFoo"
	SSYModelChangeActionSort          =  75,  // was2 55  But this one is not used in Sync Logs database
	SSYModelChangeActionMigrate       =  80,  // was1 7 "Undo/Redo Migrate Foo"
	// Changes which are not well specified
	SSYModelChangeActionVague         =  90,  // was1 8 "Undo/Redo Foo"
	SSYModelChangeActionUndefined     = 100   // was1 9
	// DO NOT CHANGE THE ORDER OF THESE because they are in users' Diaries databases,
	// and also used to "rank" changes in Chaker.
	// If you add more change types, add branches as required in
	// +objectExistenceIsAffectedByChange: and/or +objectExistenceIsAffectedByChange:
	
	/* Note 098534.  The 'was1' values were used before BookMacster version 1.5.7.  The change
	 was apparently made to fix a bug which caused changes in item attributes,
	 for example a bookmark’s name, to be not counted if the item had also been moved
	 or slid within its family by an Import or Export operation.  This could cause
	 under-counting of changes, allowing an Import or Export operation which had over
	 the Safe Limit number of changes to be not detected as such.  In other words,
	 Change Counts wants to see Modify by a higher priority than Move and Slide.
	 However, I discovered while developing BookMacster 1.7/1.6.8 that this change
	 caused a regression in exporting to Google Chrome with Style 2 because that
	 JavaScript needs to do moves and slides first; otherwise items may be attempted
	 to be placed with gaps in families, which will cause errors in the JavaScript
	 background.html function doNextPut().  To solve this problem I introduced the
	 
	 */
} ;
typedef enum SSYModelChangeAction_enum SSYModelChangeAction ;

@interface SSYModelChangeTypes : NSObject {
}

+ (BOOL)objectExistenceIsAffectedByChange:(SSYModelChangeAction)action ;
+ (BOOL)objectAttributesAreAffectedByChange:(SSYModelChangeAction)action ;

+ (NSString*)symbolForAction:(SSYModelChangeAction)action ;

// Debugging
+ (NSString*)asciiNameForAction:(SSYModelChangeAction)action ;

@end


