#import "SSYSheetEnder.h"


@implementation SSYSheetEnder

+ (void)didEndGenericSheet:(NSWindow*)sheet
				returnCode:(NSInteger)returnCode
	   retainedInvocations:(NSArray*)invocations {
	[sheet orderOut:self] ;
	NSInvocation* invocation = nil ;
	
	switch (returnCode) {
		case NSAlertFirstButtonReturn:
			if ([invocations count] > 0) {
				invocation = [invocations objectAtIndex:0] ;
			}
			break ;
		case NSAlertSecondButtonReturn:
			if ([invocations count] > 1) {
				invocation = [invocations objectAtIndex:1] ;
			}
			break ;
		case NSAlertThirdButtonReturn:
			if ([invocations count] > 2) {
				invocation = [invocations objectAtIndex:2] ;
			}
			break ;
	}
	
	[invocation retain] ;
	
	// Release 'invocations' which the caller was assumed to have retained.
	[invocations release] ;
	if ([invocation respondsToSelector:@selector(invoke)]) {
		[invocation invoke] ;
	}
	else {
		// Assume invocation is an NSNull
	}
	[invocation autorelease] ;
}

@end