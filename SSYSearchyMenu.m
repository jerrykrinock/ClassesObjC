#import "SSYSearchyMenu.h"

NSString* SSYSearchyMenuWillProcessEventNotification = @"SSYSearchyMenuWillProcessEventNotification" ;

@implementation SSYSearchyMenu

@synthesize size = m_size ;

/*
 @details  NSWindow will refuse to become the main window unless it has a title
 bar.  This override lets us become main even though we don't have a title bar.
 */
- (BOOL)canBecomeMainWindow {
    return YES ;
}

/*
 @details  Much like above method.
 */
- (BOOL) canBecomeKeyWindow {
    return YES ;
}

- (BOOL)isExcludedFromWindowsMenu {
    return YES ;
}

- (void)goAway {
	[self orderOut:self] ;
//	[[NSNotificationCenter defaultCenter] removeObserver:self] ;
}

#define SSY_SEARCHY_MENU_WIDTH 100.0
#define SSY_SEARCHY_MENU_HEIGHT 50.0

- (id)initWithTitle:(NSString*)title
         atLocation:(NSPoint)location
           delegate:(NSObject*)delegate {
    // Create dummy initial contentRect for window.
    NSRect frame = NSMakeRect(
                              location.x,
                              location.y - SSY_SEARCHY_MENU_HEIGHT,
                              SSY_SEARCHY_MENU_WIDTH,
                              SSY_SEARCHY_MENU_HEIGHT
                              ) ;
    NSRect contentFrame = NSMakeRect(
                              0.0,
                              0.0,
                              SSY_SEARCHY_MENU_WIDTH,
                              SSY_SEARCHY_MENU_HEIGHT
                              ) ;
    if ((self = [super initWithContentRect:contentFrame
								 styleMask:(NSBorderlessWindowMask + NSTitledWindowMask)
								   backing:NSBackingStoreBuffered
									 defer:NO])) {
        
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(didReceiveEvent:)
													 name:SSYSearchyMenuWillProcessEventNotification
												   object:nil] ;
		
        // Configure window
        if (title) {
            [self setTitle:title] ;
        }
        [self setMovableByWindowBackground:NO] ;
        [self setExcludedFromWindowsMenu:YES] ;
        [self setAlphaValue:1.0] ;
        [self setOpaque:NO] ;  // was NO
        [self setHasShadow:YES] ;
        [self useOptimizedDrawing:YES] ;
        
        [[self contentView] setFrame:contentFrame] ;
        [self setFrame:frame
               display:YES] ;
        
        [self setLevel:NSDockWindowLevel] ;
        [self setHidesOnDeactivate:NO] ;
        [self makeKeyAndOrderFront:self] ;        
    }

    return self ;
}

- (void)popUpMenu:(NSMenu*)menu {
    [menu popUpMenuPositioningItem:[[menu itemArray] objectAtIndex:0]
						atLocation:[self frame].origin
                            inView:nil] ;
}

@end
