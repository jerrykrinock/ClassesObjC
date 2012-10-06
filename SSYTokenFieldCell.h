#import <Cocoa/Cocoa.h>


/*!
 @brief    An NSTokenFieldCell subclass which exposes tokenizingCharacter
 as a binding, and it can handle its object value being assigned to a set
 as well as an array, and it does a smarter job of calculating the
 expansion frame.
 */
@interface SSYTokenFieldCell : NSTokenFieldCell {
	unichar m_tokenizingCharacter ;
}

@property (assign) unichar tokenizingCharacter ;

/*!
 @brief    This override calculates the expansion frame which is used to display the
 entire text in a special expansion frame tool tip, if text is truncated.
 
 @details  This is a workaround for the fact that -[NSTableColumn dataCell],
 even though it claims to be an NSTextFieldCell, must have some magic built
 into it which allows the expansion frame tool tip to be calculated
 correctly regardless of -wraps, -isScrollable, and -truncatesLastVisibleLine.
 The [[NSTextFieldCell alloc] init] used to draw the text in this class
 does not have that magic, so we calculate it from scratch, based on the
 current attributed string value.
 */
- (NSRect)expansionFrameWithFrame:(NSRect)frame
						   inView:(NSView*)view ;

@end
