#import "SSYOtherApper.h"
#import "SSYShellTasker.h"
#import "NSError+LowLevel.h"
#import "NSString+SSYExtraUtils.h"
#import "NSFileManager+SomeMore.h"
#import "NSRunningApplication+SSYHideReliably.h"
#import "NSError+InfoAccess.h"

NSString* const SSYOtherApperErrorDomain = @"SSYOtherApperErrorDomain" ;
NSString* const SSYOtherApperKeyPid = @"pid" ;
NSString* const SSYOtherApperKeyUser = @"user" ;
NSString* const SSYOtherApperKeyEtime = @"etime" ;
NSString* const SSYOtherApperKeyExecutable = @"executable" ;

@implementation SSYOtherApper

+ (pid_t)pidOfThisUsersAppWithBundleIdentifier:(NSString*)bundleIdentifier {
	pid_t pid = 0 ; // not found
	
	if (bundleIdentifier) {
        // Running the main run loop is necessary for -runningApplications to
        // update.  The next line is actually necessary in tools which may be lacking
        // a running run loop, and it actually works.
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]] ;
        NSArray* runningApps = [[NSWorkspace sharedWorkspace] runningApplications] ;
		for (NSRunningApplication* runningApp in runningApps) {
			if ([[runningApp bundleIdentifier] isEqualToString:bundleIdentifier]) {
				pid = [runningApp processIdentifier] ;
				break ;
			}
		}
	}
	
	return pid ;
}

+ (pid_t)pidOfThisUsersAppWithBundlePath:(NSString*)bundlePath {
	pid_t pid = 0 ; // not found

    if (bundlePath) {
        // Running the main run loop is necessary for -runningApplications to
        // update.  The next line is actually necessary in tools which may be lacking
        // a running run loop, and it actually works.
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]] ;
        NSArray* runningApplications = [[NSWorkspace sharedWorkspace] runningApplications] ;
        for (NSRunningApplication* runningApp in runningApplications) {
            NSURL* url = [runningApp bundleURL] ;
            NSString* path = [url path] ;
            if ([path isEqualToString:bundlePath]) {
                pid = [runningApp processIdentifier] ;
                break ;
            }
        }
    }

    return pid ;
}


+ (NSString*)pathOfThisUsersRunningAppWithBundleIdentifier:(NSString*)bundleIdentifier {
	NSString* path = nil ;
    
	if (bundleIdentifier) {
        // Running the main run loop is necessary for -runningApplications to
        // update.  To my amazement, the next line is actually necessary, and
        // it actually works.
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]] ;
        NSArray* runningApps = [[NSWorkspace sharedWorkspace] runningApplications] ;
		for (NSRunningApplication* runningApp in runningApps) {
			if ([[runningApp bundleIdentifier] isEqualToString:bundleIdentifier]) {
				path = [[runningApp bundleURL] path] ;
				break ;
			}
		}
	}
    
	return path ;
}

+ (BOOL)launchApplicationPath:(NSString*)path
					 activate:(BOOL)activate
                hideGuardTime:(NSTimeInterval)hideGuardTime
					  error_p:(NSError**)error_p {
    BOOL ok = YES ;
    NSInteger errorCode = 0 ;
	NSError* underlyingError = nil ;

    NSBundle* bundle = [NSBundle bundleWithPath:path] ;
    NSString* bundleIdentifier = [bundle bundleIdentifier] ;
    NSArray* apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:bundleIdentifier] ;
    NSRunningApplication* currentlyRunningApp = [apps lastObject] ;
    NSString* runningBundlePath = [[currentlyRunningApp bundleURL] path] ;
    BOOL currentlyRunning = ([path isEqualToString:runningBundlePath]) ;
    BOOL currentlyActive = currentlyRunning ? [currentlyRunningApp isActive] : NO ;

    NSURL* url = nil ;
    if (currentlyRunning) {
        if (currentlyActive != activate) {
            if (activate) {
                [currentlyRunningApp unhide] ;
            }
            else {
                [currentlyRunningApp hideReliably] ;
            }
        }
    }
    else {
        url = [NSURL fileURLWithPath:path] ;
    }
    
    if (url) {
        LSLaunchFlags launchFlags = 0 ;
        if (!activate) {
            launchFlags += kLSLaunchDontSwitch ;
            launchFlags += kLSLaunchAndHide ;
        }
        LSLaunchURLSpec launchSpec ;
        launchSpec.appURL = (CFURLRef)url ;
        launchSpec.itemURLs = NULL ;
        launchSpec.passThruParams = NULL ;
        launchSpec.launchFlags = launchFlags ;
        launchSpec.asyncRefCon = NULL ;
        
        OSStatus err = LSOpenFromURLSpec(
                                         &launchSpec,
                                         NULL
                                         ) ;

		if (err != noErr) {
            ok = NO ;
            errorCode = 494986 ;
            underlyingError = [NSError errorWithMacErrorCode:err] ;
        }
    }

    if (ok && !activate && hideGuardTime > 0) {
        NSBundle* bundle = [NSBundle bundleWithPath:path] ;
        NSString* bundleIdentifier = [bundle bundleIdentifier] ;
        
        NSTimeInterval doneTime = [NSDate timeIntervalSinceReferenceDate] + hideGuardTime ;
        do {
            NSArray* apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:bundleIdentifier] ;
            NSRunningApplication* app = [apps lastObject] ;
            [app hide] ;
            usleep(100000) ;
        } while ([NSDate timeIntervalSinceReferenceDate] < doneTime) ;
    }

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

+ (BOOL)launchAsHiddenAppPath:(NSString*)path
                launchTimeout:(NSTimeInterval)launchTimeout
                hideGuardTime:(NSTimeInterval)hideGuardTime
                      error_p:(NSError**)error_p {
    NSError* error = nil ;
    BOOL ok = YES ;
    if (!path) {
        error = [NSError errorWithDomain:SSYOtherApperErrorDomain
                                    code:494089
                                userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                          @"App path cannot be nil", NSLocalizedDescriptionKey,
                                          nil]] ;
        ok = NO ;
    }
    
    NSBundle* bundle = [NSBundle bundleWithPath:path] ;
    
    if (ok) {
        if (!bundle) {
            error = [NSError errorWithDomain:SSYOtherApperErrorDomain
                                        code:494090
                                    userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                              @"No bundle found at path", NSLocalizedDescriptionKey,
                                              path, @"Path",
                                              nil]] ;
            ok = NO ;
        }
    }
    
    NSString* bundleIdentifier = [bundle bundleIdentifier] ;
    
    /*  I wish we could use /usr/bin/open for this.  See Apple Bug 19070101. */
    if (ok) {
        NSString* source = [NSString stringWithFormat:
                            @" try\n"
                            @"  tell application \"%@\"\n"
                            @"  end tell\n"
                            @" end try\n",
                            path] ;
        dispatch_queue_t aSerialQueue = dispatch_queue_create("com.sheepsystems.SSYOtherApper.launchAsHidden", DISPATCH_QUEUE_SERIAL) ;
        dispatch_async(aSerialQueue, ^{
            NSAppleScript* script = [[NSAppleScript alloc] initWithSource:source] ;
            [script executeAndReturnError:NULL] ;
            /* The above method will return and allow this secondary thread to
             exit when
             a)  The launched app activates, or,
             b)  The launched app quits, or,
             c)  The built-in NSAppleScript timeout of 120 seconds,
             whichever comes first.  According to this answer:
             http://stackoverflow.com/questions/22932419/timeout-has-no-effect-in-nsapplescript
             We could get it to exit fast if we wrapped the script source
             with a 'with timeout 0.1 seconds' block *and* wrote it to a
             temporary file and then executed the script from the file.
             Then, we wouldn't need to do wrap it in a dispatch_async() to
             avoid blocking for up to 120 seconds.  But this is good enough. */
            [script release] ;
        }) ;
    }
    
    if (ok && (launchTimeout > 0.0)) {
        NSTimeInterval doneTime = [NSDate timeIntervalSinceReferenceDate] + launchTimeout ;
        // Wait for app to launch
        BOOL isLaunched = NO ;
        do {
            NSArray* apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:bundleIdentifier] ;
            NSRunningApplication* app = [apps lastObject] ;
            if (app) {
                isLaunched = YES ;
                break ;
            }
            usleep(1000000) ;
        } while ([NSDate timeIntervalSinceReferenceDate] < doneTime) ;
        if (!isLaunched) {
            error = [NSError errorWithDomain:SSYOtherApperErrorDomain
                                        code:494091
                                    userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                              @"App failed to launch in timeout", NSLocalizedDescriptionKey,
                                              path, @"Path",
                                              [NSNumber numberWithDouble:launchTimeout], @"Launch Timeout",
                                              nil]] ;
            ok = NO ;
        }
    }
    
    if (ok && (hideGuardTime > 0.0)) {
        NSTimeInterval doneTime = [NSDate timeIntervalSinceReferenceDate] + hideGuardTime ;
        do {
            NSArray* apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:bundleIdentifier] ;
            NSRunningApplication* app = [apps lastObject] ;
            if ([app isActive]) {
                [app hideReliably] ;
                break ;
            }
            usleep(100000) ;
        } while ([NSDate timeIntervalSinceReferenceDate] < doneTime) ;
    }
    
    if (error_p && error) {
        *error_p = error ;
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

+ (NSArray*)pidsExecutablesFull:(BOOL)fullExecutablePath {
	// Run unix task "ps" and get results as an array, with each element containing process command and user
	// The invocation to be constructed is: ps -xa[c]awww -o pid -o user -o command
	// -ww is required for long command path strings!!
	NSData* stdoutData ;
	NSString* options = fullExecutablePath ? @"-xaww" : @"-xacww" ;
	NSArray* args = [[NSArray alloc] initWithObjects:options, @"-o", @"pid=", @"-o", @"etime=", @"-o", @"user=", @"-o", @"comm=", nil] ;
	// In args, the "=" say to omit the column headers
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
		[processInfosString release] ;
		/* We must now parse processInfoStrings which looks like this (with fullExecutablePath = NO):
		 *     1 root           launchd
		 *    10 root           kextd
		 *     …
		 *    82 jk             loginwindow
		 *    84 root           KernelEventAgent
		 *     …
		 * 30903 jk             CrashReporter
		 * 32814 b              Google Chrome
		 *     …
		 * 48329 jk             Google Chrome Helper
		 * 48330 jk             Google Chrome Helper EH
		 *     …
		 * 50253 root           activitymonitord
		 * 53399 jk             CocoaMySQL
		 * 53410 jk             mdworker
		 * 53642 jk             gdb-i386-apple-darwin
		 * 53651 jk             BookMacster
		 *     …
		 */		
		
		processInfoDics = [[NSMutableArray alloc] init] ;
		NSScanner* scanner = nil ;
		for (NSString* processInfoString in processInfoStrings) {
			NSInteger pid ;
			NSString* user = nil ;
            NSString* etimeString = nil ;
			NSString* command ;
			BOOL ok ;
			
			scanner = [[NSScanner alloc] initWithString:processInfoString] ;
			[scanner setCharactersToBeSkipped:nil] ;

			// Scan leading whitespace, if any
			[scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet]
								intoString:NULL] ;

			// Scan pid
			ok = [scanner scanInteger:&pid] ;
			if (!ok) {
                [scanner release] ;
				continue ;
			}
			
			// Scan whitespace between pid and etime
			ok = [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet]
								intoString:NULL] ;
			if (!ok) {
                [scanner release] ;
				continue ;
			}

			/*
             Scan process elapsed time.  I would have preferred to get the
             start time using lstart or start rather than etime, but after a
             half hour of research, decided that their formats were too
             unpredictable to be parseable.
             */
			[scanner scanCharactersFromSet:[[NSCharacterSet whitespaceCharacterSet] invertedSet]
								intoString:&etimeString] ;
			
			// Scan whitespace between etime and user
			ok = [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet]
									 intoString:NULL] ;
			if (!ok) {
                [scanner release] ;
				continue ;
			}
			
			// Scan user.  Fortunately, short user names in Mac OS X cannot contain whitespace
			[scanner scanCharactersFromSet:[[NSCharacterSet whitespaceCharacterSet] invertedSet]
								intoString:&user] ;
			
			// Scan whitespace between user and command
			ok = [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet]
									 intoString:NULL] ;
			if (!ok) {
                [scanner release] ;
				continue ;
			}
			
			// Get command which is the remainder of the string
			NSInteger commandBeginsAt = [scanner scanLocation] ;
			[scanner release] ;
			scanner = nil ;
			command = [processInfoString substringFromIndex:commandBeginsAt] ;
			NSDictionary* processInfoDic = [NSDictionary dictionaryWithObjectsAndKeys:
											[NSNumber numberWithInteger:pid], SSYOtherApperKeyPid,
											user, SSYOtherApperKeyUser,
                                            etimeString, SSYOtherApperKeyEtime,
											command, SSYOtherApperKeyExecutable,
											nil ] ;
			[processInfoDics addObject:processInfoDic] ;
		}
	}
	
	NSArray* result = [processInfoDics copy] ;
	[processInfoDics release] ;

	return [result autorelease] ;
}


+ (struct ProcessSerialNumber)processSerialNumberForAppWithPid:(pid_t)pid {
	OSStatus oss ;
	struct ProcessSerialNumber psn = {0, 0};
	oss = GetProcessForPID (pid, &psn) ;
	if (oss != noErr) {
		NSLog(@"Internal Error 502-9373 %ld", (long)oss) ;
	}
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
	while (err == noErr) {
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
	NSString* targetUser = NSUserName() ;
	
	for (NSDictionary* processInfoDic in [self pidsExecutablesFull:NO]) {
		NSString* user = [processInfoDic objectForKey:SSYOtherApperKeyUser] ;
		NSString* command = [processInfoDic objectForKey:SSYOtherApperKeyExecutable] ;
		if ([targetUser isEqualToString:user] && [executableName isEqualToString:command]) {
			pid = (pid_t)[[processInfoDic objectForKey:SSYOtherApperKeyPid] integerValue] ;
			break ;
		}
	}
	
	return pid ;
}
	
+ (NSArray*)pidsOfMyRunningExecutablesName:(NSString*)executableName
                                   zombies:(BOOL)zombies {
	// The following reverse-engineering emulates the way that ps presents
	// an executable name when it is a zombie process:
	NSString* zombifiedExecutableName ;
    if (zombies) {
        zombifiedExecutableName = [NSString stringWithFormat:
           @"(%@)",
           [executableName substringToIndex:16]] ;
    }
    else {
        zombifiedExecutableName = nil ;
    }

	NSMutableArray* pids = [[NSMutableArray alloc] init] ;
	NSString* targetUser = NSUserName() ;
	for (NSDictionary* processInfoDic in [self pidsExecutablesFull:NO]) {
		NSString* user = [processInfoDic objectForKey:SSYOtherApperKeyUser] ;
		NSString* command = [processInfoDic objectForKey:SSYOtherApperKeyExecutable] ;
		if (command) {
			if (
				(
				[executableName isEqualToString:command]
				||
				[zombifiedExecutableName isEqualToString:command]
				)
				&& 
				[targetUser isEqualToString:user]
				) { 
				NSNumber* pid = [processInfoDic objectForKey:SSYOtherApperKeyPid] ;
				if (pid) { // Defensive programming
					[pids addObject:pid] ;
				}
			}
		}
	}
	
	NSArray* answer = [pids copy] ;
	[pids release] ;
	
	return [answer autorelease] ;
}

+ (SSYOtherApperProcessState)stateOfPid:(pid_t)pid {
   NSData* stdoutData ;
	NSString* options = @"-xww" ;
    NSString* pidString = [NSString stringWithFormat:@"%ld", (long)pid] ;
	NSArray* args = [[NSArray alloc] initWithObjects:options, @"-o", @"state=", pidString, nil] ;
	// In args, the "=" say to omit the column headers
	[SSYShellTasker doShellTaskCommand:@"/bin/ps"
							 arguments:args
						   inDirectory:nil
							 stdinData:nil
						  stdoutData_p:&stdoutData
						  stderrData_p:NULL
							   timeout:5.0
							   error_p:NULL] ;
	[args release] ;
	SSYOtherApperProcessState processState ;
    if ([stdoutData length] == 0) {
        processState = SSYOtherApperProcessDoesNotExist ;
    }
	else {
        NSString* stateString = [[NSString alloc] initWithData:stdoutData
                                                      encoding:[NSString defaultCStringEncoding]] ;
        unichar firstChar = [stateString characterAtIndex:0] ;
        switch (firstChar) {
            case 'S' :
                processState = SSYOtherApperProcessStateRunning ;
                break ;
            case 'U' :
                processState = SSYOtherApperProcessStateWaiting ;
                break ;
            case 'I' :
                processState = SSYOtherApperProcessStateIdle ;
                break ;
            case 'R' :
                processState = SSYOtherApperProcessStateRunnable ;
                break ;
            case 'T' :
                processState = SSYOtherApperProcessStateStopped ;
                break ;
            case 'Z' :
                processState = SSYOtherApperProcessStateZombie ;
                break ;
            default :
                processState = SSYOtherApperProcessUnknown ;
                break ;
        }
        
        [stateString release] ;
    }

    return processState ;
}

+ (NSInteger)majorVersionOfBundlePath:(NSString*)bundlePath {
	NSString* infoPlistPath = [bundlePath stringByAppendingPathComponent:@"Contents"] ;
	infoPlistPath = [infoPlistPath stringByAppendingPathComponent:@"Info.plist"] ;
	NSData* data = [NSData dataWithContentsOfFile:infoPlistPath] ;
	NSDictionary* infoDic = nil ;
    if (data) {
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
            NSError* error = nil ;
            infoDic = [NSPropertyListSerialization propertyListWithData:data
                                                                options:NSPropertyListImmutable
                                                                 format:NULL
                                                                  error:&error] ;
            if (error) {
                NSLog(@"Internal Error 425-2349 %@", error) ;
            }
        }
    }
    
	NSString* string ;
	NSInteger majorVersion ;
	if (infoDic) {
		string = [infoDic objectForKey:@"CFBundleShortVersionString"] ;
		majorVersion = [string majorVersion] ;
		
		if (majorVersion == 0) {
			string = [infoDic objectForKey:@"CFBundleVersion"] ;
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
#if __LP64__
    infoRec.processAppRef = NULL ;
#else
	infoRec.processAppSpec = NULL ;
#endif	
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

+ (pid_t)pidOfProcessNamed:(NSString*)processName
					  user:(NSString*)user {
	NSArray* infos = [self pidsExecutablesFull:NO] ;
	pid_t pid = 0 ;
    BOOL foundIt = NO ;
	for (NSDictionary* info in infos) {
		NSString* aPath = [info objectForKey:SSYOtherApperKeyExecutable] ;
		if ([aPath isEqualToString:processName]) {
            if (user) {
                NSString* aUser = [info objectForKey:SSYOtherApperKeyUser] ;
                if ([aUser isEqualToString:user] ) {
                    foundIt = YES ;
                }
            }
            else {
                foundIt = YES ;
            }
            
            if (foundIt) {
                pid = (pid_t)[[info objectForKey:SSYOtherApperKeyPid] integerValue] ;
                break ;
            }
		}
	}
		
	return pid ;
}

+ (NSSet*)infosOfProcessesNamed:(NSSet*)processNames
                          user:(NSString*)user {
	NSArray* infos = [self pidsExecutablesFull:YES] ;
    NSMutableSet* results = [[NSMutableSet alloc] init] ;
	for (NSString* processName in processNames) {
        for (NSDictionary* info in infos) {
            NSString* aPath = [info objectForKey:SSYOtherApperKeyExecutable] ;
            if ([aPath rangeOfString:processName].location != NSNotFound) {
                if (user) {
                    NSString* aUser = [info objectForKey:SSYOtherApperKeyUser] ;
                    if ([aUser isEqualToString:user] ) {
                        [results addObject:info] ;
                    }
                }
                else {
                    [results addObject:info] ;
                }
            }
        }
    }
    
    NSSet* answer = [results copy] ;
    [results release] ;
    [answer autorelease] ;
	return answer ;
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
	// -[SSYOtherApper quitThisUsersAppWithBundlePath:closeWindows:timeout:killAfterTimeout:wasRunning_p:error_p:] after
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
                          closeWindows:(BOOL)closeWindows
						  wasRunning_p:(BOOL*)wasRunning_p
							   error_p:(NSError**)error_p {
    NSError* error = nil ;
	// Because AppleScript 'tell application' will *launch* an app if it is not
	// running, we do one last test first.  Of course, this still leaves a little
	// window, a race condition, in which the app might quit and we relaunch it
	// a millisecond later, but at least this will reduce the probability of
	// that happening, and a quick launch/quit is not the end of the world.
	// I don't know how to do any better.
	BOOL isRunning = [self pidOfThisUsersAppWithBundlePath:bundlePath] != 0 ;
	
	if (wasRunning_p) {
		*wasRunning_p = isRunning ;
	}
	
	BOOL ok = YES ;
	if (isRunning) {
		NSString* source = [NSString stringWithFormat:
                            @"tell application \"%@\"\n",
                            bundlePath] ;
        if (closeWindows) {
            source = [source stringByAppendingString:@"close windows\n"] ;
        }
        source = [source stringByAppendingString:@"quit\nend tell"] ;

		ok = [self runAppleScriptSource:source
								error_p:&error] ;
	}
    
    if (error_p && error) {
        *error_p = error ;
    }
	
	return ok ;
}

#if 0
// This method worked but is no longer used
+ (BOOL)quitThisUsersAppWithBundleIdentifier:(NSString*)bundleIdentifier
									 error_p:(NSError**)error_p {
	NSString* source = [NSString stringWithFormat:
						@"tell application \"System Events\"\n"
						@"  set runCount to count (every process whose bundle identifier is \"%@\")\n"
						@"end tell\n"
						@"if runCount is greater than 0 then\n"
						@"  tell application id \"%@\"\n"
						@"    close windows\n"
						@"    quit\n"
						@"  end tell\n"
						@"end if",
						bundleIdentifier,
                        applicationId] ;
	// The 'close windows' improves the reliability of this script,
	// thanks to Shane Stanley <sstanley@myriad-com.com.au>
	// 'AppleScriptObjC Explored' <www.macosxautomation.com/applescript/apps/>
	// See http://lists.apple.com/archives/applescript-users/2011/Jun/threads.html  June 8
	// But this caused the app to launch even if it was not running!!
	// So I got the runCount idea from modifying John Gruber's idea…
	// http://daringfireball.net/2006/10/how_to_tell_if_an_app_is_running
	// to use the bundle identifier as suggested here:
	// http://macscripter.net/viewtopic.php?id=24569
	return [self runAppleScriptSource:source
							  error_p:error_p] ;
}
#endif

+ (NSString*)descriptionOfPid:(pid_t)pid {
	NSArray* args = [NSArray arrayWithObjects:
					 @"-www",      // Allow 4x the normal column width.  Should be enough!!

                     @"-o",        // Print the following column (= means to suppress header line)
					 @"command=",  // command and arguments
                     @"-o",        // Print the following column (= means to suppress header line)
                     @"stime=",    // time started
                     @"-o",        // Print the following column (= means to suppress header line)
                     @"etime=",    // elapsed running time
                     @"-o",        // Print the following column (= means to suppress header line)
                     @"uid=",      // effective user id
                     @"-o",        // Print the following column (= means to suppress header line)
                     @"user=",     // user name (from UID)
                     @"-o",        // Print the following column (= means to suppress header line)
                     @"ruid=",     // real user id
                     @"-o",        // Print the following column (= means to suppress header line)
                     @"%cpu=",     // percentage of CPU usage

                     @"-p",        // subject pid follows
					 [NSString stringWithFormat:@"%ld", (long)pid],
					 nil] ;
	
	NSString* answer = nil ;
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
		answer = [[NSString alloc] initWithData:stdoutData
                                       encoding:NSUTF8StringEncoding] ;
		[answer autorelease] ;
	}
	
	if ([answer length] == 0) {
		answer = nil ;
	}
    
    answer = [answer stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ;

	return answer ;
}

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
		[pidsString release] ;
		for (NSString* pidString in pidStrings) {
			// The members of pidStrings which are less than 5 digits long
			// have leading whitespaces so that the columns are right-justified.
			// Of course, that might change.
			// I hope that using the -[NSString intValue] will give a fairly
			// robust and future-proof reading…
			if ((pid_t)[pidString integerValue] == pid) {
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
			NSLog(@"NSWorkspace says %@ running.  But I can't find its pid %ld.  Ignoring stupid NSWorkspace.", logAs, (long)pid) ;
		}
	}
	
	return answer ;	
}	

+ (BOOL)isThisUsersAppRunningWithBundleIdentifier:(NSString*)bundleIdentifier {
	pid_t pid = [self pidOfThisUsersAppWithBundleIdentifier:bundleIdentifier] ;
	
	return [self isProcessRunningPid:pid
							   logAs:[bundleIdentifier pathExtension]] ;
}

+ (BOOL)isThisUsersAppRunningWithBundlePath:(NSString*)bundlePath {
	if (!bundlePath) {
		return NO ;
	}
	
	pid_t pid = [self pidOfThisUsersAppWithBundlePath:bundlePath] ;

	return [self isProcessRunningPid:pid
							   logAs:[bundlePath lastPathComponent]] ;
}

+ (BOOL)quitThisUsersAppWithBundlePath:(NSString*)bundlePath
                          closeWindows:(BOOL)closeWindows
							   timeout:(NSTimeInterval)timeout
					  killAfterTimeout:(BOOL)killAfterTimeout
						  wasRunning_p:(BOOL*)wasRunning_p
							   error_p:(NSError**)error_p {
	NSError* error = nil ;
    BOOL ok = YES ;
    BOOL wasRunning = NO ;
    
    if (!bundlePath) {
		goto end ;
	}
	
	NSDate* endDate = [NSDate dateWithTimeIntervalSinceNow:timeout] ;
#if 0
#warning Feigning Quitting 1
#else
    ok = [self quitThisUsersAppWithBundlePath:bundlePath
                                 closeWindows:closeWindows
                                 wasRunning_p:&wasRunning
                                      error_p:&error] ;
#endif
	if (!ok) {
		// Supposedly no chance that it will quit, so give up immediately.
		goto end ;
	}
	

	// The following test was added in BookMacster 1.13.6.  No need to wait
    // for quitting if the app was not running to begin with.
    if (wasRunning) {
        NSInteger nTries = 1 ;
        while (YES) {
            // No app is likely to quit in less than 1 second, so we sleep *first*
            [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]] ;
            
            // and *then* check if it's running
            if (![self isThisUsersAppRunningWithBundlePath:bundlePath]) {
                goto end ;
            }
            
            if ([(NSDate*)[NSDate date] compare:endDate] == NSOrderedDescending) {
                // Timed out
                if (killAfterTimeout) {
                    pid_t pid = [self pidOfThisUsersProcessWithBundlePath:bundlePath] ;
                    if (pid != 0) {
                        kill(pid, SIGKILL) ;
                    }
                    
                    goto end ;
                }
                
                ok = NO ;
                NSString* desc = [NSString stringWithFormat:
                                  @"Asked %@ nicely (via AppleScript) to quit %ld times in %g seconds, but it's still running.",
                                  bundlePath,
                                  (long)nTries,
                                  timeout] ;
                NSString* sugg = @"Try to activate and quit it yourself." ;
                error = [NSError errorWithDomain:SSYOtherApperErrorDomain
                                            code:494987
                                        userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                  desc, NSLocalizedDescriptionKey,
                                                  sugg, NSLocalizedRecoverySuggestionErrorKey,
                                                  nil]] ;
                goto end ;
            }
		}
	}

end:
    if (wasRunning_p) {
        *wasRunning_p = wasRunning ;
    }
    if (error && error_p) {
        *error_p = error ;
    }
	return ok ;
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
	
	return YES ;
}

+ (NSString*)applicationPathForUrl:(NSURL*)url {
    OSStatus oss ;
    CFURLRef appUrl ;
    oss = LSGetApplicationForURL(
                                 (CFURLRef)url,
                                 kLSRolesViewer,
                                 NULL,
                                 &appUrl
                                 ) ;
    
    
    NSString* path = nil ;
    if (oss == noErr) {		
        path = [(NSURL*)appUrl path] ;
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
	  cpuPercent_p:(CGFloat*)cpuPercent_p
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
			
			*cpuPercent_p = [cpuUsageString doubleValue] ;
			[cpuUsageString release] ;
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
	
	[psErrorString release] ;
	
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

+ (NSInteger)secondsRunningPid:(pid_t)pid {
	NSArray* arguments = [NSArray arrayWithObjects:
						  @"-p",
						  [NSString stringWithFormat:@"%ld", (long)pid],
						  @"-o",
						  @"etime=",
						  nil] ;
	
	NSData* stdoutData = nil ;
	NSInteger seconds = -1 ;
	NSInteger returnValue = [SSYShellTasker doShellTaskCommand:@"/bin/ps"
											   arguments:arguments
											 inDirectory:nil
											   stdinData:nil
											stdoutData_p:&stdoutData
											stderrData_p:NULL
												 timeout:3.0
												 error_p:NULL] ;
	if (returnValue == 0) {
		NSString* string = [[NSString alloc] initWithData:stdoutData
												 encoding:NSUTF8StringEncoding] ;
		/*  Some examples of 'string'
		 If process is not running,              <empty-string>
		 If process has been running > 1 day        dd-HH:MM:SS
		 If process has been running >1  <10 hours     0H:MM:SS
		 If process has been running >10 <24 hours     HH:MM:SS
		 If process has been running >10 <60 mins         MM:SS
		 If process has been running >1  <10 mins         0M:SS
		 So, here's how we parse it… */
		
		NSUInteger length = [string length] ;
		if (length >= 2) {
			NSString* substring = [string substringWithRange:NSMakeRange(length-3, 2)] ;
			seconds = [substring integerValue] ;
			if (length >= 5) {
				substring = [string substringWithRange:NSMakeRange(length-6, 2)] ;
				seconds += 60 * [substring integerValue] ;
			}
			if (length >= 8) {
				substring = [string substringWithRange:NSMakeRange(length-9, 2)] ;
				seconds += 60*60 * [substring integerValue] ;
			}
			if (length >=10) {
				substring = [string substringToIndex:2] ;
				seconds += 60*60*24 * [substring integerValue] ;
			}
		}
		
        [string release] ;
	}
	
	return seconds ;
}

@end



/*
 
 
 // Here is Philip Aker's method of killing a process named "System Events":
 // err = system( "kill `ps axo pid,command | grep 'System Events' | grep -v grep | cut -d '/' -f 1 | tr -d ' '`" );
 
 Some code that someone posted on CocoaBuilder.  Seems similar to mine except uses
 more process serial numbers instead of process identifiers (pid).
 
		
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