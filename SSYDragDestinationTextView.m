#import "SSYDragDestinationTextView.h"

@implementation SSYDragDestinationTextView : NSTextView

- (void)setIgnoreTabsAndReturns:(BOOL)ignoreTabsAndReturns {
    [self setFieldEditor:ignoreTabsAndReturns] ;
}

- (BOOL)ignoreTabsAndReturns {
    return [self isFieldEditor] ;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    BOOL didDo = [super performDragOperation:sender] ;

    if (self.activateUponDrop) {
        [NSApp activateIgnoringOtherApps:YES] ;
        [[self window] makeKeyAndOrderFront:self] ;
    }

	return didDo ;
}

@end
