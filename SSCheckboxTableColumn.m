#import "SSCheckboxTableColumn.h"


@implementation SSCheckboxTableColumn

// This is a callback from the OS
- (id)dataCellForRow:(int)iRow
{
	NSButtonCell * cell =[[NSButtonCell alloc] init];
	[cell setControlSize:NSSmallControlSize] ;
	[cell setButtonType:NSSwitchButton] ;
	[cell setTitle:@""] ;
	[cell setImagePosition:NSImageOnly] ;
	return [cell autorelease] ;
}

@end

