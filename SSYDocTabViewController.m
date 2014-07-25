#import "SSYDocTabViewController.h"

/*
 I was going to factor much of BkmxDocTabViewController into this, 
 and also factor an SSYLazyView out of BkmxLazyView, but
 then decided not to, because it would just be for reuse vanity that
 no one would ever re-use.
 */
#if 0

@interface SSYDocTabViewController ()

@end

@implementation SSYDocTabViewController

@synthesize windowController = m_windowController ;
@synthesize awakened = m_awakened ;

- (void)logIfBadInit {
    if (self) {
        if (![self conformsToProtocol:@protocol(BkmxDocTabViewControls)]) {
            NSLog(@"Internal Error 194-2390 %@ no conform", [self className]) ;
        }
    }
}

- (id)initWithNibName:(NSString*)nibNameOrNil
     windowController:(BkmxDocWinCon*)windowController
               bundle:(NSBundle*)nibBundleOrNil {
    [self setWindowController:windowController] ;
    self = [super initWithNibName:nibNameOrNil
                           bundle:nibBundleOrNil] ;
    [self logIfBadInit] ;
    return self ;
}

- (id)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder] ;
    [self logIfBadInit] ;
    return self ;
}

- (void)endEditing:(NSNotification*)note {
	[[self windowController] endEditing] ;
}

- (void)awakeFromNib {
	// Safely invoke super
	[self safelySendSuperSelector:_cmd
                   prettyFunction:__PRETTY_FUNCTION__
						arguments:nil] ;
    
    [self setNextResponder:[[self windowController] nextResponder]] ;
    [[self windowController] setNextResponder:self] ;
}

- (BOOL)           tabView:(NSTabView*)tabView
   shouldSelectTabViewItem:(NSTabViewItem*)tabViewItem {
    return [[self windowController] tabView:tabView
                    shouldSelectTabViewItem:tabViewItem] ;
}

- (void)       tabView:(NSTabView*)tabView
 willSelectTabViewItem:(NSTabViewItem*)tabViewItem {
    [[self windowController] tabView:tabView
               willSelectTabViewItem:tabViewItem] ;
}

- (void)       tabView:(NSTabView*)tabView
  didSelectTabViewItem:(NSTabViewItem*)tabViewItem {
    [[self windowController] tabView:tabView
                didSelectTabViewItem:tabViewItem] ;
}

- (void)tearDown {
    [self setWindowController:nil] ;
}

- (BkmxDoc*)document {
    return [[self windowController] document] ;
}

@end

#endif
