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
#if NO_ARC
	info = (NSDictionary*)ProcessInformationCopyDictionary (&psn, kProcessDictionaryIncludeAllInformationMask) ;
#else
    info = (__bridge NSDictionary*)ProcessInformationCopyDictionary (&psn, kProcessDictionaryIncludeAllInformationMask) ;
#endif
    
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
    NSRunningApplication* app = [NSRunningApplication runningApplicationWithProcessIdentifier:pid] ;
    [app activateWithOptions:0] ;
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
#pragma deploymate push "ignored-api-availability" // Skip it until next "pop"
        NSRunningApplication* menuBarApp = [[NSWorkspace sharedWorkspace] menuBarOwningApplication] ;
#pragma deploymate pop
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

        // This section was code was moved here in BookMacster 1.20.1, and
        // further, qualified to only execute prior to Mac OS X 10.9.
        if (NSAppKitVersionNumber < 1200) {
            /*
             Prior to Mac OS X 10.9, transforming a process' type to
             LSIUElement, by itself, does not cause the main menu bar to assume
             a different app.  Neither does this…
             [NSApp hide:self] ;
             So I use the following kludge, which will probably work 98% of the time.
             In my testing, it always worked.  But even if it does not work, it's not
             too bad; just a little head-scratching by the user. */
            NSString* ourBundleIdentifier = [[NSBundle mainBundle] bundleIdentifier] ;
            
            /* Officially, the order of apps in -[NSWorkspaces runningApplicatons]
             return value is unspecified.  In practice, I find that the order is roughly
             the order in which apps were launched (starting with the loginWindow and
             other system apps we don't want to re-activate), and the last activated.
             Therefore, we want something from the *end* of the array.  Hence we use
             a reverse enumerator… */
            for (NSRunningApplication* otherApp in [[[NSWorkspace sharedWorkspace] runningApplications] reverseObjectEnumerator]) {
                
                if (![[otherApp bundleIdentifier] isEqualToString:ourBundleIdentifier]) {
                    // The next if() is also kind of a heuristic.
                    if (![otherApp isHidden]) {
                        /* otherApp may in fact be a faceless app, in particular,
                         Sheep-Sys-UrlHandler.  But it seems that if we get one of those,
                         and tell it to "launch", some other, more appropriate app
                         will get ownership of the menu bar.  That's what we want. */
                        NSString* otherAppName = [otherApp localizedName] ;
                        BOOL didActivateSomeOtherApp = [[NSWorkspace sharedWorkspace] launchApplication:otherAppName] ;
                        if (didActivateSomeOtherApp) {
                            break ;
                        }
                    }
                }
            }
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

+ (void)transformToUIElement:(id)sender {
	[self transformToType:SSYProcessTyperTypeUIElement] ;
}

+ (void)transformToBackground:(id)sender {
	[self transformToType:SSYProcessTyperTypeBackground] ;
}


@end