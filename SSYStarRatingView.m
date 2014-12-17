//
//  SSYStarRatingViewView.
//
//  Created by Ernesto Garcia on 26/02/12.
//  Copyright (c) 2012 cocoawithchurros.com All rights reserved.
//  Distributed under MIT license

#import "SSYStarRatingView.h"
#import "SSYVectorImages.h"
#import "NSObject+SSYBindingsHelp.h"

#define SSY_STAR_RATING_VIEW_DEFAULT_HALFSTAR_THRESHOLD   0.6

NSString* const constKeyRating = @"rating" ;


@implementation SSYStarRatingView
@synthesize starImage = m_starImage;
@synthesize removeXImage = m_removeXImage ;
@synthesize starHighlightedImage = m_starHighlightedImage ;
@synthesize rating = m_rating;
@synthesize maxRating = m_maxRating ;
@synthesize backgroundColor = m_backgroundColor;
@synthesize editable = m_editable ;
@synthesize delegate = m_delegate ;
@synthesize horizontalMargin = m_horizontalMargin;
//@synthesize drawHalfStars;
@synthesize halfStarThreshold = m_halfStarThreshold ;
@synthesize displayMode = m_displayMode ;

+ (void)initialize {
	[self exposeBinding:constKeyRating] ;
}

#pragma mark -
#pragma mark Init & dealloc
- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		CGFloat starHeight = frame.size.height ;
        [self setMaxRating:5.0] ;
        [self setHorizontalMargin:0.0] ;
        [self setDisplayMode:SSYStarRatingViewDisplayFull] ;
        [self setHalfStarThreshold:SSY_STAR_RATING_VIEW_DEFAULT_HALFSTAR_THRESHOLD] ;
		[self setStarImage:[SSYVectorImages imageStyle:SSYVectorImageStyleStar
											    length:starHeight
												 color:[NSColor lightGrayColor]
										 rotateDegrees:0.0]] ;
		[self setStarHighlightedImage:[SSYVectorImages imageStyle:SSYVectorImageStyleStar
														   length:starHeight
															color:[NSColor blueColor]
													rotateDegrees:0.0]] ;
		[self setRemoveXImage:[SSYVectorImages imageStyle:SSYVectorImageStyleRemoveX
												   length:(0.9 * starHeight)
													color:nil
											rotateDegrees:0.0]] ;
		[self setEditable:YES] ;
    }
    
    return self;
}

#if (__ppc__)
#define NO_ARC 1
#else
#if MAC_OS_X_VERSION_MAX_ALLOWED < 1060
#define NO_ARC 1
#else
#if __has_feature(objc_arc)
#define NO_ARC 0
#else
#define NO_ARC 1
#endif
#endif
#endif

#if NO_ARC
-(void)dealloc
{
    [m_starImage release] ;
    [m_starHighlightedImage release] ;
    [m_removeXImage release] ;
    [m_backgroundColor release] ;
    
	[super dealloc] ;
}
#endif

#pragma mark -

#pragma mark Setters
-(void)setRating:(NSNumber*)rating
{
    [m_rating release] ;
	m_rating = rating ;
	[m_rating retain] ;

	[self setNeedsDisplay];
}

- (NSNumber*)rating {
	return [[m_rating copy] autorelease] ;
}

-(void)setDisplayMode:(SSYStarRatingViewDisplayMode)dispMode
{
    m_displayMode = dispMode ;
    [self setNeedsDisplay];
}

#pragma mark -
#pragma mark Drawing
-(NSPoint)pointOfStarAtPosition:(NSInteger)position highlighted:(BOOL)hightlighted
{
    NSSize size = hightlighted ? [self starHighlightedImage].size : [self starImage].size;
    
    NSInteger starsSpace = self.bounds.size.width - 2*[self horizontalMargin] - [[self removeXImage] size].width ;
    
    CGFloat removeXImageWidth = [[self removeXImage] size].width ;
	BOOL hasRemoveXButton = (removeXImageWidth > 0 ) ;

	NSInteger numberOfSpaces = [self maxRating] - 1 + (hasRemoveXButton ? 1 : 0) ;
	NSInteger numberOfStars = [self maxRating] ;
    NSInteger interSpace = 0 ;
    interSpace = numberOfSpaces > 0 ? (starsSpace - numberOfStars*size.width)/numberOfSpaces : 0 ;
    if(interSpace < 0) {
        interSpace = 0 ;
	}
	CGFloat x = [self horizontalMargin] + removeXImageWidth + size.width*position ;
    if((position > 0) || hasRemoveXButton) {
		// This star is either not the first star, or it is
		// the first star but is preceded by the Remove (X)
		// button.
		CGFloat extraMarginForRemoveX = hasRemoveXButton ? 1 : 0 ;
        x += interSpace*(position + extraMarginForRemoveX) ;
	}
    CGFloat y = (self.bounds.size.height - size.height)/2.0 ;
    return NSMakePoint(x,y) ; 
}



- (void)drawRect:(NSRect)dirtyRect
{
#if 0
	NSBezierPath *p = [NSBezierPath bezierPathWithRect:self.bounds];
	[[NSColor redColor] set] ;
    [p stroke] ;
#endif
	
	// Draw background color
    NSColor *colorToDraw = [self backgroundColor]==nil?[NSColor clearColor]:[self backgroundColor];
    [colorToDraw set];
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:self.bounds];
    [path fill] ;
	
	// Draw the Remove(X) Circle
    NSSize removeXSize = [[self removeXImage] size] ;
	CGFloat removeXTweak = -1.0 ;
	[[self removeXImage] drawAtPoint:NSMakePoint([self horizontalMargin], (self.bounds.size.height - removeXSize.height)/2.0 + removeXTweak)
							fromRect:NSMakeRect(0.0, 0.0, removeXSize.width, removeXSize.height)
						   operation:NSCompositeSourceOver
							fraction:1.0] ;
	
	// Draw stars
    NSSize starSize = [[self starImage] size] ;
    NSSize starHighlightedSize = [[self starHighlightedImage] size] ;
    for( NSInteger i=0 ; i<[self maxRating]; i++ )
    {
        [[self starImage] drawAtPoint:[self pointOfStarAtPosition:i
													  highlighted:YES]
							 fromRect:NSMakeRect(0.0, 0.0, starSize.width, starSize.height)
							operation:NSCompositeSourceOver
							 fraction:1.0] ;
        if( i < [[self rating] floatValue])
        {
            [NSGraphicsContext saveGraphicsState];
            NSBezierPath *pathClip=nil;
            NSPoint starPoint = [self pointOfStarAtPosition:i highlighted:NO];
            if( i< [[self rating] floatValue] &&  [[self rating] floatValue] < i+1 )
            {
                
                float difference = [[self rating] floatValue] - i;
                NSRect rectClip;
                rectClip.origin = starPoint;
                rectClip.size = starSize;
                if([self displayMode] == SSYStarRatingViewDisplayHalf && difference < [self halfStarThreshold])    // Draw half star image
                {

                    rectClip.size.width/=2.0;
                    pathClip = [NSBezierPath bezierPathWithRect:rectClip];
                }
                else if( [self displayMode] == SSYStarRatingViewDisplayAccurate )
                {
                    rectClip.size.width*=difference;
                    pathClip = [NSBezierPath bezierPathWithRect:rectClip];                    
                }
                if( pathClip)
                    [pathClip addClip];

            }
            [[self starHighlightedImage] drawAtPoint:starPoint fromRect:NSMakeRect(0.0, 0.0, starHighlightedSize.width, starHighlightedSize.height) operation:NSCompositeSourceOver fraction:1.0];
        
            [NSGraphicsContext restoreGraphicsState];
        }   
    }
	
	if ([[self rating] floatValue] > 0.0) {
		CGFloat removeXImageWidth = [[self removeXImage] size].width ;
		BOOL hasRemoveXButton = (removeXImageWidth > 0 ) ;
		if (hasRemoveXButton) {
			[self addToolTipRect:NSMakeRect(0.0, 0.0, removeXImageWidth, [self bounds].size.height)
						   owner:@"Reset to 'Unrated'"  // We can get away with not retaining this because it is a constant string.
						userData:nil] ;
		}
	}
}

#pragma mark -
#pragma mark Mouse Interaction
-(NSInteger) starsForPoint:(NSPoint)point
{
    NSInteger stars=0;
    for( NSInteger i=0; i<[self maxRating]; i++ )
    {
        NSPoint p =[self pointOfStarAtPosition:i highlighted:NO];
        if( point.x > p.x )
            stars=i+1;

    }
    
    return stars;
}

-(void)mouseDown:(NSEvent *)theEvent {
    if( ![self editable] )
        return;
    
    if ([theEvent type] == NSLeftMouseDown) {
        
        NSPoint pointInView   = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        
		NSNumber* rating = [NSNumber numberWithInteger:[self starsForPoint:pointInView]] ;
        [self setRating:rating] ;

		// This was moved here from -setRating: in BookMacster 1.11.6
		[self pushBindingValue:rating
						forKey:constKeyRating] ;

        
		[self setNeedsDisplay];
    }

}

-(void)mouseDragged:(NSEvent *)theEvent
{
    if( ![self editable] )
        return;
    
    NSPoint pointInView   = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    [self setRating:[NSNumber numberWithInteger:[self starsForPoint:pointInView]]] ;
    [self setNeedsDisplay];
}

-(void)mouseUp:(NSEvent *)theEvent
{
    if( ![self editable] )
        return;
    
    if( [[self delegate] respondsToSelector:@selector(starsSelectionChanged:rating:)] )
        [[self delegate] starsSelectionChanged:self rating:[[self rating] floatValue]];
}

@end