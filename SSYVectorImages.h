#import <Cocoa/Cocoa.h>


enum SSYVectorImageStyles_enum
{
    SSYVectorImageStylePlus,
    SSYVectorImageStyleMinus,
    /* Triangle, horizonal baseline, pointing up, with top vertex 90 degrees.
     This one is shorter and fatter.  */
    SSYVectorImageStyleTriangle90,
    /* Triangle, horizonal baseline, pointing up, with top vertex 2*arctan(.5)
     = 53.2 degrees.  This one is a taller and thinner. */
    SSYVectorImageStyleTriangle53,
    SSYVectorImageStyleInfo,
    /* Five-pointed star used in SSYStarRatingView */
    SSYVectorImageStyleStar,
    /* White "X" inside a gray circle, used in SSYStarRatingView */
    SSYVectorImageStyleRemoveX,
    /* "Bookmark", solid color except for a white hole near the top */
    SSYVectorImageStyleBookmark
} ;
typedef enum SSYVectorImageStyles_enum SSYVectorImageStyle ;


@interface SSYVectorImages : NSObject {
}

/*
 @param    rotateDegrees  Measure by which the result should be rotated clockwise
 */
+ (NSImage*)imageStyle:(SSYVectorImageStyle)style
              diameter:(CGFloat)diameter
                 color:(NSColor*)color
         rotateDegrees:(CGFloat)rotateDegrees ;

@end
