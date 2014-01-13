#import "SSYNull.h"


@implementation SSYNull

- (id)valueForUndefinedKey:(NSString *)key {
	return nil ;
}

@end