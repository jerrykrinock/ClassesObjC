#import "SSYDebug.h"
#import <execinfo.h>
#import <mach-o/dyld.h>

id ssyDebugGlobalObject = nil ;

NSString* SSYDebugBacktrace() {
	NSMutableString* nsString = [[NSMutableString alloc] initWithFormat:
								 @"Thread:  isMainThread=%d  name=%@\n",
								 [[NSThread currentThread] isMainThread],
								 [[NSThread currentThread] name]] ;

	[nsString appendString:@"   Slide(0x) Library\n"] ;
	unsigned long i;
	unsigned long count = _dyld_image_count();

	for (i = 0; i < count; i++) {
		unsigned long slide = _dyld_get_image_vmaddr_slide(i); 
		NSString* name = [NSString stringWithUTF8String:_dyld_get_image_name(i)] ;
		NSString* exclude1 = @"/usr/lib/" ;
		NSString* exclude2 = @"/System/Library/" ;
		if ([name hasPrefix:exclude1]) {
			continue ;
		}
		if ([name hasPrefix:exclude2]) {
			continue ;
		}
		[nsString appendFormat:@"%12x %@\n", slide, name] ;
	}
	
	[nsString appendString:@"Call Stack:\n"] ;
	// An infinite loop will "blow its stack" at 512 calls, so
	// we allow a little more than that.
	void* callstack[514] ;
	NSInteger frames = backtrace(callstack, 514) ;
	char** strs = backtrace_symbols(callstack, frames) ;
	NSInteger iFrame ;
	for (iFrame = 0; iFrame < frames; ++iFrame) {
		NSString* moreString = [NSString stringWithCString:strs[iFrame]
												  encoding:NSUTF8StringEncoding] ;
		[nsString appendString:moreString] ;
		[nsString appendString:@"\n"] ;
	}
	free(strs) ;
	
	NSString* answer = [nsString copy] ;
	[nsString release] ;
	
	return [answer autorelease] ;
}
	
void SSYDebugLogBacktrace () {
	NSLog(@"\n%@", SSYDebugBacktrace()) ;
}


NSInteger SSYDebugStackDepth() {
	// An infinite loop will "blow its stack" at 512 calls, so
	// we allow a little more than that.
	void* callstack[514] ;
	NSInteger frames = backtrace(callstack, 514) ;
	return frames ;
}



