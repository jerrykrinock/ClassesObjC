#import "SSYModelChangeTypes.h"

@implementation SSYModelChangeTypes

+ (NSString*)symbolForAction:(SSYModelChangeAction)action {
	switch (action) {
		case SSYModelChangeActionInsert:
			return @"+" ;  // I tried a circled + sign, \xe2\x8a\x95, but it was tiny and illegible at 11 pt.
			break;
		case SSYModelChangeActionModify:
			return @"\xce\x94" ; // Greek letter Delta
			break;
		case SSYModelChangeActionSort:
			return @"\xe2\x97\x83" ; // Right triangle
			break;
		case SSYModelChangeActionMosh:
			return @"\xe2\x9c\xa3" ; // Four Balloon-spoked asterisk
			break;
		case SSYModelChangeActionSlide:
			return @"\xe2\x86\x95" ; // Up-and-down arrow
			break;
		case SSYModelChangeActionMerge:
			return @"\xe2\x8a\x95" ;  // Circled Plus Sign
			break;
		case SSYModelChangeActionMove:
			return @"\xe2\x86\x96" ;  // Arrow pointing up and left
			break;
		case SSYModelChangeActionReplace:
			return @"\xe2\x87\xb5" ;  // Two arrows, pointing up and down 
			break;
		case SSYModelChangeActionRemove:
			return @"-" ;  // Circled - sign
			break;
		case SSYModelChangeActionUndefined:
			return @"" ;  
			break;
		default:
			break;
	}
	
	return @"???" ;
}

@end