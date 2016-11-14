#import "SSYProcessTyper.h"

NSString* constKeyTimeoutDate = @"timeoutDate" ;
NSString* constKeyTimeoutSelectorName = @"timeoutSelectorName"  ;

@protocol DancePartnerApp <NSObject>

- (NSString*)associatedBackgroundAppBundleIdentifier ;

@end

@implementation SSYProcessTyper

+ (NSApplicationActivationPolicy)currentType {
    return [NSApp activationPolicy] ;
}

#define TIMEOUT_TO_START_FIRST_DANCE_WITH_FINDER 1.0
/*
 The above should be long enough that it does not do the dance when launched
 from Finder, but short enough that it is not too annoying for Alfred users
 who will require the dance.  Because there are many more non-Alfred users than
 Alfred, I have biased it up toward being longer.  With only 1.5 seconds,
 launching from Xcode, I would see the dance on my 2013 MacBook Air about
 5% of the time.
 */
#define TIMEOUT_TO_START_SUBSEQUENT_DANCES 0.5
#define MENU_BAR_RETRY_INTERVAL 0.025

+ (void)setAndVerifyActivationPolicy:(NSApplicationActivationPolicy)type
                               label:(NSString*)label {
    BOOL didSucceed = [NSApp setActivationPolicy:type] ;
    /* The above method is supposed to return NO if it fails, but we have found
     that, at least in macOS 10.11 and 10.12, it falsely returns YES.  
     So we check for that outcome… */
    NSApplicationActivationPolicy newType = [NSApp activationPolicy] ;
    if ((newType != type) && (didSucceed == YES)) {
        NSLog(
              @"%@ transforming to process type %ld *says* it succeeded, but type is still %ld",
              label,
              (long)type,
              (long)newType) ;
    }
}

+ (void)dance {
    NSRunningApplication* dancePartnerApp = nil ;
    NSString* dancePartnerAppBundleIdentifier = nil ;
    if ([[NSApp delegate] respondsToSelector:@selector(associatedBackgroundAppBundleIdentifier)]) {
        dancePartnerAppBundleIdentifier = [(NSObject <DancePartnerApp> *)[NSApp delegate] associatedBackgroundAppBundleIdentifier] ;
        dancePartnerApp = [[NSRunningApplication runningApplicationsWithBundleIdentifier:dancePartnerAppBundleIdentifier] firstObject] ;
    }
    if (!dancePartnerApp) {
        dancePartnerAppBundleIdentifier = @"com.apple.finder" ;
        dancePartnerApp = [[NSRunningApplication runningApplicationsWithBundleIdentifier:dancePartnerAppBundleIdentifier] firstObject] ;
    }

    [dancePartnerApp activateWithOptions:NSApplicationActivateIgnoringOtherApps] ;

    [self performSelector:@selector(danceStep2) withObject:nil
               afterDelay:0.0];
}

+ (void)danceStep2 {
    [self setAndVerifyActivationPolicy:NSApplicationActivationPolicyRegular
                                 label:@"1325"] ;

    [self performSelector:@selector(danceStep3) withObject:nil
               afterDelay:0.0];
}

+ (void)danceStep3 {
    [[NSRunningApplication currentApplication] activateWithOptions:NSApplicationActivateIgnoringOtherApps];

    NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSDate dateWithTimeIntervalSinceNow:TIMEOUT_TO_START_SUBSEQUENT_DANCES], constKeyTimeoutDate,
                          @"dance", constKeyTimeoutSelectorName,
                          nil] ;
    [self performSelector:@selector(beginDanceToGetOwnershipOfMenuBar:)
               withObject:info
               afterDelay:MENU_BAR_RETRY_INTERVAL] ;
}

+ (void)beginDanceToGetOwnershipOfMenuBar:(NSDictionary*)info {
    NSDate* timeoutDate = [info objectForKey:constKeyTimeoutDate] ;
    if ([[NSDate date] earlierDate:timeoutDate] == timeoutDate) {
        // Timeout.  Start or restart the dance to get the menu bar
        SEL timeoutSelector = NSSelectorFromString([info objectForKey:constKeyTimeoutSelectorName]) ;
        [self performSelector:timeoutSelector] ;
    }
    else {
        BOOL ownsMenuBar = [[NSRunningApplication currentApplication] ownsMenuBar] ;
        if (!ownsMenuBar) {
            [self performSelector:@selector(beginDanceToGetOwnershipOfMenuBar:)
                       withObject:info
                       afterDelay:MENU_BAR_RETRY_INTERVAL] ;
        }
        else if ([NSApp activationPolicy] == NSApplicationActivationPolicyRegular) {
            // Succeeded.  Done.
        }
        else {
            // Try one more time
            [self setAndVerifyActivationPolicy:NSApplicationActivationPolicyRegular
                                         label:@"1335"] ;
            if ([NSApp activationPolicy] != NSApplicationActivationPolicyRegular) {
                NSString* format = NSLocalizedString(@"macOS failed to completely activate %@.  This can happen if there are dozens of tabs open in a web browser such as Safari.  Please close unnecessary tabs, then try to relauch %@.", nil) ;
                NSString* appName = [[[[NSBundle mainBundle] bundlePath] lastPathComponent] stringByDeletingPathExtension] ;
                NSString* msg = [NSString stringWithFormat:
                                format,
                                appName,
                                appName] ;
                NSAlert* alert = [[NSAlert alloc] init] ;
                alert.messageText = NSLocalizedString(@"macOS Failure", nil) ;
                alert.informativeText = msg ;
                [alert runModal] ;
                [NSApp terminate:self] ;
                [alert release] ;  // Silly, but to suppress static analyzer warning.
            }
            else {
                NSLog(@"Weird.  Succeeded activating forward on the last retry.") ;
            }
        }
    }
}

+ (void)activateNow {
    [NSApp activateIgnoringOtherApps:YES] ;
}

+ (void)transformToType:(NSApplicationActivationPolicy)type {
    [self setAndVerifyActivationPolicy:type
                                 label:@"1315"] ;
    BOOL doShow = (type == NSApplicationActivationPolicyRegular) ;
    
    if (doShow) {
		[NSApp activateIgnoringOtherApps:YES] ;

        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSDate dateWithTimeIntervalSinceNow:TIMEOUT_TO_START_FIRST_DANCE_WITH_FINDER], constKeyTimeoutDate,
                              @"dance", constKeyTimeoutSelectorName,
                               nil] ;
        [self beginDanceToGetOwnershipOfMenuBar:info] ;
    }
}

+ (void)transformToForeground:(id)sender {
	[self transformToType:NSApplicationActivationPolicyRegular] ;
}

+ (void)transformToUIElement:(id)sender {
	[self transformToType:NSApplicationActivationPolicyAccessory] ;
}

+ (void)transformToBackground:(id)sender {
	[self transformToType:NSApplicationActivationPolicyProhibited] ;
}


@end
