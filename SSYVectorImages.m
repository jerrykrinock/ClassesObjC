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
        case SSYVectorImageStyleChasingArrows: {
            [path setLineWidth:2.0] ;
            
            // The outer radius is 50 - insetPercent
#define GAP_DEGREES 15.0
#define ARROW_DEGREES 35.0
#define ARROW_START_DEGREES (GAP_DEGREES + ARROW_DEGREES)
#define ARROW_SHOULDER 12.0
#define INSIDE_RADIUS 38.0
#define OUTER_RADIUS 49.0  // = 50 - line thickness
#define AVERAGE_RADIUS ((OUTER_RADIUS + INSIDE_RADIUS) / 2.0)
            
            /* In the following code, the reason why we jump around is because
             the NSBezierPath method -appendBezierPathWithArcWithCenter::::
             seems to only go counterclockwise. */
            
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
            [path lineToPoint:NSMakePoint(50.0 - OUTER_RADIUS*sin(GAP_DEGREES*M_PI/180), 50.0 - OUTER_RADIUS*cos(GAP_DEGREES*M_PI/180))] ;
            
            // Now jump across the bottom to the right arrow and do the lower right shoulder
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
            [path lineToPoint:NSMakePoint(50.0 + OUTER_RADIUS*sin(GAP_DEGREES*M_PI/180), 50.0 + OUTER_RADIUS*cos(GAP_DEGREES*M_PI/180))] ;
            
            // Now jump across the top to the left arrow and complete it.
            [path moveToPoint:leftStart] ;
            // In to the armpit
            [path lineToPoint:NSMakePoint(50.0 - OUTER_RADIUS*sin(ARROW_START_DEGREES*M_PI/180), 50.0 + OUTER_RADIUS*cos(ARROW_START_DEGREES*M_PI/180))] ;
            // Outer arc of left arrow
            [path appendBezierPathWithArcWithCenter:NSMakePoint(50.0, 50.0)
                                             radius:(OUTER_RADIUS)
                                         startAngle:(90.0 + ARROW_START_DEGREES)
                                           endAngle:(270.0 - GAP_DEGREES)] ;
            
            // Now jump across the bottom to the right arrow and complete it.
            [path moveToPoint:rightStart] ;
            // In to the armpit
            [path lineToPoint:NSMakePoint(50.0 + OUTER_RADIUS*sin(ARROW_START_DEGREES*M_PI/180), 50.0 - OUTER_RADIUS*cos(ARROW_START_DEGREES*M_PI/180))] ;
            // Outer arc of right arrow
            [path appendBezierPathWithArcWithCenter:NSMakePoint(50.0, 50.0)
                                             radius:(OUTER_RADIUS)
                                         startAngle:(270.0 + ARROW_START_DEGREES)
                                           endAngle:(90.0 - GAP_DEGREES)] ;
            
            [path stroke] ;
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
            
            // We also use textDrawingLineWidth as a margin
            CGFloat halfX = 50.0 ;
            CGFloat halfY = 46.875 ;
            
            // Draw the horizontal line
            [path moveToPoint:NSMakePoint(12.5, halfY)] ;
            [path lineToPoint:NSMakePoint(87.5, halfY)] ;
            [path stroke] ;
            
            if (style == SSYVectorImageStylePlus) {
                // Draw the vertical line
                [path moveToPoint:NSMakePoint(halfX, 6.25)] ;
                [path lineToPoint:NSMakePoint(halfX, 87.5)] ;
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
            [glyphImage drawInRect:NSMakeRect(0,0,100,100)
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
            [glyphImage drawInRect:NSMakeRect(0,0,100,100)
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
             *reverse* and then *append* to the bookmark bezier path.
             (Prior to BookMacster  1.20.1, this was a solid white cirle.) */
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
            NSRect wholeFrame = NSMakeRect(0.0, 0.0, wength, wength) ;
            NSRect frame = NSInsetRect(wholeFrame, insetPercent, insetPercent) ;
            CGFloat insize = wength - 2*insetPercent ;
            
            NSPoint A = NSMakePoint(frame.origin.x + insize / 2, frame.origin.y + frame.size.height);
            NSPoint B = NSMakePoint(frame.origin.x + insize, frame.origin.y + frame.size.height - insize / 4);
            NSPoint C = NSMakePoint(frame.origin.x + insize, frame.origin.y + insize / 4);
            NSPoint D = NSMakePoint(frame.origin.x + insize / 2, frame.origin.y);
            NSPoint E = NSMakePoint(frame.origin.x, frame.origin.y + insize / 4);
            NSPoint F = NSMakePoint(frame.origin.x, frame.origin.y + frame.size.height - insize / 4);
            
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
         rotateDegrees:(CGFloat)rotateDegrees
                 inset:(CGFloat)inset {
    NSSize size = NSMakeSize(wength, wength) ;
    NSImage* image ;
    NSImage* rotatedImage ;
    
    // We must be in macOS 10.8 or later
    image = [NSImage imageWithSize:size
                           flipped:NO
                    drawingHandler:^(NSRect dstRect) {
                        [self drawStyle:style
                                 wength:wength
                                  color:(color ? color : [NSColor blackColor])
                                  inset:(CGFloat)inset] ;
                        return YES ;
                    }] ;
    rotatedImage = [image imageRotatedByDegrees:rotateDegrees] ;
    
    if (color == nil) {
        [rotatedImage setTemplate:YES] ;
    }
    
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
