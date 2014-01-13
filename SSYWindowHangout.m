#import "SSYWindowHangout.h"

static NSMutableSet* static_hangout = nil ;

@interface SSYWindowHangout ()

@property (retain) NSWindowController* windowController ;

@end


@implementation SSYWindowHangout

@synthesize windowController = m_windowController ;

- (void)dealloc {
    [m_windowController release] ;
    
    [super dealloc] ;
}

- (id)initWithWindowController:(NSWindowController*)windowController {
    self = [super init] ;
    if (self) {
        [self setWindowController:windowController] ;
    }
    
    return self ;
}

- (void)windowDidCloseNote:(NSNotification*)note {
    NSWindow* window = (NSWindow*)[note object] ;
    NSWindowController* windowController = [window windowController] ;
    [window setWindowController:nil] ;
    [windowController setWindow:nil] ;
    [[NSNotificationCenter defaultCenter] removeObserver:self] ;

    /*
     The following line was removed in BookMacster 1.19.2, so that window
     controllers would be deallocated immediately.  Originally, I thought that
     it was good defensive programming, but in fact there is no need for it,
     and the delayed deallocation can cause, for example, observers to hang
     on longer than necessary, causing trouble when things are town down.
     */
    //[[self retain] autorelease] ;

    [static_hangout removeObject:self] ;
    
    if ([static_hangout count] == 0) {
        [static_hangout release] ;
        static_hangout = nil ;
    }
}

+ (void)hangOutWindowController:(NSWindowController*)windowController {
    NSWindow* window = [windowController window] ;
    if (!window) {
        NSLog(@"Internal Error 614-0595.  %s Trouble ahead with %@",
              __PRETTY_FUNCTION__,
              windowController) ;
    }
    else {
        if (!static_hangout) {
            static_hangout = [[NSMutableSet alloc] init] ;
        }
        
        SSYWindowHangout* hangout = [[self alloc] initWithWindowController:windowController] ;
        [static_hangout addObject:hangout] ;
        [hangout release] ;
        
        NSNotificationCenter* noter = [NSNotificationCenter defaultCenter] ;
        [noter addObserver:hangout
                  selector:@selector(windowDidCloseNote:)
                      name:NSWindowWillCloseNotification
                    object:window] ;
	}
}

+ (NSWindowController*)hungOutWindowControllerOfClass:(Class)class {
    for (SSYWindowHangout* hangout in static_hangout) {
        NSWindowController* windowController = [hangout windowController] ;
        if ([windowController isKindOfClass:class]) {
            return windowController ;
        }
    }
    
    return nil ;
}

@end
