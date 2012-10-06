#import "SSYModelChangeTypes.h"

@implementation SSYModelChangeTypes

+ (BOOL)objectExistenceIsAffectedByChange:(SSYModelChangeAction)action {
	return (
			(action == SSYModelChangeActionReplace)
			|| (action == SSYModelChangeActionRemove)
			|| (action == SSYModelChangeActionMerge)
			|| (action == SSYModelChangeActionInsert)
			|| (action == SSYModelChangeActionCancel)
			) ;
}			

+ (BOOL)objectAttributesAreAffectedByChange:(SSYModelChangeAction)action {
	return (
			(action == SSYModelChangeActionMosh)
			|| (action == SSYModelChangeActionSlosh)
			|| (action == SSYModelChangeActionModify)
			|| (action == SSYModelChangeActionMove)
			|| (action == SSYModelChangeActionSlide)
			) ;
}			

+ (NSString*)symbolForAction:(SSYModelChangeAction)action {
    NSString* symbol = nil ;
	switch (action) {
		case SSYModelChangeActionInsert:
			symbol = @"+" ;  // I tried a circled + sign, \xe2\x8a\x95, but it was tiny and illegible at 11 pt.
			break;
		case SSYModelChangeActionModify:
			symbol = @"\u0394" ; // Greek letter Delta
			break;
		case SSYModelChangeActionSort:
			symbol = @"\u25B2" ; // Black up-pointing triangle
			break;
		case SSYModelChangeActionMosh:
			symbol = @"\u2723" ; // Four Balloon-spoked asterisk
			break;
		case SSYModelChangeActionSlosh:
			symbol = @"\u271B" ; // Open Centre Cross
			break;
		case SSYModelChangeActionSlide:
			symbol = @"\u2195" ; // Up-and-down arrow
			break;
		case SSYModelChangeActionMerge:
			symbol = @"\u2295" ;  // Circled Plus Sign
			break;
		case SSYModelChangeActionMove:
			symbol = @"\u2196" ;  // Arrow pointing up and left
			break;
		case SSYModelChangeActionReplace:
			symbol = @"\u21C5" ;  // Upwards arrow leftward of downwards arrow (two arrows) 
			break;
		case SSYModelChangeActionRemove:
			symbol = @"-" ;  // Circled - sign
			break;
		case SSYModelChangeActionUndefined:
			symbol = @"" ;  
			break;
		default:
            symbol = @"???" ;
			break;
	}

	return symbol ;
}

+ (NSString*)asciiNameForAction:(SSYModelChangeAction)action {
	switch (action) {
		case SSYModelChangeActionInsert:
			return @"INSERT" ;
			break;
		case SSYModelChangeActionModify:
			return @"MODIFY" ;
			break;
		case SSYModelChangeActionSort:
			return @"SORT" ;
			break;
		case SSYModelChangeActionMosh:
			return @"MOSH" ;
			break;
		case SSYModelChangeActionSlosh:
			return @"SLOSH" ;
			break;
		case SSYModelChangeActionSlide:
			return @"SLIDE" ;
			break;
		case SSYModelChangeActionMerge:
			return @"MERGE" ;
			break;
		case SSYModelChangeActionMove:
			return @"MOVE" ;
			break;
		case SSYModelChangeActionReplace:
			return @"REPLACE" ;
			break;
		case SSYModelChangeActionRemove:
			return @"REMOVE" ;
			break;
		case SSYModelChangeActionUndefined:
			return @"UNDEFINED" ;  
			break;
		default:
			break;
	}
	
	return @"???" ;
}

@end