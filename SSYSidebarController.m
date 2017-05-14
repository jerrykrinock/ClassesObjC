#import "SSYSidebarController.h"

enum SSYSidebarControllerExpansionDirection_enum {
    SSYSidebarControllerExpandsHorizontally,
    SSYSidebarControllerExpandsVertically
};
typedef enum SSYSidebarControllerExpansionDirection_enum SSYSidebarControllerExpansionDirection;

@interface SSYSidebarController()

@property (assign) BOOL isSidebarShowing;
@property (assign) CGFloat sidebarLength;
@property (assign) CGFloat lengthBorrowedFromMainView;

@end


@implementation SSYSidebarController

- (instancetype)initWithMainView:(NSView*)mainView
                     sidebarView:(NSView*)sidebarView
                       whichEdge:(SSYSidebarControllerWhichEdge)whichEdge {
    self = [super init];

    if (self) {
        self.mainView = mainView;
        self.sidebarView = sidebarView;
        self.whichEdge = whichEdge;
    }

    return self ;
}

- (void)awakeFromNib {
    /* Grab the original length of the sidebar for future reference */
    self.sidebarLength = [self lengthOfFrame:self.sidebarView.frame];

    /* Initially, we want the sidebar to be collapsed, and the main view to
     be its orignal (current) length. */
    [self regardlesslyExpandSidebar:NO
                    mainViewMinimum:[self lengthOfFrame:self.mainView.frame]
                            animate:NO];
}

- (BOOL)mainIsAtZeroPosition {
    BOOL answer = NO;
    switch (self.whichEdge) {
        case SSYSidebarControllerWhichEdgeRight:
        case SSYSidebarControllerWhichEdgeTop:
            answer = YES;
            break;
        case SSYSidebarControllerWhichEdgeLeft:
        case SSYSidebarControllerWhichEdgeBottom:
            answer = NO;
            break;
    }

    return answer;
}

- (SSYSidebarControllerExpansionDirection)direction {
    if (
        (self.whichEdge == SSYSidebarControllerWhichEdgeLeft)
        || (self.whichEdge == SSYSidebarControllerWhichEdgeRight)) {
        return SSYSidebarControllerExpandsHorizontally;
    }
    else {
        return SSYSidebarControllerExpandsVertically;
    }
}

- (CGFloat)lengthOfFrame:(NSRect)frame {
    if ([self direction] == SSYSidebarControllerExpandsHorizontally) {
        return frame.size.width;
    } else {
        return frame.size.height;
    }
}

- (CGFloat)positionOfFrame:(NSRect)frame {
    if ([self direction] == SSYSidebarControllerExpandsHorizontally) {
        return frame.origin.x;
    } else {
        return frame.origin.y;
    }
}

- (void)addLength:(CGFloat)length
          toFrame:(NSRect*)frame_p {
    if ([self direction] == SSYSidebarControllerExpandsHorizontally) {
        (*frame_p).size.width += length;
    } else {
        (*frame_p).size.height += length;
    }
}

- (void)addPosition:(CGFloat)position
            toFrame:(NSRect*)frame_p {
    if ([self direction] == SSYSidebarControllerExpandsHorizontally) {
        (*frame_p).origin.x += position;
    } else {
        (*frame_p).origin.y += position;
    }
}

- (void)setLength:(CGFloat)length
          ofFrame:(NSRect*)frame_p {
    if ([self direction] == SSYSidebarControllerExpandsHorizontally) {
        (*frame_p).size.width = length;
    } else {
        (*frame_p).size.height = length;
    }
}

- (void)setPosition:(CGFloat)position
            ofFrame:(NSRect*)frame_p {
    if ([self direction] == SSYSidebarControllerExpandsHorizontally) {
        (*frame_p).origin.x = position;
    } else {
        (*frame_p).origin.y = position;
    }
}

- (void)expandSidebar:(BOOL)expand
      mainViewMinimum:(CGFloat)mainViewMinimum
              animate:(BOOL)animate {
    if (self.isSidebarShowing == expand) {
        /* Sidebar is already expanded/collapsed as desired. */
        return;
    }
    self.isSidebarShowing = expand;

    [self regardlesslyExpandSidebar:expand
                    mainViewMinimum:mainViewMinimum
                            animate:animate];
}

- (void)regardlesslyExpandSidebar:(BOOL)expand
                  mainViewMinimum:(CGFloat)mainViewMinimum
                          animate:(BOOL)animate {
    /* This method contains dual-purpose generalized code:
     • We use 'length' to mean either 'height' or 'width'
     • We use 'position' to mean either 'x' or 'y'
     where the "either" choice depends on whether we are expanding and
     collapsing horizontally or vertically, which in turn depends on the
     property `whichEdge`. */

    NSRect windowFrame = self.mainView.window.frame;
    NSRect windowContentFrame = self.mainView.window.contentView.frame;
    CGFloat delta;
    if (expand) {
        if (animate) {
            self.sidebarView.animator.hidden = NO;
        }
        else {
            self.sidebarView.hidden = NO;
        }
        CGFloat availableLengthFromMainView ;
        availableLengthFromMainView = [self lengthOfFrame:windowContentFrame] - mainViewMinimum;

        delta = self.sidebarLength - availableLengthFromMainView;
        if (delta > 0.0) {
            [self addLength:delta
                    toFrame:&windowFrame];
            [self addLength:delta
                    toFrame:&windowContentFrame];

            NSRect useableFrame = self.mainView.window.screen.visibleFrame ;
            // That useableFrame does not include main menu bar or Dock.
            CGFloat screenLength = [self lengthOfFrame:useableFrame] ;
            CGFloat overflowLength;
            if ([self mainIsAtZeroPosition]) {
                overflowLength = [self positionOfFrame:windowFrame] + [self lengthOfFrame:windowFrame] - screenLength;
                if (overflowLength > 0.0) {
                    [self addPosition:-overflowLength
                              toFrame:&windowFrame];
                }
            } else {
                overflowLength = -([self positionOfFrame:windowFrame] - delta);
                if (overflowLength > 0.0) {
                    [self addPosition:overflowLength
                              toFrame:&windowFrame];
                }
            }
        }

        self.lengthBorrowedFromMainView = availableLengthFromMainView;

        if (![self mainIsAtZeroPosition]) {
            [self addPosition:-delta
                      toFrame:&windowFrame];
        }
    } else {
        if (animate) {
            self.sidebarView.animator.hidden = YES;
        }
        else {
            self.sidebarView.hidden = YES;
        }
       delta = self.sidebarLength - self.lengthBorrowedFromMainView;
        [self addLength:-delta
                toFrame:&windowFrame];
        [self addLength:-delta
                toFrame:&windowContentFrame];
        if (![self mainIsAtZeroPosition]) {
            [self addPosition:delta
                      toFrame:&windowFrame];
        }
    }

    [self.mainView.window setFrame:windowFrame
                           display:YES
                           animate:YES];

    NSRect mainFrame = self.mainView.frame;
    NSRect sidebarFrame = self.sidebarView.frame;

    [self setLength:(expand ? self.sidebarLength : 0.0)
            ofFrame:&sidebarFrame];

    CGFloat newLengthOfMainFrame = [self lengthOfFrame:windowContentFrame] - [self lengthOfFrame:sidebarFrame];
    CGFloat newLengthOfSidebarFrame = (expand ? self.sidebarLength : 0.0);

    [self setLength:newLengthOfMainFrame
            ofFrame:&mainFrame];
    [self setLength:newLengthOfSidebarFrame
            ofFrame:&sidebarFrame];

    if ([self mainIsAtZeroPosition]) {
        [self setPosition:0.0
                  ofFrame:&mainFrame];
        [self setPosition:newLengthOfMainFrame
                  ofFrame:&sidebarFrame];
    } else {
        [self setPosition:0.0
                  ofFrame:&sidebarFrame];
        [self setPosition:newLengthOfSidebarFrame
                  ofFrame:&mainFrame];
    }


    if (animate) {
        NSView* mainAnimator = [self.mainView animator];
        NSView* sidebarAnimator = [self.sidebarView animator];
        [mainAnimator setFrame:mainFrame];
        [sidebarAnimator setFrame:sidebarFrame];
    } else {
        [self.mainView setFrame:mainFrame];
        [self.sidebarView setFrame:sidebarFrame];
    }

    [self.mainView setNeedsDisplay: YES];
    [self.sidebarView setNeedsDisplay:YES];
}


@end
