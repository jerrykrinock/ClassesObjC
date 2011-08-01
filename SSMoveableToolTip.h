// Adapted from code by Eric Forget, http://www.cocoadev.com/index.pl?ToolTip

@interface SSMoveableToolTip : NSObject {
	NSPoint _offset ;
    NSWindow* _window;
    NSTextField* _textField;
    NSDictionary* _textAttributes;
}

+ (void)setString:(NSString *)string
		   origin:(NSPoint)origin
		 inWindow:(NSWindow*)hostWindow ;
+ (void)goAway ;
+ (void)setOffset:(NSPoint)offset ;

@end
