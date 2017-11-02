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
        [_window setBackgroundColor:[NSColor colorWithDeviceRed:0.953 green:0.953 blue:0.953 alpha:1.0]];
        [_window setHasShadow:YES];
        [_window setLevel:NSStatusWindowLevel];
        [_window setReleasedWhenClosed:YES]; // Defensive, since this is default behavior
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
    [_window close]; // Also releases, due to `releaseWhenClosed`
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
	
    NSRect cursorRect = [hostWindow convertRectToScreen:NSMakeRect(origin.x,origin.y,0,0)] ;
	[_window setFrameTopLeftPoint:NSMakePoint(cursorRect.origin.x, cursorRect.origin.y)] ;
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
    if (string.length > 0)
    {
        if (sharedToolTip == nil) {
            sharedToolTip = [[SSMoveableToolTip alloc] init];
        }

        [sharedToolTip setString:string
                            font:font
                          origin:origin
                        inWindow:hostWindow];
    }
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
