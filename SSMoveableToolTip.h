// Adapted from code by Eric Forget, http://www.cocoadev.com/index.pl?ToolTip

@interface SSMoveableToolTip : NSObject {
	NSPoint _offset ;
    NSWindow* _window ;
    NSTextField* _textField ;
}

/*
 @brief    Displays a moveable tool tip with given parameters
 
 @details  Any tooltip displayed by a prior invocation of this method
 disappears, so that there isonly one simultaneous moveable tooltip per app.
 If you really want more than one, talk to the User Interface Police :))
 @param    font  The font to be used in the tooltip.  If you pass nil, defaults
 to [NSFont toolTipsFontOfSize:[NSFont systemFontSize]] which is what Cocoa
 uses.
 @param    offset  On 2013-12-04, removed hard-coded
 offset of (10.0, 28.0) in the implementation which was
 being added to the offset you pass here.
 */
+ (void)setString:(NSString *)string
             font:(NSFont*)font
		   origin:(NSPoint)origin
		 inWindow:(NSWindow*)hostWindow ;

+ (void)goAway ;

+ (void)setOffset:(NSPoint)offset ;

@end
