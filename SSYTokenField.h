#import <Cocoa/Cocoa.h>

@interface SSYTokenField : NSTokenField {
	BOOL m_objectValueIsOk ;
}

@property (assign) unichar tokenizingCharacter ;

/*!
 @brief    Adjusts the size.height of the receiver's
 frame so that it just tall enough to fit one row of tokens, and 
 then adjusts its origin.y so that its y midpoint is the same as
 it was before the adjustment was made.
 
 @details  This eliminates the problem of being able to see
 to tops of wrapped tokens along the bottom edge of a token field
 that is nominally large enough to fit one line that is not
 wide enough for all tokens to fit.
*/
- (void)sizeToOneLine ;

/*!
 @brief    Sizes the receiver's height to fit its current tokens in
 the current frame width, or the height of its enclosing scroll view,
 if one exists, whichever is greater.

 @details  In the cocoa-dev@lists.apple.com archives I've seen where
 others have wanted an NSTokenField in an NSScrollView, and have been
 stymied by the lack of access to the layout mechanism in
 NSTokenField.&nbsp;   So I worked around this by adding tags one at
 a time, emulating the layout that NSTokenField must be doing.&nbsp; 
 It's tedious, but works and doesn't hack into any Apple private
 methods.
 
 Sizing is based on an interrow spacing of 2.0 which was
 determined empirically since NSTokenField, unlike NSTableView, does
 not make its interrow spacing accessible, and also the fact that
 the interrow spacing seems to be independent of font size.&nbsp;
 This has been tested with the token field's font size set to
 -[NSFont systemFontOfSize:11.0] and -[NSFont systemFontOfSize:21.0].&nbsp;
 The code may need to be tweaked if Apple ever changes the layout 
 algorithm of NSTokenField.
 */
- (void)sizeHeightToFit ;

@end
