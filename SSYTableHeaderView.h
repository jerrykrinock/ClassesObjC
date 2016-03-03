#import <Cocoa/Cocoa.h>

/*!
 @brief    This subclass provides two method overrides which
 make a table header view compatible with SSYPopUpTableHeaderCell.
 
 @details  The override of mouseDown is to send -performClickWithFrame:inView:
 to the appropriate SSYPopUpTableHeaderCell.&nbsp;  This is needed
 because, if you do this in tableView:mouseDownInHeaderOfTableColumn:
 or View:mouseDownInHeaderOfTableColumn:, it apparently begins
 a menu tracking session while the table view itself is already in
 a mouse tracking session, so that it requires two mouse clicks
 to get the app back to normal.  See cocoa-dev@lists.apple.com,
 Subject: NSPopUpButtonCell Keeps on Trackin'! Demo, Movie
 http://www.cocoabuilder.com/archive/message/cocoa/2009/4/27/235450
 */
@interface SSYTableHeaderView : NSTableHeaderView {

}

@property (retain) NSTableColumn* sortedColumn ;

@end
