#import "SSYTransformNumberToString.h"

@implementation SSYTransformNumberToString

+ (Class)transformedValueClass {
    return [NSString class] ;
}

+ (BOOL)allowsReverseTransformation {
    return YES ;
}

- (id)transformedValue:(id)number {
	return [NSString stringWithFormat:@"%g", [number doubleValue]] ;
}

- (id)reverseTransformedValue:(id)string {
	return [NSNumber numberWithDouble:[string doubleValue]] ;
}
@end
