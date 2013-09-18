#import "SSYTempWindowController.h"

static NSMutableSet* static_windowControllers = nil ;

@implementation SSYTempWindowController

+ (NSString*)nibName {
	NSLog(@"Internal Error 235-0832") ;
	return nil ;
}

- (void)goAway {
	[[NSNotificationCenter defaultCenter] removeObserver:self] ;
	[[self window] setWindowController:nil] ;
    [[self retain] autorelease] ;
    [static_windowControllers removeObject:self] ;
}


- (id)init {
	self = [super initWithWindowNibName:[[self class] nibName]] ;
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(goAway)
													 name:NSWindowWillCloseNotification
												   object:[self window]] ;
	}
	
	return self ;
}

+ (id)showWindow {
	SSYTempWindowController* instance = nil ;

	// See if a window with a window controller of this class already exists
	for (NSWindow* window in [NSApp windows]) {
		NSWindowController* candidate = [window windowController] ;
		if ([candidate isMemberOfClass:[self class]]) {
			instance = (SSYTempWindowController*)candidate ;
            [instance retain] ;
            break ;
		}
	}
	
	if (!instance) {
		instance = [[self alloc] init] ;
	}
    
    if (!static_windowControllers) {
        static_windowControllers = [[NSMutableSet alloc] init] ;
    }
    [static_windowControllers addObject:instance] ;

    [instance release] ;

	[instance showWindow:self] ;
	
	return instance ;
}

@end