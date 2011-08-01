#import "SSYVectorImages.h"
#import "NSImage+Transform.h"

@implementation SSYVectorImages

#define TEXT_DRAWING_RECIPROCAL_LINE_WIDTH 8

+ (NSImage*)imageStyle:(SSYVectorImageStyle)style
			  diameter:(CGFloat)diameter 
		 rotateDegrees:(CGFloat)rotateDegrees {
	NSSize size = NSMakeSize(diameter, diameter) ;
	CGFloat textDrawingLineWidth = diameter/TEXT_DRAWING_RECIPROCAL_LINE_WIDTH ;

	NSImage* image = [[NSImage alloc] initWithSize:size] ;
	
	[image lockFocus] ;
	
	CGFloat radius = diameter/2 ;

    NSBezierPath* path = [NSBezierPath bezierPath] ;
	
	[[NSColor colorWithCalibratedWhite:0.0 alpha:0.7] set] ;
	// [[NSColor grayColor] setStroke] ;
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
		case SSYVectorImageStyleTriangle:
		case SSYVectorImageStyleArrow:
			[path setLineWidth:0.0] ;
			
			BOOL taller = (style == SSYVectorImageStyleArrow) ;
			
			CGFloat baselineOffset = 
			taller
			? radius
			: radius/2 - textDrawingLineWidth/2 ; 
			CGFloat baseline = radius - baselineOffset ;
			
			// Start at left
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
	}
			
	[image unlockFocus] ;
	
	NSImage* rotatedImage = [image imageRotatedByDegrees:rotateDegrees] ;
	[image release] ;
	
	return rotatedImage ;	
}


@end

