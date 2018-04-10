#import "SSYDebug.h"
#import <execinfo.h>
#import <mach-o/dyld.h>
#import <objc/runtime.h>

id ssyDebugGlobalObject = nil ;
double ssyDebugGlobalDouble = 0.0 ;
NSInteger ssyDebugGlobalInteger = 0 ;

NSString* SSYDebugBacktrace(void) {
	NSMutableString* nsString = [[NSMutableString alloc] initWithFormat:
								 @"Thread:  isMainThread=%hhd  name=%@\n",
								 [[NSThread currentThread] isMainThread],
								 [[NSThread currentThread] name]] ;

	[nsString appendString:@"   Slide(0x) Library\n"] ;
	uint32_t i;
	NSUInteger count = _dyld_image_count();

	for (i = 0; i < count; i++) {
		intptr_t slide = (intptr_t)_dyld_get_image_vmaddr_slide(i);
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
	int frames = backtrace(callstack, 514) ;
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
#if !__has_feature(objc_arc)
	[nsString release] ;
    [answer autorelease] ;
#endif
    
	return answer ;
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
	int frames = backtrace(callstack, (int)depth) ;
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
#if !__has_feature(objc_arc)
	[nsString release] ;
    [answer autorelease] ;
#endif
	
	return answer ;
}

NSString* SSYDebugCaller(void) {
	void* callstack[3] ;
	int frames = backtrace(callstack, 3) ;
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
#if !__has_feature(objc_arc)
	[mutant release] ;
#endif
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

BOOL SSYDebugLogObjcClassesByBundleToFile (
                                           NSString* path,
                                           NSError** error_p) {
    BOOL ok = YES ;
    NSError* error = nil ;
    NSMutableDictionary* results = [NSMutableDictionary new] ;
    
    int numberOfClasses = objc_getClassList(NULL, 0);
    Class *classes = calloc(sizeof(Class), numberOfClasses);
    numberOfClasses = objc_getClassList(classes, numberOfClasses);
    for (int i = 0; i < numberOfClasses; ++i) {
        Class class = classes[i] ;
        NSString* className = NSStringFromClass(class) ;
        if (![className isEqualToString:@"NSViewServiceApplication"]) {
            NSBundle* bundle = [NSBundle bundleForClass:class] ;
            NSString* bundleIdentifier = bundle.bundleIdentifier ;
            if (bundleIdentifier) {
                if (className) {
                    NSMutableArray* classNames = [results objectForKey:bundleIdentifier] ;
                    if (!classNames) {
                        classNames = [NSMutableArray new] ;
                        [results setObject:classNames
                                    forKey:bundleIdentifier] ;
#if !__has_feature(objc_arc)
                        [classNames release] ;
#endif
                    }
                    
                    [classNames addObject:className] ;
                }
            }
        }
    }
    free(classes) ;
    
    NSMutableArray* bundleIdentifiers = [[results allKeys] mutableCopy] ;
    [bundleIdentifiers sortUsingSelector:@selector(caseInsensitiveCompare:)] ;

    NSMutableString* narrative = [NSMutableString new] ;
    for (NSString* bundleIdentifier in bundleIdentifiers) {
        NSMutableArray* classNames = [results objectForKey:bundleIdentifier] ;
        [classNames sortUsingSelector:@selector(caseInsensitiveCompare:)] ;
        [narrative appendFormat:@"CLASSES IN %@\n", bundleIdentifier] ;
        for (NSString* className in classNames) {
            [narrative appendFormat:@"   %@\n", className] ;
        }
    }
    
    ok = [narrative writeToFile:path
                     atomically:YES
                       encoding:NSUTF8StringEncoding
                          error:&error] ;
    
#if !__has_feature(objc_arc)
    [results release] ;
    [narrative release]  ;
#endif

    if (error && error_p) {
        *error_p = error ;
    }

    return ok ;
}

void SSYDebugLogResponderChain(void) {
    NSWindow *mainWindow = [NSApplication sharedApplication].mainWindow;

    NSMutableString* chain = [NSMutableString new];
    [chain appendString:@"Responder Chain (stops at window controller):\n"];
    NSResponder *responder = mainWindow.firstResponder;
    do {
        [chain appendFormat:@"  %@\n", [responder debugDescription]];
    } while ((responder = [responder nextResponder]));

    NSLog(@"%@", chain);
    [chain release];
}

void SSYDebugLogObjCMethods(Class clz) {

    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(clz, &methodCount);

    printf("Found %d methods on '%s'\n\n", methodCount, class_getName(clz));

    for (unsigned int i = 0; i < methodCount; i++) {
        Method method = methods[i];

        printf("%s\n", sel_getName(method_getName(method)));

        /**
         *  Or do whatever you need here...
         */
    }
    printf("\n\n");
    free(methods);
}
