#import "SSYHierarchicalTabViewItem.h"

NSString* const constDiscontiguousTabViewHierarchyString = @"Discontiguous tab view hierarchy" ;


@implementation SSYHierarchicalTabViewItem

- (NSTabViewItem*)selectedChild {
    NSTabViewItem* selectedChild = nil ;
    for (NSTabView* subview in [[self view] subviews]) {
        if ([subview isKindOfClass:[NSTabView class]]) {
            selectedChild = [subview selectedTabViewItem] ;
            // Note that we consider only the *first* subview which is an
            // NSTabView.  For this method to make sense, this must also be the
            // *only* subview which is an NSTabViewItem.
            break ;
        }
    }

    //  The following code seems to have been a good guess.  That is,
    //  it seems to work, but I haven't really thought it through.
    //  The idea is that it can reach down to find a tab view through, I
    //  think, one level of NSView subview.  I need this for the topTabView
    //  in BookMacster.  This "feature" is not explained in the header doc.
    if (!selectedChild) {
        for (NSView* subview in [[self view] subviews]) {
//          NSLog(@"2 Considering subview %@", subview) ;
            if ([subview respondsToSelector:@selector(subviews)]) {
                for (NSTabView* innerSubview in [subview subviews]) {
//                  NSLog(@"3 Considering innerSubview %@", innerSubview) ;
                    if ([innerSubview isKindOfClass:[NSTabView class]]) {
                        selectedChild = [innerSubview selectedTabViewItem] ;
                        // Note that we consider only the *first* subview which is an
                        // NSTabView.  For this method to make sense, this must also be the
                        // *only* subview which is an NSTabViewItem.
                        break ;
                    }
                }
            }
            
            if (selectedChild) {
                break ;
            }
        }
    }
    
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

- (BOOL)isDeeplySelected {
    NSView* view = [[[self view] window] contentView] ;
    NSTabViewItem* tabViewItem = nil ;
    BOOL answer = NO ;
    while (view != nil) {
        NSArray* subviews = [view subviews] ;
        view = nil ;
        for (NSTabView* tabView in subviews) {
            // Of course, tabView is not necessarily an NSTabView.  Test it…
            if ([tabView isKindOfClass:[NSTabView class]]) {
                tabViewItem = [tabView selectedTabViewItem] ;
                view = [tabViewItem view] ;
                break ;
            }
        }
        
        if (tabViewItem == self) {
            answer = YES ;
            break ;
        }
        else if (!tabViewItem) {
            NSLog(
                  @"%@ : %@",
                  constDiscontiguousTabViewHierarchyString,
                  [self identifier]) ;
        }
    }
    // NSLog(@"<< %s is returning %hhd for %@", __PRETTY_FUNCTION__, answer, [self identifier]) ;

    return answer ;
}

@end
