#import "SSYExtrospectiveViewController.h"
#import "NSObject+SuperUtils.h"

@implementation SSYExtrospectiveViewController

- (void)awakeFromNib {
	// Safely invoke super
	[self safelySendSuperSelector:_cmd
                   prettyFunction:__PRETTY_FUNCTION__
						arguments:nil] ;
    
    [self setNextResponder:[windowController nextResponder]] ;
    [windowController setNextResponder:self] ;
}

- (NSWindowController*)windowController {
    return windowController ;
}

@end
