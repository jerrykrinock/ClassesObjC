#import <Cocoa/Cocoa.h>

#define SSY_DEBUG_INCLUDED 1

extern id ssyDebugGlobalObject ;

/*!
 @brief    Define a trace-level debugging macro
 @param    object  An object whose description you want printed
 */
#if 0
#warning Compiling with SSYTRACE macros activated to make NSLogs
#define MIRSKY 1
#define SSYTRACE(identifier,object) { NSString* objectDesc = object ? [NSString stringWithFormat:@" %@", [(id)object shortDescription]] : @"" ; NSLog(@"SSYTrace: %06d (%@)%@", identifier, [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] stringByDeletingPathExtension], objectDesc) ; }
#else
#define SSYTRACE(identifier,object) 
#endif

/*!
 @brief    Returns a string containing the current backtrace, prefixed
 by a table of useful library load addresses (slides).

 @details  Slides for system libraries, those in directories 
 /usr/lib/ or /System/Library, are not included in the table
 of slides because they are useless and noise up the result with
 many lines of useless text.
 */
NSString* SSYDebugBacktrace() ;

void SSYDebugLogBacktrace() ;

NSInteger SSYDebugStackDepth() ;
