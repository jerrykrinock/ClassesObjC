#import <Cocoa/Cocoa.h>

#if 0
#warning Compiling with SSYDebuggingMutableDictionary
#define SSY_DEBUGGING_MUTABLE_DICTIONARY_INCLUDED

// Set one or both of the following to 1
#define SSY_DEBUGGING_MUTABLE_DICTIONARY_LOG_CONTENTS_CHANGED 0
#define SSY_DEBUGGING_MUTABLE_DICTIONARY_LOG_MEMORY_MANAGEMENT 0



/*!
 @brief    A thin wrapper around NSMutableDictionary which may
 be used in place of NSMutableDictionary when you want to have
 logged whenever the dictionary's contents are changed, and/or
to log memory management.
 
 @details  When using this class in place of NSMutableDictionary,
 you may get compiler warnings that SSYDebuggingMutableDictionary
 may not implement methods such as -count.&nbsp;  Ignore those
 warnings.&nbsp;  SSYDebuggingMutableDictionary will forward those
 messages to the NSMutableDictionary that it wraps.
 
 This class requires Mac OS 10.5 or later due to the use of
 -forwardingTargetForSelector.
 */
@interface SSYDebuggingMutableDictionary : NSObject
{
	NSMutableDictionary* dic ;
}

@end

#endif