#import "SSYVectorImages.h"
#import "NSImage+Transform.h"

@implementation SSYVectorImages

+ (void)glyphOnPath:(NSBezierPath*)path
          character:(UniChar)character
          halfWidth:(CGFloat)halfWidth {
    NSFont* font = [NSFont labelFontOfSize:100] ;
    UniChar characters[1] ;
    characters[0] = character ;
    CGGlyph glyphs[1] ;
    CTFontGetGlyphsForCharacters(
                                 (CTFontRef)font,
                                 characters,
                                 glyphs,
                                 1) ;
    NSRect glyphRect = [font boundingRectForGlyph:glyphs[0]] ;
    CGFloat offsetX = NSMidX(glyphRect) - halfWidth ;
    CGFloat offsetY = NSMidY(glyphRect) - 50 ;
    [path moveToPoint:NSMakePoint(-offsetX,-offsetY)] ;
    [path appendBezierPathWithGlyph:glyphs[0]
                             inFont:font] ;
}

+ (void)drawCharacter:(UniChar)character
                 size:(NSSize)size
                color:(NSColor*)color
                 fill:(BOOL)fill {
    NSBezierPath* bezier = [NSBezierPath bezierPath] ;
    [self glyphOnPath:bezier
            character:character
            halfWidth:size.width/2] ;
    [bezier setLineWidth:2] ;
    [color set] ;
    [bezier stroke] ;
    if (fill) {
        [color setFill] ;
        [bezier fill] ;
    }
}

+ (NSImage*)imageOfCharacter:(UniChar)character
                    fattenBy:(CGFloat)fattenBy
                       color:(NSColor*)color
                        fill:(BOOL)fill {
    NSSize size = NSMakeSize(100/fattenBy, 100) ;
    NSImage* image ;
    image = [NSImage imageWithSize:size
                           flipped:NO
                    drawingHandler:^(NSRect dstRect) {
                        [self drawCharacter:character
                                       size:size
                                      color:color
                                       fill:fill] ;
                        return YES ;
                    }] ;
    
    return image ;
}

+ (void)checkmarkOnPath:(NSBezierPath*)path
                      x:(CGFloat)x {
    [path setLineWidth:8] ;
    [path moveToPoint:NSMakePoint(x,42)] ;
    [path lineToPoint:NSMakePoint(x+17,21)] ;
    [path curveToPoint:NSMakePoint(x+49, 79)
         controlPoint1:NSMakePoint(x+26, 53)
         controlPoint2:NSMakePoint(x+31, 64)] ;
    [[NSColor blackColor] set] ;
    [path stroke] ;
    [path removeAllPoints] ;
}

+ (void)bookmarkOnPath:(NSBezierPath*)path
                  midX:(CGFloat)midX
                 width:(CGFloat)width
                bottom:(CGFloat)bottom
                height:(CGFloat)height
                inseam:(CGFloat)inseam {
    [path moveToPoint:NSMakePoint(midX-(width/2), height + bottom)] ;
    [path lineToPoint:NSMakePoint(midX-(width/2), bottom)] ;
    [path lineToPoint:NSMakePoint(midX, (inseam * height + bottom))] ;
    [path lineToPoint:NSMakePoint(midX+(width/2), bottom)] ;
    [path lineToPoint:NSMakePoint(midX+(width/2), height + bottom)] ;
    [path closePath] ;
}

+ (void)grooveOnPath:(NSBezierPath*)path
                midX:(CGFloat)midX {
#define GROOVE_TOP 100
#define GROOVE_BOTTOM 0
#define GROOVE_WIDTH 8
    NSRect rect ;
    NSBezierPath* aPath ;
    
    rect = NSMakeRect(midX-(GROOVE_WIDTH/2), GROOVE_BOTTOM, GROOVE_WIDTH, GROOVE_TOP - GROOVE_BOTTOM) ;
    aPath = [NSBezierPath bezierPathWithRoundedRect:rect
                                            xRadius:(GROOVE_WIDTH/2)
                                            yRadius:(GROOVE_WIDTH/2)] ;
    [path appendBezierPath:aPath] ;
}

+ (void)handleOnPath:(NSBezierPath*)path
                midX:(CGFloat)midX
                midY:(CGFloat)midY {
#define HANDLE_HEIGHT 10
#define HANDLE_WIDTH 20
    NSRect rect = NSMakeRect(midX-(HANDLE_WIDTH/2), midY - HANDLE_HEIGHT/1, HANDLE_WIDTH, HANDLE_HEIGHT) ;
    [path appendBezierPathWithRect:rect] ;
}

#if 0
/* I was going to use this method but then realized I did not need to, yet.
 This method is based on:
  http://www.spaceroots.org/documents/ellipse/elliptical-arc.pdf >
 secs. 2.2-2.2.1, (pages 4-5)
 and boxed equations at end of sec. 3.4.1 (page 18)

 Like the NSBezierPath `curve` methods, it only produces a counterclockwise
 path, or equivalently, in the context of this paper, lambda1 < lambda2 is
 required.

 In our case, we have a circle so a = b = r and theta = 0. */
+ (void)bezierCubicApproximationForCircularArcWithRadius:(CGFloat)r
                                                  center:(CGPoint)c
                                              startAngle:(CGFloat)lambda1
                                                endAngle:(CGFloat)lambda2
                                           controlPoint1:(CGPoint*)controlPoint1_p
                                           controlPoint2:(CGPoint*)controlPoint2_p
                                                endPoint:(CGPoint*)endPoint_p {
    CGFloat eta1 = atan2(sin(lambda1)/r , cos(lambda1)/r);
    CGFloat eta2 = atan2(sin(lambda2)/r , cos(lambda2)/r);
    CGPoint pointP1 = CGPointMake(c.x + r*cos(eta1), c.y + r*sin(eta1));
    CGPoint pointP2 = CGPointMake(c.x + r*cos(eta2), c.y + r*sin(eta2));
    CGPoint EPrime1 = CGPointMake(-r*sin(eta1), r*cos(eta1));
    CGPoint EPrime2 = CGPointMake(-r*sin(eta2), r*cos(eta2));
    CGFloat alpha = sin(eta2 - eta1) * (sqrt(4 + 3 * pow(tan((eta2-eta1)/2), 2)) - 1.0) / 3.0;
    CGPoint controlPoint1 = CGPointMake(pointP1.x + alpha*EPrime1.x, pointP1.y - alpha*EPrime1.y);
    CGPoint controlPoint2 = CGPointMake(pointP2.x + alpha*EPrime2.x, pointP2.y - alpha*EPrime2.y);

    if(controlPoint1_p) {
        *controlPoint1_p = controlPoint1;
    }
    if(controlPoint2_p) {
        *controlPoint2_p = controlPoint2;
    }
    if (endPoint_p) {
        *endPoint_p = pointP2;
    }
}
#endif

+ (void)drawStyle:(SSYVectorImageStyle)style
           wength:(CGFloat)wength
            color:(NSColor *)color
            inset:(CGFloat)inset {
    NSBezierPath* path = [NSBezierPath bezierPath] ;

    [color setFill] ;
    [color setStroke] ;

    [[NSGraphicsContext currentContext] saveGraphicsState] ;

    /* The idea here is that all images have a normalized size of 100 x 100.
     Makes it easier to mentally write the code.
     Do NOT use radius, wength or inset.
     Instead, use 50, 100 and insetPercent. */

    CGFloat scale = wength / 100.0 ;
    CGFloat insetPercent = inset * 100 / wength ;
    NSAffineTransform* scaleTransform = [NSAffineTransform transform] ;
    [scaleTransform scaleXBy:scale
                         yBy:scale] ;
    
    [scaleTransform concat] ;

    switch (style) {
        case SSYVectorImageStyleChasingArrows:
        case SSYVectorImageStyleChasingArrowsFilled: {
            [path setLineWidth:2.0] ;

            // The outer radius is 50 - insetPercent
#define GAP_DEGREES 15.0
#define ARROW_DEGREES 35.0
#define ARROW_START_DEGREES (GAP_DEGREES + ARROW_DEGREES)
#define ARROW_SHOULDER 12.0
#define INSIDE_RADIUS 38.0
#define OUTER_RADIUS 49.0  // = 50 - line thickness
#define AVERAGE_RADIUS ((OUTER_RADIUS + INSIDE_RADIUS) / 2.0)

            /* This method:
             -[NSBezierPath appendBezierPathWithArcWithCenter:radius:startAngle:endAngle:]
             will only draw in the clockwise direction.  That makes it not
             handy for drawing each half of a chasing arrow which you want to
             be able to separately treat as a closed path so you can fill it
             if the style is SSYVectorImageStyleChasingArrowsFilled.  Think
             about it.  Either the inner arc or the outer arc must be drawn
             clockwise.

             To solve this problem, for each arrow we create in tempPath
             an arc drawn counterclockwise, then reverse it so it is clockwise,
             then append to the main path.

             I was wondering if this would behave, because there might be a
             slight gap, at least theoretically, between the end point of the
             appendee path and the start point of the appended path.  Would
             Cocoa bridge this gap so that the path would fill properly?
             Apparently so, because it fills properly.  But if I invoke
             -closePath, it closes back to the emd point of the appendee which
             draws a line across the figure.  Solution: Just don't invoke
             -closePath. */
             NSBezierPath* tempPath;

            /* Left side arrow */

            // Start at the top left shoulder of the left arrow:
            NSPoint leftStart = NSMakePoint(50.0-(OUTER_RADIUS+ARROW_SHOULDER)*sin(ARROW_START_DEGREES*M_PI/180), 50.0 + (OUTER_RADIUS+ARROW_SHOULDER)*cos(ARROW_START_DEGREES*M_PI/180)) ;
            [path moveToPoint:leftStart] ;
            // to the tip of the arrow
            [path lineToPoint:NSMakePoint(50 - AVERAGE_RADIUS*sin(GAP_DEGREES*M_PI/180.0), 50.0 + AVERAGE_RADIUS*cos(GAP_DEGREES*M_PI/180.0))] ;
            // to the other shoulder
            [path lineToPoint:NSMakePoint(50.0 - (INSIDE_RADIUS-ARROW_SHOULDER)*sin(ARROW_START_DEGREES*M_PI/180), 50.0 + (INSIDE_RADIUS-ARROW_SHOULDER)*cos(ARROW_START_DEGREES*M_PI/180))] ;
            // back in to the inner circle, at the armpit
            [path lineToPoint:NSMakePoint(50.0 - INSIDE_RADIUS*sin(ARROW_START_DEGREES*M_PI/180), 50.0 + INSIDE_RADIUS*cos(ARROW_START_DEGREES*M_PI/180))] ;
            // Inner arc of left arrow
            [path appendBezierPathWithArcWithCenter:NSMakePoint(50.0, 50.0)
                                             radius:(INSIDE_RADIUS)
                                         startAngle:(90.0 + ARROW_START_DEGREES)
                                           endAngle:(270.0 - GAP_DEGREES)] ;
            // across the tail
            NSPoint leftArrowOuterTail = NSMakePoint(50.0 - OUTER_RADIUS*sin(GAP_DEGREES*M_PI/180), 50.0 - OUTER_RADIUS*cos(GAP_DEGREES*M_PI/180));
            NSPoint leftArrowOuterArmpit = NSMakePoint(50.0 - OUTER_RADIUS*sin(ARROW_START_DEGREES*M_PI/180), 50.0 + OUTER_RADIUS*cos(ARROW_START_DEGREES*M_PI/180));
            [path lineToPoint:leftArrowOuterTail] ;
            // Outer arc of left arrow
            tempPath = [NSBezierPath bezierPath];
            [tempPath moveToPoint:leftArrowOuterArmpit];
            [tempPath appendBezierPathWithArcWithCenter:CGPointMake(50.0, 50.0)
                                                 radius:OUTER_RADIUS
                                             startAngle:(90.0 + ARROW_START_DEGREES)
                                               endAngle:(270.0 - GAP_DEGREES)];
            tempPath = [tempPath bezierPathByReversingPath];
            [path appendBezierPath:tempPath];
            [path lineToPoint:leftStart];
            [path stroke];
            if (style == SSYVectorImageStyleChasingArrowsFilled) {
                [path fill];
            }

             /* Right side arrow */

            [path removeAllPoints];

            // Start with lower right shoulder
            NSPoint rightStart = NSMakePoint(50.0+(OUTER_RADIUS+ARROW_SHOULDER)*sin(ARROW_START_DEGREES*M_PI/180), 50.0 - (OUTER_RADIUS+ARROW_SHOULDER)*cos(ARROW_START_DEGREES*M_PI/180)) ;
            [path moveToPoint:rightStart] ;
            // to the tip of the arrow
            [path lineToPoint:NSMakePoint(50 + AVERAGE_RADIUS*sin(GAP_DEGREES*M_PI/180.0), 50.0 - AVERAGE_RADIUS*cos(GAP_DEGREES*M_PI/180.0))] ;
            // to the other shoulder
            [path lineToPoint:NSMakePoint(50.0 + (INSIDE_RADIUS-ARROW_SHOULDER)*sin(ARROW_START_DEGREES*M_PI/180), 50.0 - (INSIDE_RADIUS-ARROW_SHOULDER)*cos(ARROW_START_DEGREES*M_PI/180))] ;
            // back in to the inner circle, at the armpit
            [path lineToPoint:NSMakePoint(50.0 + INSIDE_RADIUS*sin(ARROW_START_DEGREES*M_PI/180), 50.0 - INSIDE_RADIUS*cos(ARROW_START_DEGREES*M_PI/180))] ;
            // Inner arc of right arrow
            [path appendBezierPathWithArcWithCenter:NSMakePoint(50.0, 50.0)
                                             radius:(INSIDE_RADIUS)
                                         startAngle:(270.0 + ARROW_START_DEGREES)
                                           endAngle:(90.0 - GAP_DEGREES)] ;

            // across the tail
            NSPoint rightArrowOuterTail = NSMakePoint(50.0 + OUTER_RADIUS*sin(GAP_DEGREES*M_PI/180), 50.0 + OUTER_RADIUS*cos(GAP_DEGREES*M_PI/180));
            NSPoint rightArrowOuterArmpit = NSMakePoint(50.0 + OUTER_RADIUS*sin(ARROW_START_DEGREES*M_PI/180), 50.0 - OUTER_RADIUS*cos(ARROW_START_DEGREES*M_PI/180));
            [path lineToPoint:rightArrowOuterTail] ;
            // outer arc of right arrow
            tempPath = [NSBezierPath bezierPath];
            [tempPath moveToPoint:rightArrowOuterArmpit];
            [tempPath appendBezierPathWithArcWithCenter:CGPointMake(50.0, 50.0)
                                                 radius:OUTER_RADIUS
                                             startAngle:(270.0 + ARROW_START_DEGREES)
                                               endAngle:(90.0 - GAP_DEGREES )];
            tempPath = [tempPath bezierPathByReversingPath];
            [path appendBezierPath:tempPath];
            [path lineToPoint:rightStart];
            [path stroke];
            if (style == SSYVectorImageStyleChasingArrowsFilled) {
                [path fill];
            }

            break ;
        }
        case SSYVectorImageStyleTarget:
            // The circle
            [path appendBezierPathWithArcWithCenter:NSMakePoint(50.0, 50.0)
                                             radius:(50.0 - insetPercent)
                                         startAngle:0.0
                                           endAngle:359.99] ;
            [path closePath] ;
            // The +45° line
            [path moveToPoint:NSMakePoint(0.0, 0.0)] ;
            [path relativeLineToPoint:NSMakePoint(100.0, 100.0)] ;
            // The vertical line
            [path moveToPoint:NSMakePoint(0.0, 100.0)] ;
            [path relativeLineToPoint:NSMakePoint(100.0, -100.0)] ;
            
            [path stroke] ;
            break ;
        case SSYVectorImageStyleDot:;
            [path appendBezierPathWithArcWithCenter:NSMakePoint(50.0, 50.0)
                                             radius:(50.0 - insetPercent)
                                         startAngle:0.0
                                           endAngle:359.99] ;
            [path closePath] ;
            [path fill] ;
            break ;
        case SSYVectorImageStylePlus:
        case SSYVectorImageStyleMinus:;
            [path setLineWidth:10] ;
            
            // Draw the horizontal line
            [path moveToPoint:NSMakePoint(insetPercent, 50.0)] ;
            [path lineToPoint:NSMakePoint(100.0 - insetPercent, 50.0)] ;
            [path stroke] ;
            
            if (style == SSYVectorImageStylePlus) {
                // Draw the vertical line
                [path moveToPoint:NSMakePoint(50.0, insetPercent)] ;
                [path lineToPoint:NSMakePoint(50.0, 100.0 - insetPercent)] ;
                [path stroke] ;
            }
            break ;
        case SSYVectorImageStyleDash:;
            [path setLineWidth:6] ;
            
            // Draw the horizontal line
            [path moveToPoint:NSMakePoint(25, 50)] ;
            [path lineToPoint:NSMakePoint(75, 50)] ;
            [path stroke] ;
            break ;
        case SSYVectorImageStyleWindowWithSidebar: {
#define SIDEBAR_WIDTH 40.0
#define SIDEBAR_HALF_LINE_WIDTH 4.0

            CGFloat mainWidth = 100.0 - SIDEBAR_WIDTH;
            CGRect mainRect = NSMakeRect(
                                         0.0,
                                         0.0,
                                         mainWidth,
                                         100.0) ;
            [path appendBezierPathWithRect:mainRect] ;
            [path fill];

            [path moveToPoint:NSMakePoint(mainWidth, SIDEBAR_HALF_LINE_WIDTH)];
            [path lineToPoint:NSMakePoint(100.0 - SIDEBAR_HALF_LINE_WIDTH, SIDEBAR_HALF_LINE_WIDTH)];
            [path lineToPoint:NSMakePoint(100.0 - SIDEBAR_HALF_LINE_WIDTH, 100.0 - SIDEBAR_HALF_LINE_WIDTH)];
            [path lineToPoint:NSMakePoint(mainWidth, 100.0 - SIDEBAR_HALF_LINE_WIDTH)];
            [path setLineWidth:SIDEBAR_HALF_LINE_WIDTH * 2.0];
            [path stroke] ;

            break ;
        }
        case SSYVectorImageStyleTriangle90:
        case SSYVectorImageStyleTriangle53: {
            [path setLineWidth:0.0] ;
            
            BOOL taller = (style == SSYVectorImageStyleTriangle53) ;
            
            CGFloat centerToBottom = taller ? 50 : 25 ;
            CGFloat baseline = 50.0 - centerToBottom + insetPercent ;
            CGFloat width = 100.0 - 2.0 * insetPercent ;
            CGFloat height = (taller ? 100.0 : 50.0) - 2.0 * insetPercent ;
            
            // Start at bottom left
            [path moveToPoint:NSMakePoint(insetPercent, baseline)] ;
            
            // Move to the right
            [path relativeLineToPoint:NSMakePoint(width, 0)] ;
            
            // Move back halfway to the left, and up
            [path relativeLineToPoint:NSMakePoint(-(width/2), height)] ;
            
            // Finish
            [path closePath] ;
            [path fill] ;
            break;
        }
        case SSYVectorImageStyleInfoOff:;
        case SSYVectorImageStyleInfoOn: {
            NSImage* glyphImage = [self imageOfCharacter:'i'
                                                fattenBy:1.5
                                                   color:color
                                                    fill:(style == SSYVectorImageStyleInfoOn)] ;
            [glyphImage drawInRect:NSMakeRect(0.0, 0.0, 100.0,100)
                          fromRect:NSZeroRect
                         operation:NSCompositeCopy
                          fraction:1.0] ;
            break ;
        }
        case SSYVectorImageStyleHelp: {
            NSImage* glyphImage = [self imageOfCharacter:'?'
                                                fattenBy:1.3
                                                   color:color
                                                    fill:NO] ;
            [glyphImage drawInRect:NSMakeRect(0,0,100,100)
                          fromRect:NSZeroRect
                         operation:NSCompositeCopy
                          fraction:1.0] ;
            break ;
        }
        case SSYVectorImageStyleExclamation: {
            NSImage* glyphImage = [self imageOfCharacter:'!'
                                                fattenBy:1.3
                                                   color:color
                                                    fill:YES] ;
            NSRect frame = NSInsetRect(NSMakeRect(0,0,100,100), insetPercent, insetPercent) ;
            [glyphImage drawInRect:frame
                          fromRect:NSZeroRect
                         operation:NSCompositeCopy
                          fraction:1.0] ;
            break ;
        }
        case SSYVectorImageStyleStar:; {
            // 5-pointed star.  We draw starting at the top, go counterclockwise
            [path moveToPoint: NSMakePoint(50, 100)];     // top point
            [path lineToPoint: NSMakePoint(37, 58.4)];
            [path lineToPoint: NSMakePoint(0, 58.4)];  // top left point
            [path lineToPoint: NSMakePoint(30, 37)];
            [path lineToPoint: NSMakePoint(19, 0)]; // bottom left point
            [path lineToPoint: NSMakePoint(50.0, 22.2)];
            [path lineToPoint: NSMakePoint(81, 0)]; // bottom right point
            [path lineToPoint: NSMakePoint(70, 37)];
            [path lineToPoint: NSMakePoint(100.0, 58.4)];  // top right point
            [path lineToPoint: NSMakePoint(63.0, 58.4)];
            [path closePath] ;
            [path fill] ;
            break ;
        }
        case SSYVectorImageStyleRemoveX: {
#define X_SIZE .4
            // Draw the circle
            [path appendBezierPathWithArcWithCenter:NSMakePoint(50.0, 50.0)
                                             radius:50.0
                                         startAngle:0.0
                                           endAngle:360.0] ;
            [path closePath] ;
            [path fill] ;
            [path removeAllPoints] ;
            
            // Draw the "X"
            [path setLineWidth:100.0/10] ;
            [[NSColor whiteColor] setStroke] ;
            CGFloat xMargin = (1.0 - X_SIZE) / 2 ;
            CGFloat xMin = 100.0 * xMargin ;
            CGFloat xMax = 100.0 * (1.0 - xMargin) ;
            [path moveToPoint:NSMakePoint(xMin, xMax)] ;
            [path lineToPoint:NSMakePoint(xMax, xMin)] ;
            [path moveToPoint:NSMakePoint(xMin, xMin)] ;
            [path lineToPoint:NSMakePoint(xMax, xMax)] ;
            [path stroke] ;
            break ;
        }
        case SSYVectorImageStyleFlat: {
#define ITEM_SPACING 25
            // Draw the three bullets and lines, indicating three "items"
            [path setLineWidth:10] ;
            NSInteger y ;
            for (y=(50-ITEM_SPACING); y<100; y+=ITEM_SPACING) {
                // Bullet
                [path appendBezierPathWithArcWithCenter:NSMakePoint(15, y)
                                                 radius:7
                                             startAngle:0.0
                                               endAngle:360.0] ;
                [path closePath] ;
                [[NSColor blackColor] setFill] ;
                [path fill] ;
                [path removeAllPoints] ;
                
                // Line
                [[NSColor darkGrayColor] set] ;
                [path moveToPoint:NSMakePoint(30,y)] ;
                [path lineToPoint:NSMakePoint(80, y)] ;
                [path stroke] ;
                [path removeAllPoints] ;
            }
            break ;
        }
        case SSYVectorImageStyleHierarchy:
        case SSYVectorImageStyleLineage: {
#define NUMBER_OF_NODES 3
#define NODE_RADIUS 7
#define NODE_TO_LINE_SPACING (NODE_RADIUS + 5.0)
#define ANCESTRYLINE_WIDTH 2.0
            // Draw the three nodes (little circles)
            [path setLineWidth:ANCESTRYLINE_WIDTH] ;
            NSInteger i ;
            CGFloat xb = 20 ;
            CGFloat yb = 75 ;
            NSPoint nodes[NUMBER_OF_NODES] ;
            for (i=0; i<NUMBER_OF_NODES; i++) {
                // Node (bullet)
                NSPoint point = NSMakePoint(xb, yb) ;
                nodes[i] = point ;
                [path appendBezierPathWithArcWithCenter:point
                                                 radius:NODE_RADIUS
                                             startAngle:0.0
                                               endAngle:360.0] ;
                [path closePath] ;
                [[NSColor blackColor] setFill] ;
                [path fill] ;
                [path removeAllPoints] ;
                
                xb += 28 ;
                yb -= 24 ;
            }
            
            // Draw lines connecting the nodes
            
            [path moveToPoint:NSMakePoint(nodes[0].x + NODE_TO_LINE_SPACING, nodes[0].y)] ;
            [path lineToPoint:NSMakePoint(nodes[1].x + ANCESTRYLINE_WIDTH/2, nodes[0].y)] ;
            [path stroke] ;
            [path removeAllPoints] ;
            
            [path moveToPoint:NSMakePoint(nodes[1].x, nodes[0].y)] ;
            [path lineToPoint:NSMakePoint(nodes[1].x, nodes[1].y + NODE_TO_LINE_SPACING)] ;
            [path stroke] ;
            [path removeAllPoints] ;
            
            [path moveToPoint:NSMakePoint(nodes[1].x + NODE_TO_LINE_SPACING, nodes[1].y)] ;
            [path lineToPoint:NSMakePoint(nodes[2].x+ ANCESTRYLINE_WIDTH/2, nodes[1].y)] ;
            [path stroke] ;
            [path removeAllPoints] ;
            
            [path moveToPoint:NSMakePoint(nodes[2].x, nodes[1].y)] ;
            [path lineToPoint:NSMakePoint(nodes[2].x, nodes[2].y + NODE_TO_LINE_SPACING)] ;
            [path stroke] ;
            [path removeAllPoints] ;
            
            if (style == SSYVectorImageStyleLineage) {
                break ;
            }
            
            // Two more lines needed for SSYVectorImageStyleLineage…
            
            [path moveToPoint:NSMakePoint(nodes[1].x , nodes[1].y - NODE_TO_LINE_SPACING)] ;
            [path lineToPoint:NSMakePoint(nodes[1].x, 0.0)] ;
            [path stroke] ;
            [path removeAllPoints] ;
            
            [path moveToPoint:NSMakePoint(nodes[2].x , nodes[2].y - NODE_TO_LINE_SPACING)] ;
            [path lineToPoint:NSMakePoint(nodes[2].x, 0.0)] ;
            [path stroke] ;
            [path removeAllPoints] ;
            
            break ;
        }
        case SSYVectorImageStyleBookmark: {
            [path setLineWidth:1.0] ;
            
            // Draw the bookmark body
            [self bookmarkOnPath:path
                            midX:50
                           width:50
                          bottom:0
                          height:100
                          inseam:0.35] ;
            
            /* Punch a round hole near the top of the bookmark
             This is done by with a separate bezier path which we first
             *reverse* and then *append* to the bookmark bezier path. */
            NSBezierPath* holePath = [NSBezierPath bezierPath] ;
            [holePath setLineWidth:5.0] ;
#define HOLE_RADIUS 12
            NSRect holeRect = NSMakeRect(
                                         ((50.0) - HOLE_RADIUS),
                                         65,
                                         2*HOLE_RADIUS,
                                         2*HOLE_RADIUS
                                         ) ;
            [holePath appendBezierPathWithOvalInRect:holeRect] ;
            holePath = [holePath bezierPathByReversingPath] ;
            [path appendBezierPath:holePath] ;
            
            
            [path fill] ;
            [path stroke] ;
            
            break ;
        }
        case SSYVectorImageStyleTag: {
#define LINE_WIDTH 7.0
#define TAG_HEIGHT 54
#define TAG_INSET 22
#define TAG_HOLE_RADIUS 4
            CGFloat bottomMargin = (100.0-TAG_HEIGHT)/2 ;
            [path setLineWidth:4.0] ;
            [path moveToPoint:NSMakePoint(0, 50)] ;
            [path lineToPoint:NSMakePoint(TAG_INSET, bottomMargin)] ;
            [path lineToPoint:NSMakePoint(100, bottomMargin)] ;
            [path lineToPoint:NSMakePoint(100, 100 - bottomMargin)] ;
            [path lineToPoint:NSMakePoint(TAG_INSET, 100 - bottomMargin)] ;
            [path closePath] ;
            [path appendBezierPathWithArcWithCenter:NSMakePoint(TAG_INSET, 50)
                                             radius:TAG_HOLE_RADIUS
                                         startAngle:0.0
                                           endAngle:360.0] ;
            [[NSColor blackColor] set] ;
            [path stroke] ;
            
            break ;
        }
        case SSYVectorImageStyleCheck1:;
            [self checkmarkOnPath:path
                                x:25] ;
            break ;
        case SSYVectorImageStyleCheck2:;
            [self checkmarkOnPath:path
                                x:10] ;
            [self checkmarkOnPath:path
                                x:45] ;
            break ;
        case SSYVectorImageStyleBookmarksInFolder:;
#define BOX_MARGIN 1.5
#define BOX_WIDTH (100 - 2.0*BOX_MARGIN)
#define BOX_HEIGHT 100
#define BOOKMARK_WIDTH 25
#define COUNT_OF_BOOKMARKS 2
#define BOX_AIR_WIDTH (BOX_WIDTH - COUNT_OF_BOOKMARKS * BOOKMARK_WIDTH)
#define BOOKMARK_SPACING BOX_AIR_WIDTH/(COUNT_OF_BOOKMARKS + 1)
#define BOOKMARK_TOP_MARGIN 15.0
#define BOOKMARK_BOTTOM_MARGIN 10.0
#define BOOKMARK_PITCH (BOOKMARK_SPACING + BOOKMARK_WIDTH)
#define LITTLE_HOLE_RADIUS 4.0
            [path moveToPoint:NSMakePoint(BOX_MARGIN, BOX_MARGIN + BOX_HEIGHT)] ;
            [path lineToPoint:NSMakePoint(BOX_MARGIN, BOX_MARGIN)] ;
            [path lineToPoint:NSMakePoint(100 - BOX_MARGIN, BOX_MARGIN)] ;
            [path lineToPoint:NSMakePoint(100 - BOX_MARGIN, BOX_MARGIN + BOX_HEIGHT)] ;
            [[NSColor blackColor] set] ;
            [path setLineWidth:3.0] ;
            [path stroke] ;
            [path removeAllPoints] ;
            
            CGFloat xbb = BOX_MARGIN + BOOKMARK_SPACING + BOOKMARK_WIDTH/2.0 ;
            for (NSInteger i=0; i<COUNT_OF_BOOKMARKS; i++) {
                CGFloat bottom = (BOX_MARGIN + BOOKMARK_BOTTOM_MARGIN) ;
                CGFloat height = (BOX_HEIGHT - BOX_MARGIN - BOOKMARK_TOP_MARGIN - BOOKMARK_BOTTOM_MARGIN) ;
                [self bookmarkOnPath:path
                                midX:xbb
                               width:BOOKMARK_WIDTH
                              bottom:bottom
                              height:height
                              inseam:0.35] ;
                [path setLineWidth:2.0] ;
                [path stroke] ;
                [path removeAllPoints] ;
                
                NSPoint holeCenter = NSMakePoint(xbb, bottom + 0.75 * height) ;
                NSPoint holeEdge = NSMakePoint(xbb + LITTLE_HOLE_RADIUS, holeCenter.y) ;
                [path moveToPoint:holeEdge] ;
                [path appendBezierPathWithArcWithCenter:holeCenter
                                                 radius:LITTLE_HOLE_RADIUS
                                             startAngle:0.0
                                               endAngle:360.0] ;
                [path setLineWidth:2.0] ;
                [path stroke] ;
                [path removeAllPoints] ;
                
                xbb += BOOKMARK_PITCH ;
            }
            
            [path stroke] ;
            
            break ;
        case SSYVectorImageStyleSettings:;
#define COUNT_OF_SLIDERS 3
#define SLIDER_PITCH (100.0/COUNT_OF_SLIDERS)
            CGFloat handlePositions[COUNT_OF_SLIDERS] ;
            handlePositions[0] = 70 ;
            handlePositions[1] = 25 ;
            handlePositions[2] = 55 ;
            CGFloat xs = SLIDER_PITCH/2 ;
            for (NSInteger i=0; i<COUNT_OF_SLIDERS; i++) {
                [self grooveOnPath:path
                              midX:xs] ;
                [path setLineWidth:2.0] ;
                [path stroke] ;
                [path removeAllPoints] ;
                
                [self handleOnPath:path
                              midX:xs
                              midY:handlePositions[i]] ;
                
                xs += SLIDER_PITCH ;
            }
            
            [path stroke] ;
            break ;
        case SSYVectorImageStyleReports:;
#define TITLE_HEIGHT 15
#define TITLE_WIDTH 80
#define TITLE_EXTRA_VERTICAL_MARGIN 10
#define REPORT_ITEM_HEIGHT 6.0
#define COUNT_OF_REPORT_ITEMS 5
#define LINE_PITCH ((100 - TITLE_HEIGHT - TITLE_EXTRA_VERTICAL_MARGIN)/COUNT_OF_REPORT_ITEMS)
            NSRect rect ;
            rect = NSMakeRect(
                              (100 - TITLE_WIDTH)/2,
                              100 - TITLE_HEIGHT,
                              TITLE_WIDTH,
                              TITLE_HEIGHT) ;
            [path appendBezierPathWithRect:rect] ;
            
            for (NSInteger i=0; i<COUNT_OF_REPORT_ITEMS; i++) {
                rect = NSMakeRect(0, i*LINE_PITCH, 100, REPORT_ITEM_HEIGHT) ;
                [path appendBezierPathWithRect:rect] ;
            }
            
            [[NSColor blackColor] set] ;
            [path setLineWidth:2] ;
            [path stroke] ;
            break ;
        case SSYVectorImageStyleRoundRadioKnob:;
#define KNOB_MARGIN 12.5
            [path setLineWidth:2.0] ;
            [path appendBezierPathWithArcWithCenter:NSMakePoint(50.0,50.0)
                                             radius:(50.0 - [path lineWidth] - KNOB_MARGIN)
                                         startAngle:0.0 endAngle:360.0] ;
            [path moveToPoint:NSMakePoint(50.0, 50.0)] ;
            [path relativeLineToPoint:NSMakePoint(0.0, 50.0 - [path lineWidth] - KNOB_MARGIN)] ;
            [path stroke] ;
            break ;
        case SSYVectorImageStyleHexagon:;
            NSRect frame = NSInsetRect(NSMakeRect(0.0, 0.0, 100.0, 100.0), insetPercent, insetPercent) ;
            CGFloat insize = 100 - 2*insetPercent ;
            /* The vertexInset scalar used here, (2/3 - sqrt(7)/6) = .22570811,
             gives "half regular, by length, square-filling" hexagon as
             explained in the header documentation.

             Alternatively, you might use a vertexInset scalar of 0.25 which
             results in a "half regular, by angle, square-filling" hexagon.
             In this case, the interior angles would all be 120 degrees, but
             the two vertical sides would be only 2/5 the length of the four
             nonvertical sides.

             Actually, the vertexInset scalar can be any value from 0 to 0.5.

             If 0, the vertical sides lengths become 0, the top interior angle
             becomes 180 degrees so that the vertex disappears, and the sides
             lines nearest the top become one, and similarly at the bottom, so
             that the hexagon degenerates to a square with sides on the x and
             y axes.

             If 0.5, the two vertical sides' lengths go to 0, the four left
             side vertices combine into one, and similarly on the right side,
             so that the hexagon degenerates to a square oriented as a
             diamond shape. */
            CGFloat vertexInset = insize * .2257081148;
            
            NSPoint A = NSMakePoint(frame.origin.x + insize / 2, frame.origin.y + frame.size.height);
            NSPoint B = NSMakePoint(frame.origin.x + insize, frame.origin.y + frame.size.height - vertexInset);
            NSPoint C = NSMakePoint(frame.origin.x + insize, frame.origin.y + vertexInset);
            NSPoint D = NSMakePoint(frame.origin.x + insize / 2, frame.origin.y);
            NSPoint E = NSMakePoint(frame.origin.x, frame.origin.y + vertexInset);
            NSPoint F = NSMakePoint(frame.origin.x, frame.origin.y + frame.size.height - vertexInset);
            
            [path moveToPoint:A] ;
            [path lineToPoint:B] ;
            [path lineToPoint:C] ;
            [path lineToPoint:D] ;
            [path lineToPoint:E] ;
            [path lineToPoint:F] ;
            [path closePath] ;
            
            [path fill] ;
            [path stroke] ;
            break ;
    }
    
    [[NSGraphicsContext currentContext] restoreGraphicsState] ;
}

+ (NSImage*)imageStyle:(SSYVectorImageStyle)style
                wength:(CGFloat)wength
                 color:(NSColor*)color
          darkModeView:(NSView*)darkModeView
         rotateDegrees:(CGFloat)rotateDegrees
                 inset:(CGFloat)inset {
    NSSize size = NSMakeSize(wength, wength) ;
    NSImage* image ;
    NSImage* rotatedImage ;
    
    image = [NSImage imageWithSize:size
                           flipped:NO
                    drawingHandler:^(NSRect dstRect) {
                        NSColor* colorNow = color;
                        if (!colorNow) {
                            BOOL darkMode = NO;
                            if (@available(macOS 10.14, *)) {
                                NSAppearanceName basicAppearance = [darkModeView.effectiveAppearance bestMatchFromAppearancesWithNames:@[
                                                                                                                                         NSAppearanceNameAqua,
                                                                                                                                         NSAppearanceNameDarkAqua
                                                                                                                                         ]];
                                darkMode = [basicAppearance isEqualToString:NSAppearanceNameDarkAqua];
                            }

                            colorNow = darkMode ? [NSColor whiteColor] : [NSColor blackColor];
                        }

                        [self drawStyle:style
                                 wength:wength
                                  color:colorNow
                                  inset:(CGFloat)inset] ;
                        return YES ;
                    }] ;

    rotatedImage = [image imageRotatedByDegrees:rotateDegrees] ;
    
    if (color == nil) {
        [rotatedImage setTemplate:YES] ;
    }

    NSString* name;
    switch (style) {

        case SSYVectorImageStylePlus:
            name = @"Plus";
            break;
        case SSYVectorImageStyleMinus:
            name = @"Minus";
            break;
        case SSYVectorImageStyleDash:
            name = @"Dash";
            break;
        case SSYVectorImageStyleDot:
            name = @"Dot";
            break;
        case SSYVectorImageStyleTarget:
            name = @"Target";
            break;
        case SSYVectorImageStyleChasingArrows:
            name = @"ChasingArrows";
            break;
        case SSYVectorImageStyleChasingArrowsFilled:
            name = @"ChasingArrowsFilled";
            break;
        case SSYVectorImageStyleWindowWithSidebar:
            name = @"WindowWithSidebarr";
            break;
        case SSYVectorImageStyleTriangle90:
            name = @"Triangle90";
            break;
        case SSYVectorImageStyleTriangle53:
            name = @"Triangle53";
            break;
        case SSYVectorImageStyleInfoOff:
            name = @"InfoOff";
            break;
        case SSYVectorImageStyleInfoOn:
            name = @"InfoOn";
            break;
        case SSYVectorImageStyleHelp:
            name = @"Help";
            break;
        case SSYVectorImageStyleExclamation:
            name = @"Exclamation";
            break;
        case SSYVectorImageStyleStar:
            name = @"Star";
            break;
        case SSYVectorImageStyleRemoveX:
            name = @"RemoveX";
            break;
        case SSYVectorImageStyleBookmark:
            name = @"Bookmark";
            break;
        case SSYVectorImageStyleHierarchy:
            name = @"Bookmark";
            break;
        case SSYVectorImageStyleFlat:
            name = @"Flat";
            break;
        case SSYVectorImageStyleLineage:
            name = @"Lineage";
            break;
        case SSYVectorImageStyleTag:
            name = @"Tag";
            break;
        case SSYVectorImageStyleCheck1:
            name = @"Check1";
            break;
        case SSYVectorImageStyleCheck2:
            name = @"Check2";
            break;
        case SSYVectorImageStyleBookmarksInFolder:
            name = @"Folder";
            break;
        case SSYVectorImageStyleSettings:
            name = @"Settings";
            break;
        case SSYVectorImageStyleReports:
            name = @"Reports";
            break;
        case SSYVectorImageStyleRoundRadioKnob:
            name = @"RoundRadioKnow";
            break;
        case SSYVectorImageStyleHexagon:
            name = @"Hexagon";
            break;
    }
    rotatedImage.name = name;
    image.name = name;
    
    return rotatedImage ;
}


@end

#if 0
/* The following code, which shows how to draw a fancy tag that is filled except
 for an unfilled hole, and rotated 30 degrees, is no longer used, but I'm
 keeping it as sample code in case the fashion designers at Apple someday
 decide that flat is out and fancy is in.
 */
#define LINE_WIDTH 3.0
#define LEFT_MARGIN 9
#define TAG_WIDTH 67
#define TAG_HEIGHT 42
#define HOLE_FOR_STRING_RADIUS 6
#define HOLE_OFFSET 5
#define STRING_INSET 2
#define TAG_ROTATION 30
CGFloat bottomMargin = (100.0-TAG_HEIGHT)/2 ;
NSRect tagRect = NSMakeRect(LEFT_MARGIN, bottomMargin, TAG_WIDTH, TAG_HEIGHT) ;

path = [NSBezierPath bezierPathWithRect:tagRect] ;

[path setLineWidth:LINE_WIDTH] ;

/* Punch a round hole near the left side of the tag body
 This is done by with a separate bezier path which we first
 *reverse* and then *append* to the bookmark bezier path. */
NSBezierPath* stringHolePath = [NSBezierPath bezierPath] ;
NSRect stringHoleRect = NSMakeRect(
                                   (LEFT_MARGIN + HOLE_OFFSET),
                                   (50.0 - HOLE_FOR_STRING_RADIUS),
                                   2*HOLE_FOR_STRING_RADIUS,
                                   2*HOLE_FOR_STRING_RADIUS
                                   ) ;
[stringHolePath appendBezierPathWithOvalInRect:stringHoleRect] ;
stringHolePath = [stringHolePath bezierPathByReversingPath] ;
[path appendBezierPath:stringHolePath] ;

NSBezierPath* stringPath = [NSBezierPath bezierPath] ;
NSPoint stringStart = NSMakePoint(LEFT_MARGIN + HOLE_OFFSET + STRING_INSET, (50.0)) ;
[stringPath moveToPoint:stringStart] ;
[stringPath relativeCurveToPoint:NSMakePoint(-30, -30)
                   controlPoint1:NSMakePoint(-15, 5)
                   controlPoint2:NSMakePoint(-25,-15)] ;
[stringPath setLineWidth:LINE_WIDTH] ;
[stringPath setLineCapStyle:NSRoundLineCapStyle] ;

// Now move the origin to the center of the eye and rotate it
NSAffineTransform* centerRotateTransform = [NSAffineTransform transform] ;
[centerRotateTransform translateXBy:(50.0)
                                yBy:(50.0)];
[centerRotateTransform rotateByDegrees:TAG_ROTATION];
[centerRotateTransform translateXBy:-(50.0)
                                yBy:-(50.0)];
[centerRotateTransform translateXBy:7
                                yBy:0];
[centerRotateTransform concat];

[[NSColor whiteColor] set] ;
[path fill] ;

[[NSColor blackColor] set] ;
[path stroke] ;

[[NSColor blackColor] set] ;
[stringPath stroke] ;

// Clean up the coordinate system - although not technically necessary because we're all done
[centerRotateTransform invert] ;
[centerRotateTransform concat] ;

#endif
