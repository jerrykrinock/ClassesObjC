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

+ (NSArray*)weekdayChoices ;
+ (NSString*)displayStringForWeekday:(NSInteger)weekday ;
- (NSString*)displayWeekday ;
- (NSString*)displaySummary ;

@end
