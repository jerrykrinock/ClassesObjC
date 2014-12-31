#import "SSYMenuGearButton.h"
#import "NSMenu+PopOntoView.h"

@implementation SSYMenuGearButton

- (void)drawRect:(NSRect)dirtyRect {
	[super drawRect:dirtyRect] ;
	
	// Draw the Gear
	NSImage* image = [NSImage imageNamed:@"NSActionTemplate"] ;
	[image drawInRect:NSMakeRect(3,
								 3,
								 14,
								 14)
			 fromRect:NSZeroRect
			operation:NSCompositeSourceOver fraction:1.0] ;

	// Draw the Triangle
	[[NSColor blackColor] set] ;
	NSBezierPath* path = [NSBezierPath bezierPath] ;
	[path moveToPoint:NSMakePoint(21, 10)] ;
	[path relativeLineToPoint:NSMakePoint(8, 0)] ;
	[path relativeLineToPoint:NSMakePoint(-4, 4)] ;
	[path closePath] ;
	[path fill] ;
}

 @end