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
	//NSLog(@"2000 New ActiveApp: %@", [[[NSWorkspace sharedWorkspace] activeApplication] objectForKey:@"NSApplicationName"]) ;
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
	
#if 0
		ProcessSerialNumber psn;
		pid_t pid = getpid();
		OSStatus err;
		err = ShowHideProcess(&psn, true);
		err = TransformProcessType(&psn, kProcessTransformToForegroundApplication);
		[NSMenu setMenuBarVisible:NO];
		SetFrontProcess(&psn);
		[NSMenu setMenuBarVisible:YES];
		// [NSMenu setMenuBarVisible:YES] ;  // causes The Dreaded Two Help Menus if run in app delegate's -init
		
		// More stuff which doesn't work
		// At this point, this app will show in the dock, but the menu
		// will not show unless you activate some other app and then
		// re-activate this app.  I tried a bunch of stuff but nothing
		// worked reliably
		
		BOOL yes = YES ;
		NSInvocation* invocation = [NSInvocation invocationWithTarget:[NSMenu class]
															 selector:@selector(setMenuBarVisible:)
													  retainArguments:YES
													argumentAddresses:&yes] ;
		[invocation performSelector:@selector(invoke)
						 withObject:nil
						 afterDelay:1.0] ;
		[invocation performSelector:@selector(invoke)
						 withObject:nil
						 afterDelay:2.0] ;
		[invocation performSelector:@selector(invoke)
						 withObject:nil
						 afterDelay:3.0] ;

		for (NSWindow* window in [NSApp windows]) {
			[window display] ;
			usleep(500000) ;
			[NSMenu setMenuBarVisible:NO];
			[window makeKeyAndOrderFront:self] ;
			usleep(500000) ;
			[NSMenu setMenuBarVisible:YES];
		}
		[NSApp activateIgnoringOtherApps:YES] ;
		// [[[[[NSApp mainMenu] itemArray] objectAtIndex:0] submenu] performActionForItemAtIndex:0] ;
#else
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
#endif
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