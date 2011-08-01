#import "SSYTokenField.h"
#import "SSYTokenFieldCell.h"
#import "NSArray+CountedSet.h"
#import "NSSet+CountedSet.h"

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
	[self lockFocus] ;
	[bp setLineWidth:4.0] ;
	[[NSColor redColor] set] ;
	[bp stroke] ;
	[self unlockFocus] ;
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

- (void)setObjectValue:(NSObject <NSFastEnumeration> *)tokens {
	if ([tokens respondsToSelector:@selector(objectAtIndex:)]) {
		// tokens is a NSArray
		tokens = [(NSArray*)tokens countedSet] ;
	}
	else if ([tokens respondsToSelector:@selector(countForObject:)]) {
		tokens = [(NSSet*)tokens countedSet] ;
	}
	
	// tokens is now a NSCountedSet
	NSArray* sortedStrings = [[(NSCountedSet*)tokens allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] ;
	NSMutableArray* stringsWithCounts = [[NSMutableArray alloc] initWithCapacity:[(NSSet*)tokens count]] ;
	for (NSString* string in sortedStrings) {
		NSString* stringWithCount = [NSString stringWithFormat:
						@"%@ [%d]",
						string,
						[(NSCountedSet*)tokens countForObject:string]] ;
		[stringsWithCounts addObject:stringWithCount] ;
	}
	
	NSArray* stringsToDisplay = [[stringsWithCounts copy] autorelease] ;
	[stringsWithCounts release] ;
	
	// super wants objectValue to be an NSArray
	[super setObjectValue:stringsToDisplay] ;
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
	CGFloat tokenHeight ;
	CGFloat interrowSpace = 2.0 ; // Determined empirically
	while (nTokensPlaced < allTokensCount) {
		NSRange tokenRange = NSMakeRange(startingToken, nTokensInThisRow + 1) ;
		NSArray* currentRowTokens = [allTokens subarrayWithRange:tokenRange] ;
		[self setObjectValue:currentRowTokens] ;
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
	[self setObjectValue:allTokens] ;
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

- (void)setNoTokensPlaceholder:(NSString*)placeholder {
	[[self cell] setNoTokensPlaceholder:placeholder] ;
}

- (void)setMultipleValuesPlaceholder:(NSString*)placeholder {
	[[self cell] setMultipleValuesPlaceholder:placeholder] ;
}

- (void)setNotApplicablePlaceholder:(NSString*)placeholder {
	[[self cell] setNotApplicablePlaceholder:placeholder] ;
}

- (void)setNoSelectionPlaceholder:(NSString*)placeholder {
	[[self cell] setNoSelectionPlaceholder:placeholder] ;
}

@end