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
#define SSYTRACE(identifier,object) { NSString* objectDesc = object ? [NSString stringWithFormat:@" %@", [(id)object shortDescription]] : @"" ; NSLog(@"SSYTrace: %06ld (%@)%@", (long)identifier, [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] stringByDeletingPathExtension], objectDesc) ; }
#else
#define SSYTRACE(identifier,object) 
#endif

/*!
 @brief    Returns a string containing the complete current backtrace,
 beginning with the caller of this function, prefixed by a table of
 useful library load addresses (slides).

 @details  This is the most verbose function in this file, the
 one whose output you'll want to include in your error reports.
 
 Slides for system libraries, those in directories 
 /usr/lib/ or /System/Library, are not included in the table
 of slides because they are useless and noise up the result with
 many lines of useless text.
 */
NSString* SSYDebugBacktrace(void) ;

/*!
 @brief    Returns a string containing the current backtrace, to a
 given depth.

 @param    depth  Determines what this function will return, per this table…
 depth  This function will return
 -----  -------------------------
 0      nil 
 1      1 line of text, containing the caller of the function that called this function
 2      2 lines of text, as in (1), plus another line consisting of the caller of the caller
 …      …
 
 Note that this function never returns the caller of this function, since you
 should already know that or can get it by __PRETTY_FUNCTION__.
*/
NSString* SSYDebugBacktraceDepth(NSInteger depth) ;

/*!
 @brief    Returns a string consisting of the symbol name of the
 caller of the function that called it.
*/
NSString* SSYDebugCaller(void) ;

void SSYDebugLogBacktrace(void) ;

NSInteger SSYDebugStackDepth(void) ;
