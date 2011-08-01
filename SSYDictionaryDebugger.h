#import <Cocoa/Cocoa.h>


/*!
 @brief    A thin wrapper around NSMutableDictionary which may
 be used in place of NSMutableDictionary when you want to have
 logged whenever the dictionary's contents are altered.
 
 @details  When using this class in place of NSMutableDictionary,
 you may get compiler warnings that SSYDebuggingMutableDictionary
 may not implement methods such as -count.&nbsp;  Ignore those
 warnings.&nbsp;  SSYDebuggingMutableDictionary will forward thoe
 messages to the NSMutableDictionary that it wraps.
 
 This class requires Mac OS 10.5 or later due to the use of
 -forwardingTargetForSelector.
 */
@interface SSYDebuggingMutableDictionary : NSObject
{
	NSMutableDictionary* dic ;
}
@end

