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

@end
