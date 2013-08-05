#import <Cocoa/Cocoa.h>

extern NSString* const constDiscontiguousTabViewHierarchyString ;

@interface SSYHierarchicalTabViewItem : NSTabViewItem

/*
 @brief    Returns self, unless the receiver's view contains a (sub) tab view, 
 then returns the selected tab view item of the first such sub tab view, unless
 the view of that item contans a (subsub) tab view, then returns the selected
 tab view item of the first subsub tab view, etc. recursively until a leaf tab
 view item is found.
 
 @details  This method has some safety built into it.  If self, or any leaf item
 found during the recursion, does not respond as required (typically because the
 items is a NSTabViewItem but not a SSYHierarchicalTabViewItem), this method 
 stops and returns the deepest tab view item it has already found.  No
 exception is raised.
 
 The phrase "first … tab view" means the first in the array -[NSView subviews].
 You should probably have only one of these, unless you want to confuse users
 even more than having hierarchical tab view items already does :))
 
 @result   The tab view item returned is often the receiver itself.
 */
- (NSTabViewItem*)selectedLeafmostTabViewItem ;

/*
 @brief    Returns whether or not the receiver is selected, *and* all of its
 ancestor tab view items are selected, which means that the receiver should be
 actually visible.
 
 @details  Unfortunately, because there is no way for a given view, which
 happens to be the 'view' of a tab view item, to access its "parent' tab view
 item, we cannot walk the hierarchy upward as we would like.  A tab view item
 can access its window, though, and a view can access its subviews.  So we start
 at the receiver's window and walk down.
 
 Because of this walking down, this method will fail if the receiver's greatest
 ancestor tab view is directly a subview of the the receiver's window, or if
 any of its intermediate ancestor tab views are not directly a subview of the
 view of the parent tab view items.  If this condition occurs, this method will
 return NO and NSLog constDiscontiguousTabViewHierarchyString with the
 receiver's identifier appended.
 */
- (BOOL)isDeeplySelected ;

@end
