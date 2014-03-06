#import <Cocoa/Cocoa.h>

/*
 Use this if you need to keep a process running long enough for your
 sound to complete playing.  This is an integer so that it can be
 used as a parameters to functions that require integers, like sleep().
 */
#define SECONDS_NEEDED_FOR_ONE_ALERT_SOUND 1


/*!
 @brief    This is a quick hacky wrapper on Audio Services
 to play an alert sound cheaply and reliably (in contrast to NSSound)

 @details   Requires System/Library/Frameworks/AudioToolbox.framework,
 which is Mac OS 10.5 or later.

 In the earlier System Sound API, for these sounds to play, it was required
 that, in System Preferences > Sound > Play User Interface Sound Effects
 be enabled.  But this appears to work without it.
*/
__attribute__((visibility("default"))) @interface SSYAlertSounder : NSObject {
	NSMutableDictionary* m_soundIds ;
}

/*!
 @brief    Plays a desired sound

 @details  
 @param    name  The name of a sound file, not including the .aiff extension,
 or nil to no-op
*/
- (void)playAlertSoundNamed:(NSString*)name ;

+ (SSYAlertSounder*)sharedSounder ;

@end

