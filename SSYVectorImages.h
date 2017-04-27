#import <Cocoa/Cocoa.h>


enum SSYVectorImageStyles_enum
{
    SSYVectorImageStylePlus,
    SSYVectorImageStyleMinus,
    /* Dash is narrower and thinner than Minus */
    SSYVectorImageStyleDash,
    SSYVectorImageStyleDot,
    /* An open circle, and two lines, oriented at +45° and -45°.  The lines
     intersect at the center of the circle, forming a "target".   For this
     style, the inset is the inset of the circle.  The width and height of the
     square enclosing the two lines is equal to the wength.  */
    SSYVectorImageStyleTarget,
    SSYVectorImageStyleChasingArrows,
    SSYVectorImageStyleWindowWithSidebar,
    /* Triangle, horizonal baseline, pointing up, with top vertex 90 degrees.
     This one is shorter and fatter.  */
    SSYVectorImageStyleTriangle90,
    /* Triangle, horizonal baseline, pointing up, with top vertex 2*arctan(.5)
     = 53.2 degrees.  This one is a taller and thinner than Triangle90. */
    SSYVectorImageStyleTriangle53,
    SSYVectorImageStyleInfoOff,
    SSYVectorImageStyleInfoOn,
    SSYVectorImageStyleHelp,
    SSYVectorImageStyleExclamation,
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
    SSYVectorImageStyleReports,
    /* Circle with a single radial line inside of it, like an old fashioned
     radio knob with a pointer inside of it */
    SSYVectorImageStyleRoundRadioKnob,
    /* Hexagon oriented with a vertex at the top center, vertical side lines */
    SSYVectorImageStyleHexagon
} ;
typedef enum SSYVectorImageStyles_enum SSYVectorImageStyle ;


@interface SSYVectorImages : NSObject {
}

/*
 @param    wength  The width = length of the square image to be returned
 @param    color  The fill and stroke color of the result, and indication of
 whether or not you want a so-called "template image".  If you pass nil, the
 fill and stroke color will be black, and also the result will be a "template
 image".  Otherwise, the result will not be a "template image".  See
 -[NSImage setTemplate:] documentation for more information.
 @param    rotateDegrees  Measure by which the result will be rotated clockwise
 @param    inset  Percent of wength by which to inset the desired shape from the
 given wength on all four edges.  The maximum useful value of inset is 50.0, at
 which the returned image will be empty because if you take 50% from each edge
 you are left with zero.
 
 @details  Known Bug: Not all of the image styles obey the color, rotateDegrees
 and inset parameters.  It's a todo.
 */
+ (NSImage*)imageStyle:(SSYVectorImageStyle)style
                wength:(CGFloat)wength
                 color:(NSColor*)color
         rotateDegrees:(CGFloat)rotateDegrees
                 inset:(CGFloat)inset ;

@end
