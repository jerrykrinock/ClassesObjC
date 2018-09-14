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
		[choices addObject:[NSNumber numberWithInteger:i]] ;
	}
	[choices addObject:[NSNumber numberWithInteger:SSRecurringDateWildcard]] ;
	
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
		case 0:
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


- (BOOL)isEqual:(SSYRecurringDate*)otherDate {
	// It would be nice to add a 'tolerance' parameter to this, so that
	// you could see whether or not two recurring dates were the same
	// within "5 minutes" or whatever, but you'd have to consider the 
	// weekday and hour too in case they were near midnight or week-end.
	if ([self weekday] != [otherDate weekday]) {
		return NO ;
	}
	if ([self hour] != [otherDate hour]) {
		return NO ;
	}
	if ([self minute] != [otherDate minute]) {
		return NO ;
	}
	
	return YES ;
}

- (NSTimeInterval)timeIntervalToNextOccurrence {
    static NSCalendar* gregorianCalendar = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    });

    NSDateComponents* currentComponents = [gregorianCalendar components: NSCalendarUnitWeekday | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond
                                                               fromDate:[NSDate date]];
	/* Unfortunately, years ago, I defined my weekdays based on Sunday=0 but
     NSDateComponents defines based on Sunday=1.  So we must subtract 1. */
    NSInteger currentWeekday = currentComponents.weekday - 1;
    NSInteger currentSecondsInDay = 60*60*currentComponents.hour + 60*currentComponents.minute + currentComponents.second;
    NSInteger targetSecondsInDay = 60*60*self.hour + 60*self.minute;

    NSTimeInterval answer = targetSecondsInDay - currentSecondsInDay;

    if (answer < 0) {
        NSInteger daysToAdd;
        if (self.weekday == SSRecurringDateWildcard) {
            daysToAdd = 1;
        } else {
            daysToAdd = self.weekday - currentWeekday;
            if (daysToAdd < 1) {
                daysToAdd += 7;
            }
        }
        answer += daysToAdd*24*60*60;
    }

    return answer;
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
