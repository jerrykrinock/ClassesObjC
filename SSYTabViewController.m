#import "SSYTabViewController.h"

@implementation SSYTabViewController

- (void)        tabView:(NSTabView*)tabView
  willSelectTabViewItem:(NSTabViewItem*)tabViewItem {
    [super       tabView:tabView
   willSelectTabViewItem:tabViewItem];
    [self.surrogate tabView:tabView
      willSelectTabViewItem:tabViewItem];
}

- (void)       tabView:(NSTabView*)tabView
  didSelectTabViewItem:(NSTabViewItem*)tabViewItem {
    [self.surrogate tabView:tabView
       didSelectTabViewItem:tabViewItem];
    [super      tabView:tabView
   didSelectTabViewItem:tabViewItem];
}

@end
