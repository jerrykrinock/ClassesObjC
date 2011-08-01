#import "SSMatrixButtons.h"

@implementation SSMatrixButtons

SSANm(int, tagOffset, setTagOffset)

// Over-rides of NSMatrix methods
// The objectValue is an NSArray of NSNumbers of buttons which are pushed

- (NSArray*)objectValue {
	NSMutableArray* pushedButtonIndexes = [[NSMutableArray alloc] init] ;
	NSEnumerator* e = [[self cells] objectEnumerator] ;
	NSCell* cell ;
	while ((cell = [e nextObject])) {
		if ([[cell objectValue] boolValue]) {
			NSNumber* value = [NSNumber numberWithInt:([cell tag] + _tagOffset)] ;
			[pushedButtonIndexes addObject:value] ;
		}
	}
	
	NSArray* output = [pushedButtonIndexes copy] ;
	[pushedButtonIndexes release] ;
	return [output autorelease] ;			
}

- (void)setObjectValue:(NSArray*)pushedButtonIndexes {
	NSEnumerator* e = [[self cells] objectEnumerator] ;
	NSCell* cell ;
	while ((cell = [e nextObject])) {
		NSNumber* cellKey = [NSNumber numberWithInt:([cell tag] + _tagOffset)] ;
		BOOL active = ([pushedButtonIndexes indexOfObject:cellKey] != NSNotFound) ;
		NSNumber* value = [NSNumber numberWithBool:active] ;
		[cell setObjectValue:value] ;
	}
}

- (id)initWithCoder:(NSCoder*)coder {
	if ((self = [super initWithCoder:coder])) {
		_tagOffset = 0 ;
	}
	
	return self ;
}

@end
