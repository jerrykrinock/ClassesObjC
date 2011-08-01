#import <Cocoa/Cocoa.h>
#import "SSYModelChangeTypes.h"

@protocol SSYArrayControllerVariableRowHeightObject

- (NSInteger)numberOfSubrows ;

@end

/*!
 @brief    An array controller which supports reordering of objects by the user,
 better-behaved -remove:, a new "add" method which behaves better than -add:,
 and other features.
 
 @details  The features are listed in this section.
 
 REORDERING
 
 For reordering to work, the SSYArrayController must be tightly connected to its associated
 table view, as listed below.  These connections are typically made in the xib file:
 <ul>
 <li>The tableView outlet of the SSYArrayController must be connected to the associated table view.</li>
 <li>The delegate outlet of the associated tableView must be connected to the SSYArrayController.</li>
 <li>The dataSource outlet of the associated tableView must be connected to the SSYArrayController.</li>
 </ul>
 
 All objects in the controlled array must conform to the SSYIndexee protocol.
 
 The associated table view must implement draggingSourceOperationMaskForLocal:.  (Hint: Use SSYDragTableView.)
 
 In order to pass reordering changes to the data model, you may set either the SSYArrayController's
 parentObject or parentObjectKey.  The former is used if the controlled array never changes,
 and the latter is used if the controlled array changes; for example if it is a detail
 in a master-detail view.
 <ul>
 <li>The SSYArrayController's parentObject may be set to the object in the data model which has a
 KVC-compliant mutable set key which will be mutated when the user reorders the objects
 in the controlled array.  To avoid retain cycles, the SSYArrayController maintains only a
 weak reference to its parentObject.</li>
 <li>The SSYArrayController's parentObjectKey may be set to a key of the receiver's object class
 whose value is an object which itself has a key whose value is the controlled array.   In a
 managed object context, parentObjectKey is a to-one relationship from the entity of the
 SSYArrayController's content objects to their "parent", and contentKey is its inverse to-one
 relationship.  The SSYArrayController obtains the parentObject of content object by sending
 valueForKey:parentObjectKey to the content object.</li>
 </ul>
 If both are set, the parentObject is used and the parentObjectKey is ignored.
 
 The SSYArrayController's contentKey must be set to a key in the parentObject whose value
 is the controlled array.
 
 The parentObject, parentObjectKey and contentKey may be set in a window controller's
 awakeFromNib.  (Todo: Develop this class into an Interface Builder Library object.
 The parentObject would be an outlet, and the parentObjectKey and contentKey would
 be string attributes, set in the Inspector's 'Attributes' tab.)
 
 If Core Data is involved, operation may also depend on other options of the superclass
 NSArrayController.&nbsp;  See documentation -[NSArrayController removeObject:] > Discussion.

 The implementation does not actually put any items on the pasteboard.&nbsp;  Instead, it
 passes dragged objects indexes an internal "sneakerboard" index set.  Therefore, objects
 represented in the table need not be serializable nor encodeable.  Also, 
 drags from other table views or any other pasteboard sources will be rejected.
 
 The concept of implementing drag and drop methods in a table view's associated array
 controller was ripped from mmalc's 'Bookmarks' Apple Sample Code project. 
  
 TOOLTIPS
 
 Tooltips are provided in the associated table view for objects which conform to the 
 SSYToolTipper protocol.
 
 MULTILINE TEXT ROWS
 
 For efficiency when not needed, this feature must be turned on by sending 
 -setHeightControllingColumnIndex:.  SSYArrayController will determine from this
 column a multiplier factor for multiple-line rows, and will subsequently
 respond to delegate messages tableView:heightOfRow: by sending the relevant
 content object a -numberOfSubrows message, and returning a height which is
 equal to the table view's -rowHeight multiplied by this multiplier, and 
 again by this number of subrows.  Thus, once you send the receiver a
 -setHeightControllingColumnIndex: message, your content objects
 must respond to -numberOfSubrows if rowHeightsVary is switched to YES.
 This response is assumed and not tested.
 
 Note that this method of caching the multiplier is a little cheesy but
 will work for most usage cases, and was chosen in order to satisfy Apple's
 recommendation that subclass implementations of -tableView:heightOfRow: be
 efficient.  If your table dynamically changes data cells, fonts, or columns,
 you'll need to re-send this message after making such a change so that the
 multiplier will be recalculated.
 
 Even with that, it's still a little cheesy in that it uses my 
 -[NSFont tableRowHeight] method and assumes that data in one column controls
 the height.  If you really want to do it the correct way, or if your cell
 is not a text cell, in -tableView:heightOfRow:, you'll need to use a layout
 manager and calculate the height based on the actual cell data/text
 instead of using the -numberOfRows approximation.  Also, instead of 
 considering only one column as "controlling", a bullet-proof design would
 calculate height for all the columns, and then return the maximum.
 
 For the cheesy method to work properly, the row height of the table
 must be exactly equal to the line spacing of the font used.  You won't
 notice any problem when there is a small mismatch but only one or
 two lines, but you will see a big problem when there are ten lines
 since the small mismatch relative to a line height will be ten times
 greater.
 
 SELECTION METHODS
 
 Provides -selectFirstArranged, -hasSelection.
 
 TABLE FONT SIZE
 
 If you set the tableFontSize property of the receiver, it will cause this
 font size to be set in the table view's cell.  It does this by implementing
 the delegate method tableView:willDisplayCell:forTableColumn:row:.
 */
@interface SSYArrayController : NSArrayController {
    id m_parentObject ;
    NSString* m_parentObjectKey ;
	NSString* m_contentKey ;
	NSIndexSet* m_pendingObjectsIndexSet ;
	CGFloat m_lineHeightMultiplier ;
	CGFloat m_tableFontSize ;
	BOOL m_hasSelection ;

	IBOutlet NSTableView *tableView ;
}

@property (assign) id parentObject ;
@property (copy) NSString* parentObjectKey ;
@property (copy) NSString* contentKey ;
@property (assign) CGFloat tableFontSize ;
// To work around Apple Bug ID  in NSArrayController
@property (assign, readonly) BOOL hasSelection ;

/*!
 @brief    Adds a new item below the current selection, or at the 
 bottom if no item is selected, and selects the new item.
 
 @details  This is a replacement for Apple's add: method as the action
 for a "+" button.&nbsp;  The difference is that this method does what
 the user expects, by putting it under the selection.
 
 If the new object conforms to the SSYIndexee protocol, this method
 will set its -index.  It will not increment the -index of any
 higher-indexed siblings, however.  Presumably you have bound the
 content array of the receiver to an (ordered) array attribute of
 some parent object, and when we insert the new object, your
 data model will get a KVO and take care of the siblings' indexes.
 */
- (IBAction)addBelowCurrentSelection:(id)sender ;

/*!
 @brief    Overrides the base class method to select the next item
 in the content array after the last removed item, instead of
 selecting the first item in the array.
*/
- (void)remove:(id)sender ;

/*!
 @brief    Moves the selection by a given index offset

 @details  You can use this method as the heavy lifter for moving the selection
 using commandKey+arrowKey.&nbsp;  To do this, override -keyDown in the table view,
 and, after validation, send this message with moveBy = +1 or -1.&nbsp;  Hint: 
 Use SSYDragTableView.
 @param    moveBy  The offset by which to move the selection.
 
 @details  As with -addBelowCurrentSelection, this method will not
 adjust the -index of any siblings.  Presumably you have bound the
 content array of the receiver to an (ordered) array attribute of
 some parent object, and when we insert the new object, your
 data model will get a KVO and take care of the siblings' indexes.
*/
- (void)moveSelectionIndexBy:(NSInteger)moveBy ;

/*!
 @brief    Deselects all items and instead selects the first
 object in the receiver's arrangedObjects, if any.
*/
- (void)selectFirstArrangedObject ;

/*!
 @brief    Tells the receiver to measure a line-height multiplication'
 factor from the font used in the text cell of the given column
 and hence respond to future tableView:heightOfRow: delegate messages
 by sending -numberOfRows to the relevant object and doing the math.

 @details  
*/
- (void)setHeightControllingColumnIndex:(NSInteger)index ;

@end
