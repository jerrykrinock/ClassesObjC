#import "SSYSuffixedMenuItem.h"

@implementation SSYSuffixedMenuItem

- (void)setTitlePrefix:(NSString*)prefix
				suffix:(NSString*)suffix {
	
	if ([suffix length] == 0) {
		[super setTitle:prefix] ;
		[super setAttributedTitle:nil] ;
		return ;
	}

	// Documentation for -menuOfFontSize says that nil is supposed to give default
	// menu font size, but it gives 13 instead of 14.  So, I hard-code 14.0.
	NSFont* font = [NSFont menuFontOfSize:14.0] ;
	NSString* newTitleText = [prefix stringByAppendingString:suffix] ;
	NSDictionary* fontAttribute = [NSDictionary dictionaryWithObjectsAndKeys:
								   font, NSFontAttributeName,
								   nil] ;				
	NSMutableAttributedString* attributedTitle = [[NSMutableAttributedString alloc] initWithString:newTitleText
																						attributes:fontAttribute] ;
	NSRange suffixRange = NSMakeRange([prefix length], [suffix length]) ;
	NSDictionary* suffixAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
										 [NSColor blueColor], NSForegroundColorAttributeName,
										 nil] ;				
	[attributedTitle addAttributes:suffixAttributes
							 range:suffixRange] ;
	[self setAttributedTitle:attributedTitle] ;
	[attributedTitle release] ;
}

@end
