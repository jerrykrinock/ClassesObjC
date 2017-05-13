#import "SSYLineBox.h"

@implementation SSYLineBox

#define DESIRED_WHITENESS 0.2
#define DESIRED_ALPHA 1.0
#define DESIRED_THICKNESS 1.0

- (void)awakeFromNib {
    self.accessibilityElement = NO;
}

- (void)drawRect:(NSRect)dirtyRect {
    NSColor* color = [NSColor colorWithCalibratedWhite:DESIRED_WHITENESS
                                                 alpha:DESIRED_ALPHA] ;
    [color setFill] ;

    /* The thickness (frame.size.width of a Vertical Line, or frame.size.height
     of a Horizontal Line) drawn out of the object library in Xcode's xib
     editor is 5 points.  I don't know why, because the line itself is only 1
     pixel thick.  Anyhow, the following code deals with that 5 (or whatever)
     points, positioning the line drawn in the center of the frame. */
    NSRect rect = NSZeroRect ;
    if ([self frame].size.height > [self frame].size.width) {
        // We want a vertical line
        CGFloat frameThickness = [self frame].size.width ;
        rect.origin.x = (frameThickness - DESIRED_THICKNESS)/2.0 ;
        rect.size.width = DESIRED_THICKNESS ;
        rect.size.height = [self frame].size.height ;
    }
    else {
        // We want a horizontal line
        CGFloat frameThickness = [self frame].size.height ;
        rect.origin.y = (frameThickness - DESIRED_THICKNESS)/2.0 ;
        rect.size.height = DESIRED_THICKNESS ;
        rect.size.width = [self frame].size.width ;
    }
    
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:rect] ;
    [path fill] ;
}

@end
