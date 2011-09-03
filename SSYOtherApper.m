#import "SSYOtherApper.h"
#import "SSYShellTasker.h"
#import "NSError+LowLevel.h"
#import "NSString+SSYExtraUtils.h"
#import "NSFileManager+SomeMore.h"

#if (MAC_OS_X_VERSION_MAX_ALLOWED < 1060)

/*!
@brief    Declares stuff which is defined in the 10.6 SDK,
to eliminate compiler warnings.

@details  Be careful to only invoke super on these methods after
you've checked that you are running under Mac OS X 10.6.
*/

typedef NSUInteger NSPropertyListReadOptions ;

@interface NSPropertyListSerialization (DefinedInMac_OS_X_10_6)

+ (id)propertyListWithData:(NSData*)data
				   options:(NSPropertyListReadOptions)opt
					format:(NSPropertyListFormat*)format
					 error:(NSError**)error ;

@end

#endif

NSString* const SSYOtherApperErrorDomain = @"SSYOtherApperErrorDomain" ;
NSString* const SSYOtherApperKeyExecutable = @"executable" ;
NSString* const SSYOtherApperKeyPid = @"pid" ;

@implementation SSYOtherApper

+ (BOOL)launchApplicationPath:(NSString*)path
					 activate:(BOOL)activate
					  error_p:(NSError**)error_p {
	NSInteger errorCode = 0 ;
	NSError* underlyingError = nil ;

	FSRef fsRef ;
	NSURL* url = [NSURL fileURLWithPath:path] ;
	BOOL ok = [[NSFileManager defaultManager] getFromUrl:url
												 fsRef_p:&fsRef
												 error_p:&underlyingError] ;
	if (!ok) {
		errorCode = 494985 ;
		goto end ;
	}
	
	LSApplicationParameters parms ;
	parms.version = 0 ;
	parms.flags = activate ? 0 : kLSLaunchAndHide ;
	parms.application = &fsRef ;
	parms.asyncLaunchRefCon = NULL ;
	parms.environment = NULL ;
	parms.argv = NULL ;
	parms.initialEvent = NULL ;
	OSStatus err = LSOpenApplication(&parms, NULL) ;
	if (err != noErr) {
		ok = NO ;
		errorCode = 494986 ;
		underlyingError = [NSError errorWithMacErrorCode:err] ;
	}
	
end:;
	if (!ok && error_p) {
		NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								  @"Could not launch app", NSLocalizedDescriptionKey,
								  path, @"Path",
								  underlyingError, NSUnderlyingErrorKey,  // may be nil sentinel
								  nil] ;
		
		*error_p = [NSError errorWithDomain:SSYOtherApperErrorDomain
									   code:errorCode
								   userInfo:userInfo] ;
	}
	
	return ok ;
}

+ (NSImage*)iconForAppWithBundleIdentifier:(NSString*)bundleIdentifier {
	NSString* path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:bundleIdentifier] ;
	NSImage* answer ;
	if (path) {
		answer = [[NSWorkspace sharedWorkspace] iconForFile:path] ;
	}
	else {
		answer = nil ;
	}
	
	return answer ;
}


+ (NSString*)fullPathForAppWithBundleIdentifier:(NSString*)bundleIdentifier {
	NSString* fullPath = nil ;
	if (bundleIdentifier) {
		NSWorkspace* sharedWorkspace = [NSWorkspace sharedWorkspace] ;
		fullPath = [sharedWorkspace absolutePathForAppBundleWithIdentifier:bundleIdentifier] ;
	}
	
	return fullPath ;
}

+ (pid_t)pidOfThisUsersAppWithBundleIdentifier:(NSString*)bundleIdentifier {
	pid_t pid = 0 ; // not found
	
	if (bundleIdentifier) {
		NSArray* appDicts = [[NSWorkspace sharedWorkspace] launchedApplications] ;
		// Note that the above method returns only applications launched by the
		// current user, not other users.  (Not documented, determined by experiment
		// in Mac OS 10.5.5).  Also it returns only "applications", defined as
		// "things which can appear in the Dock that are not documents and are launched by the Finder or Dock"
		// (See documentation of ProcessSerialNumber).  Therefore, it does not return Bookwatchdog 
		for (NSDictionary* appDict in [appDicts objectEnumerator]) {
			if ([[appDict objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:bundleIdentifier]) {
				pid = [[appDict objectForKey:@"NSApplicationProcessIdentifier"] intValue] ;
				break ;
			}
		}
	}
	
	return pid ;
}

+ (NSArray*)pidsExecutablesFull:(BOOL)fullExecutablePath {
	int i ;
	
	// Run unix task "ps" and get results as an array, with each element containing process command and user
	// The invocation to be constructed is: ps -x[c]awww -o pid -o command -o user
	// -ww was added in Bookdog 3.11.25.
	NSData* stdoutData ;
	NSString* options = fullExecutablePath ? @"-xww" : @"-xcww" ;
	NSArray* args = [[NSArray alloc] initWithObjects:options, @"-o", @"pid", @"-o", @"comm", nil] ;
	[SSYShellTasker doShellTaskCommand:@"/bin/ps"
							 arguments:args
						   inDirectory:nil
							 stdinData:nil
						  stdoutData_p:&stdoutData
						  stderrData_p:NULL
							   timeout:5.0
							   error_p:NULL] ;
	[args release] ;
	NSMutableArray* processInfoDics = nil ;
	if (stdoutData) {
		NSString* processInfosString = [[NSString alloc] initWithData:stdoutData encoding:[NSString defaultCStringEncoding]] ;
		NSArray* processInfoStrings = [processInfosString componentsSeparatedByString:@"\n"] ;
		/* We must now parse processInfosString which looks like this (with fullExecutablePath = NO):
		 PID      COMMAND
		 1        launchd
		 86       WindowServer
		 238      Archive Assistant Scheduler
		 13668    BkmxLicensor
		 19523    Safari
		 19754    Camino
		 19755    firefox-bin
		 20575    ps                               */		
		
		processInfoDics = [[NSMutableArray alloc] init] ;
		// The range of this loop omits the first element, which is the column
		// headings, and the last element, which is blank due to the trailing \n.
		for (i=1; i<([processInfoStrings count] -1); i++) {
			NSInteger pid ;
			NSString* command ;
			
			NSString* processInfoString = [processInfoStrings objectAtIndex:i] ;
			
			NSScanner* scanner = [[NSScanner alloc] initWithString:processInfoString] ;
			// By default, NSScanner skips whitespace.  This will be handy to skip the
			// leading whitespace before the pid, and the whitespaces separating pid,
			// user and command.  There may be whitespace which we want in the command,
			// but we don't scan for the command (see below).
			BOOL ok ;
			ok = [scanner scanInteger:&pid] ;
			NSInteger commandBeginsAt = [scanner scanLocation] ;
			[scanner release] ;
			if (!ok) {
				continue ;
			}
			command = [processInfoString substringFromIndex:commandBeginsAt] ;
			command = [command stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] ;
			NSDictionary* processInfoDic = [NSDictionary dictionaryWithObjectsAndKeys:
											[NSNumber numberWithInteger:pid], SSYOtherApperKeyPid,
											command, SSYOtherApperKeyExecutable,
											nil ] ;
			[processInfoDics addObject:processInfoDic] ;
		}
	}
	
	NSArray* result = [processInfoDics copy] ;
	[processInfoDics release] ;
	
	return [result autorelease] ;
}


+ (NSArray*)pidsOfThisUsersProcessPath:(NSString*)path {
	NSArray* infos = [self pidsExecutablesFull:YES] ;
	NSMutableArray* pids = [[NSMutableArray alloc] init] ;
	for (NSDictionary* info in infos) {
		NSString* aPath = [info objectForKey:SSYOtherApperKeyExecutable] ;
		if ([aPath isEqualToString:path]) {
			[pids addObject:[info objectForKey:SSYOtherApperKeyPid]] ;
		}
	}
	
	NSArray* answer = [pids copy] ;
	[pids release] ;
	return [answer autorelease] ;
}

+ (struct ProcessSerialNumber)processSerialNumberForAppWithPid:(pid_t)pid {
	OSStatus oss ;
	
	struct ProcessSerialNumber psn = {0, 0};
	oss = GetProcessForPID (pid, &psn) ;
	/* Note: GetProcessForPID() will return procNotFound if the process whose
	 pid is 'pid' does not have a PSN.  To find if a process has a PSN, in Terminal
	 command "ps -alxww".  Processes which have a PSN are apps, and *some* helper
	 tools.  Basic unix executables such as launchd, kextd, etc. do *not* have a PSN.
	 BookMacster-Worker does *not* have a PSN.  iChatAgent *does* have a PSN. */
	 return psn ;	
}	

+ (struct ProcessSerialNumber)processSerialNumberForAppWithBundleIdentifier:(NSString*)bundleIdentifier {
	OSStatus err = noErr;
	ProcessSerialNumber psn = { kNoProcess, kNoProcess };
	while ((err == noErr)) {
		err = GetNextProcess(&psn);
		if (err == noErr) {
			CFDictionaryRef procInfo = ProcessInformationCopyDictionary(
																		&psn,
																		kProcessDictionaryIncludeAllInformationMask
			) ;
			if ([[(NSDictionary *)procInfo objectForKey:(NSString*)kCFBundleIdentifierKey] isEqualToString:bundleIdentifier]) {
				CFRelease(procInfo) ;
				break ;
			}
			CFRelease(procInfo) ;
		}
	}
	
	return psn ;
}

+ (pid_t)pidOfMyRunningExecutableName:(NSString*)executableName {
	pid_t pid = 0 ;  // not found
	
	for (NSDictionary* processInfoDic in [self pidsExecutablesFull:NO]) {
		NSString* command = [processInfoDic objectForKey:SSYOtherApperKeyExecutable] ;
		if (command) {
			if ([executableName isEqualToString:command]) {
				pid = [[processInfoDic objectForKey:SSYOtherApperKeyPid] intValue] ;
				if (pid > 0) {
					break ;
				}
			}
		}
	}
	
	return pid ;
}
	
+ (NSArray*)pidsOfMyRunningExecutablesName:(NSString*)executableName {
	// The following reverse-engineering emulates the way that ps presents
	// an executable name when it is a zombie process:
	NSString* zombifiedExecutableName = [NSString stringWithFormat:
										 @"(%@)",
										 [executableName substringToIndex:16]] ;

	NSMutableArray* pids = [[NSMutableArray alloc] init] ;
	for (NSDictionary* processInfoDic in [self pidsExecutablesFull:NO]) {
		NSString* command = [processInfoDic objectForKey:SSYOtherApperKeyExecutable] ;
		if (command) {
			if (
				[executableName isEqualToString:command]
				||
				[zombifiedExecutableName isEqualToString:command]
				) { 
				NSNumber* pid = [processInfoDic objectForKey:SSYOtherApperKeyPid] ;
				if (pid) {
					[pids addObject:pid] ;
				}
			}
		}
	}
	
	NSArray* answer = [pids copy] ;
	[pids release] ;
	
	return [answer autorelease] ;
}

+ (NSInteger)majorVersionOfBundlePath:(NSString*)bundlePath {
	NSString* infoPlistPath = [bundlePath stringByAppendingPathComponent:@"Contents"] ;
	infoPlistPath = [infoPlistPath stringByAppendingPathComponent:@"Info.plist"] ;
	NSData* data = [NSData dataWithContentsOfFile:infoPlistPath] ;
	NSDictionary* infoDic = nil ;
	if ([[NSPropertyListSerialization class] respondsToSelector:@selector(propertyListWithData:options:format:error:)]) {
		// Mac OS X 10.6 or later
		NSError* error = nil ;
		infoDic = [NSPropertyListSerialization propertyListWithData:data
															options:NSPropertyListImmutable
															 format:NULL
															  error:&error] ;
		// Documentation of this method is vague, but it appears to be
		// better to check for error != nil than infoDic == nil.
		if (error) {
			NSLog(@"Internal Error 425-2349 %@", error) ;
		}
	}
	else if ([[NSPropertyListSerialization class] respondsToSelector:@selector(propertyListFromData:mutabilityOption:format:errorDescription:)]) {
		// Mac OS X 10.5 or earlier
		NSString* errorDescription = nil ;
		infoDic = [NSPropertyListSerialization propertyListFromData:data
												   mutabilityOption:NSPropertyListImmutable
															 format:NULL
												   errorDescription:&errorDescription] ;
		if (errorDescription) {
			NSLog(@"Internal Error 425-2349 %@", errorDescription) ;
		}
	}
	
	NSString* string ;
	NSInteger majorVersion ;
	if (infoDic) {
		string = [infoDic objectForKey:@"CFBundleVersion"] ;
		majorVersion = [string majorVersion] ;
		
		if (majorVersion == 0) {
			string = [infoDic objectForKey:@"CFBundleShortVersionString"] ;
			majorVersion = [string majorVersion] ;
		}
	}
	else {
		// This scheme was the only one used until BookMacster 1.6.5.
		// It was found that this gives an outdated answer when Firefox is updated,
		// until Firefox was launched and quit again.
		// This is due to the same bug that plagues Path Finder.
		// Actually, the bug is documented, in +[NSBundle bundleWithPath],
		// "This method allocates and initializes the returned object if there is no
		// existing NSBundle associated with fullPath, in which case it returns the
		// existing object" (which, if bundlePath has been updated since this
		// app launched, is going to be the old bundle).  So now we only
		// use this scheme if all else has failed.
		NSBundle* bundle = [NSBundle bundleWithPath:bundlePath] ;
		
		string = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"] ;
		majorVersion = [string majorVersion] ;
		
		if (majorVersion == 0) {
			string = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ;
			majorVersion = [string majorVersion] ;
		}
	}

	return majorVersion ;
}

+ (NSString*)processNameWithProcessSerialNumber:(struct ProcessSerialNumber)psn {
	OSStatus    err = noErr;  
	ProcessInfoRec  infoRec;
	
	Str255 processName ; // unsigned char Str255[256]
    
	infoRec.processInfoLength = sizeof(ProcessInfoRec) ;
	// These two must be initialized or GetProcessInformation() will crash…
	infoRec.processName = (StringPtr)&processName ; // a StringPtr = unsigned char *
	infoRec.processAppSpec = NULL ;
	
	err = GetProcessInformation(&psn, &infoRec);
	
	NSString* name = nil ;
	if (err == noErr) {
		name = (NSString *)CFStringCreateWithPascalString(NULL,
														  (ConstStr255Param)&processName,  // a ConstStr255Param = const unsigned char *
														  CFStringGetSystemEncoding()) ;
		// The following worked too
		// name = [[NSString alloc] initWithBytes:&(processName[1])
		//								length:processName[0] 
		//							  encoding:NSMacOSRomanStringEncoding] ;
	}
	
	return [name  autorelease] ;
}

+ (pid_t)pidOfThisUsersProcessNamed:(NSString*)processName {
	OSStatus err = noErr;
	pid_t pid = 0 ;
	struct ProcessSerialNumber psn ;
	
	psn.lowLongOfPSN  = kNoProcess;
	psn.highLongOfPSN  = kNoProcess;
	
	while (!(GetNextProcess (&psn))) {
		NSString* aProcessName = [self processNameWithProcessSerialNumber:psn] ;
		if ([aProcessName isEqualToString:processName] ) {
			err = GetProcessPID(&psn, &pid);
			if (!err) {
				break ;
			}
		}
	}
	
	return pid ;
}

+ (NSArray*)pidsOfThisUsersProcessesNamed:(NSString*)processName {
	OSStatus err = noErr;
	struct ProcessSerialNumber psn ;
	
	psn.lowLongOfPSN  = kNoProcess;
	psn.highLongOfPSN  = kNoProcess;
	
	NSMutableArray* pids = [[NSMutableArray alloc] init] ;
	while (!(GetNextProcess (&psn))) {
		NSString* aProcessName = [self processNameWithProcessSerialNumber:psn] ;
		if ([aProcessName isEqualToString:processName] ) {
			pid_t pid = 0 ;
			err = GetProcessPID(&psn, &pid);
			if (!err) {
				[pids addObject:[NSNumber numberWithInt:pid]] ;
			}
		}
	}
	
	NSArray* answer = [pids copy] ;
	[pids release] ;
	
	return [answer autorelease] ;
}

+ (NSString*)processBundlePathWithProcessSerialNumber:(struct ProcessSerialNumber)psn {
	NSDictionary* processInfo = (NSDictionary*)ProcessInformationCopyDictionary (
																				 &psn,
																				 kProcessDictionaryIncludeAllInformationMask) ;
	NSString* bundlePath = [processInfo objectForKey:@"BundlePath"] ;
	
	// Because Core Foundation doesn't have autorelease, we need to do this:
	[[processInfo retain] autorelease] ;
	// Otherwise, it will be released as soon as the app whose bundlePath it is quits.
	// Before we did that, if Bookdog was running, BookMacster would crash in 
	// -[SSYOtherApper quitThisUsersAppWithBundlePath:ttimeout:error_p:] after
	// quitting Bookdog, when sending [self isThisUsersAppRunningWithBundlePath:bundlePath].
	// (This bug was fixed in BookMacster 1.5.7.)
	CFRelease(processInfo) ;
	return bundlePath ;
}

+ (NSString*)bundlePathForProcessName:(NSString*)processName {
	struct ProcessSerialNumber psn ;
	NSString* path = nil ;
	
	psn.lowLongOfPSN  = kNoProcess;
	psn.highLongOfPSN  = kNoProcess;
	
	while (!(GetNextProcess (&psn))) {
		NSString* aProcessName = [self processNameWithProcessSerialNumber:psn] ;
		if ([aProcessName isEqualToString:processName] ) {
			path = [self processBundlePathWithProcessSerialNumber:psn] ;
			break ;
		}
	}
	
	return path ;
}


+ (pid_t)pidOfThisUsersProcessWithBundlePath:(NSString*)bundlePath {
	OSStatus err = noErr;
	pid_t pid = 0 ;
	struct ProcessSerialNumber psn ;
	
	psn.lowLongOfPSN  = kNoProcess;
	psn.highLongOfPSN  = kNoProcess;
	
	while (!(GetNextProcess (&psn))) {
		NSString* aBundlePath = [self processBundlePathWithProcessSerialNumber:psn] ;
		if ([aBundlePath isEqualToString:bundlePath] ) {
			err = GetProcessPID(&psn, &pid);
			if (!err) {
				break ;
			}
		}
	}
	
	return pid ;
}

+ (BOOL)isThisUsersAppRunningWithPID:(pid_t)pid {
	ProcessSerialNumber psn = [self processSerialNumberForAppWithPid:pid] ;
	return ((psn.lowLongOfPSN != 0) || (psn.highLongOfPSN != 0)) ;
}

+ (BOOL)runAppleScriptSource:(NSString*)source
					 error_p:(NSError**)error_p {
	NSAppleScript* script = [[NSAppleScript alloc] initWithSource:source] ;
	NSDictionary* errorDic = nil ;
	BOOL spuriousError = NO ;
	NSAppleEventDescriptor* descriptor = [script executeAndReturnError:&errorDic] ;
	if (!descriptor && error_p) {
		NSNumber* errorNumber = [errorDic objectForKey:NSAppleScriptErrorNumber] ;
		if ([errorNumber respondsToSelector:@selector(integerValue)]) {
			if ([errorNumber integerValue] == errAENoSuchObject) {
				// App with given bundleIdentifier is probably
				// not installed on the system.  English 
				// NSAppleScriptErrorMessage is probably:
				// "Can't get application id \"given.bundle.identifier\"."
				// Since we don't need to quit an app which is not installed
				// on the system, this is not an error.
				spuriousError = YES ;
			}
		}
		
		if (!spuriousError) {
			*error_p = [NSError errorWithAppleScriptErrorDictionary:errorDic] ;
		}
	}
	[script release] ;
	
	BOOL ok = (descriptor != nil) || spuriousError ;
	
	return ok ;
}

+ (BOOL)quitThisUsersAppWithBundlePath:(NSString*)bundlePath
							   error_p:(NSError**)error_p {
	NSString* source = [NSString stringWithFormat:
						@"tell application \"%@\"\n"
						@"  close windows\n"
						@"  quit\n"
						@"end tell\n",
						bundlePath] ;
	// The 'close windows' improves the reliability of this script,
	// thanks to Shane Stanley <sstanley@myriad-com.com.au>
	// 'AppleScriptObjC Explored' <www.macosxautomation.com/applescript/apps/>
	// See http://lists.apple.com/archives/applescript-users/2011/Jun/threads.html  June 8
	return [self runAppleScriptSource:source
							  error_p:error_p] ;
}

#if 0
// This method works but is no longer used
+ (BOOL)quitThisUsersAppWithBundleIdentifier:(NSString*)bundleIdentifier
									 error_p:(NSError**)error_p {
	NSString* source = [NSString stringWithFormat:
						@"tell application id \"%@\" to quit",
						bundleIdentifier] ;
	return [self runAppleScriptSource:source
							  error_p:error_p] ;
}
#endif

+ (BOOL)isProcessRunningPid:(pid_t)pid
			   thisUserOnly:(BOOL)thisUserOnly {
	BOOL answer = NO ;
	NSArray* args ;
	if (thisUserOnly) {
		args = [NSArray arrayWithObjects:
				@"-x",
				@"-o",    // Print the following column(s)
				@"pid=",  // = means to suppress header line
				nil] ;
	}
	else {
		args = [NSArray arrayWithObjects:
				@"-x",
				@"-a",    // All users
				@"-o",    // Print the following column(s)
				@"pid=",  // = means to suppress header line
				nil] ;
	}

	NSData* stdoutData ;
	[SSYShellTasker doShellTaskCommand:@"/bin/ps"
							 arguments:args
						   inDirectory:nil
							 stdinData:nil
						  stdoutData_p:&stdoutData
						  stderrData_p:NULL
							   timeout:5.0
							   error_p:NULL] ;
	if (stdoutData) {
		NSString* pidsString = [[NSString alloc] initWithData:stdoutData
													 encoding:NSUTF8StringEncoding] ;
		NSArray* pidStrings = [pidsString componentsSeparatedByString:@"\n"] ;
		for (NSString* pidString in pidStrings) {
			// The members of pidStrings which are less than 5 digits long
			// have leading whitespaces so that the columns are right-justified.
			// Of course, that might change.
			// I hope that using the -[NSString intValue] will give a fairly
			// robust and future-proof reading…
			if ([pidString intValue] == pid) {
				answer = YES ;
				break ;
			}
		}
	}
	
	return answer ;
}

+ (BOOL)isProcessRunningPid:(pid_t)pid
					  logAs:(NSString*)logAs {
	BOOL answer = NO ;
	// There is a bug in -launchedApplications.  Sometimes, after an app such
	// as "com.google.Chrome" quits, it still keeps showing up on repeated invocations
	// of -launchedApplications.  So we need to check and see if it is *really*
	// still running before setting answer to YES.
	if (pid > 0) {
		answer = [self isProcessRunningPid:pid
							  thisUserOnly:YES] ;
		
		if (!answer) {
			NSLog(@"NSWorkspace says %@ running.  But I can't find its pid %d.  Ignoring stupid NSWorkspace.", logAs, pid) ;
		}
	}
	
	return answer ;	
}	

+ (BOOL)isThisUsersAppRunningWithBundleIdentifier:(NSString*)bundleIdentifier {
	NSWorkspace* workspace = [NSWorkspace sharedWorkspace] ;
	pid_t pid = 0 ;

	// For Mac OS 10.6 (someday), one should use -runningApplications
	// and +[NSRunningApplication runningApplicationsWithBundleIdentifier:]
	// However be careful.  Tests I've done show that it might have the 
	// same bug worked around below.  Or it might not.
	NSArray* appDicts = [workspace launchedApplications] ;
	for (NSDictionary* appDict in appDicts) {
		if ([[appDict objectForKey:@"NSApplicationBundleIdentifier"] isEqual:bundleIdentifier]) {
			pid = [[appDict objectForKey:@"NSApplicationProcessIdentifier"] longValue] ;
		}
	}
	
	return [self isProcessRunningPid:pid
							   logAs:[bundleIdentifier pathExtension]] ;
}

+ (BOOL)isThisUsersAppRunningWithBundlePath:(NSString*)bundlePath {
	if (!bundlePath) {
		return NO ;
	}
	
	NSWorkspace* workspace = [NSWorkspace sharedWorkspace] ;
	pid_t pid = 0 ;
	
	// For Mac OS 10.6 (someday), one should use -runningApplications
	// and +[NSRunningApplication runningApplicationsWithBundleIdentifier:]
	// However be careful.  Tests I've done show that it might have the 
	// same bug worked around below.  Or it might not.
	NSArray* appDicts = [workspace launchedApplications] ;
	for (NSDictionary* appDict in appDicts) {
		if ([[appDict objectForKey:@"NSApplicationPath"] isEqualToString:bundlePath]) {
			pid = [[appDict objectForKey:@"NSApplicationProcessIdentifier"] longValue] ;
		}
	}
	
	return [self isProcessRunningPid:pid
							   logAs:[bundlePath lastPathComponent]] ;
}

+ (BOOL)quitThisUsersAppWithBundlePath:(NSString*)bundlePath
							   timeout:(NSTimeInterval)timeout
							   error_p:(NSError**)error_p {
	if (!bundlePath) {
		return YES ;
	}
	
	NSDate* endDate = [NSDate dateWithTimeIntervalSinceNow:timeout] ;
	BOOL ok = [self quitThisUsersAppWithBundlePath:bundlePath
										   error_p:error_p] ;
	
	if (!ok) {
		// Supposedly no chance that it will quit, so give up immediately.
		return NO ;
	}
	
	while (YES) {
		if (![self isThisUsersAppRunningWithBundlePath:bundlePath]) {
			return YES ;
		}
		
		if ([(NSDate*)[NSDate date] compare:endDate] == NSOrderedDescending) {
			return NO ;
		}
		
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]] ;
	}

	return NO ; // Never happens due to infinite loop above; to suppress compiler warning
}

+ (BOOL)killProcessWithProcessSerialNumber:(ProcessSerialNumber)psn {
	OSErr err = KillProcess(&psn) ;
	return (err == noErr) ;
}

/*
 + (void)killProcessPID:(pid_t)pid
		 waitUntilExit:(BOOL)wait {
	if (pid) {
		NSArray* args = [[NSArray alloc] initWithObjects: @"-9", [NSString stringWithFormat:@"%i", pid], nil] ;
		[SSYShellTasker doShellTaskCommand:@"/bin/kill"
								 arguments:args
							   inDirectory:nil
								 stdinData:nil
							  stdoutData_p:NULL
							  stderrData_p:NULL
							 waitUntilExit:YES
								   error_p:NULL] ;
	}
}
*/

+ (BOOL)killThisUsersAppWithBundleIdentifier:(NSString*)bundleIdentifier
									 timeout:(NSTimeInterval)timeout {
	if (!bundleIdentifier) {
		return YES ;
	}
	
	NSDate* endDate = [NSDate dateWithTimeIntervalSinceNow:timeout] ;
	pid_t pid = [self pidOfThisUsersAppWithBundleIdentifier:bundleIdentifier] ;
	if (pid != 0) {
		kill(pid, SIGKILL) ;
		
		while (YES) {
			if (![self isThisUsersAppRunningWithBundleIdentifier:bundleIdentifier]) {
				return YES ;
			}
			
			if ([(NSDate*)[NSDate date] compare:endDate] == NSOrderedDescending) {
				return NO ;
			}
			
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]] ;
		}
	}
	
	return NO ; // Never happens due to infinite loop above; to suppress compiler warning
}

+ (NSString*)applicationPathForUrl:(NSURL*)url {
  OSStatus oss ;
    FSRef appRef ;
	
	oss = LSGetApplicationForURL(
								 (CFURLRef)url,
								 kLSRolesViewer,
								 &appRef,
								 NULL
								 ) ;

	
	char fullPath[1024];
  	if (oss == noErr) {
		oss = FSRefMakePath (
							 &appRef,
							 (UInt8*)fullPath,
							 sizeof(fullPath)
							 ) ;
	}
	
	NSString* path = nil ;
	if (oss == noErr) {		
		path = [NSString stringWithCString:fullPath
								  encoding:NSUTF8StringEncoding] ;
	}
	
	return path ;
}

+ (NSString*)nameOfDefaultWebBrowser {
	NSURL* url = [NSURL URLWithString:@"http://apple.com"] ;
	NSString *path = [self applicationPathForUrl: url];
	NSString* name = [path stringByDeletingPathExtension] ;
	name = [[name pathComponents] lastObject] ;
	return name ;
}

+ (NSString*)nameOfDefaultEmailClient {
	NSURL* url = [NSURL URLWithString:@"mailto://me@me.com"] ;
	NSString *path = [self applicationPathForUrl: url] ;
	NSString* name = [path stringByDeletingPathExtension] ;
	name = [[name pathComponents] lastObject] ;
	return name ;
}

+ (NSString*)bundleIdentifierOfDefaultEmailClient {
	NSURL* url = [NSURL URLWithString:@"mailto://me@me.com"] ;
	NSString *path = [self applicationPathForUrl: url] ;
	NSBundle* bundle = [NSBundle bundleWithPath:path] ;
	NSString* bundleIdentifier = [bundle bundleIdentifier] ;
	return bundleIdentifier ;
}

+ (BOOL)processPid:(pid_t)pid
		   timeout:(NSTimeInterval)timeout
	  cpuPercent_p:(float*)cpuPercent_p
		   error_p:(NSError**)error_p {
	NSInteger errorCode = 0 ;
	NSInteger psReturnValue = 0 ;
	NSString* psErrorString = nil ;
	NSString* errorDescription = nil ;
	NSString* pidString = [NSString stringWithFormat:@"%i", pid] ;
	NSArray* args = [NSArray arrayWithObjects:
					 @"-x",      // include processes which do not have a controlling terminal
					 @"-p",      // include only the process with the following pid
					 pidString,
					 @"-o"       // print the value of the following key
					 "%cpu=",    // %cpu is percent CPU usage.  = says to omit the column header line
					 nil] ;
	NSData* stdoutData = nil ;
	NSData* stderrData = nil ;
	
	NSString* const command = @"/bin/ps" ;
	psReturnValue = [SSYShellTasker doShellTaskCommand:command
											 arguments:args
										   inDirectory:nil
											 stdinData:nil
										  stdoutData_p:&stdoutData
										  stderrData_p:&stderrData
											   timeout:timeout
											   error_p:NULL] ;
	if (psReturnValue == 0) {
		if (stdoutData && cpuPercent_p) {
			NSString* cpuUsageString = [[NSString alloc] initWithData:stdoutData
															 encoding:NSASCIIStringEncoding] ;
			
			*cpuPercent_p = [cpuUsageString floatValue] ;
		}
		else {
			errorCode = 228401 ;
			errorDescription = @"No stdout" ;
		}
	}
	else {
		errorCode = 228402 ;
		errorDescription = @"ps returned nonzero" ;
	}
	
	if (stderrData) {
		psErrorString = [[NSString alloc] initWithData:stderrData
											  encoding:NSASCIIStringEncoding] ;
	}
	
	BOOL ok = (errorCode == 0) ;
	if (!ok) {
		if (error_p) {
			NSError* underlyingError = [NSError errorWithDomain:NSPOSIXErrorDomain
														   code:psReturnValue
													   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																 psErrorString, NSLocalizedDescriptionKey, // may be nil
																 nil]] ;
			*error_p = [NSError errorWithDomain:SSYOtherApperErrorDomain
										   code:errorCode
									   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
												 errorDescription, NSLocalizedDescriptionKey,
												 underlyingError, NSUnderlyingErrorKey,
												 nil]] ;
		}
	}
	
	return ok ;
}

+ (NSString*)bundlePathOfSenderOfEvent:(NSAppleEventDescriptor*)event {
	// Thanks to Greg Robbins for this…
	// http://www.cocoabuilder.com/archive/cocoa/125741-finding-the-sender-of-an-appleevent-in-cocoa-app-on-10-2-8-or-greater.html
	// I think that the second part of his code, where you get the OSTypeSendersSignature,
	// is probably depracated since 20050114, so I did not include it.
	NSAppleEventDescriptor *addrDesc = [event attributeDescriptorForKeyword:keyAddressAttr] ;
	NSData *psnData = [[addrDesc coerceToDescriptorType:typeProcessSerialNumber] data] ;
	NSString* bundlePath ;
	if (psnData) {
		ProcessSerialNumber psn = *(ProcessSerialNumber *) [psnData bytes] ;
		bundlePath = [SSYOtherApper processBundlePathWithProcessSerialNumber:psn] ;
	}
	else {
		bundlePath = nil ;
	}
	
	return bundlePath ;
}

+ (NSString*)pathIfRunningForThisUserBundleIdentifier:(NSString*)bundleIdentifier {
	NSArray* launchedApplications = [[NSWorkspace sharedWorkspace] launchedApplications] ;
	// An undocumented "feature" of -[NSWorkspace launchedApplications], which I determined
	// by testing in Mac OS 10.6.6, is that it only returns info for applications whose
	// user is the current user.
	for (NSDictionary* appInfo in launchedApplications) {
		if ([[appInfo objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:bundleIdentifier]) {
			return [appInfo objectForKey:@"NSApplicationPath"] ;
		}
	}
		
	return nil ;
}

+ (BOOL)activateAppWithBundlePath:(NSString*)bundlePath
				 bundleIdentifier:(NSString*)bundleIdentifier {
	if (!bundlePath && bundleIdentifier) {
		bundlePath = [[NSBundle bundleWithIdentifier:bundleIdentifier] bundlePath] ;
	}
	
	BOOL ok = NO ;
	if (bundlePath) {
		ok = [[NSWorkspace sharedWorkspace] openFile:nil
									 withApplication:bundlePath
									   andDeactivate:YES] ;
	}
	
	return ok ;
}

@end



/*
 
 
 // Here is Philip Aker's method of killing a process named "System Events":
 // err = system( "kill `ps axo pid,command | grep 'System Events' | grep -v grep | cut -d '/' -f 1 | tr -d ' '`" );
 
 Some code that someone posted on CocoaBuilder.  Seems similar to mine except uses
 more process serial numbers instead of process identifiers (pid).
 
 #include <IOKit/IOCFBundle.h>
		
int ProcessIsRunningWithBundleID(CFStringRef inBundleID, ProcessSerialNumber* outPSN) {
	int theResult = 0;
	
	ProcessSerialNumber thePSN = {0, kNoProcess};
	OSErr theError = noErr;
	do {
		theError = GetNextProcess(&thePSN);
		if(theError == noErr) {
			CFDictionaryRef theInfo = NULL;
			theInfo = ProcessInformationCopyDictionary(
													   &thePSN,
													   kProcessDictionaryIncludeAllInformationMask
			) ;
			if(theInfo) {
				CFStringRef theBundleID = CFDictionaryGetValue(theInfo, IOBundleIdentifierKey);
				if(theBundleID)
				{
					if(CFStringCompare(theBundleID, inBundleID, 0) == kCFCompareEqualTo)
					{
						theResult = 1;
					}
				}
				CFRelease(theInfo);
			}
		}
	} while((theError != procNotFound) && (theResult == 0));
	
	if(theResult && outPSN)
	{
		*outPSN = thePSN;
	}
	
	return theResult;
}

//  The second argument can be NULL. If you pass the address of a ProcessSerialNumber, you can then use this routine to quit it.

OSErr QuitApplicationByPSN(const ProcessSerialNumber* inPSN) {
	AppleEvent theQuitEvent = {typeNull, NULL};
	AEBuildError theBuildError;
	OSErr theError = AEBuildAppleEvent(
									   kCoreEventClass,
									   kAEQuitApplication,
									   typeProcessSerialNumber,
									   inPSN,
									   sizeof(ProcessSerialNumber),
									   kAutoGenerateReturnID,
									   kAnyTransactionID,
									   &theQuitEvent,
									   &theBuildError,
									   "");
	if(theError == noErr)
	{
		AppleEvent theReply = {};
		theError = AESend(&theQuitEvent, &theReply, kAENoReply | kAENeverInteract,
						  kAENormalPriority, kNoTimeOut, NULL, NULL);
		(void)AEDisposeDesc(&theQuitEvent);
	}
	return theError;
}


// Or, try this....
		
#include <Carbon/Carbon.h>
		
OSStatus QuitApplication(char *bundleID) {
	AppleEvent evt, res;
	OSStatus err;
	
	err = AEBuildAppleEvent(
							kCoreEventClass, kAEQuitApplication,
							typeApplicationBundleID, bundleID, strlen(bundleID),
							kAutoGenerateReturnID,
							kAnyTransactionID,
							&evt,
							NULL,
							""
	) ;
	if (err == noErr) {
		err = AESendMessage(&evt, &res, kAENoReply, kAEDefaultTimeout);
		AEDisposeDesc(&evt);
	}
	return err;
}
*/