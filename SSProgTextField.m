#import "SSProgTextField.h"
#import "NS(Attributed)String+Geometrics.h"
#import "NSView+Layout.h"
#import "SSTruncatingTextField.h"
#import "SSYLocalize/NSString+Localize.h"

@implementation SSRolloverButton

// The following do not work unless you -addTrackingRect
//- (void)mouseEntered:(NSEvent *)event {
//	if ([self isEnabled]) {
//	}
//	
//	[super mouseEntered:event] ;
//}
//
//- (void)mouseExited:(NSEvent *)event {
//	if ([self isEnabled]) {
//	}
//
//	[super mouseExited:event] ;
//}

- (void)resetCursorRects {
	NSRect wholeThing = NSMakeRect(0,0, [self width], [self height]) ;
	[self addCursorRect:wholeThing
				 cursor:[NSCursor pointingHandCursor]] ;
}


@end

@implementation SSProgTextField

- (CGFloat)textSize {
	return floor(0.8 * _wholeFrame.size.height) ;
}

- (NSTextField*)textField {
	if (!_textField) {
		_textField = [[SSTruncatingTextField alloc] initWithFrame:NSMakeRect(0,0,0, _wholeFrame.size.height)] ;
		[[_textField cell] setTruncationStyle:NSLineBreakByTruncatingHead] ;
		[_textField setBordered:NO] ;
		[_textField setEditable:NO] ;
		[_textField setDrawsBackground:NO] ;
		[_textField setFont:[NSFont systemFontOfSize:[self textSize]]] ;
		[self addSubview:_textField] ;
	}
	
	return _textField ;
}

- (SSRolloverButton*)hyperButton {
	if (!_hyperButton) {
		_hyperButton = [[SSRolloverButton alloc] initWithFrame:NSMakeRect(0,0,0,_wholeFrame.size.height)] ;
		[_hyperButton setBordered:NO] ;
		[_hyperButton setAlignment:NSCenterTextAlignment] ;
		[self addSubview:_hyperButton] ;
	}
	
	return _hyperButton ;
}

- (void)rejuvenateProgressBar {
	NSRect frame ;
	if (_progBar != nil) {
		frame = [_progBar frame] ;
		[_progBar removeFromSuperviewWithoutNeedingDisplay] ;
	}
	else {
		frame = NSMakeRect(0,0,100,8) ;
	}
	_progBar = [[NSProgressIndicator alloc] initWithFrame:frame] ;
	[self addSubview:_progBar] ;
	[_progBar release] ;
	[_progBar setStyle:NSProgressIndicatorBarStyle] ;
	[_progBar setUsesThreadedAnimation:YES] ; // unreliable pre-Leopard
	[_progBar setDisplayedWhenStopped:NO] ;
}

- (NSProgressIndicator*)progBar {
	if (_progBar == nil) {
		[self rejuvenateProgressBar] ;
	}
	
	return _progBar ;
}

- (SSRolloverButton*)cancelButton {
	if (!_cancelButton) {
		CGFloat length = _wholeFrame.size.height ;
		_cancelButton = [[SSRolloverButton alloc] initWithFrame:NSMakeRect(_wholeFrame.size.width - length, 0, length, length)] ;
		[_cancelButton setImage:[NSImage imageNamed:@"stop14"]] ;
		[_cancelButton setBordered:NO] ;
		[_cancelButton setToolTip:[NSString localize:@"cancel"]] ;
		[self addSubview:_cancelButton] ;
	}
	
	return _cancelButton ;
}

- (void)hideCancelButton {
	if (_cancelButton != nil) {
		// Set width = 0.0
		NSRect frame = [_cancelButton frame] ;
		NSRect displayRect = frame ;
		frame.size.width = 0.0 ;
		[_cancelButton setFrame:frame] ;

		[self setNeedsDisplayInRect:displayRect] ;
	}
}	

- (void)setHasCancelButtonWithTarget:(id)target
							  action:(SEL)action {
	BOOL needsButton = (target != nil) && (action != nil) ;
	NSRect displayRect ;
	
	if (needsButton && !_cancelButton) {
		// Create one of does not exist
		[self cancelButton] ;
	}
	else if (!needsButton && _cancelButton) {
		[self hideCancelButton] ;
	}
	
	if (needsButton) {
		[_cancelButton setTarget:target] ;
		[_cancelButton setAction:action] ;
		// Set width = height
		NSRect frame = [_cancelButton frame] ;
		displayRect = frame ;
		frame.size.width = frame.size.height ;
		[_cancelButton setFrame:frame] ;
	}
	
	[self setNeedsDisplayInRect:displayRect] ;
}
	
- (void)setBarWidth:(CGFloat)barWidth
		  textWidth:(CGFloat)textWidth {
	NSRect textFrame = NSMakeRect(0.0, 0.0, textWidth, _wholeFrame.size.height) ;
	NSTextField* textField = [self textField] ;
	[textField setFrame:textFrame] ;
	
	if (barWidth > 0) {
		NSRect barFrame = NSMakeRect(textWidth, 0.0, barWidth, _wholeFrame.size.height) ;
		NSProgressIndicator* progBar = [self progBar] ;
		[progBar setFrame:barFrame] ;
	}
	
	[self setNeedsDisplay:YES] ;
}

- (CGFloat)textBarWidth {
	CGFloat textBarWidth = _wholeFrame.size.width ;
	if (_cancelButton) {
		textBarWidth -= [[self cancelButton] frame].size.width ;
	}
	
	return textBarWidth ;
}
	
- (void)setProgressBarWidth:(CGFloat)barWidth {
	CGFloat textWidth = [self textBarWidth] - barWidth ;
	[self setBarWidth:barWidth
			textWidth:textWidth] ;
}

- (void)setTextWidthForText {
	NSTextField* textField = [self textField] ;
	
	// Make textToDisplay by appending ellipsis to verbToDisplay
	NSString* text = [textField stringValue] ;
	CGFloat requiredWidth = [text widthForHeight:CGFLOAT_MAX
										  font:[textField font]] ;
	// Instead of using [textField frame].size.height as the last argument, we use FLT_MAX because if
	// NSLayoutManager thinks that one or more of the characters in the string is too tall to fit in the
	// given height (this happens frequently in Japanese), the width will be returned as 0.00.
	// This fix is in Bookdog 4.2.12.
	CGFloat textWidth = MIN(requiredWidth, [self textBarWidth]) ;
	
	CGFloat barWidth = [self textBarWidth] - textWidth ;
	
	[self setBarWidth:barWidth
			textWidth:textWidth] ;
}

- (void)setVerb:(NSString*)newVerb
		 resize:(BOOL)resize {
	[[self textField] setStringValue:newVerb] ;
	if (resize) {
		[self setTextWidthForText] ;
	}
}

- (void)hideProgressBar {
	NSProgressIndicator* bar = [self progBar] ;
	[bar stopAnimation:self] ;
	[bar setHidden:YES] ;
}

- (void)clearAll {
	[self hideCancelButton] ;
	[self hideProgressBar] ;
	
	[_hyperButton setWidth:0.0] ;
	
	NSTextField* textField = [self textField] ;
	[textField setStringValue:@""] ;
	[textField setWidth:0.0] ;
	[_hyperButton setLeftEdge:[textField rightEdge]] ;
	
}

- (void)displayIndeterminate:(BOOL)indeterminate
		withLocalizedVerb:(NSString*)localizedVerb {
	[self clearAll] ;
	
	NSTextField* textField = [self textField] ;
	
	// Make textToDisplay by appending ellipsis to verbToDisplay
	NSString* text = [NSString stringWithFormat:@"%@%C", localizedVerb, 0x2026] ;
	[textField setStringValue:text] ;
	
	NSProgressIndicator* progBar = [self progBar] ;
	[self setTextWidthForText] ;
	// Animation does not work very well pre-Leopard
	if (NSAppKitVersionNumber < 900) {
		[self rejuvenateProgressBar] ;
		progBar = [self progBar] ; // The new one, that is
	}
	[progBar setIndeterminate:indeterminate] ;
	[progBar startAnimation:self] ;
	[progBar setHidden:NO] ;
	[self display] ;

}

- (void)displayIndeterminate:(BOOL)indeterminate
		 withLocalizableVerb:(NSString*)localizableVerb {
	[self displayIndeterminate:indeterminate
			 withLocalizedVerb:[NSString localize:localizableVerb]] ;
}

- (void)displayOnlyText:(NSString*)text
			  hyperText:(NSString*)hyperText
				 target:(id)target
				 action:(SEL)action {
	[self hideCancelButton] ;
	
	if (hyperText != nil) {
		SSRolloverButton* hyperButton = [self hyperButton] ;
		
		NSFont* font = [NSFont systemFontOfSize:11.0] ;
		NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:
			font, NSFontAttributeName,
			[NSColor blueColor], NSForegroundColorAttributeName,
			[NSNumber numberWithInteger:NSUnderlineStyleSingle], NSUnderlineStyleAttributeName,
			nil] ;				
		NSAttributedString* title = [[NSAttributedString alloc] initWithString:hyperText
																	attributes:attributes] ;
		[hyperButton setAttributedTitle:title] ;
		[hyperButton setWidth:[title widthForHeight:100.0]] ;
		[hyperButton setTarget:target] ;
		[hyperButton setAction:action] ;
	}
	else {
		[_hyperButton setWidth:0.0] ;
	}

	if (text == nil) {
		text = @"" ;
	}
	NSTextField* textField = [self textField] ;
	[textField setStringValue:text] ;
	CGFloat requiredTextWidth = [text widthForHeight:CGFLOAT_MAX
											  font:[textField font]] ;
	CGFloat availableTextWidth = [self textBarWidth] - [_hyperButton width] ;
	CGFloat textWidth = MIN(requiredTextWidth, availableTextWidth) ;
	[textField setWidth:textWidth] ;

	[_hyperButton setLeftEdge:[textField rightEdge]] ;
	
	[self hideProgressBar] ;

	[self display] ;
}

- (void)displayClearAll {
	[self clearAll] ;
	[self display] ;
}

- (void)setMaxValue:(double)value {
	NSProgressIndicator* progBar = [self progBar] ;

	[progBar setIndeterminate:NO] ;
	[progBar setMaxValue:value] ;
	[progBar setHidden:NO] ;
}

- (void)setIndeterminate:(BOOL)yn {
	[[self progBar] setIndeterminate:yn] ;
}

- (void)setDoubleValue:(double)value {
	[[self progBar] setDoubleValue:value] ;
	NSTimeInterval secondsNow = [NSDate timeIntervalSinceReferenceDate] ;
	if (secondsNow > _nextProgressUpdate) {
		_nextProgressUpdate = secondsNow + .05 ;
		[[self progBar] display] ;
	}
}

- (void)incrementDoubleValueBy:(double)doubleValue {
	NSProgressIndicator* progBar = [self progBar] ;
	double newValue = [progBar doubleValue] + doubleValue ;
	[self setDoubleValue:newValue] ;
}	

- (void)incrementDoubleValueByObject:(NSNumber*)value {
	[self incrementDoubleValueBy:[value doubleValue]] ;
}	

- (SSProgTextField*)initWithFrame:(NSRect)frame {
	frame.size.height = 14.0 ;
	if ((self = [super initWithFrame:frame])) {
		_wholeFrame = frame ;
	}

	return self ;
}

- (void)dealloc {
	[_textField release] ;
	[_hyperButton release] ;
	[_cancelButton release] ;

	[super dealloc] ;
}




@end