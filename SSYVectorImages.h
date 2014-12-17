#import <Cocoa/Cocoa.h>


enum SSYVectorImageStyles_enum
{
	SSYVectorImageStylePlus,
	SSYVectorImageStyleMinus,
    /* Dash is narrower and thinner than Minus */
    SSYVectorImageStyleDash,
    /* Triangle, horizonal baseline, pointing up, with top vertex 90 degrees.
     This one is shorter and fatter than Triangle53.  */
	SSYVectorImageStyleTriangle90,
    /* Triangle, horizonal baseline, pointing up, with top vertex 2*arctan(.5)
     = 53.2 degrees.  This one is a taller and thinner than Triangle90. */
	SSYVectorImageStyleTriangle53,
	SSYVectorImageStyleInfoOff,
    SSYVectorImageStyleInfoOn,
    SSYVectorImageStyleHelp,
	/* Five-pointed star used in SSYStarRatingView */
    SSYVectorImageStyleStar,
    /* White "X" inside a gray circle, used in SSYStarRatingView */
	SSYVectorImageStyleRemoveX,
    /* "Bookmark", solid black except for a white hole near the top */
    SSYVectorImageStyleBookmark,
    SSYVectorImageStyleHierarchy,
    SSYVectorImageStyleFlat,
    SSYVectorImageStyleLineage,
    SSYVectorImageStyleTag,
    SSYVectorImageStyleCheck1,
    SSYVectorImageStyleCheck2,
    SSYVectorImageStyleBookmarksInFolder,
    SSYVectorImageStyleSettings,
    SSYVectorImageStyleReports
} ;
typedef enum SSYVectorImageStyles_enum SSYVectorImageStyle ;


@interface SSYVectorImages : NSObject {
}

/*
@param    rotateDegrees  Measure by which the result should be rotated clockwise
 */
+ (NSImage*)imageStyle:(SSYVectorImageStyle)style
                length:(CGFloat)length
				 color:(NSColor*)color
		 rotateDegrees:(CGFloat)rotateDegrees ;

@end
