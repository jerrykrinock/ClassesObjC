#import "SSButton.h"
#import "NS(Attributed)String+Geometrics.h"
//#import "SSViewSizing.h"

@implementation SSButtonCell

- (id)initWithTitleFont:(NSFont*)font {
	if ((self = [super init])) {
		[self setFont:font] ;
	}
	
	return self ;
}
	
- (void)setColor:(NSColor*)color {
	[color retain] ;
	[_color release] ;
	_color = color ;
}

- (NSColor*)color {
	return _color ;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView {
	[super drawInteriorWithFrame:cellFrame inView:controlView];
	
	if ([self color] != nil) {
		[[[self color] colorWithAlphaComponent:0.9] set];
		NSRectFillUsingOperation(cellFrame, NSCompositePlusDarker);
	}
}
	
- (void)mouseDown:(NSEvent *)theEvent {
	[[self target] performSelector:[self action]] ;
	//[super mouseDown:theEvent] ;
}

@end	


@implementation SSButton

- (BOOL)keyEquivalentWithOrWithoutAltKey {
    return keyEquivalentWithOrWithoutAltKey;
}

- (void)setKeyEquivalentWithOrWithoutAltKey:(BOOL)value {
    if (keyEquivalentWithOrWithoutAltKey != value) {
        keyEquivalentWithOrWithoutAltKey = value;
    }
}


- (void)setKeyEquivalentSuffix:(NSString*)suffix {
	[suffix retain] ;
	[_keyEquivalentSuffix release] ;
	_keyEquivalentSuffix = suffix ;
}

- (NSString*)keyEquivalentSuffix
{
	return _keyEquivalentSuffix ;
}

- (void)setTitleText:(NSString*)titleText {
	[titleText retain] ;
	[_titleText release] ;
	_titleText = titleText ;

	if (keyEquivalentShowing) {
		NSString* newTitle = [[NSString alloc] initWithFormat:@"%@ %@",
			_titleText,
			[self keyEquivalentSuffix]] ;
		[self setTitle:newTitle] ;
		[newTitle release] ;
	}
	else {
		[self setTitle:_titleText] ;
	}
}

- (NSString*)titleText
{
	return _titleText ;
}

- (void)setColor:(NSColor*)color {
	[[self cell] setColor:color] ;
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super initWithCoder:coder])) {
		// I don't know why this was there.  Commented out in Bookdog 4.0.1...
		// [self setCell:[[[SSButtonCell alloc] initWithTitleFont:[self font]] autorelease]] ;
		[self setKeyEquivalentWithOrWithoutAltKey:NO] ; // default behavior
	}
	return  self ;
}

// Over-ride this so it will not highlight for milliseconds
// Just send the action to the target
//[[self target] performSelector:[self action]] ;
	
- (void)showKeyEquivalent {
	NSString* newTitle = [[NSString alloc] initWithFormat:@"%@ %@",
		[self titleText],
		[self keyEquivalentSuffix]] ;
	
	NSFont* font = [self font] ;
	CGFloat height = [font boundingRectForFont].size.height ;
	
	CGFloat width ;
	width =  [newTitle widthForHeight:height
								 font:font] ;

	if (width > [self frame].size.width - widthMargin) {
        [newTitle release] ;
		newTitle = [[NSString alloc] initWithFormat:@"%@\n%@",
			[self titleText],
			[self keyEquivalentSuffix]] ;
	}
	
	[self setTitle:newTitle] ;
	[newTitle release] ;
	keyEquivalentShowing = YES ;
}

- (void)setWidthMargin:(CGFloat)wm {
	widthMargin = wm ;
}

- (void)hideKeyEquivalent {
	[self setTitle:[self titleText]] ;
	keyEquivalentShowing = NO ;
}

- (void)dealloc {
	[_titleText release] ;
	[_keyEquivalentSuffix release] ;
	
	[super dealloc] ;
}

- (BOOL)performKeyEquivalent:(NSEvent *)event {
	NSEvent* tweakedEvent ;
	if ([self keyEquivalentWithOrWithoutAltKey]) {
		tweakedEvent = [NSEvent keyEventWithType:[event type]
										location:[event locationInWindow]
								   modifierFlags:[event modifierFlags] & ~NSEventModifierFlagOption
									   timestamp:[event timestamp]
									windowNumber:[event windowNumber]
										 context:[event context]
									  characters:[event characters]
					 charactersIgnoringModifiers:[event charactersIgnoringModifiers]
									   isARepeat:[event isARepeat]
										 keyCode:[event keyCode]] ;
	}
	else {
		tweakedEvent = event ;
	}


	return [super performKeyEquivalent:tweakedEvent] ;
}

@end
