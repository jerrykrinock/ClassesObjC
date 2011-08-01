#import "SSYAutoHeightTableView.h"

@class SSYAutoHeightBox ;


@implementation SSYAutoHeightTableView

#ifdef j
- (NSRect)frame {
	CGFloat headerHeight = NSHeight([[self headerView] frame]) ;
	NSInteger nRows = [self numberOfRows] ;
	CGFloat rowsHeight = nRows * [self rowHeight] ;
	CGFloat gapsHeight = (nRows-1) * [self intercellSpacing].height ;
	CGFloat height = headerHeight + rowsHeight + gapsHeight ;
	
	NSRect frame_ = [super frame] ;
	frame_.size.height = height ;
	
	return frame_ ;
}
#endif

- (void)noteHeightOfRowsWithIndexesChanged:(NSIndexSet *)indexSet {
}

- (void)viewWillDraw {
    // Perform some operations before recursing for descendants.
	
    // Now recurse to handle all our descendants.
    // Overrides must call up to super like this.
    [super viewWillDraw];
	
    // Perform some operations that might depend on descendants
    //  already having had a chance to update.
	NSTableHeaderView* headerView = [self headerView] ;
	CGFloat headerHeight ;
	if (headerView) {
		headerHeight = NSHeight([headerView frame]) ;
	}
	else {
		headerHeight = 0.0 ;
	}
	NSInteger nRows = [self numberOfRows] ;
	
	CGFloat rowsHeight = nRows * [self rowHeight] ;
	CGFloat gapsHeight = (nRows-1) * [self intercellSpacing].height ;
	CGFloat height = headerHeight + rowsHeight + gapsHeight ;
	
	NSRect frame = [self frame] ;
	frame.size.height = height ;
	[self setFrame:frame] ;
	CGFloat width = frame.size.width ;
	
	NSScrollView* enclosingScrollView = [self enclosingScrollView] ;
	
	frame = [enclosingScrollView frame] ;
	frame.size.width = width + 2.0 ;	
	frame.size.height = height + 2.0 ;	
	[enclosingScrollView setFrame:frame] ;
} 
@end