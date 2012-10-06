#import "SSTableView.h"

@interface NSObject ( ContextualMenuDelegate )
	- (NSMenu*)menuForTableColumnIndex:(NSInteger)iCol rowIndex:(NSInteger)iRow ;
@end

@implementation SSTableView

//- (id)initWithFrame:(NSRect)frameRect
//{
//	if ((self = [super initWithFrame:frameRect]) != nil)
//	{
//		// Add initialization code here
//	}
//	return self;
//}
//
//- (void)drawRect:(NSRect)rect
//{
//	[super drawRect:rect] ;
//}

-(NSMenu*)menuForEvent:(NSEvent*)evt
{
	NSMenu* output = nil ;
	
	NSPoint point = [self convertPoint:[evt locationInWindow] fromView:nil] ;
    NSInteger iCol = [self columnAtPoint:point];
    NSInteger iRow = [self rowAtPoint:point];
	
    if (		iCol >= 0
			&&	iRow >= 0
			&&	[[self delegate] respondsToSelector:@selector(menuForTableColumnIndex:rowIndex:)] ) {
		output = [[self delegate] menuForTableColumnIndex:iCol rowIndex:iRow];
    }
	
	return output;
}

// ***** NSDraggingSource Methods (These must be here, in the subclass, not in its dataSource!) ***** //

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isIntraApp;
{
	return isIntraApp
	? (NSDragOperationCopy | NSDragOperationMove)
	: NSDragOperationCopy ;
}




@end
