#import <Cocoa/Cocoa.h>

#define SSRecurringDateWildcard 0x7fff

// Keys to instance variables

extern NSString* const constKeyWeekday ;
extern NSString* const constKeyHour ;
extern NSString* const constKeyMinute ;

/*!
 @brief    

 @details  Use the constant NSUndefinedDateComponent to
 indicate "any" or "every".
*/
@interface SSYRecurringDate : NSObject <NSCoding, NSCopying> {
	NSInteger weekday ;
	NSInteger hour ;
	NSInteger minute ;
}

@property (assign) NSInteger weekday ;
@property (assign) NSInteger hour ;
@property (assign) NSInteger minute ;

/*!
 @details   If you are deploying to macOS 10.14+ or iOS 10+, and are using
 this to set a timer for an alarm of some kind, consider using
 UNCalendarNotificationTrigger instead.
 */
@property (readonly) NSTimeInterval timeIntervalToNextOccurrence;

+ (NSArray*)weekdayChoices ;
+ (NSString*)displayStringForWeekday:(NSInteger)weekday ;
- (NSString*)displayWeekday ;
- (NSString*)displaySummary ;

@end

#if 0

/* TEST CODE */

#import "SSYRecurringDate.h"

- (void)testRecurringDate:(SSYRecurringDate*)rd {
    NSTimeInterval ti = [rd timeIntervalToNextOccurrence];
    NSDate* nd = [NSDate dateWithTimeIntervalSinceNow:ti];
    NSLog(@"%@ : %@  (in %0.1f minutes)", [rd displaySummary], [nd geekDateTimeString], ti / 60);
}

SSYRecurringDate* rd = [SSYRecurringDate new];

rd.weekday = 3;
rd.hour = 5;
rd.minute = 00;
[self testRecurringDate:rd];
rd.hour = 10;
rd.minute = 21;
[self testRecurringDate:rd];
rd.weekday = SSRecurringDateWildcard;
[self testRecurringDate:rd];
rd.hour = 5;
rd.minute = 00;
[self testRecurringDate:rd];
rd.weekday = 3;
[self testRecurringDate:rd];
rd.weekday = 0;
[self testRecurringDate:rd];
rd.weekday = 6;
[self testRecurringDate:rd];

#endif
