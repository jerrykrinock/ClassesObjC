#import "SSTruncatingTextField.h"
#import "SSTextFieldCell.h"

@implementation SSTruncatingTextField

- (id)initWithFrame:(NSRect)frame {
	if ((self = [super initWithFrame:frame])) {
		SSTextFieldCell* cell = [[SSTextFieldCell alloc] init] ;
		[self setCell:cell] ;
		[cell release] ;
	}
	
	return self ;
}

- (void)setTruncationStyle:(NSInteger)truncationStyle {
	[[self cell] setTruncationStyle:truncationStyle] ;
}

@end