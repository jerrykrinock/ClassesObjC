#import "SSYTableHeaderView.h"
#import "NSTableView+MoreSizing.h"

@implementation SSYTableHeaderView : NSTableHeaderView

- (void)mouseDown:(NSEvent*)event {
	NSTableView* tableView = [self tableView] ;
	NSTableColumn* tableColumn = [[self tableView] tableColumnOfCurrentMouseLocationWithInset:5.0] ;
	
	if (tableColumn) {
		NSString *identifier = [tableColumn identifier] ;
		
        NSTableHeaderCell* headerCell = [tableColumn headerCell] ;
        NSRect rect = [self headerRectOfColumn:[tableView columnWithIdentifier:identifier]] ;
        
        [(NSPopUpButtonCell*)headerCell performClickWithFrame:rect
                                                       inView:self] ;
	}
	else {
		[super mouseDown:event] ;
	}
}

- (void)dealloc {
    [_sortedColumn release] ;
    
    [super dealloc] ;
}

@end