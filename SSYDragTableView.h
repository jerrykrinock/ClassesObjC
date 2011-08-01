#import <Cocoa/Cocoa.h>

/*!
 @brief    A table view which adds several features to a
 table when used in conjunction with SSYArrayController
 to which its columns are bound in the conventional way.
 
 @details  The features added are:
 <ul>
 <li>Drag and Drop reordering (Notes 1, 2, 3)</li>
 <li>cmd+upArrow or downArrow to move selection (Note 1)</li>
 <li>'delete' key to delete selection (Note 1)</li>
 </ul>
 
 Note 1.  Requires that the receiver's 'delegate' outlet be
 connected to the associated array controller.
 Note 2.  Requires that the receiver's 'dataSource' outlet be
 connected to the associated array controller.
 Note 3.  Requires that the associated SSYArrayController's
 'tableView' outlet be connected to the receiver.
*/
@interface SSYDragTableView : NSTableView {
}

@end
