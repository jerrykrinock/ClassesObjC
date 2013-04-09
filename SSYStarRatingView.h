//
//  SSYStarRatingViewView.
//
//  Created by Ernesto Garcia on 26/02/12.
//  Copyright (c) 2012 cocoawithchurros.com All rights reserved.
//  Distributed under MIT license




//
//  ARC Helper
//
//  Version 1.2.1
//
//  Created by Nick Lockwood on 05/01/2012.
//  Copyright 2012 Charcoal Design
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://gist.github.com/1563325
//


#import <Cocoa/Cocoa.h>

extern NSString* const constKeyRating ;

enum {
    SSYStarRatingViewDisplayFull=0,
    SSYStarRatingViewDisplayHalf,
    SSYStarRatingViewDisplayAccurate
};
typedef NSUInteger SSYStarRatingViewDisplayMode;

@protocol SSYStarRatingViewProtocol;

@interface SSYStarRatingView : NSControl {
	NSColor* m_backgroundColor ;
	NSImage* m_starHighlightedImage ;
	NSImage* m_starImage ;
	NSImage* m_removeXImage ;
	NSInteger m_maxRating ;
	NSNumber* m_rating ;
	CGFloat m_horizontalMargin ;
	BOOL m_editable ;
	SSYStarRatingViewDisplayMode m_displayMode ;
	float m_halfStarThreshold ;
	id <SSYStarRatingViewProtocol> m_delegate ;
}

@property (nonatomic, retain) NSColor *backgroundColor;
@property (nonatomic, retain) NSImage *starHighlightedImage;
@property (nonatomic, retain) NSImage *starImage;
@property (nonatomic, retain) NSImage *removeXImage;
@property (nonatomic) NSInteger maxRating;
@property (retain) NSNumber* rating;
@property (nonatomic) CGFloat horizontalMargin;
@property (nonatomic) BOOL editable;
@property (nonatomic) SSYStarRatingViewDisplayMode displayMode;
@property (nonatomic) float halfStarThreshold;

@property (nonatomic, assign) id<SSYStarRatingViewProtocol> delegate;
@end


@protocol SSYStarRatingViewProtocol <NSObject>

@optional
-(void)starsSelectionChanged:(SSYStarRatingView*)control rating:(float)rating;

@end

