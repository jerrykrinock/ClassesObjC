#import "SSYDebug.h"
#import <execinfo.h>
#import <mach-o/dyld.h>

id ssyDebugGlobalObject = nil ;

NSString* SSYDebugBacktrace(void) {
	NSMutableString* nsString = [[NSMutableString alloc] initWithFormat:
								 @"Thread:  isMainThread=%hhd  name=%@\n",
								 [[NSThread currentThread] isMainThread],
								 [[NSThread currentThread] name]] ;

	[nsString appendString:@"   Slide(0x) Library\n"] ;
	NSUInteger i;
	NSUInteger count = _dyld_image_count();

	for (i = 0; i < count; i++) {
		intptr_t slide = _dyld_get_image_vmaddr_slide(i); 
		NSString* name = [NSString stringWithUTF8String:_dyld_get_image_name(i)] ;
		NSString* exclude1 = @"/usr/lib/" ;
		NSString* exclude2 = @"/System/Library/" ;
		if ([name hasPrefix:exclude1]) {
			continue ;
		}
		if ([name hasPrefix:exclude2]) {
			continue ;
		}
		[nsString appendFormat:@"%12lx %@\n", slide, name] ;
	}
	
	[nsString appendString:@"Call Stack:\n"] ;
	// An infinite loop will "blow its stack" at 512 calls, so
	// we allow a little more than that.
	void* callstack[514] ;
	NSInteger frames = backtrace(callstack, 514) ;
	char** strs = backtrace_symbols(callstack, frames) ;
	NSInteger iFrame ;
	for (iFrame = 1; iFrame < frames; ++iFrame) {
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
	
void SSYDebugLogBacktrace (void) {
	NSLog(@"\n%@", SSYDebugBacktrace()) ;
}

NSInteger SSYDebugStackDepth(void) {
	// An infinite loop will "blow its stack" at 512 calls, so
	// we allow a little more than that.
	void* callstack[514] ;
	NSInteger frames = backtrace(callstack, 514) ;
	return frames ;
}

NSString* SSYDebugBacktraceDepth(NSInteger depth) {
	if (depth < 1) {
		return nil ;
	}

	// Omit this function, and the function that called it
	depth += 2 ;
	NSMutableString* nsString = [[NSMutableString alloc] init] ;
	
	void* callstack[depth] ;
	NSInteger frames = backtrace(callstack, depth) ;
	char** strs = backtrace_symbols(callstack, frames) ;
	NSInteger iFrame ;
	for (iFrame = 2; iFrame < frames; ++iFrame) {
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

NSString* SSYDebugCaller(void) {
	void* callstack[3] ;
	NSInteger frames = backtrace(callstack, 3) ;
	char** strs = backtrace_symbols(callstack, frames) ;
	NSString* caller = [NSString stringWithCString:strs[2]
										  encoding:NSUTF8StringEncoding] ;
	free(strs) ;
	// caller is, e.g., "2   AppKit                              0x9a13352e -[NSCustomObject nibInstantiate] + 385"
	NSMutableString* mutant = [caller mutableCopy] ;
	NSUInteger oldLength ;
	do {
		oldLength = [mutant length] ;		
		[mutant replaceOccurrencesOfString:@"  "
								withString:@" "
								   options:0
									 range:NSMakeRange(0, [mutant length])] ;
	} while ([mutant length] < oldLength) ;
	caller = [NSString stringWithString:mutant] ;
	[mutant release] ;
	NSArray* comps = [caller componentsSeparatedByString:@" "] ;
	caller = [comps objectAtIndex:3] ;
	if ([comps count] > 6) {
		// caller is an Objective-C method name, which includes a space.
		// Thus it consists of two components which we now re-concatenate
		caller = [caller stringByAppendingString:@" "] ;
		caller = [caller stringByAppendingString:[comps objectAtIndex:4]] ;
	}
	return caller ;
}


