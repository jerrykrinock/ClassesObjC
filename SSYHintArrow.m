#import "SSYHintArrow.h"
#import <QuartzCore/CoreAnimation.h>
#include <tgmath.h>

NSString* const SSYHintArrowDidCloseNotification = @"SSYHintArrowDidCloseNotification" ;

NSString* const SSYHintArrowWillProcessEventNotification = @"SSYHintArrowWillProcessEventNotification" ;
NSString* const SSYHintArrowEventKey = @"SSYHintArrowEventKey" ;

#define SSYHINTARROW_TOP_COLOR [NSColor colorWithCalibratedRed:(80.0/256.0) green:(111.0/256.0) blue:(246.0/256.0) alpha:1.0]
#define SSYHINTARROW_BOTTOM_COLOR [NSColor colorWithCalibratedRed:(27.0/256.0) green:(68.0/256.0) blue:(243.0/256.0) alpha:1.0]
#define SSYHINTARROW_BORDER_COLOR [NSColor whiteColor]
#define SSYHINTARROW_SCALE_FACTOR [[NSScreen mainScreen] userSpaceScaleFactor]

static SSYHintArrow* static_helpArrow = nil ;

@implementation SSYHintArrow

# pragma mark * Heavy Lifters

- (void)updateGeometry {
    [m_view setFrame:NSMakeRect(0.0, 0.0, m_size.width, m_size.height)] ;
	
	NSRect contentRect = NSZeroRect ;
    contentRect.size = [m_view frame].size ;
    
    // Account for viewMargin.
    m_viewFrame = NSMakeRect(m_viewMargin * SSYHINTARROW_SCALE_FACTOR,
                            m_viewMargin * SSYHINTARROW_SCALE_FACTOR,
                            [m_view frame].size.width, [m_view frame].size.height) ;
    contentRect = NSInsetRect(contentRect, 
                              -m_viewMargin * SSYHINTARROW_SCALE_FACTOR, 
                              -m_viewMargin * SSYHINTARROW_SCALE_FACTOR) ;
    
    CGFloat scaledArrowHeight = m_arrowHeight * SSYHINTARROW_SCALE_FACTOR ;
    m_viewFrame.origin.x += scaledArrowHeight ;
    contentRect.size.width += scaledArrowHeight ;
    
    // Position frame origin appropriately, accounting for arrow-inset.
    contentRect.origin = (m_window) ? [m_window convertBaseToScreen:m_point] : m_point ;
    CGFloat halfHeight = contentRect.size.height / 2.0 ;
    contentRect.origin.y -= halfHeight ;
    
    // Account for distance in new window frame.
    contentRect.origin.x += m_distance ;

    // Reconfigure window and view frames appropriately.
    [self setFrame:contentRect display:NO] ;
    [m_view setFrame:m_viewFrame] ;
}


- (NSBezierPath *)backgroundPath {
    CGFloat scaleFactor = SSYHINTARROW_SCALE_FACTOR ;
    CGFloat scaledRadius = m_cornerRadius * scaleFactor ;
    NSRect contentArea = NSInsetRect(m_viewFrame,
                                     -m_viewMargin * scaleFactor,
                                     -m_viewMargin * scaleFactor) ;
    CGFloat minX = ceilf(NSMinX(contentArea) * scaleFactor + 0.5f) ;
	CGFloat maxX = floorf(NSMaxX(contentArea) * scaleFactor - 0.5f) ;
	CGFloat minY = ceilf(NSMinY(contentArea) * scaleFactor + 0.5f) ;
	CGFloat midY = NSMidY(contentArea) * scaleFactor ;
	CGFloat maxY = floor(NSMaxY(contentArea) * scaleFactor - 0.5f) ;
	
    NSBezierPath* path = [NSBezierPath bezierPath] ;
    [path setLineJoinStyle:NSRoundLineJoinStyle] ;
    
    // Begin at top-left.
    NSPoint currPt = NSMakePoint(minX, maxY) ;
    [path moveToPoint:currPt] ;
        
    // Line to rounded corner at top right.
    NSPoint endOfLine = NSMakePoint(maxX - scaledRadius, maxY) ;
    [path lineToPoint:endOfLine] ;
    
    // Rounded corner on top-right.
	[path appendBezierPathWithArcFromPoint:NSMakePoint(maxX, maxY) 
								   toPoint:NSMakePoint(maxX, maxY - scaledRadius) 
									radius:scaledRadius] ;
    
    
    // Right side, beginning at top.
    endOfLine = NSMakePoint(maxX, minY + scaledRadius) ;
    [path lineToPoint:endOfLine] ;
    
	[path appendBezierPathWithArcFromPoint:NSMakePoint(maxX, minY) 
								   toPoint:NSMakePoint(maxX - scaledRadius, minY) 
									radius:scaledRadius] ;
    
    
    // Bottom side, beginning at right.
    endOfLine = NSMakePoint(minX, minY) ;
    [path lineToPoint:endOfLine] ;
        
    // Draw to arrow point, beginning at the bottom-left.
    endOfLine = NSMakePoint(minX - (maxY - midY), midY) ;
    [path lineToPoint:endOfLine] ;
    
    // Return to top left
	[path closePath] ;

    return path ;
}

- (NSColor *)backgroundColorPatternImage {
    NSImage* bg = [[NSImage alloc] initWithSize:[self frame].size] ;
    NSRect bgRect = NSZeroRect ;
    bgRect.size = [bg size] ;
    
    [bg lockFocus] ;
    NSBezierPath* bgPath = [self backgroundPath] ;
    [NSGraphicsContext saveGraphicsState] ;
    [bgPath addClip] ;
    
    // Draw background gradient.
	[m_gradient drawInBezierPath:bgPath
									  angle:270.0] ;
    
    // Draw border if appropriate.
    if (m_borderWidth > 0) {
        // Double the borderWidth since we're drawing inside the path.
        [bgPath setLineWidth:(m_borderWidth * 2.0) * SSYHINTARROW_SCALE_FACTOR] ;
        [m_borderColor set] ;
        [bgPath stroke] ;
    }
    
    [NSGraphicsContext restoreGraphicsState] ;
    [bg unlockFocus] ;
    
    return [NSColor colorWithPatternImage:[bg autorelease]] ;
}

- (void)updateBackground {
    // Call NSWindow's implementation of -setBackgroundColor: because we override 
    // it in this class to let us set the entire background image of the window 
    // as an NSColor patternImage.
    NSDisableScreenUpdates() ;
    [super setBackgroundColor:[self backgroundColorPatternImage]] ;
    if ([self isVisible]) {
        [self display] ;
        [self invalidateShadow] ;
    }
    NSEnableScreenUpdates() ;
}

- (void)redisplay {
    if (m_isResizingLockout) {
        return ;
    }
    
    m_isResizingLockout = YES ;
    NSDisableScreenUpdates() ;
    [self updateGeometry] ;
    [self updateBackground] ;
    NSEnableScreenUpdates() ;
    m_isResizingLockout = NO ;
}


# pragma mark * Basic Infrastructure

- (SSYHintArrow *)initAttachedToPoint:(NSPoint)point 
							 inWindow:(NSWindow *)window 
						   atDistance:(CGFloat)distance {
    // Create dummy initial contentRect for window.
    NSRect contentRect = NSMakeRect(0.0, 0.0, m_size.width, m_size.height) ;
    contentRect.size = m_size ;
    if ((self = [super initWithContentRect:contentRect 
								 styleMask:NSBorderlessWindowMask 
								   backing:NSBackingStoreBuffered 
									 defer:NO])) {
		// Parameters for displaying the fat blue arrow.
		m_gradient = [[NSGradient alloc] initWithStartingColor:SSYHINTARROW_TOP_COLOR
															  endingColor:SSYHINTARROW_BOTTOM_COLOR] ;
		m_size = NSMakeSize(74.0, 28.0) ; 
		m_borderColor = [SSYHINTARROW_BORDER_COLOR copy] ;
		m_borderWidth = 3.0 ;
		m_viewMargin = 3.0 ;
		m_cornerRadius = 10.0 ;
		m_arrowHeight = m_size.height/2 ;
		m_isResizingLockout = NO ;
		
        m_window = window ;
        m_point = point ;
        m_distance = distance ;
        
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(endWithNote:)
													 name:NSWindowWillCloseNotification
												   object:window] ;
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(didReceiveEvent:)
													 name:SSYHintArrowWillProcessEventNotification
												   object:window] ;
		
        // Configure window
        [super setBackgroundColor:[NSColor clearColor]] ;
        [self setMovableByWindowBackground:NO] ;
        [self setExcludedFromWindowsMenu:YES] ;
        [self setAlphaValue:1.0] ;
        [self setOpaque:NO] ;
        [self setHasShadow:YES] ;
        [self useOptimizedDrawing:YES] ;
		
        // Make the view
		m_view = [[NSView alloc] initWithFrame:contentRect] ;
		// Add view as subview of our contentView.
		[[self contentView] addSubview:m_view] ;
		[m_view release] ;
		
		
		// Configure our initial geometry.
        [self updateGeometry] ;
        
        // Update the background.
        [self updateBackground] ;
    }
    return self ;
}

- (void)dealloc {
	[m_borderColor release] ;
	[m_gradient release] ;
	
    [super dealloc] ;
}

- (NSWindow*)window {
	return m_window ;
}

# pragma mark * Other Methods

- (void)endWithNote:(NSNotification*)notUsed {
	[[NSNotificationCenter defaultCenter] removeObserver:self] ;
	[[self window] removeChildWindow:static_helpArrow] ;
	[self orderOut:self] ;
	[self autorelease] ;
	// I tried a -release instead of the above, but it
	// would usually crash, often reporting that
	// _runningDocModal was sent to the deallocated self
	static_helpArrow = nil ;
	self = nil ;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:SSYHintArrowDidCloseNotification
														object:self
													  userInfo:nil] ;
}

- (void)sendEvent:(NSEvent *)event {
	[SSYHintArrow removeIfEvent:event] ;
	[super sendEvent:event] ;
}

# pragma mark * Overrides

- (BOOL)canBecomeMainWindow {
    return NO ;
}


- (BOOL)canBecomeKeyWindow {
    return YES ;
}


- (BOOL)isExcludedFromWindowsMenu {
    return YES ;
}

- (BOOL)validateMenuItem:(NSMenuItem *)item {
   if (m_window) {
        return [m_window validateMenuItem:item] ;
    }
    return [super validateMenuItem:item] ;
}

# pragma mark * Class Methods

+ (CAKeyframeAnimation *)shakeAnimation:(NSRect)frame {
	CAKeyframeAnimation *shakeAnimation = [CAKeyframeAnimation animation] ;
	
	CGMutablePathRef shakePath = CGPathCreateMutable() ;
	CGPathMoveToPoint(shakePath, NULL, NSMinX(frame), NSMinY(frame)) ;
	NSInteger i ;
	for (i = 0; i < 3; ++i) {
		CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame), NSMinY(frame)) ;
		CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) + 15.0, NSMinY(frame)) ;
	}
	CGPathCloseSubpath(shakePath) ;
	shakeAnimation.path = shakePath ;
	shakeAnimation.duration = 3 ;
    CFRelease(shakePath) ; // I hope that CAKeyframeAnimation retains its -path.
	return shakeAnimation ;
}

+ (void)showHelpArrowAtPoint:(NSPoint)point
					inWindow:(NSWindow*)window {
	if (static_helpArrow) {
		// Only one SSYHintArrow at a time!!
		NSLog(@"Internal Error 892-8178  Intercepted call to display > 1 SSYHintArrow") ;
		return ;
	}

	static_helpArrow = [[SSYHintArrow alloc] initAttachedToPoint:point 
														inWindow:window 
													  atDistance:0.0] ;        
	[window addChildWindow:static_helpArrow
				   ordered:NSWindowAbove] ;
	
	NSDictionary* animations = [NSDictionary dictionaryWithObject:[self shakeAnimation:[static_helpArrow frame]]
														   forKey:@"frameOrigin"] ;
	[static_helpArrow setAnimations:animations];
	[[static_helpArrow animator] setFrameOrigin:[static_helpArrow frame].origin] ;
	
	// static_helpArrow will be released in its -endWithNote: message
}

+ (void)showHelpArrowRightOfView:(NSView*)view {
	NSView* superview = [view superview] ;
	NSRect targetRect = [view frame] ;
	NSWindow* window = [view window] ;
	NSPoint point = NSMakePoint(NSMaxX(targetRect), NSMidY(targetRect)) ;
	point = [superview convertPoint:point
							 toView:[window contentView]] ; 
	[SSYHintArrow showHelpArrowAtPoint:point
							  inWindow:window] ;
}

+ (void)remove {
	[static_helpArrow endWithNote:nil] ;
}

+ (void)removeIfEvent:(NSEvent*)event {
	NSEventType eventType = [event type] ;
	if (
		(eventType == NSLeftMouseDown)
		||
		(eventType == NSRightMouseDown)
		||
		(eventType == NSOtherMouseDown)
		||
		(eventType == NSKeyDown)
		) {
		[static_helpArrow endWithNote:nil] ;
	}
}

@end