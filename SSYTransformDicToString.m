#import "SSYTransformDicToString.h"
#import "NSDictionary+Readable.h"


@implementation SSYTransformDicToString

+ (Class)transformedValueClass {
    return [NSString class] ;
}

+ (BOOL)allowsReverseTransformation {
    return NO ;
}

- (id)transformedValue:(id)dic {
	return [dic readable] ;
}

@end
