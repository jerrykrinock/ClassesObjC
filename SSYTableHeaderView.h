#import <Cocoa/Cocoa.h>

/*!
 @brief    This subclass provides two method overrides which
 make a table header view compatible with SSYPopUpTableHeaderCell.
 
 @details  The override of -drawRect: is to work around some
 weirdness which occurred if you'd a user-defined column
 header back and forth between "Last Verify Result" and
 "Verify Disposition", sometimes it would send two 
 -drawWithFrame:inView: messages to one column and none to the
 other, instead of one to each, and this would cause incomplete
 redrawing.&nbsp;  This was most likely to happen if you clicked
 over to another window in another app between the two column-
 header clicks.&nbsp;  So I reverse-engineered and re-implemented
 that method and that seemed to fix the problem.
 
 The override of mouseDown is to send -performClickWithFrame:inView:
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

@end
