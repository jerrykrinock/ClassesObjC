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
    
    return selectedChild ;
}

- (NSTabViewItem*)selectedLeafmostTabViewItem {
    NSTabViewItem* leafItem = self ;
    NSTabViewItem* selectedChild = nil ;
    do {
        if (![leafItem respondsToSelector:@selector(selectedChild)]) {
            break ;
        }
        
        selectedChild = [(SSYHierarchicalTabViewItem*)leafItem selectedChild] ;
        if (selectedChild) {
            leafItem = selectedChild ;
        }
    } while (selectedChild != nil) ;
    /*SSYDBL*/ NSLog(@"<< %s returning leaf = %@ for %@", __PRETTY_FUNCTION__, [leafItem identifier], [self identifier]) ;
	
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
    /*SSYDBL*/ NSLog(@"<< %s is returning %hhd for %@", __PRETTY_FUNCTION__, answer, [self identifier]) ;

    return answer ;
}

@end
