#import <Foundation/Foundation.h>

/*!
 @brief    Image view which will be skipped over by VoiceOver

 @details  Be careful that you *really* want the view to be skipped over by
 VoiceOver, because its meaning is conveyed in a better, non-visual way,
 elsewhere.  Remember that not all VoiceOver users are completely blind.
 */
@interface SSYNoVoiceOverImageView : NSImageView {}
@end

/*!
 @brief    Button which will be skipped over by VoiceOver

 @details  Be careful that you *really* want the button to be skipped over by
 VoiceOver, because its meaning is conveyed in a better, non-visual way,
 elsewhere.  Remember that not all VoiceOver users are completely blind.
 */
@interface SSYNoVoiceOverButton : NSButton {}
@end

/*!
 @brief    Text field which will be skipped over by VoiceOver

 @details  Be careful that you *really* want the field to be skipped over by
 VoiceOver, because its meaning is conveyed in a better, non-visual way,
 elsewhere.  Remember that not all VoiceOver users are completely blind.
 */
@interface SSYNoVoiceOverTextField : NSTextField {}
@end

