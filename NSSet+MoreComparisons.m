#import "NSSet+MoreComparisons.h"


@implementation NSSet (MoreComparisons)

+ (BOOL)isEqualHandlesNilSet1:(NSSet*)set1
						 set2:(NSSet*)set2 {
	BOOL isEqual = YES ;
	if (set1) {
		if (!set2) {
			// Documentation for -isEqualToSet does not state if
			// the argument can be nil, so for safety I handle that
			// here, without invoking it.
			isEqual = NO ;
		}
		else {
			isEqual = [set1 isEqualToSet:set2] ;
		}
	}
	else if (set2) {
		// oldValue is nil but newValue is not
		isEqual = NO ;
	}
	
	return isEqual ;
}

@end

