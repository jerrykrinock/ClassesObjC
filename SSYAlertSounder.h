#import <Cocoa/Cocoa.h>

/*!
 @brief    This is wrapper on macOS and iOS Audio Services API, whose purpose is
 to play an alert sound cheaply and reliably (in contrast to NSSound)
 
 @details   The sound level (volume) of the sounds produced by this class
 tracks the setting of both sliders in System Preferences > Sound: 'Alert
 volume' and 'Output volume'.  This behavior is inherent in the Audio Services
 API.

 To make performance even cheaper, sounds are cached by name upon first use.
 See -forgetCache > Description.
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

/*!
 @brief    Returns an array, localizedly sorted, containing all of the names
 of the sounds which are available for use by -playAlertSoundNamed, provided
 that none of the underlying files disappeared in the meantime
 */
- (NSArray*)availableSoundsSorted;

/*!
 @details  You must send this message if you want the new sounds to be
 played after sounds are changed on disk, or after user assigns a custom
 sound in user defaults.
 */
- (void)forgetCache;

+ (SSYAlertSounder*)sharedSounder;

/*!
 @brief    Returns a key which may be used to set a custom sound for a given
 name.  To do that, set in user defaults the path to the desired sound, which
 must be a .aiff file.  If the path is enclosed in the user's home directory,
 for portability, you may give it in tilde form – example:
 •    ~/Library/My Sounds/Example.aiff
 */
+ (NSString*)userDefaultsKeyForCustomSoundPathForName:(NSString*)name;

@end

