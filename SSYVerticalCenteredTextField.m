#import "SSYVerticalCenteredTextField.h"
#import "NSView+Layout.h"


@implementation SSYVerticalCenteredTextField

- (void)setFont:(NSFont*)font {
	CGFloat oldFontSize = [[self font] pointSize] ;
	[super setFont:font] ;
	CGFloat newFontSize = [font pointSize] ;
	
	if (newFontSize != oldFontSize) {
		NSControlSize newControlSize ;
		if (newFontSize > 13) {
			newControlSize = NSControlSizeRegular ;
		}
		else if (newFontSize > 10) {
			newControlSize = NSControlSizeSmall ;
		}
		else {
			newControlSize = NSControlSizeMini ;
		}
		[[self cell] setControlSize:newControlSize] ;

		CGFloat deltaFontSize = newFontSize - oldFontSize ;
		CGFloat deltaBottom = -0.55 * deltaFontSize ;
		CGFloat newBottom = [self bottom] + deltaBottom ;
		[self setBottom:newBottom] ;
	}
}

@end
