#import "SSYMiniProgressWindow.h"
#import "NSString+SSYExtraUtils.h"

#define SSY_MINI_PROGRESS_WINDOW_WIDTH 200.0
#define SSY_MINI_PROGRESS_WINDOW_HEIGHT 52.0

@implementation SSYMiniProgressWindow

- (SSYMiniProgressWindow*)initWithVerb:(NSString*)verb
								 point:(NSPoint)point {
	point.y -= SSY_MINI_PROGRESS_WINDOW_HEIGHT ;
    NSRect rect = NSMakeRect(0.0, 0.0, SSY_MINI_PROGRESS_WINDOW_WIDTH, SSY_MINI_PROGRESS_WINDOW_HEIGHT) ;
    self = [super initWithContentRect:rect 
							styleMask:NSWindowStyleMaskBorderless 
							  backing:NSBackingStoreBuffered 
								defer:NO] ;
	if (self) {
        [super setBackgroundColor:[NSColor windowBackgroundColor]] ;  // clearColor looks cool
        [self setMovableByWindowBackground:YES] ;
        [self setExcludedFromWindowsMenu:YES] ;
        [self setAlphaValue:1.0] ;
        [self setOpaque:NO] ;
        [self setHasShadow:YES] ;
		[self setLevel:NSFloatingWindowLevel] ;
		
		// Adjust position if the window is going to overflow off the screen
		NSSize screenSize = [[self screen] visibleFrame].size ;  // Checked that .height does not include menu bar
		point.x = MIN(point.x, screenSize.width - SSY_MINI_PROGRESS_WINDOW_WIDTH) ;
		point.y = MIN(point.y, screenSize.height - SSY_MINI_PROGRESS_WINDOW_HEIGHT) ;
		point.y = MAX(point.y, 0.0) ;
		[self setFrameOrigin:point] ;
		
		rect = NSMakeRect(20.0, 34.0, 160.0, 8.0) ;
		NSProgressIndicator* progressIndicator = [[NSProgressIndicator alloc] initWithFrame:rect] ;
		[progressIndicator setUsesThreadedAnimation:YES] ;
		[progressIndicator setIndeterminate:YES] ;
		[progressIndicator startAnimation:self] ;
		[[self contentView] addSubview:progressIndicator] ;
        [progressIndicator release] ;
		
		rect.origin.y = 10.0 ;
		rect.size.height = 14.0 ;
		NSTextField* textField = [[NSTextField alloc] initWithFrame:rect] ;
		[[textField cell] setLineBreakMode:NSLineBreakByTruncatingMiddle] ;
		[textField setBordered:NO] ;
		[textField setEditable:NO] ;
		[textField setDrawsBackground:NO] ;
		[textField setFont:[NSFont systemFontOfSize:11.0]] ;
		// A newly-created NSTextField has string value "Field".
		[textField setStringValue:[verb ellipsize]] ;
		[textField setAlignment:NSTextAlignmentCenter] ;
		[[self contentView] addSubview:textField] ;
        [textField release] ;
		
		[self display] ;
		[self orderFrontRegardless] ;
    }

    return self ;
}


#if 0
#warning Logging dealloc ocf SSYMiniProgressWindow
- (void)dealloc {
	[super dealloc] ;
}
#endif
@end
