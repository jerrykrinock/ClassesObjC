#import "SSTableKit.h"
#import "SSUtils.h"
#import "SSUtilityCategories.h"

@implementation SSTableKit

SSAOm (NSArrayController*, arrayController, setArrayController)
SSAOm (id, defaultNewObject, setDefaultNewObject)
SSAOm (id, dataStore, setDataStore)
	
//- (NSArray*)selectedObjects {
//	return [[self arrayController] selectedObjects] ;
//}
//
//- (id)selectedObject {
//	return [[self selectedObjects] lastObject] ;
//}
	
- (void)setArray:(id)array {
	SSLog(5, "Prolog: SSTableKit -setArray") ;
	NSMutableArray* mutableArray = [array mutableCopy] ;
	[[self arrayController] setContent:mutableArray] ;
	[mutableArray release] ;
	[table reloadData] ;
	[table display] ;
}

- (id)array {
	// NSArrayController -arrangedObjects returns a _NSControllerArrayProxy.
	// If you try and write this "array" to user defaults, as you will do if 
	// this table is in a preferences window, you will get exceptions, for example:
	// *** -[_NSControllerArrayProxy getObjects:inRange:]: selector not recognized
	// Maybe _NSControllerArrayProxy is "not a property list object"?
	// Anyhow, I use arrayWithArray to solve this problem.
	return [NSArray arrayWithArray:[[self arrayController] arrangedObjects]] ;
}

- (void) syncArrayControllerToTableAndDataStore {
	NSIndexSet* indexes = [[self arrayController] selectionIndexes] ;
	[table selectRowIndexes:indexes byExtendingSelection:NO] ;
	[table reloadData] ;
	[[self dataStore] setArray:[self array] sender:self] ;
}

- (id)initWithFrame:(NSRect)frame
{
	SSLog(5, "Prolog SSTableKit -initWithFrame") ;
	self = [super initWithFrame:frame];
	if (self) {
		NSArrayController* arrayController = [[NSArrayController alloc] init] ;
		[self setArrayController:arrayController] ;
		[arrayController release] ;
		
		//[self registerForDraggedTypes:[NSArray arrayWithObjects:NSStringPboardType, nil]];
	}
	return self;
}

- (IBAction)addNew:(id)sender {
	NSArrayController* arrayController = [self arrayController] ;
	id newObject = [self defaultNewObject] ;
	[arrayController addObject:newObject] ;
	[arrayController setSelectedObjects:[NSArray arrayWithObject:newObject]] ;
	[self syncArrayControllerToTableAndDataStore] ;	
}

- (IBAction)removeSelected:(id)sender {
	NSArrayController* arrayController = [self arrayController] ;
	[arrayController remove:self] ; // Misleading syntax!!
		// The above "removes selected object(s)", not "self.  
		// That argument is "sender" (It is an "action" method).

	[self syncArrayControllerToTableAndDataStore] ;
}


- (void)setTopText:(NSString*)topText
    defaultNewItem:(id)defaultNewObject 
		 dataStore:(id <SSTableDataStore>)dataStore {

	[textTop setStringValue:topText] ;
	[self setDefaultNewObject:defaultNewObject] ;
	[self setDataStore:dataStore] ;
}	


- (void)awakeFromNib {
	SSLog(5, "Prolog SSTableKit awakeFromNib") ;

	[buttonPlus setImage:[NSImage imageNamed:@"ButtonPlus"]] ;
	[buttonMinus setImage:[NSImage imageNamed:@"ButtonMinus"]] ;

	[buttonPlus setTarget:self] ;
	[buttonPlus setAction:@selector(addNew:)] ;
	
	[buttonMinus setTarget:self] ;
	[buttonMinus setAction:@selector(removeSelected:)] ;
	
	[table setDelegate:self] ;
	[table setDataSource:self] ;
}

- (void)dealloc {
	[self setArrayController:nil] ;
	
	[super dealloc] ;
}

// ***** Table View delegate methods *****

/* When the user pauses over a cell, the value returned from this method will be displayed in a tooltip.
'point' represents the current mouse location in view coordinates.  If you don't want a tooltip
at that location, return nil.  On entry, 'rect' represents the proposed active
area of the tooltip.  By default, rect is computed as [cell drawingRectForBounds:cellFrame].
To control the default active area, you can modify the 'rect' parameter.
*/
//- (NSString *)tableView:(NSTableView *)aTableView
//		 toolTipForCell:(NSCell *)aCell
//				   rect:(NSRectPointer)rect
//			tableColumn:(NSTableColumn *)aTableColumn
//					row:(int)row
//		  mouseLocation:(NSPoint)mouseLocation{
//	NSString* output = nil ;
//	if ([[aTableColumn identifier] isEqualToString:@"parentName"]) {
//		output = [[aTableView itemAtRow:row] pathIndentedIncludingSelf:NO] ;
//	} else {
//		output = [NSString localize:@"ctrlClickOrRightClickToShowMenu"] ;
//	}
//	
//	return output ;
//}

// This implementation is to provide "sorting by clicking the column heading"
- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
	NSString* key = [NSString stringWithFormat:@"%@", [tableColumn identifier]] ;
	BOOL ascending ;
	
	NSImage* currentImage = [tableView indicatorImageInTableColumn:tableColumn] ;
    
	if (currentImage == [NSImage imageNamed:@"NSAscendingSortIndicator"]) {
		[tableView setIndicatorImage:[NSImage imageNamed:@"NSDescendingSortIndicator"]
					   inTableColumn:tableColumn] ;
		ascending = NO ;
	} else {
		[tableView setIndicatorImage:[NSImage imageNamed:@"NSAscendingSortIndicator"]
					   inTableColumn:tableColumn] ;
		ascending = YES ;
	}
	
	NSArrayController* arrayController = [self arrayController] ;
	
	NSSortDescriptor* descriptor = [[NSSortDescriptor alloc] initWithKey:key
															   ascending:ascending
																selector:@selector(localizedCaseInsensitiveCompare:)] ;
	NSArray* descriptors = [NSArray arrayWithObject:descriptor] ;
	[arrayController setSortDescriptors:descriptors] ;
	[descriptor release] ;
	
	
	// Remember selection
	NSArray* selectedObjects = [arrayController selectedObjects] ;

	// Sort (arrange)
	[arrayController rearrangeObjects] ;
	
	// Restore selection
	[arrayController setSelectedObjects:selectedObjects] ;

	// Make table and dataStore mirror new arrangement
	[self syncArrayControllerToTableAndDataStore] ;
	[table selectRowIndexes:[arrayController selectionIndexes] byExtendingSelection:NO] ;
}


// ***** Table Data Source delegate methods *****

- (id)				tableView:(NSTableView *)tableView
	objectValueForTableColumn:(NSTableColumn *)tableColumn
						  row:(NSInteger)rowIndex {
	NSArray* items = [[self arrayController] arrangedObjects] ;
	id output = [items objectAtIndex:rowIndex] ;

	return output ;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	NSInteger output = [[[self arrayController] arrangedObjects] count] ;
	return output ;
}

// Getting user edits from NSTableView
- (void)tableView:(NSTableView *)tableView
   setObjectValue:(id)object
   forTableColumn:(NSTableColumn *)tableColumn
			  row:(NSInteger)rowIndex {
	
	// Do not allow strings of all whitespace
	if ([object respondsToSelector:@selector(isAllWhite)]) {
		if ([object isAllWhite]) {
			return ;
		}
	}
	
	NSArrayController* arrayController = [self arrayController] ;
	[arrayController removeObjectAtArrangedObjectIndex:rowIndex] ;
	[arrayController insertObject:object atArrangedObjectIndex:rowIndex] ;

	[self syncArrayControllerToTableAndDataStore] ;
}

// To keep arrayController's selection synchronized with the table's selection
- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	NSIndexSet* indexes = [table selectedRowIndexes] ;
	[[self arrayController] setSelectionIndexes:indexes] ;
}

@end