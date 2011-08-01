#import <Cocoa/Cocoa.h>
#import "SSAppGlobals.h"

enum SSWhichCrontab {
	SSSystemCrontab, 
	SSUserCrontab 
} ;

//enum SSCronHoursMask {
//	SSMaskNoHour = 0 ,
//	SSMaskEveryHour =  0x00ffffff
//	// To indicate any hour, shift the number 1 left by the hour.
//	// Example, for hour 0, so the SSDateOfMonth would be 1 << 0 = 0x1
//} ;
//
//// Named day of week
//enum SSCronDaysMask {
//	SSMaskNoDay = 0 ,
//	SSMaskSunday = 1 ,
//	SSMaskMonday = 2 ,
//	SSMaskTuesday = 4 ,
//	SSMaskWednesday = 8 ,
//	SSMaskThursday = 16 ,
//	SSMaskFriday = 32 ,
//	SSMaskSaturday = 64 , 
//	SSMaskWeekdays = 0x3E ,
//	SSMaskEveryDay =  0x7F
//} ;
//
//// Numbered date of month
//enum SSCronDatesMask {
//	SSMaskNoDate = 0 ,
//	SSMaskEveryDate =  0xfffffffe
//	// To indicate any day, shift the number 1 left by the date.
//	// Example, for September 4, date = 4, so the SSDateOfMonth would be 1 << 4
//	// Note that the least significant bit is never used.
//} ;
//
//enum SSCronMonthsMask {
//	SSMaskNoMonth = 0 ,
//	SSMaskEveryMonth =  0x00001ffe
//	// To indicate any month, shift the number 1 left by the date.
//	// Example, for September 4, date = 4, so the SSDateOfMonth would be 1 << 4
//	// Note that the least significant bit is never used.
//} ;
//
//typedef int unsigned SSCronMask ;

NSString* SSLocalizedDayOfWeekFromCronNumber(int n) ;
NSArray* SSLocalizedDaysOfWeekFromCronNumbers(NSArray* numbers) ;

@interface SSCronJob : NSObject
{
	NSString* _commentOut ;
		// if _commentOut is nil, job will be enabled
		// else, job will be disabled by commenting out with the prefix field "#_commentOut\t"
		// When reading crontab files, whitespace will be trimmed from ends of _commentOut
	NSArray* _minutes ;
	NSArray* _hours ;
	NSArray* _days ;
	NSArray* _dates ;
	NSArray* _months ;
	NSString* _user ;
	NSString* _directory ;
	NSString* _filename ;
} ;

SSAOh(NSString*,commentOut, setCommentOut)
SSAOh(NSArray*, minutes, setMinutes)
SSAOh(NSArray*, hours, setHours)
SSAOh(NSArray*, days, setDays)
SSAOh(NSArray*, dates, setDates)
SSAOh(NSArray*, months, setMonths)
SSAOh(NSString*, user, setUser)
SSAOh(NSString*, directory, setDirectory)
SSAOh(NSString*, filename, setFilename)

+ (NSArray*)readCronJobsFromWhichCrontab:(enum SSWhichCrontab)which user:(NSString*)user ;
- (void)appendToFileWhichCrontab:(enum SSWhichCrontab)which ;

@end