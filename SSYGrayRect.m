#import "SSYGrayRect.h"


@implementation SSYGrayRect
    
@synthesize topWhite = m_topWhite ;
@synthesize bottomWhite = m_bottomWhite ;
    
- (void)awakeFromNib {
    [self setTopWhite:0.627] ;
    [self setBottomWhite:0.784] ;
}
    
- (void)drawRect:(NSRect)dirtyRect {
	[super drawRect:dirtyRect] ;
	
	[self lockFocus] ;
	
	NSGradient* gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:[self topWhite]
                                                                                                 alpha:1.0]
														 endingColor:[NSColor colorWithCalibratedWhite:[self bottomWhite]
                                                                                                 alpha:1.0]] ;
    
    // The following was fixed in BookMacster 1.18 so that it works
    // if the instance does not happen to located at {0,0} in its superview :)
    NSRect frame ;
    frame.origin.x = 0 ;
    frame.origin.y = 0 ;
    frame.size.width = [self frame].size.width ;
    frame.size.height = [self frame].size.height ;
	[gradient drawInRect:frame
				   angle:270.0] ;
	[self unlockFocus] ;
	[gradient release] ;
}

@end