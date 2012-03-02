//
//  SSPieProgressView.m
//  SSToolkit
//
//  Created by Sam Soffes on 4/22/10.
//  Copyright 2010-2011 Sam Soffes. All rights reserved.
//

#import "SSYPieProgressView.h"
//#import "SSDrawingUtilities.h"
#import <math.h>

CGFloat const kStartingAngle = M_PI_2 ;
// Use M_PI_2 = π/2, etc.
NSInteger const kBallSmallness = 12 ;
NSTimeInterval const kAnimationPeriod = .025 ;

@interface SSYPieProgressView ()
- (void)_initialize;
@property (atomic, assign) NSTimer* animationTimer ;
@end

@implementation SSYPieProgressView

#pragma mark - Accessors

@synthesize progress = _progress;
@synthesize animationTimer = _animationTimer;
@synthesize pieBorderWidth = _pieBorderWidth;
@synthesize pieBorderColor = _pieBorderColor;
@synthesize pieFillColor = _pieFillColor;
@synthesize pieBackgroundColor = _pieBackgroundColor;

- (void)setProgress:(CGFloat)newProgress {
	_progress = fmaxf(0.0f, fminf(1.0f, newProgress));
	[self setNeedsDisplay];
}

- (void)animate:(NSTimer*)timer {
    [self setNeedsDisplay] ;
}

- (void)setIndeterminate:(BOOL)indeterminate {
    if (indeterminate) {
        [self setAnimationTimer:[NSTimer scheduledTimerWithTimeInterval:kAnimationPeriod
                                                                 target:self
                                                               selector:@selector(animate:)
                                                               userInfo:nil
                                                                repeats:YES]] ;
    }
    else {
        [[self animationTimer] invalidate] ;
        [self setAnimationTimer:nil] ;
        [self setNeedsDisplay] ;
    }    
}



- (void)setPieBorderWidth:(CGFloat)pieBorderWidth {
	_pieBorderWidth = pieBorderWidth;
	
	[self setNeedsDisplay];
}


- (void)setPieBorderColor:(NSColor *)pieBorderColor {
	[pieBorderColor retain];
	[_pieBorderColor release];
	_pieBorderColor = pieBorderColor;
	
	[self setNeedsDisplay];
}

- (void)setPieFillColor:(NSColor *)pieFillColor {
	[pieFillColor retain];
	[_pieFillColor release];
	_pieFillColor = pieFillColor;
	
	[self setNeedsDisplay];
}


- (void)setPieBackgroundColor:(NSColor *)pieBackgroundColor {
	[pieBackgroundColor retain];
	[_pieBackgroundColor release];
	_pieBackgroundColor = pieBackgroundColor;
	
	[self setNeedsDisplay];
}


#pragma mark - Class Methods

+ (NSColor *)defaultPieColor {
	return [NSColor colorWithCalibratedRed:0.612f green:0.710f blue:0.839f alpha:1.0f];
}


#pragma mark - NSObject

- (void)dealloc {
	[_pieBorderColor release];
	[_pieFillColor release];
	[_pieBackgroundColor release];
	[super dealloc];
}


#pragma mark - UIView

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
		[self _initialize];
    }
    return self;
}


- (id)initWithFrame:(CGRect)aFrame {
    if ((self = [super initWithFrame:aFrame])) {
		[self _initialize];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	CGContextClipToRect(context, rect);
	
	// Background
	[_pieBackgroundColor set];
	CGContextFillEllipseInRect(context, rect);
	
	// Fill
	[_pieFillColor set];
    if ([self animationTimer] != nil) {
         // Indeterminate
        CGFloat rand1 = (CGFloat)random() / 0x7fffffff ;
        CGFloat rand2 = (CGFloat)random() / 0x7fffffff ;
        CGFloat ballRadialPosition = (1 - 1/kBallSmallness) * CGRectGetMidX(rect) * rand1 / 2 ;
        CGFloat ballAnglePosition = 2 * M_PI * rand2;

        CGFloat x = CGRectGetMidX(rect) + ballRadialPosition * cosf(ballAnglePosition) ;
        CGFloat y = CGRectGetMidY(rect) + ballRadialPosition * sinf(ballAnglePosition) ;
        CGPoint ballCenter = CGPointMake(x, y) ;
        CGFloat ballRadius = CGRectGetMaxX(rect) / kBallSmallness ;
        CGPoint points[3] = {
            CGPointMake(ballCenter.x + ballRadius, ballCenter.y),
            ballCenter,
            CGPointMake(ballCenter.x + ballRadius, ballCenter.y)
        };
        CGContextAddLines(context, points, sizeof(points) / sizeof(points[0]));
        CGContextAddArc(context, ballCenter.x, ballCenter.y, ballRadius, 0, 2*M_PI, false);
        CGContextDrawPath(context, kCGPathEOFill);
    }
    else {
        // Determinate
        if (_progress > 0.0f) {
            CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
            CGFloat radius = center.y;
            CGFloat angle = (2*M_PI*_progress) + kStartingAngle ;
            CGPoint points[3] = {
                CGPointMake(center.x + radius * cosf(kStartingAngle), center.y + radius * sinf(kStartingAngle)),
                center,
                CGPointMake(center.x + radius * cosf(angle), center.y + radius * sinf(angle))
            };
            CGContextAddLines(context, points, sizeof(points) / sizeof(points[0]));
            CGContextAddArc(context, center.x, center.y, radius, kStartingAngle, angle, false);
            CGContextDrawPath(context, kCGPathEOFill);
        }

        // Border
        [_pieBorderColor set];
        CGContextSetLineWidth(context, _pieBorderWidth);
        CGRect pieInnerRect = CGRectMake(_pieBorderWidth / 2.0f, _pieBorderWidth / 2.0f, rect.size.width - _pieBorderWidth, rect.size.height - _pieBorderWidth);
        CGContextStrokeEllipseInRect(context, pieInnerRect);    
    }
        
}

#pragma mark - Private

- (void)_initialize {
//	self.backgroundColor = [UIColor clearColor];
	
	self.progress = 0.0f;
	self.pieBorderWidth = 2.0f;
	self.pieBorderColor = [[self class] defaultPieColor];
	self.pieFillColor = self.pieBorderColor;
	self.pieBackgroundColor = [NSColor whiteColor];
}

@end
