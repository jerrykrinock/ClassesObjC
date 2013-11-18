#import "SSYTableHeaderView.h"
#import "NSTableView+MoreSizing.h"

@implementation SSYTableHeaderView : NSTableHeaderView

- (void)drawRect:(NSRect)dirtyRect {
    /*
     Added in BookMacster 1.19.6.  After eliminating the realSelf crap from
     SSYPopUpTableHeaderCell, when closing a document once, I got a failure in
     this method, at end where it invokes [headerCell drawWithFrame:inView:],
     an assertion was raised in -[NSView lockFocus].
     
     ** Assertion failure in -[SSYTableHeaderView lockFocus], /SourceCache/AppKit/AppKit-1265/AppKit.subproj/NSView.m:7041
     2013-11-15 06:52:03.413 BookMacster[11590:303] -[SSYTableHeaderView(0x6080003ab6e0) lockFocus] failed with window=0x6000001f6700, windowNumber=-1, [self isHiddenOrHasHiddenAncestor]=0

     Poking around with the
     debugger, it seems that while the window controller is still around, its
     -document is nil, and furthermore
     [[NSDocumentController sharedDocumentController] documents] returns an
     empty set.  So it seems like the following should fix this problem…
     */
    if ([[[self window] windowController] document] == nil) {
        return ;
    }
    
	CGFloat height = [self frame].size.height ;
	CGFloat overallWidth = [self frame].size.width ;
	CGFloat intercellWidth = [[self tableView] intercellSpacing].width ;
	CGFloat x = 0.0 ;
	
	// Note that the individual column headers are apparently
	// our cells and not our subviews.  (We have 0 subviews.)
	// Therefore, we get the columns whose headers are to be
	// drawn from our table view.
	NSArray* tableColumns = [[self tableView] tableColumns] ;
	for (NSTableColumn* tableColumn in tableColumns) {
		CGFloat width = [tableColumn width] + intercellWidth ;
		// Before I added the following line, the vertical bar which was the
		// right side of the bezel would sometimes fall into the vertical scroller
		// and not be drawn.  It would seem to be about 1 pixel too wide.
		// Maybe there's a roundoff error in adding up all the column widths
		// or something.
		width = MIN(width, overallWidth - x) ;
		NSRect frame = NSMakeRect(x, 0, width, height) ;
		x += width ;
		
		NSCell* headerCell = [tableColumn headerCell] ;
		[headerCell drawWithFrame:frame
						   inView:self] ;
	}
}

- (void)mouseDown:(NSEvent*)event {
	NSTableView* tableView = [self tableView] ;
	NSTableColumn* tableColumn = [[self tableView] tableColumnOfCurrentMouseLocationWithInset:5.0] ;
	
	if (tableColumn) {
		NSString *identifier = [tableColumn identifier] ;
		
		if ([identifier hasPrefix:@"userDefined"]) {
			NSPopUpButtonCell* headerCell = [tableColumn headerCell] ;
			NSRect rect = [self headerRectOfColumn:[tableView columnWithIdentifier:identifier]] ;
			[headerCell performClickWithFrame:rect
									   inView:self] ;
		}
	}
	else {
		[super mouseDown:event] ;
	}
}

@end