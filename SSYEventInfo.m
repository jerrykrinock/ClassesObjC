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

+ (BOOL)commandKeyDown {
    CGEventFlags modifiers  = (CGEventFlags)CGEventSourceFlagsState(kCGEventSourceStateCombinedSessionState) ;
    return  (modifiers & kCGEventFlagMaskCommand) != 0 ;
}

+ (BOOL)controlKeyDown {
    CGEventFlags modifiers  = (CGEventFlags)CGEventSourceFlagsState(kCGEventSourceStateCombinedSessionState) ;
    return  (modifiers & kCGEventFlagMaskControl) != 0 ;
}

@end
