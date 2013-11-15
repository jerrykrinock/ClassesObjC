#import "SSYProcessTyper.h"

NSString* constKeyTimeoutDate = @"timeoutDate" ;
NSString* constKeyTimeoutSelectorName = @"timeoutSelectorName"  ;

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

#define TIMEOUT_BEFORE_TRYING_DANCE_WITH_FINDER 2.0
/*
 The above should be long enough that it does not do the dance when launched
 from Finder, but short enough that it is not too annoying for Alfred users
 who will require the dance.  Because there are many more non-Alfred users than
 Alfred, I have biased it up toward being longer.  With only 1.5 seconds,
 launching from Xcode, I would see the dance on my 2013 MacBook Air about
 5% of the time.
 */
#define TIMEOUT_AFTER_DANCE 0.5
#define WAIT_TO_TEST_AFTER_DANCE 1.0
#define MENU_BAR_RETRY_INTERVAL 0.025
#define TIMEOUT_FOR_DANCE_WITH_FINDER 3.0

+ (void)bringFrontPid:(pid_t)pid {
	ProcessSerialNumber psn ;
	OSStatus err ;
	err = GetProcessForPID(pid, &psn) ;
	if (err != noErr) {
        NSLog(@"Internal Error 915-9386 %ld", (long)err) ;
    }
	SetFrontProcess(&psn);
}

+ (void)danceWithFinder {
    for (NSRunningApplication * app in [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.finder"]) {
        [app activateWithOptions:NSApplicationActivateIgnoringOtherApps];
        break;
    }
    [self performSelector:@selector(danceWithFinderStep2) withObject:nil afterDelay:0.0];
}

+ (void)danceWithFinderStep2 {
    ProcessSerialNumber psn = { 0, kCurrentProcess };
    (void) TransformProcessType(&psn, kProcessTransformToForegroundApplication);
    
    [self performSelector:@selector(danceWithFinderStep3) withObject:nil afterDelay:0.0];
}

+ (void)danceWithFinderStep3 {
    [[NSRunningApplication currentApplication] activateWithOptions:NSApplicationActivateIgnoringOtherApps];

    NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSDate dateWithTimeIntervalSinceNow:TIMEOUT_AFTER_DANCE], constKeyTimeoutDate,
                          @"danceWithFinder", constKeyTimeoutSelectorName,
                          nil] ;

    [self performSelector:@selector(takeMenuBarWithInfo:)
               withObject:info
               afterDelay:MENU_BAR_RETRY_INTERVAL] ;
}

+ (void)takeMenuBarWithInfo:(NSDictionary*)info {
    NSDate* timeoutDate = [info objectForKey:constKeyTimeoutDate] ;
    if ([[NSDate date] earlierDate:timeoutDate] == timeoutDate) {
        // Timeout
        SEL timeoutSelector = NSSelectorFromString([info objectForKey:constKeyTimeoutSelectorName]) ;
        [self performSelector:timeoutSelector] ;
    }
    else {
        NSInteger gotMenuBarState = [self weGotMenuBar] ;
        if (gotMenuBarState == NSOffState) {
            [self performSelector:@selector(takeMenuBarWithInfo:)
                       withObject:info
                       afterDelay:MENU_BAR_RETRY_INTERVAL] ;
        }
        else {
            // Succeeded getting the menu bar.  Done.
        }
    }
}

+ (NSInteger)weGotMenuBar {
    NSInteger answer ;
    if (
        NSClassFromString(@"NSRunningApplication")
        &&
        [[NSWorkspace sharedWorkspace] respondsToSelector:@selector(menuBarOwningApplication)]
        ) {
        NSRunningApplication* menuBarApp = [[NSWorkspace sharedWorkspace] menuBarOwningApplication] ;
        BOOL weGotMenuBar = ([menuBarApp isEqual:[NSRunningApplication currentApplication]]) ;
        answer = weGotMenuBar ? NSOnState : NSOffState ;
    }
    else {
        // Mac OS X 10.6 or earlier..  We cannot test whether we got menu bar.
        // Stupid -[NSMenu isVisible] returns YES even when we are LSUIElement.
        answer = NSMixedState ;  // "We don't know."
    }
    
    return answer ;
}

+ (void)transformToType:(SSYProcessTyperType)type {
    // The following was removed in BookMacster 1.18
    //    if (type == [self currentType]) {
    //        // Nothing to do
    //        return ;
    //    }
    
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
    ProcessApplicationTransformState appleType = [self appleTypeForType:type] ;
    err = TransformProcessType(&psn, appleType) ;
    if (err != noErr) {
        // If you TransformProcessType to the current process type, that is,
        // don't change the type, you'll get err = -50 = paramErr here.
        // We don't consider that to be an error, and there are no other
        // reasonable errors that we know of.  So we ignore err.
    }
    
    BOOL doShow = (type == SSYProcessTyperTypeForeground) ;
    
    if (doShow) {
		[NSApp activateIgnoringOtherApps:YES] ;

        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSDate dateWithTimeIntervalSinceNow:TIMEOUT_BEFORE_TRYING_DANCE_WITH_FINDER], constKeyTimeoutDate,
                              @"danceWithFinder", constKeyTimeoutSelectorName,
                              nil] ;
        [self takeMenuBarWithInfo:info] ;
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