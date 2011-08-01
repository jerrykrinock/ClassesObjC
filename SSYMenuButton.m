#import "SSYMenuButton.h"
#import "NSMenu+PopOntoView.h"


@implementation SSYMenuButton

- (id)initWithCoder:(NSCoder*)coder {
	self = [super initWithCoder:coder];
	if (self != nil) {
		[self setTarget:self] ;
		[self setAction:@selector(showMenu:)] ;
	}
	
	return self ;
}

- (void)showMenu:(id)sender {
	NSMenu* menu = [menuMaker menuForButton:self] ;
	[menu popOntoView:self
			  atPoint:NSMakePoint([self frame].size.width, [self frame].size.height)
			pullsDown:NO] ;
}

@end
