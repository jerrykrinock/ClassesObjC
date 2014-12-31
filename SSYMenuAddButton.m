#import "SSYMenuAddButton.h"
#import "NSMenu+PopOntoView.h"
#import "SSYVectorImages.h"

@implementation SSYMenuAddButton

- (void)drawRect:(NSRect)dirtyRect {
	[super drawRect:dirtyRect] ;
	
    // Draw the "+"
    // The y-axis seems to be flipped in here.
    NSImage* image = [NSImage imageNamed:@"NSAddTemplate"] ;
    [image drawInRect:NSMakeRect(3,
                                 6,
                                 14,
                                 14)
             fromRect:NSZeroRect
            operation:NSCompositeSourceOver fraction:0.7
     ] ;
    
	// Draw the Triangle
	[[NSColor colorWithCalibratedWhite:0.0 alpha:0.7] set] ;
	NSBezierPath* path = [NSBezierPath bezierPath] ;
	[path moveToPoint:NSMakePoint(14, 18)] ;
	[path relativeLineToPoint:NSMakePoint(8, 0)] ;
	[path relativeLineToPoint:NSMakePoint(-4, 4)] ;
	[path closePath] ;
	[path fill] ;
}

 @end