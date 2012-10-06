/*

 The cron utility uses two different types of configuration files called "crontabs": "system" and "user".
 
 system crontab
    There is only one such file
    is in /private/etc/crontab (aka /etc/crontab)
 
 user crontabs
	Each user, including root, may or may not have one.
    are in /private/var/cron/tabs/aName (aka /var/cron/tabs/aName)
    aName of each file is the short name of the user who created it
 
 The system crontab [has] the ability to run commands as any user. In a user crontab, commands run as the user who created the crontab; this is an important security feature.
 
 Note: User crontabs allow individual users to schedule tasks without the need for root privileges. Commands in a user's crontab run with the permissions of the user who owns the crontab.
 
 The root user can have a user crontab just like any other user. This one is different from /etc/crontab (the system crontab). Because of the system crontab, there is usually no need to create a user crontab for root.

*/


#import "SSAuthorizationTool.h"
#import "SSAuthorizedFunctions.h"
#import "SSAuthorizedTool.h"
#import "SSAppGlobals.h"
#import "SSUtils.h"
#import "SSCronJob.h"
#import "SSUtilityCategories.h"

// globals
extern NSInteger gLogging ;

NSString* SSLocalizedDayOfWeekFromCronNumber(NSInteger n) {
NSString* dayName = nil ;
	switch (n) {
		case 0:
		case 7:
			dayName = @"weekdaySun" ;
			break;
		case 1:
			dayName = @"weekdayMon" ;
			break;
		case 2:
			dayName = @"weekdayTue" ;
			break;
		case 3:
			dayName = @"weekdayWed" ;
			break;
		case 4:
			dayName = @"weekdayThu" ;
			break;
		case 5:
			dayName = @"weekdayFri" ;
			break;
		case 6:
			dayName = @"weekdaySat" ;
	}

	return [NSString localize:dayName] ;
}
	
	
NSArray* SSLocalizedDaysOfWeekFromCronNumbers(NSArray* numbers) {
	NSMutableArray* days = [[NSMutableArray alloc] init] ;
	NSEnumerator* e = [numbers objectEnumerator] ;
	NSNumber* number ;
	while ((number = [e nextObject])) {
		NSInteger dayNumber = [number integerValue] ;
		NSString* dayName = SSLocalizedDayOfWeekFromCronNumber(dayNumber) ;
		[days addObject:dayName] ;
	}

	NSArray* output = [days copy] ;
	[days release] ;
	return [output autorelease] ;
}

NSString* SSReadUserCrontabForCurrentUser() {
    NSArray* args = [NSArray arrayWithObject:@"-l"] ;
    NSData* cronData ;
	NSData* stdErrData ;
	
	NSInteger taskResult = SSDoShellTask(@"/usr/bin/crontab", args, nil, nil, &cronData, &stdErrData, YES) ;
    
    NSString* stdErrString = [[NSString alloc] initWithData:stdErrData encoding:[NSString defaultCStringEncoding]] ;	
    // Check for "no crontab for" in stderr, and if so over-ride the taskResult to OK, since it
    // is OK if the user does not have a crontab yet.
    if ( [stdErrString isLike: @"*no crontab for*" ] ) {
        taskResult = 0; // 0=OK
	}
	else if ([stdErrString length] > 0) {
		NSLog(@"SSReadUserCrontabForCurrentUser read crontab, got stderr: \"%@\"", stdErrString) ;
	}
	[stdErrString release] ;
	
    NSString* crontabString = [[NSString alloc] initWithData:cronData encoding:[NSString defaultCStringEncoding]] ;
	SSLog(5, "got user crontabString:%@", crontabString) ;
	return [crontabString autorelease] ;
}

NSString* SSReadSystemCrontab() {
    NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath: @"/etc/crontab"] ;
    NSData *data ;
	NSString* string ;
    if (fh) {
        data = [fh readDataToEndOfFile] ;
		string = [[NSString alloc] initWithData:data encoding:[NSString defaultCStringEncoding]] ;
	}
	return [string autorelease] ;
}

@implementation SSCronJob

SSAOm(NSString*, commentOut, setCommentOut)
SSAOm(NSArray*, minutes, setMinutes)
SSAOm(NSArray*, hours, setHours)
SSAOm(NSArray*, days, setDays)
SSAOm(NSArray*, dates, setDates)
SSAOm(NSArray*, months, setMonths)
SSAOm(NSString*, user, setUser)
SSAOm(NSString*, directory, setDirectory)
SSAOm(NSString*, filename, setFilename)


// Methods for parsing crontab numeric fields
// Base Method
// if no numbers or indicators found in field, returns empty array
// if wildcard * is found, returns an array containing one object, the string @"*"
// If array cannot be parsed, returns nil
- (NSArray*)arrayFromCrontabField:(NSString*)field {
	NSMutableArray* array = [[NSMutableArray alloc] init] ;
	
	NSException* exception = [NSException
						exceptionWithName:@"parse error"
								   reason:@"can't parse"
								 userInfo:nil] ;
	
	NS_DURING
		if ([field rangeOfString:@"*"].location != NSNotFound) {
			// field contains the wildcard "*"
			[array addObject:@"*"] ;
		}
		else {
			NSArray* clauses = [field componentsSeparatedByString:@","] ;
			NSEnumerator* e = [clauses objectEnumerator] ;
			NSString* clause ;
			while ((clause = [e nextObject]))
			{
				NSRange stepValue = [clause rangeOfString:@"/"] ;
				if (stepValue.location != NSNotFound) {
					// We don't support step values
					[exception raise] ;
				}
				
				NSRange dash = [clause rangeOfString:@"-"] ; 
				if (dash.location == NSNotFound) {
					// This is a single value
					[array addObject:[NSNumber numberWithInteger:[clause integerValue]]] ;
				}
				else {
					// This is a range, such as "1-5"
					NSRange lowerLimitRange, upperLimitRange ;
					lowerLimitRange.location = 0 ;
					lowerLimitRange.length = dash.location ;
					upperLimitRange.location = dash.location + 1 ;
					upperLimitRange.length = [clause length] - 1 - lowerLimitRange.length ;
					NSInteger lowerLimit = [[clause substringWithRange:lowerLimitRange] integerValue] ;
					NSInteger upperLimit = [[clause substringWithRange:upperLimitRange] integerValue] ;
					NSInteger i ;
					for (i=lowerLimit; i<=upperLimit; i++) {
						[array addObject:[NSNumber numberWithInteger:i]] ;
					}
				}
			}
		}

	NS_HANDLER
		[array release] ;
		array = nil ;
	NS_ENDHANDLER
	
	NSArray* output = [array copy] ;
	[array release] ;
	return [output autorelease] ;
}

// Specialized Methods
// If the field cannot be parsed, these methods will set the subject instance variable
// to nil and return NO.  If all goes well, they return YES
- (BOOL)setMinutesFromCronField:(NSString*)field {
	NSArray* array = [self arrayFromCrontabField:field] ;
	
	BOOL ok = YES;
	if (!array) {
		ok = NO ;
	}
	else if (([array count] ==1) && ([[array objectAtIndex:0] isEqual:@"*"])) {
		array = [NSArray arrayOfIntegersStartingWith:0 endingWith:59] ;
	}
	
	[self setMinutes:array] ;
	return ok ;
}

- (BOOL)setHoursFromCronField:(NSString*)field {
	NSArray* array = [self arrayFromCrontabField:field] ;
	
	BOOL ok = YES;
	if (!array) {
		ok = NO ;
	}
	else if (([array count] ==1) && ([[array objectAtIndex:0] isEqual:@"*"])) {
		array = [NSArray arrayOfIntegersStartingWith:0 endingWith:23] ;
	}
	
	[self setHours:array] ;
	return ok ;
}

- (BOOL)setDaysFromCronField:(NSString*)field {
	NSArray* array = [self arrayFromCrontabField:field] ;
	NSNumber* o7 = [NSNumber numberWithInteger:7] ;
	
	BOOL ok = YES;
	if (!array) {
		ok = NO ;
	}
	else if (([array count] ==1) && ([[array objectAtIndex:0] isEqual:@"*"])) {
		array = [NSArray arrayOfIntegersStartingWith:0 endingWith:6] ;
	}
	else if ([array indexOfObject:o7] != NSNotFound) { // If someone used 7 for Sunday
		NSMutableArray* mutableArray = [array mutableCopy] ;
		[mutableArray removeObject:o7] ;  // remove the 7
		[mutableArray insertObject:[NSNumber numberWithInteger:0] atIndex:0] ; // add in 0 to replace it
		array = [[mutableArray copy] autorelease] ;
		[mutableArray release] ;
	}
	
	[self setDays:array] ;
	return ok ;
}

- (BOOL)setDatesFromCronField:(NSString*)field {
	NSArray* array = [self arrayFromCrontabField:field] ;
	
	BOOL ok = YES;
	if (!array) {
		ok = NO ;
	}
	else if (([array count] ==1) && ([[array objectAtIndex:0] isEqual:@"*"])) {
		array = [NSArray arrayOfIntegersStartingWith:0 endingWith:31] ;
	}
	
	[self setDates:array] ;
	return ok ;
}

- (BOOL)setMonthsFromCronField:(NSString*)field {
	NSArray* array = [self arrayFromCrontabField:field] ;
	
	BOOL ok = YES ;
	if (!array) {
		ok = NO ;
	}
	else if (([array count] ==1) && ([[array objectAtIndex:0] isEqual:@"*"])) {
		array = [NSArray arrayOfIntegersStartingWith:1 endingWith:12] ;
	}
	
	[self setMonths:array] ;
	return ok ;
}

// Methods for generating crontab numeric fields
// Base Method
- (NSString*)crontabFieldFromArray:(NSArray*)array
{
	NSMutableString* field = [[NSMutableString alloc] init] ;
	BOOL firstEntry = YES ;
	
	NSEnumerator* e = [array objectEnumerator] ;
	NSNumber* number ;
	while ((number = [e nextObject])) {
		if (!firstEntry)
			[field appendString:@","] ;
		[field appendString:[number stringValue]] ;
		firstEntry = NO ;
	}
		
	NSArray* output = [array copy] ;
	[array release] ;
	return [output autorelease] ;
}

// Specialized Methods
- (NSString*)crontabMinutesField {
	return [self crontabFieldFromArray:[self minutes]] ;
}

- (NSString*)crontabHoursField {
	return [self crontabFieldFromArray:[self hours]] ;
}

- (NSString*)crontabDaysField {
	return [self crontabFieldFromArray:[self days]] ;
}

- (NSString*)crontabDatesField {
	return [self crontabFieldFromArray:[self dates]] ;
}

- (NSString*)crontabMonthsField {
	return [self crontabFieldFromArray:[self months]] ;
}

- (NSString*)description {
	return [NSString stringWithFormat:@"SSCronJob:\n    minutes: %@ (%@)\n     hours: %@ (%@)\n      days: %@ (%@)\n     dates: %@ (%@)\n    months: %@ (%@)\ncommentOut: %@\n      user: %@\n directory: %@\n  filename: %@", 
		  [self crontabMinutesField], [self minutes],
		  [self crontabHoursField], [self hours],
		  [self crontabDaysField], [self days],
		  [self crontabDatesField], [self dates],
		  [self crontabMonthsField], [self months],
		  [self commentOut] ,
		  [self user] ,
		  [self directory],
		  [self filename] ] ;
}

- (void)appendToFileWhichCrontab:(enum SSWhichCrontab)which ;
// Appends this cron job to the desired crontab
// if which=NSUserCrontab, appends to crontab of current user
{	
	// Part 1.  Generate ourNewLine
	NSString* ourNewLine = [NSString stringWithFormat:@"\n%@\t%@\t%@\t%@\t%@",
		[self crontabMinutesField],
		[self crontabHoursField],
		[self crontabDatesField],
		[self crontabMonthsField],
		[self crontabDaysField] ] ;
	if (which == SSSystemCrontab) {
		ourNewLine = [ourNewLine stringByAppendingFormat:@"\t%@", [self user]] ;
	}
	NSString* command = [[self directory] stringByAppendingPathComponent:[self filename]] ;
	ourNewLine = [ourNewLine stringByAppendingFormat:@"\t%@", command] ;
	
	NSString* commentOut = [self commentOut] ;
	if (commentOut) {
		NSString* commentField = [NSString stringWithFormat:@"#%@\t", commentOut] ;
		ourNewLine = [commentField stringByAppendingString:ourNewLine] ;
	}
	
	// Part 2.  Read the existing crontab string from file
	NSString* existingCrontabString ;
	if (which == SSUserCrontab) {
		existingCrontabString = SSReadUserCrontabForCurrentUser() ;
	}
	else {
		existingCrontabString = SSReadSystemCrontab() ;
	}

	// Part 3.  Since we don't know who was there last, clean it up by trimming whitespace
	// and newlines from both ends, then add ONE newline at the end.
	existingCrontabString = [existingCrontabString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ;
	existingCrontabString = [existingCrontabString stringByAppendingString:@"\n"] ;
	
	// Part 4.  Generate newCrontabData to be written to file
	NSString* newCrontabString = [existingCrontabString stringByAppendingString: ourNewLine] ;
	NSData* newCrontabData = [newCrontabString dataUsingEncoding:[NSString defaultCStringEncoding]] ;
	    
    // Part 5.  Write to file
	NSInteger err ;
	if (which == SSUserCrontab) {
		NSArray* args = [NSArray arrayWithObjects: @"-", nil] ;
			// The argument "-" tells crontab to take data from stdin
		NSData* stdErrData ;
		
		err = SSDoShellTask(@"usr/bin/crontab", args, nil, newCrontabData, nil, &stdErrData, YES) ;
		if (err) {
			NSLog(@"Error %li writing user crontab", (long)err) ;
		}
	}
	else {
		if (!SSAuthorizedWriteDataToFile(newCrontabData, @"/etc/crontab")) {
l			NSLog(@"Error %li writing system crontab", (long)err) ;
		}
	}
}

+ (NSArray*)readCronJobsFromWhichCrontab:(enum SSWhichCrontab)which user:(NSString*)user {
	// if which==SSUserCrontab, will ignore user field and return jobs in current user's crontab
	// if which==SSSytemCrontab && user==nil, will return all jobs in system crontab 
	// The returned value may contain SSCronJobs and/or NSStrings.
	// An attempt will be made to parse each line in the crontab
	// If a line can be parsed, an SSCronJob will be created and added to the returned array.
	// If a line cannot be parsed, the line itself, as an NSString with no trailing \n, will be added to the returned array.
	NSString* crontabString ;
	if (which == SSUserCrontab) {
		if (![user isEqualToString:NSUserName()]) {
			NSLog(@"WARNING!! readCronJobsFromWhichFile:SSUserCrontab can only get crontab for current user!") ;
		}		
		crontabString = SSReadUserCrontabForCurrentUser() ;
	}
	else {
		crontabString = SSReadSystemCrontab() ;
	}
	NSMutableArray* jobs = [[NSMutableArray alloc] init] ;
	
	if (crontabString) {
		NSMutableArray* cronLines = [[crontabString componentsSeparatedByString: @"\n"] mutableCopy] ;
		
		NSEnumerator* e = [cronLines objectEnumerator] ;
		NSString* cronLine ;
		while ((cronLine = [e nextObject])) {
			NSException* exception = [NSException
						exceptionWithName:@"parse error"
								   reason:@"can't parse"
								 userInfo:nil];
			SSCronJob* job ;
			NS_DURING
				// Break up into its tab-delimited fields
				cronLine = [cronLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] ;
				NSArray* cronJobFields = [cronLine componentsSeparatedByString:@"\t"] ;

				SSLog(5, "cronJobFields:\n%@", cronJobFields) ;
				// Reasons why I start from the last field instead of the first:
				//    There may or may not be comment field at the beginning
				//    Get command and user quicker, needed to see if cronLine qualifies
				NSInteger i = [cronJobFields count] ;

				// First, we make sure it is a "well-formed" line so we don't crash
				if ((which == SSUserCrontab) && (i != 6)) {
					[exception raise] ;
				}
				if ((which == SSSystemCrontab) && (i != 7)) {
					[exception raise] ;
				}	

				i-- ; // start at last field
				NSString* command = [cronJobFields objectAtIndex:i--] ;
				NSString* aDirectory = [command stringByDeletingLastPathComponent] ;
				// System crontab has a "user" field, but User crontab omits this field
				NSString* aUser ;
				if (which == SSSystemCrontab) {
					aUser = [cronJobFields objectAtIndex:i--] ;
				}
				else {
					aUser = user ;
				}
				
				// Create a SSCronJob
				job = [[SSCronJob alloc] init ] ;
				// set its instance variables
				[job setUser:aUser] ;
				[job setDirectory:aDirectory] ;
				[job setFilename:[command lastPathComponent]] ;
				if (![job setDaysFromCronField:[cronJobFields objectAtIndex:i--]]) {
					[exception raise] ;
				}
				if (![job setMonthsFromCronField:[cronJobFields objectAtIndex:i--]]) {
					[exception raise] ;
				}					
				if (![job setDatesFromCronField:[cronJobFields objectAtIndex:i--]]) {
					[exception raise] ;
				}
				if (![job setHoursFromCronField:[cronJobFields objectAtIndex:i--]] ) {
					[exception raise] ;
				}
				if (![job setMinutesFromCronField:[cronJobFields objectAtIndex:i--]] ) {
					[exception raise] ;
				}
				if (i >=0) {
					// Commenter has politely used a tab to separate comments from minutes field
					NSString* commentField = [cronJobFields objectAtIndex:0] ;
					commentField = [commentField stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] ;
					if ([commentField hasPrefix:@"#"]) {
						[job setCommentOut:[commentField substringFromIndex:1]] ;
						// substringFromIndex:1 will omit the "#"
					}
					else {
						[exception raise] ;
					}
				}
				else {
					// CronniX uses a space instead of a tab between its comment and the minutes field
					NSString* firstField = [cronJobFields objectAtIndex:++i] ;
					NSArray* commentAndMinutes = [firstField componentsSeparatedByString:@" " ] ;
					NSMutableArray* commentFields = [commentAndMinutes mutableCopy] ;
					[commentFields removeLastObject] ;
					NSMutableString* comments = [[NSMutableString alloc] init] ;
					NSEnumerator* f = [commentFields objectEnumerator] ;
					NSString* commentField ;
					BOOL continuation = NO ;
					while ((commentField = [f nextObject])) {
						if (continuation) {
							[comments appendString:@" "] ;
						}
						[comments appendString:commentField] ;
						continuation = YES ;
					}
					[commentFields release] ;
					NSString* concatenatedCommentOut = [NSString stringWithString:comments] ;
					[comments release] ;
					if ([concatenatedCommentOut hasPrefix:@"#"]) {
						[job setCommentOut:[concatenatedCommentOut substringFromIndex:1]] ;
						// substringFromIndex:1 will omit the "#"
					}
					else {
						[exception raise] ;
					}
				}
				
				// add it to the array
				[jobs addObject:job] ;
			
			NS_HANDLER
				
				[jobs addObject:cronLine] ;
				
			NS_ENDHANDLER
				
			[job release] ;			
		}
		[cronLines release] ;
	}
	
	SSLog(5, "Found %i cron jobs", [jobs count]) ;
	NSArray* output = [jobs copy] ;
	[jobs release] ;
	return [output autorelease] ;
}

- (id)init {
	if ((self = [super init])) {
		[self setCommentOut:nil] ; // This field may not be found
	}
	return self ;
}

- (void)dealloc
{
	[self setHours:nil] ;
	[self setMinutes:nil] ;
	[self setDates:nil] ;
	[self setDays:nil] ;
	[self setMonths:nil] ;
	[self setCommentOut:nil] ;
	[self setUser:nil] ;
	[self setDirectory:nil] ;
	[self setFilename:nil] ;
	
    [super dealloc] ;
}


@end




/*
Not used:

	//NSDictionary* myEnviro = [NSDictionary dictionaryWithDictionary:[[NSProcessInfo processInfo] environment]] ;
	//NSRunInformationalAlertPanel([NSString localize:@"Environment..."], [myEnviro description], [NSString localize:@"ok"], nil, nil) ;
	//NSRunInformationalAlertPanel([NSString localize:@"Arguments..."], [[NSArray arrayWithArray:[[NSProcessInfo processInfo] arguments]] description], [NSString localize:@"ok"], nil, nil) ;
	//NSString* theCmd ;
	
	//if ([myEnviro objectForKey:@"PWD"])
	//{
	//	theCmd = [NSString stringWithString:[myEnviro objectForKey:@"PWD"]] ;
	//}
	//else
	//{

			NSOpenPanel* thePanel = [NSOpenPanel openPanel] ;
			[thePanel setTitle:[NSString localize:@"Find the SS Application"]] ;
			[thePanel setPrompt:[NSString localize:@"Bingo"]] ;
			[thePanel setRequiredFileType:nil] ;
			if ([thePanel respondsToSelector:@selector(setMessage:)])  // Jaguar does not
			{
				[thePanel setMessage:[NSString localize:@"Find and select the SS Application, then click \"Bingo\""]] ;
			}
			if ([thePanel respondsToSelector:@selector(setCanCreateDirectories:)])  // Jaguar does not
			{
				[thePanel setCanCreateDirectories:NO ] ;
			}
			NSArray* appType = [NSArray arrayWithObject:[NSString stringWithString:@"app"]] ;
			int reply = [thePanel runModalForDirectory:@"/Applications" file:@"SS" types:appType] ;  // the file:@"SS" part does not work.  Bug in MacOS?
			if (reply == NSCancelButton)
				aOK = NO ;
			else if (reply == NSOKButton)
			{
				gAppLaunchPath = [NSMutableString stringWithString:[thePanel filename]] ;
			}
*/
