#import <Cocoa/Cocoa.h>


@interface SSDictionaryEntry : NSObject {
	NSMutableDictionary* _parent ;
	id _key ;
	id _value ;
}

@end

// Transforms a dictionary into an array of SSDictionaryEntrys
// Reverse transforms an array of SSDictionaryEntrys into a dictionary
@interface DicToReadableValuesArray : NSValueTransformer
@end

