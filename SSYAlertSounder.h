#import <Cocoa/Cocoa.h>


/*!
 @brief    This is a quick hacky wrapper on Audio Services
 to play an alert sound cheaply and reliably (in contrast to NSSound)

 @details   Requires System/Library/Frameworks/AudioToolbox.framework,
 which is Mac OS 10.5 or later.

 In the earlier System Sound API, for these sounds to play, it was required
 that, in System Preferences > Sound > Play User Interface Sound Effects
 be enabled.  But this appears to work without it.
*/
@interface SSYAlertSounder : NSObject {
	NSMutableDictionary* m_soundIds ;
}

/*!
 @brief    Plays a desired sound

 @details  
 @param    name  The name of a sound file, not including the .aiff extension.
*/
- (void)playAlertSoundNamed:(NSString*)name ;

+ (SSYAlertSounder*)sharedSounder ;

@end

