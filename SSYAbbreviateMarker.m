#import "SSYAbbreviateMarker.h"


@implementation SSYAbbreviateMarker

+ (Class)transformedValueClass {
    return [NSString class] ;
}

+ (BOOL)allowsReverseTransformation {
    return NO ;
}

- (id)transformedValue:(id)value {
	id answer = value ;
	
	if ((!value) || value == NSNoSelectionMarker) {
		answer = @"\xe2\x80\x94" ;  // em dash
	}
	if (value == NSMultipleValuesMarker) {
		answer = @"\xe2\x80\xa2\xe2\x80\xa2\xe2\x80\xa2" ;  // three bullets
	}
	else if (value == NSNotApplicableMarker) {
		answer = @"\xe2\x92\x96" ;  // a thick "X"
	}

	return answer ;
}

@end
