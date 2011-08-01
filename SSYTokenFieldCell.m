#import "SSYTokenFieldCell.h"
#import "NS(Attributed)String+Geometrics.h"

@implementation SSYTokenFieldCell

+ (void)initialize {
	[self exposeBinding:@"tokenizingCharacter"] ;
}

@synthesize noSelectionPlaceholder ;
@synthesize noTokensPlaceholder ;
@synthesize multipleValuesPlaceholder ;
@synthesize notApplicablePlaceholder ;

- (NSArray*)objectValue {
	NSArray* value = [super objectValue] ;
	return value ;
}

- (void)setObjectValue:(id)value {
	if (value == NSNoSelectionMarker) {
		[self setPlaceholderString:[self noSelectionPlaceholder]] ;
		value = nil ;
	}		
	else if (value == NSMultipleValuesMarker) {
		[self setPlaceholderString:[self multipleValuesPlaceholder]] ;
		value = nil ;
	}
	else if (value == NSNotApplicableMarker) {
		[self setPlaceholderString:[self notApplicablePlaceholder]] ;
		value = nil ;
	}
	else if ([value isKindOfClass:[NSArray class]]) {
		if ([value count] == 0) {
			[self setPlaceholderString:[self noTokensPlaceholder]] ;
			value = nil ;
		}
	}
	else {
		// When the user edits the cell, this method gets a 'value'
		// parameter which is an object of class  NSConcreteTextStorage.
		// I have no idea what that is doing, but if we just let it flow
		// through here to super without touching it, things work.
	}
	
	[super setObjectValue:value] ;
}


/*!
 @brief    Calculates the expansion frame which is used to display the
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
						   inView:(NSView*)view {
	NSRect expansionFrame = [super expansionFrameWithFrame:frame
													inView:view] ;
	// Since we are not using a magic NSTextFieldCell, the
	// expansionFrame at this point will be no wider than the
	// cell, and will be high enough to display the text if
	// it were wrapped to multiple lines, which it does not.
    // (You can get the correct rect if you setWraps:NO, but
    // then the ellipsis does not show when drawing normally.)
	// So we discard the size and use only the origin.

	// Super does correctly return NSZeroRect if the text
	// is not currently truncated, so we use that and do same.
	if (
		(expansionFrame.size.width == 0.0)
		&&
		(expansionFrame.size.height == 0.0)
		) {
		return NSZeroRect ;
	}
	
	NSAttributedString* as = [self attributedStringValue] ;
	CGFloat height = frame.size.height ;
	CGFloat width = [as widthForHeight:height] ;
	expansionFrame.size.width = width ;
	expansionFrame.size.height = height ;
	return expansionFrame ;
}

@synthesize tokenizingCharacter = m_tokenizingCharacter ;

- (unichar)tokenizingCharacter {
	unichar tokenizingCharacter ;
	@synchronized(self) {
		tokenizingCharacter = m_tokenizingCharacter ;
	}
	return tokenizingCharacter ;
}

- (void)setTokenizingCharacter:(unichar)tokenizingCharacter {
	// NSTokenFieldCell raises an exception if you set tokenizing
	// character set to {0}.  I've seen this happen in BookMacster
	// when a document is closing.  I'm not sure if it's due to
	// some other bug, but as defensive programming…
	if (tokenizingCharacter == 0) {
		return ;
	}
	
	@synchronized(self) {
		m_tokenizingCharacter = tokenizingCharacter ;
	}

	[self setTokenizingCharacterSet:[NSCharacterSet characterSetWithRange:NSMakeRange(tokenizingCharacter, 1)]] ;
	
}


- (void)dealloc {
	[noSelectionPlaceholder release] ;
	[noTokensPlaceholder release] ;
	[multipleValuesPlaceholder release] ;
	[notApplicablePlaceholder release] ;
	
	[super dealloc] ;
}

@end