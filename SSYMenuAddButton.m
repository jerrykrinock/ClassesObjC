#import "SSYMenuAddButton.h"
#import "NSMenu+PopOntoView.h"

@implementation SSYMenuAddButton

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect] ;
    
    [self lockFocus] ;
    
    // Draw the "+"
    // The y-axis seems to be flipped in here.
    NSImage* image = [NSImage imageNamed:@"NSAddTemplate"] ;
    [image drawInRect:NSMakeRect(8,
                                 8,
                                 8,
                                 8)
             fromRect:NSZeroRect
            operation:NSCompositeSourceOver fraction:0.7
     ] ;
    // Above, the size of 8x8 and fraction 0.7 matches the
    // look that I get when I simply set NSAddTemplate as
    // the image of the button.
    
    // Draw the Triangle
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.7] set] ;
    NSBezierPath* path = [NSBezierPath bezierPath] ;
    [path moveToPoint:NSMakePoint(15, 17)] ;
    [path relativeLineToPoint:NSMakePoint(6, 0)] ;
    [path relativeLineToPoint:NSMakePoint(-3, 3)] ;
    [path closePath] ;
    [path fill] ;
    
    [self unlockFocus] ;
}

@end