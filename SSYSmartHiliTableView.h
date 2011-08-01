#import <Cocoa/Cocoa.h>


/*!
 @brief    A subclass of NSTableView that does not highlight cells
 which are not editable.

 @details  From: http://www.cocoabuilder.com/archive/message/cocoa/2006/6/1/164789:
 The "secret" is that you need to override the highlighting in two places:
 
 - The NSCell used in the table
 - The NSTableView itself
 
 I've done the second one, but I'm not sure how to do the first one without
 screwing up all the cells that I've set in Interface Builder.
 
 With the code below, it works perfectly in Tiger but in Leopard the
 first column of the clicked row is flashed in the highlight color whenever you click 
 in a different column of that row.  If I ever wanted to fix that, and get
 rid of the hacks, supposedly the
 following method in all relevant NSCell subclasses would do it:
 
 If I ever figure that out, this should be done in the NSCell subclass:
 - (NSColor *)highlightColorWithFrame:(NSRect)cellFrame
 inView:(NSView*)controlView {
 return nil;
 }
 
*/
@interface SSYSmartHiliTableView : NSTableView {
}

 @end
