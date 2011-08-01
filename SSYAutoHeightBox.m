#import "SSYAutoHeightBox.h"

@interface NSView (SortByOriginY)

- (NSComparisonResult)compareOriginY:(NSView*)other ;

@end

@implementation NSView (SortByOriginY)

- (NSComparisonResult)compareOriginY:(NSView*)other {
	CGFloat selfY = [self frame].origin.y ;
	CGFloat otherY = [other frame].origin.y ;
	if (selfY < otherY) {
		return NSOrderedAscending ;
	}
	else if (selfY > otherY) {
		return NSOrderedDescending ;
	}

	return NSOrderedSame ;
}


@end


@implementation SSYAutoHeightBox

- (void)awakeFromNib {
	// Since we are going to use "manual" control of the
	// y-axis margins, the "automatic" had better be off
	// in all of our subviews.
	// Since the animation in
	// Interface Builder is confusing, we (re)-do it here:
	NSArray* subviews = [[self contentView] subviews] ;
	for (NSView* subview in subviews) {
		NSUInteger autoresizingMask = [subview autoresizingMask] ;
		NSUInteger mask = ~(NSViewMinYMargin + NSViewMaxYMargin) ;
		autoresizingMask = autoresizingMask & mask ;
		[subview setAutoresizingMask:autoresizingMask] ;
	}
	
}


- (void)drawRect:(NSRect)rect {
	[super drawRect:rect] ;
}

- (void)doLayout {
	NSRect frame ;
	
	frame = [self frame] ;
	frame.origin.y = 2.0 ;
	[self setFrame:frame] ;
	
	NSArray* subviews = [[[self contentView] subviews] sortedArrayUsingSelector:@selector(compareOriginY:)] ;
	
	CGFloat y = 6.0 ;
	
	for (NSView* subview in subviews) {
		NSRect subframe = [subview frame] ;
		
		subframe.origin.y = y ;
		[subview setFrame:subframe] ;
		y += subframe.size.height ;
		y += 2.0 ;
	}
	
	y += 4.0 ;
	
	frame = [[self contentView] frame] ;
	frame.size.height = y ;
	[[self contentView] setFrame:frame] ;
	
	frame = [self frame] ;
	frame.size.height = y ;
	[self setFrame:frame] ;
}

- (void)viewWillDraw {
    // Now recurse to handle all our descendants.
    // Overrides must call up to super like this.
    [super viewWillDraw];
	
    // Perform some operations that might depend on descendants
    //  already having had a chance to update.
	[self doLayout] ;
	
} 



@end