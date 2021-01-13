#import "SSYArrayController.h"
#import "SSYIndexee.h"
#import "NSSet+Indexing.h"
#import "SSYToolTipper.h"
#import "NSFont+Height.h"

NSString* SSYArrayControllerRowsType = @"SSYArrayControllerRowsType" ;

@interface SSYArrayController ()

@property (retain) NSIndexSet* pendingObjectsIndexSet ;
@property (assign) CGFloat lineHeightMultiplier ;

@end



@implementation SSYArrayController

@synthesize parentObject = m_parentObject ;
@synthesize parentObjectKey = m_parentObjectKey ;
@synthesize contentKey = m_contentKey ;
@synthesize pendingObjectsIndexSet = m_pendingObjectsIndexSet ;
@synthesize lineHeightMultiplier = m_lineHeightMultiplier ;
@synthesize tableFontSize = m_tableFontSize ;

- (void)dealloc {	
	[m_parentObjectKey release] ;
	[m_contentKey release] ;
	[m_pendingObjectsIndexSet release] ;
	
	[super dealloc] ;
}

- (void)awakeFromNib {
	// Per Discussion in documentation of -[NSObject respondsToSelector:].
	// the superclass name in the following must be hard-coded.
	if ([NSArrayController instancesRespondToSelector:@selector(awakeFromNib)]) {
		[super awakeFromNib] ;
	}

	// Register for drag and drop
	NSArray* draggedTypes = [NSArray arrayWithObjects:
							 SSYArrayControllerRowsType,
							 NSPasteboardTypeURL,
							 nil] ;
    [tableView registerForDraggedTypes:draggedTypes] ;
    [tableView setAllowsMultipleSelection:YES] ;
}

- (BOOL)     tableView:(NSTableView *)tv
  writeRowsWithIndexes:(NSIndexSet*)indexes
		  toPasteboard:(NSPasteboard*)pboard {
	// declare our own pasteboard types
    NSArray *typesArray = [NSArray arrayWithObject:SSYArrayControllerRowsType] ;
	
	[pboard declareTypes:typesArray
				   owner:self];
	[self setPendingObjectsIndexSet:indexes] ;
	
    return YES ;
}

- (NSDragOperation)tableView:(NSTableView*)tv
				validateDrop:(id <NSDraggingInfo>)info
				 proposedRow:(NSInteger)targetRow
	   proposedDropOperation:(NSTableViewDropOperation)op {
    
    NSDragOperation dragOp = NSDragOperationNone ;
    
    if ([info draggingSource] == tableView) {
		NSArray* objects = [[self arrangedObjects] objectsAtIndexes:[self pendingObjectsIndexSet]] ;
		
		BOOL willMove = NO ;
		for (id object in objects) {
			if ([object conformsToProtocol:@protocol(SSYIndexee)]) {
				NSInteger currentIndex = [[(NSObject <SSYIndexee> *)object index] integerValue] ;
				NSInteger offset = (currentIndex < targetRow) ? -1 : 0 ;
				
				if (currentIndex != targetRow + offset) {
					willMove = YES ;
					break ;
				}
			}
		}
		
		if (willMove) {
			// We want to put the object at, not over,
			// the current row (contrast NSTableViewDropOn) 
			[tv setDropRow:targetRow
			 dropOperation:NSTableViewDropAbove];
			dragOp =  NSDragOperationMove;
		}
		else {
			// Proposed move would be a no-op to the same, existing index
			dragOp = NSDragOperationNone ;
		}
	}
	
    return dragOp;
}

- (void)movePendingObjectsToTargetRow:(NSInteger)targetRow {
	NSArray* objects = [[self arrangedObjects] objectsAtIndexes:[self pendingObjectsIndexSet]] ;
	
	NSMutableIndexSet* landingIndexSet = [NSMutableIndexSet indexSet] ;
	id parentObject = [self parentObject] ;
	
	for (id object in objects) {
		if ([object conformsToProtocol:@protocol(SSYIndexee)]) {
			NSInteger currentIndex = [[(NSObject <SSYIndexee> *)object index] integerValue] ;
			NSInteger offset = (currentIndex < targetRow) ? -1 : 0 ;
			
			if (!parentObject) {
				parentObject = [object valueForKey:[self parentObjectKey]] ;
			}
			NSMutableSet* siblings = [parentObject mutableSetValueForKey:[self contentKey]] ;
			
			[siblings moveObject:object
						 toIndex:(targetRow + offset)] ;
			[landingIndexSet addIndex:(targetRow + offset)] ;
		}
		
		targetRow++ ;
	}
	
	[self setSelectionIndexes:landingIndexSet] ;
}

- (BOOL)tableView:(NSTableView*)tv
	   acceptDrop:(id <NSDraggingInfo>)info
			  row:(NSInteger)targetRow
	dropOperation:(NSTableViewDropOperation)op {
    if (targetRow < 0) {
		targetRow = 0;
	}
    
    BOOL accepts ;
	
	if ([info draggingSource] == tableView) {
		
		[self movePendingObjectsToTargetRow:targetRow] ;
		
		accepts = YES ;
    }
	else {
		accepts = NO ;
	}
	
    return accepts ;
}

- (void)addBelowCurrentSelection:(id)sender {
	NSUInteger selectionIndex = [self selectionIndex] ;
	NSInteger oldCount = [[self arrangedObjects] count] ;
	NSUInteger targetIndex ;
	if (selectionIndex == NSNotFound) {
		// No selection.  Target to insert at bottom
		targetIndex = oldCount ;
	}
	else {
		// Selection.  Target to insert under it
		targetIndex = selectionIndex + 1 ;
	}

	// We need to create a new object, set its 'index' attribute,
	// and if the data model does not have ordered storage of
	// collections (e.g., Core Data), increment the 'index'
	// attribute of higher-indexed siblings.
	// Action methods -add: and -insert: will create a new object,
	// but not return it.  And I'm not sure if I could reliably
	// get it because I'm not sure whether or not 'Auto Rearrange
	// Content' is set on, and whether or not that would trigger
	// immediate sorting which means I wouldn't know if the new
	// object is still at the bottom or had been moved.
	// So, instead of this I use the -newObject method, which does
	// not insert the object
	id newObject = [self newObject] ;	
	if ([newObject conformsToProtocol:@protocol(SSYIndexee)]) {
		[(NSObject <SSYIndexee> *)newObject setIndex:[NSNumber numberWithInteger:targetIndex]] ;
	}
	// And then insert it manually
	[self     insertObject:newObject
     atArrangedObjectIndex:targetIndex] ;
    [newObject release] ;
	/* The data model will get a KVO of that insertion
	 and increment higher-indexed siblings' indexes.  If 
	 this array controller is bound as the detail in a
	 master-detail relationship, it will also add the new
	 object to the master, as shown in this call stack:
	 #12	0x000fa34e in -[Agent setTriggersOrdered:] at Agent.m:422
	 #13	0x93907c95 in _NSSetObjectValueAndNotify
	 #14	0x90a05d1a in -[NSManagedObject setValue:forKey:]
	 #15	0x93917acf in -[NSObject(NSKeyValueCoding) setValue:forKeyPath:]
	 #16	0x91447d1e in -[NSArrayController _setMultipleValue:forKeyPath:atIndex:]
	 #17	0x91446e39 in -[NSArrayController _setSingleValue:forKeyPath:]
	 #18	0x93917aab in -[NSObject(NSKeyValueCoding) setValue:forKeyPath:]
	 #19	0x912e4062 in -[NSBinder _setValue:forKeyPath:ofObject:mode:validateImmediately:raisesForNotApplicableKeys:error:]
	 #20	0x912e3e3c in -[NSBinder setValue:forBinding:error:]
	 #21	0x9166adfd in -[NSObjectDetailBinder setMasterObjectRelationship:refreshDetailContent:]
	 #22	0x9144a934 in -[NSArrayDetailBinder _performArrayBinderOperation:singleObject:multipleObjects:singleIndex:multipleIndexes:selectionMode:]
	 #23	0x91449f55 in -[NSArrayDetailBinder addObjectToMasterArrayRelationship:selectionMode:]
	 #24	0x91448ea2 in -[NSArrayController _insertObject:atArrangedObjectIndex:objectHandler:]
	 #25	0x91444ddb in -[NSArrayController insertObject:atArrangedObjectIndex:]
	 #26	0x0017b3c9 in -[SSYArrayController addBelowCurrentSelection:] at SSYArrayController.m:241
	 In that call stack, all of the methods are Apple's except
	 for the top one #12 and the bottom one #26 which is this method. */	 
}

- (void)remove:(id)sender {
	NSUInteger lastSelectedIndex = [[self selectionIndexes] lastIndex] ;	
	NSUInteger oldCount = [[self arrangedObjects] count] ;

	[super remove:sender] ;
	
	NSUInteger newCount = [[self arrangedObjects] count] ;
	NSUInteger nRemoved = oldCount - newCount ;
	NSUInteger nextIndex = lastSelectedIndex + 1 - nRemoved ;
	nextIndex = MIN(nextIndex, newCount - 1) ;
	[self setSelectionIndex:nextIndex] ;
}

- (void)moveSelectionIndexBy:(NSInteger)moveBy {
	if (moveBy > 0) {
		// Compensate for removing target item
		moveBy++ ;
	}
	
	[self setPendingObjectsIndexSet:[self selectionIndexes]] ;
	NSInteger targetRow = [self selectionIndex] + moveBy ;
	[self movePendingObjectsToTargetRow:targetRow] ;
}

- (NSString*)tableView:(NSTableView*)tableView
		toolTipForCell:(NSCell*)cell
				  rect:(NSRectPointer)rect
		   tableColumn:(NSTableColumn*)tableColumn
				   row:(NSInteger)row
		 mouseLocation:(NSPoint)mouseLocation {
	NSString* toolTip = nil ;

	id object = [[self arrangedObjects] objectAtIndex:row] ;
	if ([object conformsToProtocol:@protocol(SSYToolTipper)]) {
		toolTip = [(NSObject <SSYToolTipper>*)object longDisplayName] ;
	}
	
	return toolTip ;
}

- (void)tableView:(NSTableView*)tableView
  willDisplayCell:(id)cell
   forTableColumn:(NSTableColumn*)tableColumn
			  row:(NSInteger)rowIndex {
	if ([self tableFontSize] > 0.0) {
		NSFont* font = [cell font] ;
		if ([font pointSize] != [self tableFontSize]) {
			NSFont* newFont = [NSFont fontWithName:[font fontName]
											  size:[self tableFontSize]] ;
			[cell setFont:newFont] ;
		}
	}
}

- (void)setHeightControllingColumnIndex:(NSInteger)index {
	NSTableColumn* column = [[tableView tableColumns] objectAtIndex:index] ;
	NSCell* dataCell = [column dataCell] ;
	NSFont* font = [dataCell font] ;
	CGFloat height2 = [font tableRowHeight] + 2.0;
	CGFloat height1 = [tableView rowHeight] ;
	m_lineHeightMultiplier = (height2/height1) ;
}

- (CGFloat)tableView:(NSTableView*)aTableView
		 heightOfRow:(NSInteger)index {
	// Could assert here that aTableView == tableView.
	CGFloat height = [aTableView rowHeight] ;
	if (m_lineHeightMultiplier > 0) {
		NSArray* objects = [self arrangedObjects] ;
		if ((index >= 0) && (index < [objects count])) {
			NSObject <SSYArrayControllerVariableRowHeightObject> * object = [objects objectAtIndex:index] ;
			if ([object respondsToSelector:@selector(isFault)]) {
				if ([(NSManagedObject*)object isFault]) {
					return 1.0 ;
				}
			}
			NSInteger nSubrows = [object numberOfSubrows] ;
			height *= nSubrows ;
			height *= m_lineHeightMultiplier ;
		}
		else {
			NSLog(@"Internal Error 384-5250") ;
		}
	}
	
	// In earlier versions, I was getting lines and artifacts and little bottoms or tops
	// of characters between lines when scrolling (the Diaries in BookMacster).  I did
	// something to fix it.  Later, on 20101124, in cocoa-dev@lists.apple.com, subject
	// Customised NSCell leaves dirty traces while scrolling, I read that Josh Yu
	// solved this problem by making sure that this method always returned a height with
	// a 0 fractional part.  So I put in the following: 
	// if (height != ceil(height)) {
	//  	NSLog(@"%3.3f != %3.3f", height, ceil(height)) ;
	// }
	// but it never logged anything, indicating that I must have implemented his fix
	// in some other way.
	// Oh well, the following line might execute if [aTableView rowHeight] ever returned
	// a number with a nonzero fractional part.  Added in BookMacster 1.3.5…
	height = ceil(height) ;
	
	return height ;
}

- (void)selectFirstArrangedObject {
	[self removeSelectionIndexes:[self selectionIndexes]] ;
	if ([[self arrangedObjects] count] > 0) {
		NSRange range = NSMakeRange(0, 1) ;
		NSIndexSet* indexSet = [NSIndexSet indexSetWithIndexesInRange:range] ;
		[self addSelectionIndexes:indexSet] ;
	}
}

#if 0
#warning Logging _setMultipleValue:forKeyPath for Mythical Deep Observer
- (void)_setMultipleValue:(id)mv
forKeyPath:(NSString*)keyPath
atIndex:(NSUInteger)index {
	NSLog(@"8403 %s mv: %p = %@ keyPath: %@ index: %ld", __PRETTY_FUNCTION__, mv, [mv shortDescription], keyPath, (long)index) ;
	[super _setMultipleValue:mv
				  forKeyPath:keyPath
					 atIndex:index] ;
}
#endif

@end
