#import "SSYEventInfo.h"


@implementation SSYEventInfo

+ (BOOL)alternateKeyDown {
	NSUInteger modifiers  = CGEventSourceFlagsState(kCGEventSourceStateCombinedSessionState) ;	
	return  (modifiers & kCGEventFlagMaskAlternate) != 0 ;
}

+ (BOOL)shiftKeyDown {
	NSUInteger modifiers  = CGEventSourceFlagsState(kCGEventSourceStateCombinedSessionState) ;	
	return  (modifiers & kCGEventFlagMaskShift) != 0 ;
}

@end
