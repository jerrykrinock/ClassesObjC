#import <Cocoa/Cocoa.h>


/*!
 @brief    Returns the current state of the modifier keys on the
 keyboard.

 @details  Uses a Quartz event function because [NSEvent currentEvent]
 may return nil during -applicationDidFinishLaunching.
 
 There are also Carbon functions which work, but they appear to
 be kind of depracated, returning a UInt32.
 #import "Carbon/Carbon.h"
 UInt32 carbonModifiers = GetCurrentEventKeyModifiers() ;
 UInt32 carbonModifiers = GetCurrentKeyModifiers() ;
 So I don't use them.
 */
@interface SSYEventInfo : NSObject {
}

+ (BOOL)alternateKeyDown;
+ (BOOL)shiftKeyDown;
+ (BOOL)commandKeyDown;
+ (BOOL)controlKeyDown;

@end
