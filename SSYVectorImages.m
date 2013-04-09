#import "SSYVectorImages.h"
#import "NSImage+Transform.h"

@implementation SSYVectorImages

#define TEXT_DRAWING_RECIPROCAL_LINE_WIDTH 8

+ (NSImage*)imageStyle:(SSYVectorImageStyle)style
			  diameter:(CGFloat)diameter 
				 color:(NSColor*)color
		 rotateDegrees:(CGFloat)rotateDegrees {
	NSSize size = NSMakeSize(diameter, diameter) ;
    // This is the width of a pencil-stroke that would make maximally legible text
    // if you wanted to draw a single character of text within the given diameter.
    // Think of an old-fashioned 7-segment LED display maybe.
	CGFloat textDrawingLineWidth = diameter/TEXT_DRAWING_RECIPROCAL_LINE_WIDTH ;

	NSImage* image = [[NSImage alloc] initWithSize:size] ;
	
	[image lockFocus] ;
	
	CGFloat radius = diameter/2 ;

    NSBezierPath* path = [NSBezierPath bezierPath] ;
	
	[[NSColor colorWithCalibratedWhite:0.0 alpha:0.7] set] ;
	switch (style) {
		case SSYVectorImageStylePlus:
		case SSYVectorImageStyleMinus:;
			CGFloat adjustedRadius = radius - textDrawingLineWidth/2 ;
			CGFloat adjustedDiameter = diameter - textDrawingLineWidth/2 ;
			
			[path setLineWidth:textDrawingLineWidth] ;

			// Draw the horizontal line
			[path moveToPoint:NSMakePoint(0, adjustedRadius)] ;
			[path lineToPoint:NSMakePoint(diameter, adjustedRadius)] ;
			[path stroke] ;
			
			if (style == SSYVectorImageStylePlus) {
				// Draw the vertical line
				[path moveToPoint:NSMakePoint(radius, 0 - textDrawingLineWidth/2)] ; // Below zero!
				[path lineToPoint:NSMakePoint(radius, adjustedDiameter - textDrawingLineWidth/2)] ;
				[path stroke] ;
			}
			break ;
		case SSYVectorImageStyleTriangle90:
		case SSYVectorImageStyleTriangle53:
			[path setLineWidth:0.0] ;
			
			BOOL taller = (style == SSYVectorImageStyleTriangle53) ;
			
			CGFloat baselineOffset = 
			taller
			? radius
			: radius/2 ; 
			CGFloat baseline = radius - baselineOffset ;
			
			// Start at bottom left
			[path moveToPoint:NSMakePoint(0, baseline)] ;

			// Move to the right
			[path relativeLineToPoint:NSMakePoint(diameter, 0)] ;

			// Move back halfway to the left, and up
			CGFloat height = taller ? diameter : radius ;
			[path relativeLineToPoint:NSMakePoint(-radius, height)] ;

			// Finish
			[path closePath] ;
			[path fill] ;
			break;
		case SSYVectorImageStyleInfo:;
			[path setLineWidth:textDrawingLineWidth] ;
			
			// Draw the dot on the "i"
			NSRect rectOfDotOnI = NSMakeRect(
											 radius - textDrawingLineWidth*(2/6.0),
											 diameter - textDrawingLineWidth*(3.0/2),
											 textDrawingLineWidth*3.0/4,
											 textDrawingLineWidth*3.0/4
											 ) ;
			[path closePath] ;
			[path fill] ;
			[path removeAllPoints] ;
			
			[path appendBezierPathWithOvalInRect:rectOfDotOnI] ;
			// Draw the lower part of the "i"
			textDrawingLineWidth *= (7.0/4) ;
			[path setLineWidth:textDrawingLineWidth] ;
			[path moveToPoint:NSMakePoint(radius, diameter - 2*textDrawingLineWidth)] ;
			[path lineToPoint:NSMakePoint(radius, 0 - textDrawingLineWidth)] ;  // Below zero!
			[path stroke] ;
			break ;
		case SSYVectorImageStyleStar:;
			// 5-pointed star.  We draw starting at the top, go counterclockwise
			[path moveToPoint: NSMakePoint(0.5*diameter, 1.0*diameter)];     // top point
			[path lineToPoint: NSMakePoint(0.37*diameter, 0.584*diameter)];
			[path lineToPoint: NSMakePoint(0.00*diameter, 0.584*diameter)];  // top left point
			[path lineToPoint: NSMakePoint(0.300*diameter, 0.370*diameter)];
			[path lineToPoint: NSMakePoint(0.190*diameter, 0.000*diameter)]; // bottom left point
			[path lineToPoint: NSMakePoint(0.5*diameter, 0.222*diameter)];
			[path lineToPoint: NSMakePoint(0.810*diameter, 0.000*diameter)]; // bottom right point
			[path lineToPoint: NSMakePoint(0.700*diameter, 0.370*diameter)];
			[path lineToPoint: NSMakePoint(1.00*diameter, 0.584*diameter)];  // top right point
			[path lineToPoint: NSMakePoint(0.630*diameter, 0.584*diameter)];
			[path closePath];
			[color setFill];
			[path fill];
			break ;
		case SSYVectorImageStyleRemoveX:;
			// Draw the circle
			[path appendBezierPathWithArcWithCenter:NSMakePoint(radius, radius)
											 radius:radius
										 startAngle:0.0
										   endAngle:360.0] ;
			[path closePath] ;
			if (!color) {
				color = [NSColor lightGrayColor] ;
			}
			[color setFill] ;
			[path fill] ;
			[path removeAllPoints] ;

			// Draw the "X"
			[path setLineWidth:diameter/10] ;
			[[NSColor whiteColor] setStroke] ;
#define X_SIZE .4
			CGFloat xMargin = (1.0 - X_SIZE) / 2 ;
			CGFloat xMin = diameter * xMargin ;
			CGFloat xMax = diameter * (1.0 - xMargin) ;
			[path moveToPoint:NSMakePoint(xMin, xMax)] ;
			[path lineToPoint:NSMakePoint(xMax, xMin)] ;
			[path moveToPoint:NSMakePoint(xMin, xMin)] ;
			[path lineToPoint:NSMakePoint(xMax, xMax)] ;
			[path stroke] ;
			break ;
	}
			
	[image unlockFocus] ;
	
	NSImage* rotatedImage = [image imageRotatedByDegrees:rotateDegrees] ;
	[image release] ;
	
	return rotatedImage ;	
}


@end

