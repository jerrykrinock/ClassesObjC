// This is 99% the work of Sam Soffes as indicated below.
// His SSPieProgressView is for iOS; I modified it for Mac OS X,
// made it start at the 12 o'clock position instead of 6 o'clock,
// and changed the name to SSYPieProgressView.


//
//  SSPieProgressView.h
//  SSToolkit
//
//  Created by Sam Soffes on 4/22/10.
//  Copyright 2010-2011 Sam Soffes. All rights reserved.
//

/**
 Pie chart style progress pie chart similar to the one in Xcode 3's status bar.
 */
@interface SSYPieProgressView : NSControl

///---------------------------
///@name Managing the Progress
///---------------------------

- (void)setIndeterminate:(BOOL)indeterminate ;

/**
 The current progress shown by the receiver.
 
 The current progress is represented by a floating-point value between `0.0` and `1.0`, inclusive, where `1.0` indicates
 the completion of the task. Values less than `0.0` and greater than `1.0` are pinned to those limits.
 
 The default value is `0.0`.
 */
@property (nonatomic, assign) CGFloat progress;

///-------------------------------------
/// @name Configuring the Pie Appearance
///-------------------------------------

/**
 The outer border width.
 
 The default is `2.0`.
 */
@property (nonatomic, assign) CGFloat pieBorderWidth;

/**
 The border color.
 
 @see defaultPieColor
 */
@property (nonatomic, retain) NSColor *pieBorderColor;

/**
 The fill color.
 
 @see defaultPieColor
 */
@property (nonatomic, retain) NSColor *pieFillColor;

/**
 The background color.
 
 The default is white.
 */
@property (nonatomic, retain) NSColor *pieBackgroundColor;


///---------------
/// @name Defaults
///---------------

/**
 The default value of `pieBorderColor` and `pieFillColor`.
 */
+ (NSColor *)defaultPieColor;

@end
