#import "SSYSmartHiliTableView.h"
#import "NSColor+Tweak.h"
#import "NSView+ActiveControl.h"


/* Interesting References on this topic and related topics:
http://stoneship.org/journal/2005/using-a-nsoutlineview-as-a-source-list/
 http://chanson.livejournal.com/176310.html
 http://www.cocoadev.com/index.pl?IconAndTextInTableCell
 http://mattgemmell.com/source

 The blue-highlight color that NSTableView uses is this:
 
 + (NSColor *)alternateSelectedControlColor;	// Similar to selectedControlColor; for use in lists and tables
 
 Note: for custom cells, you may want to simply return nil from this method to avoid having the NSCell do any background highlight color drawing:
 
 - (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
 
 That only works in NSTableViews; it won't work with cells in NSBrowsers, which actually rely on this method to draw the highlighting (since it is a matrix of cells).
 
 corbin
  
 */

 
@interface SmartHiliTextCell : NSTextFieldCell {
}
@end

@implementation SmartHiliTextCell

- (void)drawInteriorWithFrame:(NSRect)cellFrame
					   inView:(NSView *)controlView {
	// Note: When a cell if "highlighted", this is the same as when its
	// row or column are "selected".  "Highlighted" <==> "Selected".

	// ARGHHHH!!! I set the cell to be not editable below, in awakeFromNib,
	// but SOMETHING comes by and later sets it to be editable!!!!!!!!!
	
	if(![self isHighlighted]) {
		// Cell is not selected --> Let super draw text in black
		[super drawInteriorWithFrame:cellFrame
							  inView:controlView] ;
	}
	else if ([self isEditable]) {
		// Cell is selected and editable --> Draw text in white
		NSRect inset = cellFrame;
		inset.origin.x += 2;
		NSDictionary* oldAttrs = [[self attributedStringValue] attributesAtIndex:0
																	effectiveRange:NULL] ;
		NSMutableDictionary* newAttrs = [oldAttrs mutableCopy] ;
		[newAttrs setValue:[NSColor whiteColor]
					forKey:@"NSColor"] ;
		[[self stringValue] drawInRect:inset
						withAttributes:newAttrs] ;
		[newAttrs release] ;
	}
	else {
		// Cell is selected but not editable --> Draw nothing
		// The editable controls (popup button, date picker)
		// will be drawn in our rect.
	}
}


@end

@implementation SSYSmartHiliTableView

- (void)highlightSelectionInClipRect:(NSRect)clipRect {

	NSInteger selectedRow = [self selectedRow];
	if(selectedRow != -1) { 
		// A row is selected 

		[self lockFocus];
		
		// Get the appropriate color for the selected row
		NSColor* color ;
		if([self isTheActiveControl]) {
			color = [NSColor selectedTextBackgroundColor] ;
			// This is what is set in System Preferences
			//   > Appearance > Highlight Color (for selected text)
			color = [color colorTweakBrightness:-.20] ;
			// The -.2 factor was determined by reverse-engineering:
			// I set the color in System Preferences to RGB = {255, 0, 255},
			// but when I use DigitalColor Meter.app on a highlighted cell
			// in a "stock" NSTableView, I measure {204, 0, 204}.  Now,
			// 204=51*4 and 255=51*5.  So it looks like Apple decided to
			// reduce the brightness by 20%, because, of course, if someone
			// set their "highlight" (sic) color to all white, the white text
			// drawn on it by NSTextFieldCell would be invisible.
			
			// Interestingly, in NSTextViews (TextEdit docs, message in
			// Mail.app), the text is drawn in black instead of white, and
			// the 20% reduction is not applied.
		}
		else {
			color = [NSColor secondarySelectedControlColor] ;
		}
		color = [color colorUsingColorSpaceName:@"NSDeviceRGBColorSpace"] ;
		NSRect rect = [self rectOfRow:selectedRow] ;
		NSInteger i = 0 ;
		for (NSTableColumn* column in [self tableColumns]) {
			if ([column isEditable]) {
				rect = NSIntersectionRect(rect, [self rectOfColumn:i]) ;
			}
			i++ ;
		}
		
		if (
			(rect.size.width > 0.0)
			 &&
			 (rect.size.height > 0.0)
			) {
			[[NSGraphicsContext currentContext] setCompositingOperation:NSCompositeSourceOver] ; 
			[color set] ;
			[NSBezierPath fillRect:rect] ;
		}
		
		[self unlockFocus] ;
	}	
}


- (void)awakeFromNib {
	for (NSTableColumn* column in [self tableColumns]) {
		if (![column isEditable]) {
			NSFont* font = [[column dataCell] font] ;
			
			NSCell* newCell = [[[SmartHiliTextCell alloc] init] autorelease] ;
			[newCell setFont:font] ;
			[column setDataCell:newCell] ;
		}
	}
}

- (BOOL)becomeFirstResponder {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BkmxViewDidBecomeFirstResponder"
														object:self] ;
	return YES ;
}

- (BOOL)resignFirstResponder {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BkmxViewDidResignFirstResponder"
														object:self] ;
	return YES ;
}

@end