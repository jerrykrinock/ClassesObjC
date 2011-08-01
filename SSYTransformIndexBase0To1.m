#import "SSYTransformIndexBase0To1.h"


@implementation SSYTransformIndexBase0To1

+ (Class)transformedValueClass {
    return [NSNumber class] ;
}

+ (BOOL)allowsReverseTransformation {
    return YES ;
}

- (id)transformedValue:(id)numberBase0 {
	return [NSNumber numberWithInteger:([numberBase0 integerValue] + 1)] ;
}

- (id)reverseTransformedValue:(id)numberBase1 {
	return [NSNumber numberWithInteger:([numberBase1 integerValue] - 1)] ;
}

@end
