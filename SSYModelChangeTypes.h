

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
	// DO NOT CHANGE THE ORDER OF THESE because they are in users' Diaries databases!
	SSYModelChangeActionReplace   =  10,  // was 0 "Undo/Redo Replace myFoo1 with myFoo2"
	SSYModelChangeActionRemove    =  20,  // was 1 "Undo/Redo Delete object myFoo"
	SSYModelChangeActionMerge     =  30,  // was 2 "Undo/Redo Merge objects myFoo"
	SSYModelChangeActionInsert    =  40,  // was 3 "Undo/Redo Insert object myFoo"
	SSYModelChangeActionCancel    =  45,  // Insertion which was cancelled by a deletion before all changes completed
	SSYModelChangeActionModify    =  50,  // was 6 "Undo/Redo Change myBar of object myFoo"
	SSYModelChangeActionSort      =  55,
	SSYModelChangeActionMove      =  60,  // was 4 "Undo/Redo Move object myFoo"
	SSYModelChangeActionSlide     =  70,  // was 5 "Undo/Redo Slide object myFoo"
	SSYModelChangeActionMigrate   =  80,  // was 7 "Undo/Redo Migrate Foo"
	SSYModelChangeActionVague     =  90,  // was 8 "Undo/Redo Foo"
	SSYModelChangeActionUndefined = 100   // was 9
	// The 'was' values give values before BookMacster version 1.5.7
	// DO NOT CHANGE THE ORDER OF THESE because they are in users' Diaries databases,
	// and also used to "rank" changes in Chaker.
} ;
typedef enum SSYModelChangeAction_enum SSYModelChangeAction ;

@interface SSYModelChangeTypes : NSObject {
}

+ (NSString*)symbolForAction:(SSYModelChangeAction)action ;

@end


