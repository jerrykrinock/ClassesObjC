#import "SSYEventInfo.h"


@implementation SSYEventInfo

+ (BOOL)alternateKeyDown {
	CGEventFlags modifiers  = (CGEventFlags)CGEventSourceFlagsState(kCGEventSourceStateCombinedSessionState) ;
	return  (modifiers & kCGEventFlagMaskAlternate) != 0 ;
}

+ (BOOL)shiftKeyDown {
	CGEventFlags modifiers  = (CGEventFlags)CGEventSourceFlagsState(kCGEventSourceStateCombinedSessionState) ;
	return  (modifiers & kCGEventFlagMaskShift) != 0 ;
}

@end
