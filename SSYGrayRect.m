#import "SSYGrayRect.h"


@implementation SSYGrayRect

- (void)drawRect:(NSRect)dirtyRect {
	[super drawRect:dirtyRect] ;
	
	[self lockFocus] ;
	
	// Using Digital Color Meter.app, Safari's status bar measures 216 at the bottom, 221 at the top.
	// To match this, I need to use 208/255 at the bottom, 214/255 at the top (Why????)
	// However, I want it to complement the toolbar in BookMacster, which is a little darker.
	NSGradient* gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:(160.0/255.0) alpha:1.0]    // top color
														 endingColor:[NSColor colorWithCalibratedWhite:(200.0/255.0) alpha:1.0]] ; // bottom color
	[gradient drawInRect:[self frame]
				   angle:270.0] ;
	
	[self unlockFocus] ;
}

@end