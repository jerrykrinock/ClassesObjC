#import "SSMonthMatrix.h"
#import "SSUtilityCategories.h"
#import "SSYLocalize/NSString+Localize.h"

@implementation SSMonthMatrix

// Over-rides of NSMatrix methods
// The objectValue is an NSArray of NSNumbers of buttons which are pushed
//- (NSArray*)objectValue {
//	NSMutableArray* pushedButtonIndexes = [[NSMutableArray alloc] init] ;
//	NSEnumerator* e = [[self cells] reverseObjectEnumerator] ;
//	// We go in reverse because we first want to see if lastDayOfTheMonth is active
//	// because if it is, we filter out days 29, 30 and 31.
//	BOOL lastDayOfMonthActive = NO ;
//	NSCell* cell ;
//	while ((cell = [e nextObject])) {
//		if ([[cell objectValue] boolValue]) {
//			int intValue = ([cell tag] + _tagOffset) ;
//			if (intValue == 32) {
//				lastDayOfMonthActive = YES ;
//			}
//			if (!lastDayOfMonthActive || (intValue <= 28) || (intValue >= 32)) {
//				NSNumber* value = [NSNumber numberWithInt:intValue] ;
//				[pushedButtonIndexes addObject:value] ;
//			}
//		}
//	}
//	
//	NSArray* output = [[NSArray arrayWithArray:pushedButtonIndexes] arrayByReversingOrder] ;
//	// Note that we also re-reverse the array to get it back in normal order
//	[pushedButtonIndexes release] ;
//	return output ;			
//}

//- (void)setObjectValue:(NSArray*)pushedButtonIndexes {
//	[super setObjectValue:pushedButtonIndexes] ;
//	
//	int i ;
//	for (i=28; i<=31; i++) {
//		NSButtonCell* cell = [self cellWithTag:(i - _tagOffset)] ;
//		if (lastDayOfMonthActive) {
//			[cell setState:NSOffState] ;
//			[cell setEnabled:NO] ;
//		}
//		else {
//			[cell setEnabled:YES] ;
//		}
//	}
//}

- (id)initWithCoder:(NSCoder*)coder {
	if ((self = [super initWithCoder:coder])) {
		_tagOffset = 1 ; // Since cells start with 0 but months start with 1
	}
	
	return self ;
}

- (void)awakeFromNib {
	[self setToolTip:[NSString localize:@"lastDayOfTheMonth"] forCell:[self cellWithTag:(32 - _tagOffset)]] ;
	int i ;
	for (i=29; i<=31; i++) {
		NSButtonCell* cell = [self cellWithTag:(i - _tagOffset)] ;
		[self setToolTip:[NSString localize:@"warningWillRunOnLastDay"] forCell:cell] ;
	}
}

@end
