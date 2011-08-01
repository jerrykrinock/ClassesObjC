#import "SSYRecurringDate.h"
#import "NSString+LocalizeSSY.h"
#import "NSDate+Components.h"

NSString* const constKeyWeekday = @"weekday" ;
NSString* const constKeyHour = @"hour" ;
NSString* const constKeyMinute = @"minute" ;

@implementation SSYRecurringDate

@synthesize weekday ;
@synthesize hour ;
@synthesize minute ;

+ (NSArray*)weekdayChoices {
	NSInteger i ;
	NSMutableArray* choices = [[NSMutableArray alloc] init] ;
	
	for (i=0; i<7; i++) {
		[choices addObject:[NSNumber numberWithInt:i]] ;
	}
	[choices addObject:[NSNumber numberWithInt:SSRecurringDateWildcard]] ;
	
	NSArray* answer = [NSArray arrayWithArray:choices] ;
	[choices release] ;
	
	return answer ;
}

+ (NSString*)displayStringForWeekday:(NSInteger)weekday {
	NSString* day = nil ;
	NSString* key ;
	switch (weekday) {
		case 1:
			day = @"Mon" ;
			break;
		case 2:
			day = @"Tue" ;
			break;
		case 3:
			day = @"Wed" ;
			break;
		case 4:
			day = @"Thu" ;
			break;
		case 5:
			day = @"Fri" ;
			break;
		case 6:
			day = @"Sat" ;
			break;
		case SSRecurringDateWildcard:
			key = @"everyDay" ;
			break ;
		default:
			day = @"Sun" ;
			break;
	}
	
	if (day) {
		key = [@"weekday" stringByAppendingString:day] ;
	}
	
	return [NSString localize:key] ;
}

- (NSString*)displayWeekday {
	return [[self class] displayStringForWeekday:[self weekday]] ;
}

- (NSString*)displayTime {	
	NSDate* ourDate = [NSDate dateWithYear:NSNotFound
									 month:NSNotFound
									   day:NSNotFound
									  hour:[self hour]
									minute:[self minute]
									second:NSNotFound
							timeZoneOffset:NSNotFound] ;
	
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init]  autorelease] ;

	// Format it to the user's preferences
	[dateFormatter setDateStyle:NSDateFormatterNoStyle] ;  // Do not show date
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle] ;  // Do show time
	NSString* displayTime = [dateFormatter stringFromDate:ourDate] ;
	
	return displayTime ;
}

- (NSString*)displaySummary {
	NSString* answer = [NSString localizeFormat:
						@"dateDayTime",
						[self displayWeekday],
						[self displayTime]] ;
	
	return answer ;						
}

- (NSString*)description {
	return [NSString stringWithFormat:
			@"%@ <%p> d=%@ t=%@",
			[self class],
			self,
			[self displayWeekday],
			[self displayTime]] ;
}


#pragma mark * NSCoding Protocol Conformance

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeInteger:weekday forKey:constKeyWeekday] ;
	[encoder encodeInteger:hour forKey:constKeyHour] ;
	[encoder encodeInteger:minute forKey:constKeyMinute] ;
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super init] ;
	
	if (self) {
		weekday = [decoder decodeIntegerForKey:constKeyWeekday] ;
		hour = [decoder decodeIntegerForKey:constKeyHour] ;
		minute = [decoder decodeIntegerForKey:constKeyMinute] ;
	}
	
	return self ;
}


#pragma mark * NSCopying Protocol Conformance

- (id)copyWithZone:(NSZone *)zone {
    SSYRecurringDate* copy = [[SSYRecurringDate allocWithZone: zone] init] ;
	[copy setWeekday:[self weekday]] ;
	[copy setHour:[self hour]] ;
	[copy setMinute:[self minute]] ;
	
    return copy ;
}


@end