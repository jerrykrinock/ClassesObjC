#import "SSYHierarchicalTabViewItem.h"

NSString* const constDiscontiguousTabViewHierarchyString = @"Discontiguous tab view hierarchy" ;

@interface NSView (SSYTabSubviews)

- (NSTabViewItem*)deeplySelectedTabViewItem ;

@end

@implementation NSView (SSYTabSubviews)

- (NSTabViewItem*)deeplySelectedTabViewItem {
    NSTabViewItem* selectedChild = nil ;
    if ([self respondsToSelector:@selector(selectedTabViewItem)]) {
        // self is a tab view
        selectedChild = [(NSTabView*)self selectedTabViewItem] ;
    }
    else {
       for (NSView* subview in [self subviews]) {
            selectedChild = [subview deeplySelectedTabViewItem] ;
            if (selectedChild) {
                break ;
            }
        }
    }
    
    return selectedChild ;
}


@end

@implementation SSYHierarchicalTabViewItem

- (NSTabViewItem*)selectedChild {
    NSTabViewItem* selectedChild = [[self view] deeplySelectedTabViewItem] ;

    return selectedChild ;
}

- (NSTabViewItem*)selectedLeafmostTabViewItem {
    NSTabViewItem* leafItem = self ;
    NSTabViewItem* selectedChild = nil ;
   do {
        // This is in case the leaf item in a tree of SSYHierarchicalTabViewItem
        // objects is not itself a class descendant of
        // SSYHierarchicalTabViewItem.  It is also for safety,
        // in case someone sends this message to a tab view item
        // which is not or does not inherit from this class.
        if (![leafItem respondsToSelector:@selector(selectedChild)]) {
          break ;
        }
        
        selectedChild = [(SSYHierarchicalTabViewItem*)leafItem selectedChild] ;
       if ([selectedChild isKindOfClass:[NSTabViewItem class]]) {
            leafItem = selectedChild ;
        }
    } while (selectedChild != nil) ;
	
    return leafItem ;
}

@end
