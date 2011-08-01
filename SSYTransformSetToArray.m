#import "SSYTransformSetToArray.h"


@implementation SSYTransformSetToArray

+ (Class)transformedValueClass {
    return [NSArray class] ;
}

+ (BOOL)allowsReverseTransformation {
    return YES ;
}

- (id)transformedValue:(id)set {
	return [set allObjects] ;
}

- (id)reverseTransformedValue:(id)array {
	return [NSSet setWithArray:array] ;
}

@end
