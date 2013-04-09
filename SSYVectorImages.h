#import <Cocoa/Cocoa.h>


enum SSYVectorImageStyles_enum
{
	SSYVectorImageStylePlus,
	SSYVectorImageStyleMinus,
    /* Triangle, horizonal baseline, pointing up, with top vertex 90 degrees */
	SSYVectorImageStyleTriangle90,
    /* Triangle, horizonal baseline, pointing up, with top vertex 2*arctan(.5) = 53.2 degrees */
	SSYVectorImageStyleTriangle53,
	SSYVectorImageStyleInfo,
	/* Five-pointed star used in SSYStarRatingView */
    SSYVectorImageStyleStar,
    /* White "X" inside a gray circle, used in SSYStarRatingView */
	SSYVectorImageStyleRemoveX,
} ;
typedef enum SSYVectorImageStyles_enum SSYVectorImageStyle ;


@interface SSYVectorImages : NSObject {
}

+ (NSImage*)imageStyle:(SSYVectorImageStyle)style
			  diameter:(CGFloat)diameter
				 color:(NSColor*)color
		 rotateDegrees:(CGFloat)rotateDegrees ;

@end
