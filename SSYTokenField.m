#import "SSYTokenField.h"
#import "SSYTokenFieldCell.h"

/*
 @interface RedXView : NSView {
 }
 @end
  
@implementation RedXView  

- (void)drawRect:(NSRect)rect {
	NSRect frame = [self frame] ;
	NSBezierPath* bp = [NSBezierPath bezierPathWithRect:frame] ;
	[bp moveToPoint:frame.origin] ;
	[bp relativeLineToPoint:NSMakePoint(frame.size.width, frame.size.height)] ;
	[bp moveToPoint:NSMakePoint(frame.origin.x, frame.origin.y+frame.size.height)] ;
	[bp relativeLineToPoint:NSMakePoint(frame.size.width, -frame.size.height)] ;
	[bp setLineWidth:4.0] ;
	[[NSColor redColor] set] ;
	[bp stroke] ;
	[super drawRect:rect] ;
}
@end
*/

@interface SSYTokenField ()

@end

@implementation SSYTokenField

- (id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect] ;
	SSYTokenFieldCell* cell = [[SSYTokenFieldCell alloc] initTextCell:@""] ;
	[self setCell:cell] ;
	[cell release] ;
	return self ;
}

- (void)sizeToOneLine {
	NSRect frame = [self frame] ;
	[self sizeToFit] ;
	CGFloat height = [self frame].size.height ;
	
	[self setFrame:NSMakeRect(
							  frame.origin.x,
							  NSMidY(frame) - height/2,
							  frame.size.width,
							  height)] ;
}

/* 
 Bug: The following code does not work, because it never executes, because -setObjectValue:
 never executes in this method when invoked by bindings.  I think maybe it might work if it was moved in to 
 SSYTokenFieldCell, whose -setObjectValue: method does execute.
 */
- (void)sizeHeightToFit {
	NSArray* allTokens = [self objectValue] ;
	NSInteger allTokensCount = [allTokens count] ;
	CGFloat availableWidth = [self frame].size.width ;
	NSInteger nRows = 1 ;
	NSInteger startingToken = 0 ;
	NSInteger nTokensInThisRow = 0 ;
	NSInteger nTokensPlaced = 0 ;
	CGFloat height = 0.0 ;
	CGFloat totalHeightWithOneRow = 0.0 ;
	CGFloat tokenHeight = 0.0 ;
	CGFloat interrowSpace = 2.0 ; // Determined empirically
	while (nTokensPlaced < allTokensCount) {
		NSRange tokenRange = NSMakeRange(startingToken, nTokensInThisRow + 1) ;
		NSArray* currentRowTokens = [allTokens subarrayWithRange:tokenRange] ;
		if (!m_objectValueIsOk) {
			[self setObjectValue:currentRowTokens] ;
		}
		[self sizeToFit] ;
		if (totalHeightWithOneRow == 0.0) {
			totalHeightWithOneRow = [self frame].size.height ;
			tokenHeight = totalHeightWithOneRow - interrowSpace ;
			// Initial height: one token, plus space above, plus space below
			height = (tokenHeight + 2 * interrowSpace) ;
		}
		CGFloat requiredWidth = [self frame].size.width ;
		if (requiredWidth > availableWidth) {
			nRows++ ;
			if (nRows == 1) {
				// This would only happen if the first token by itself was too wide
				// to fit in a row, which would be very rare
				height += (tokenHeight + 2 * interrowSpace) ;
			}
			else {
				height += (tokenHeight + interrowSpace) ;
			}
            
            // Bug fix contributed by francesco-romano, 2012-07-07, supposedly
            // to keep this from becoming an infinite loop if token's required
            // width is larger than the availableWidth
            if (!nTokensInThisRow) {
               // This happens if one tag is too long to be added in one row,
                // so we want to add a row with a lone tag.  It will be
                // truncated by the NSTokenField. We now increase the height of
                // the field.
                height += (tokenHeight + interrowSpace) ;
                // The above counts another row for the too-long tag
                // We now count a fake row with one tag
                nRows++;
                nTokensInThisRow = 1;
                nTokensPlaced++;
            }
            
			startingToken = startingToken + nTokensInThisRow ;
			nTokensInThisRow = 0 ;
		}
		else {
			nTokensInThisRow++ ;
			nTokensPlaced++ ;
		}
	}
	
	[self setFrame:NSMakeRect(
							  [self frame].origin.x,
							  [self frame].origin.y,
							  availableWidth,
							  height
							  )] ;
	
	// Restore all tokens
	if (!m_objectValueIsOk) {
		[self setObjectValue:allTokens] ;
	}
}

- (void)setTokenizingCharacter:(unichar)tchar {
	// NSTokenFieldCell raises an exception if you set tokenizing
	// character set to {0}.  I've seen this happen in BookMacster
	// when a document is closing.  I'm not sure if it's due to
	// some other bug, but as defensive programming…
	if (tchar == 0) {
		return ;
	}
	
	[[self cell] setTokenizingCharacter:tchar] ;
}

- (unichar)tokenizingCharacter {
	return [[self cell] tokenizingCharacter] ;
}


@end