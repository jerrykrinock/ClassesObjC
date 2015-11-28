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
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular] ;

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
        else {
            // Succeeded owning the menu bar.  Done.
        }
    }
}

+ (void)activateNow {
    [NSApp activateIgnoringOtherApps:YES] ;
}

+ (void)transformToType:(NSApplicationActivationPolicy)type {
    [NSApp setActivationPolicy:type] ;
    
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