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
    SSYVectorImageStyleChasingArrowsFilled,
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
    SSYVectorImageStyleBookmarksInBox,
    SSYVectorImageStyleBookmarksNoBox,
    SSYVectorImageStyleSettings,
    SSYVectorImageStyleReports,
    /* Circle with a single radial line inside of it, like an old fashioned
     radio knob with a pointer inside of it */
    SSYVectorImageStyleRoundRadioKnob,
    /* A "half regular, by length, square-filling" hexagon, oriented with one
     vertex at the top center of the square frame, one vertex at the bottom
     center of the square frame, two vertices on each side of the square frame.
     I called it "half regular, by length" because it fulfills one of the two
     requirements of a regular hexagon, namely that the side lengths are
     equal, but it does not fulfill the other requirement that all interior
     angles be equal to 120 degrees.  The two interior angles at the top and
     bottom are 131.41 degrees, while the four interior angles along the sides
     are 114.30 degrees.

     Note that when a regular hexagon (all sides of equal length and all
     interior angles equal to 120 degrees) of this orientation is inscribed in
     a square, the two two vertical lines are inset from the sides of the
     square, leaving empty space on either side.  Such a regular hexagon is
     taller than it is wide. */
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
 @param    darkModeView: If not nil, and if color is nil, and if the effective
 appearance of darkModeView better matches NSAppearanceNameDarkAqua than
 NSAppearanceNameAqua at time of drawing, the strokes and fill of the returned
 template image will be white rather than black.  Use this if the returned
 image will draw itself to the screen in a custom view or control.  Do not use
 this if the returned image will be passed in as the image to a NSButton or
 other Cocoa control because Cocoa will do the luminance inversion based on
 opacity.
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
          darkModeView:(NSView*)darkModeView
         rotateDegrees:(CGFloat)rotateDegrees
                 inset:(CGFloat)inset ;

@end
