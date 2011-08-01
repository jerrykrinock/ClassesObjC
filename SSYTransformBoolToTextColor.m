#import "SSYTransformBoolToTextColor.h"


@implementation SSYTransformBoolToTextColor

+ (Class)transformedValueClass {
    return [NSColor class] ;
}

+ (BOOL)allowsReverseTransformation {
    return NO ;
}

- (id)transformedValue:(id)enabled {
	if ([enabled boolValue]) {
		return [NSColor textColor] ;
	}
	else {
		return [NSColor disabledControlTextColor] ;
		//return [NSColor colorWithCalibratedWhite:0.2 alpha:1.0] ;
	}
}

@end
