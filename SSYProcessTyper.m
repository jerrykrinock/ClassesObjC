#import "SSYProcessTyper.h"

@implementation SSYProcessTyper

/*
 Added in BookMacster 1.14.4.  See piggyback comment in counterpart .h file.
 */
+ (ProcessApplicationTransformState)appleTypeForType:(SSYProcessTyperType)type {	
	ProcessApplicationTransformState answer ;

#if MAC_OS_X_VERSION_MAX_ALLOWED > 1060
	switch (type) {
		case SSYProcessTyperTypeForeground:
			answer = kProcessTransformToForegroundApplication ;
			break ;
		case SSYProcessTyperTypeBackground:
			answer = kProcessTransformToBackgroundApplication ;
			break ;
		case SSYProcessTyperTypeUIElement:
			answer = kProcessTransformToUIElementApplication ;
			break ;
	}
#else
	// Sorry, this is the only type available prior to Mac OS X 10.7
	answer = SSYProcessTyperTypeForeground ;
	if (type != SSYProcessTyperTypeForeground) {
		NSLog(@"Internal Error 254-2210") ;
	}
#endif
	
	return answer ;
}

+ (SSYProcessTyperType)currentType {
	ProcessSerialNumber psn = { 0, kCurrentProcess } ;
	NSDictionary* info = nil ;
	info = (NSDictionary*)ProcessInformationCopyDictionary (&psn, kProcessDictionaryIncludeAllInformationMask) ;
	
    SSYProcessTyperType type ;
    
	if ([[info objectForKey:@"LSUIElement"] boolValue]) {
        type = SSYProcessTyperTypeUIElement ;
    }
    else if ([[info objectForKey:@"LSBackgroundOnly"] boolValue]) {
        type = SSYProcessTyperTypeBackground ;
    }
    else {
        type = SSYProcessTyperTypeForeground ;
    }

	if (info != NULL) {
		CFRelease((CFDictionaryRef)info) ;
	}
	
	return type ;
}

+ (pid_t)inactivateActiveAppAndReturnNewActiveApp {
	//NSLog(@"1000 Hiding Current ActiveApp: %@", [[[NSWorkspace sharedWorkspace] activeApplication] objectForKey:@"NSApplicationName"]) ;
	pid_t activeAppPid = (pid_t)[[[[NSWorkspace sharedWorkspace] activeApplication] objectForKey:@"NSApplicationProcessIdentifier"] integerValue] ;
	OSStatus err;
	ProcessSerialNumber psn ;
	err = GetProcessForPID(activeAppPid, &psn) ;
	if (err != noErr) {
        NSLog(@"Internal Error 915-9384 %ld", (long)err) ;
    }
	err = ShowHideProcess(&psn, false) ;
	if (err != noErr) {
        NSLog(@"Internal Error 915-9385 %ld", (long)err) ;
    }
	activeAppPid = (pid_t)[[[[NSWorkspace sharedWorkspace] activeApplication] objectForKey:@"NSApplicationProcessIdentifier"] integerValue] ;
    return activeAppPid ;
}

+ (void)bringFrontPid:(pid_t)pid {
	// Remember that any NSLogs early in the app results in two "Help" menus
	//NSLog(@"ActiveApp: %@", [[[NSWorkspace sharedWorkspace] activeApplication] objectForKey:@"NSApplicationName"]) ;
	sleep(2) ;
	ProcessSerialNumber psn ;
	OSStatus err ;
	err = GetProcessForPID(pid, &psn) ;
	if (err != noErr) {
        NSLog(@"Internal Error 915-9386 %ld", (long)err) ;
    }
	SetFrontProcess(&psn);
}

+ (void)transformToType:(SSYProcessTyperType)type {
    if (type == [self currentType]) {
        // Nothing to do
        return ;
    }
    
    if (type != SSYProcessTyperTypeForeground) {
        if (NSAppKitVersionNumber < 1100) {
            // Sorry, transforming to UIElement or Background requires
            // Mac OS X 10.7 or later.
            return ;
        }
    }
    
    // Actual Subtance
    ProcessSerialNumber psn = { 0, kCurrentProcess } ;
    OSStatus err ;
    err = TransformProcessType(&psn, [self appleTypeForType:type]) ;
    if (err != noErr) {
        NSLog(@"Internal Error 915-9387 %ld", (long)err) ;
    }
    
    BOOL doShow = (type == SSYProcessTyperTypeForeground) ;

    if (doShow) {
		[NSApp activateIgnoringOtherApps:YES] ;
        err = ShowHideProcess(&psn, true);
        if (err != noErr) {
            NSLog(@"Internal Error 915-9172 %ld", (long)err) ;
        }
    }
}

+ (void)transformToForeground:(id)sender {
	[self transformToType:SSYProcessTyperTypeForeground] ;
}

#if (MAC_OS_X_VERSION_MAX_ALLOWED > 1060)

+ (void)transformToUIElement:(id)sender {
	[self transformToType:SSYProcessTyperTypeUIElement] ;
}

+ (void)transformToBackground:(id)sender {
	[self transformToType:SSYProcessTyperTypeBackground] ;
}

#endif


@end