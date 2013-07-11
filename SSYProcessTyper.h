#import <Cocoa/Cocoa.h>

/*
 This enum was added in BookMacster 1.14.4.  Prior to that,
 I piggybacked on kProcessTransformToForegroundApplication and 
 its two friends.  But those are not all defined in the 10.6
 SDK.  So I did it the correct way now.  For defensive programming,,
 the three values here match the values of the corresponding
 kProcessTransformToForegroundApplication and friends.
 
 I don't know what is the difference between the types "Background" and
 "UIElement".  I never user the former, only the latter.  I have not been able
 to find any explanation in Apple documemtation.
 */
enum SSYProcessTyperType_enum {
	SSYProcessTyperTypeForeground = 1,
	SSYProcessTyperTypeBackground = 2,
	SSYProcessTyperTypeUIElement = 4
} ;
typedef enum SSYProcessTyperType_enum SSYProcessTyperType ;


@interface SSYProcessTyper : NSObject {

}

+ (SSYProcessTyperType)currentType ;

+ (void)transformToForeground:(id)sender ;

#if (MAC_OS_X_VERSION_MAX_ALLOWED > 1060)
+ (void)transformToUIElement:(id)sender ;
+ (void)transformToBackground:(id)sender ;
#endif

@end
