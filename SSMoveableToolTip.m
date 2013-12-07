#import "SSMoveableToolTip.h"

static SSMoveableToolTip	*sharedToolTip = nil;

@interface ToolTipTextField : NSTextField
@end

@implementation ToolTipTextField

- (void) drawRect:(NSRect)aRect
{
    [super drawRect:aRect];
    
    [[NSColor colorWithCalibratedWhite:0.925 alpha:1.0] set];
    NSFrameRect(aRect);
}

@end

@implementation SSMoveableToolTip

- (id)init {
    self = [super init] ;
    
    if (self != nil) {
        // These size are not really import, just the relation between the two...
        NSRect        contentRect       = { { 100, 100 }, { 100, 20 } };
        NSRect        textFieldFrame    = { { 0, 0 }, { 100, 20 } };
        
        _window = [[NSWindow alloc]
                    initWithContentRect:    contentRect
                              styleMask:    NSBorderlessWindowMask
                                backing:    NSBackingStoreBuffered
                                  defer:    YES];
        
        [_window setOpaque:NO];
        [_window setAlphaValue:0.80];
        [_window setBackgroundColor:[NSColor colorWithDeviceRed:1.0 green:0.96 blue:0.76 alpha:1.0]];
        [_window setHasShadow:YES];
        [_window setLevel:NSStatusWindowLevel];
        [_window setReleasedWhenClosed:YES];
        [_window orderFront:nil];
        
        _textField = [[ToolTipTextField alloc] initWithFrame:textFieldFrame];
        [_textField setEditable:NO];
        [_textField setSelectable:NO];
        [_textField setBezeled:NO];
        [_textField setBordered:NO];
        [_textField setDrawsBackground:NO];
        [_textField setAlignment:NSLeftTextAlignment];
        [_textField setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [[_window contentView] addSubview:_textField];
        
    }
    
    return self ;
}

- (void) dealloc {
    [_window release] ;
    [_textField release] ;  // Memory leak fixed in BookMacster 1.17

    [super dealloc];
}

#define GRRRRR_MARGIN_REQUIRED_TO_SAFELY_PREVENT_TEXT_WRAPPING 10.0

- (void) setString:(NSString*)string
              font:(NSFont*)font
			origin:(NSPoint)origin
		  inWindow:(NSWindow*)hostWindow {
    if (!font) {
        font = [NSFont toolTipsFontOfSize:[NSFont smallSystemFontSize]] ;
    }
    
    if ([string length] == 0) {
        string = @ " " ;
    }
	
    [_textField setStringValue:string] ;
    [_textField setFont:font] ;

    NSDictionary* textAttributes = [[_textField attributedStringValue] attributesAtIndex:0
                                                                          effectiveRange:nil] ;
    origin.x += _offset.x ;
	origin.y += _offset.y ;
	
	NSSize size = [string sizeWithAttributes:textAttributes] ;
    NSSize windowSize = NSMakeSize(
                                   size.width + GRRRRR_MARGIN_REQUIRED_TO_SAFELY_PREVENT_TEXT_WRAPPING,
                                   size.height + 1
                                   ) ;
	
    NSPoint cursorScreenPosition = [hostWindow convertBaseToScreen:origin];

    // On 2013-12-04, removed hard-coded offsets in here which were for my app.
    // Any offset you need should be passed in the 'origin' parameter!
	[_window setFrameTopLeftPoint:NSMakePoint(cursorScreenPosition.x, cursorScreenPosition.y)];
    [_window setContentSize:windowSize] ;
}

- (void)setOffset:(NSPoint)offset {
	_offset = offset ;
}

+ (void) setString:(NSString*)string
              font:(NSFont*)font
			origin:(NSPoint)origin
		  inWindow:(NSWindow*)hostWindow
{
    if (sharedToolTip == nil) {
        sharedToolTip = [[SSMoveableToolTip alloc] init];
    }
    
    [sharedToolTip setString:string
                        font:font
					  origin:origin
					inWindow:hostWindow];
}

+ (void) goAway
{
    [sharedToolTip release];
    sharedToolTip = nil;
}

+ (void)setOffset:(NSPoint)offset {
	[sharedToolTip setOffset:offset] ;
}

@end
