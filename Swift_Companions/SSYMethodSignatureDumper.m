#import "MethodSignatureDumper.h"
#import <OS/log.h>

@implementation SSYMethodSignatureDumper

+ (void)dumpMethodSignatureForTarget:(id)target
                            selector:(SEL)selector {
    NSMethodSignature* ms = [target methodSignatureForSelector:selector];
    os_log(OS_LOG_DEFAULT, "dump of %@", NSStringFromSelector(selector));
    os_log(OS_LOG_DEFAULT, "   return type is '%s'", ms.methodReturnType);
    os_log(OS_LOG_DEFAULT, "   frame length is '%ld'", (long)ms.frameLength);
    NSInteger nArgs = [ms numberOfArguments] ;
    os_log(OS_LOG_DEFAULT, "   nArgs is %ld", (long)ms.numberOfArguments);
    for (NSInteger i=0; i<nArgs; i++) {
        const char* argType = [ms getArgumentTypeAtIndex:i];
        os_log(OS_LOG_DEFAULT, "   argument %ld is of type code '%s'", (long)i, argType);
    }
}

@end
