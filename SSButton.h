#import <Cocoa/Cocoa.h>


@interface SSButtonCell : NSButtonCell {

	NSColor* _color ;
}

- (id)initWithTitleFont:(NSFont*)font ;
- (void)setColor:(NSColor*)color ;

@end

@interface SSButton : NSButton {
	NSString* _titleText ;
	NSString* _keyEquivalentSuffix ;
	BOOL keyEquivalentShowing ;
	CGFloat widthMargin ;
	BOOL keyEquivalentWithOrWithoutAltKey ;
}

- (BOOL)keyEquivalentWithOrWithoutAltKey;
- (void)setKeyEquivalentWithOrWithoutAltKey:(BOOL)value;

- (void)setColor:(NSColor*)color ;
- (void)setTitleText:(NSString*)titleText ;
- (void)setKeyEquivalentSuffix:(NSString*)suffix ;
- (void)setWidthMargin:(CGFloat)wm ;
- (void)showKeyEquivalent ;
- (void)hideKeyEquivalent ;


@end
