#import "SSYRuntimeUtilities.h"


@implementation SSYRuntimeUtilities

+ (NSInteger)numberOfArgumentsInSelector:(SEL)selector {
	NSString* string = NSStringFromSelector(selector) ;
	NSScanner* scanner = [[NSScanner alloc] initWithString:string] ;
	NSInteger nColons = 0 ;
	do {
		[scanner scanUpToString:@":"
					 intoString:NULL] ;
		if ([scanner isAtEnd]) {
			break ;
		}
		else {
			nColons++ ;
			[scanner setScanLocation:[scanner scanLocation]+1] ;
		}
	} while (YES) ;
	[scanner release] ;
	return nColons ;
}


@end
