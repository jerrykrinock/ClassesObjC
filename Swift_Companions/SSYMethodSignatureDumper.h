#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SSYMethodSignatureDumper : NSObject

/*!
 @brief  Dumps to the console a nice description of the Objective-C method
 signature for a given method

 @details  Although this method is Objective-C, it is used in Swift code.
 It is useful if you need to see the Objective-C method signature of a method
 when debugging code from a Swift file, because Swift does not  expose
 NSMethodSignature.  Import this file in your Swift-Bridging-Header.h

 Here are 4 examples of how to invoke this method in Swift:

 MethodSignatureDumper.dumpMethodSignature(forTarget:self, selector:#selector(self.agentBundleIdentifier))
 MethodSignatureDumper.dumpMethodSignature(forTarget:self, selector:#selector(GUIAppDel.loginItemSwitch(on:)))
 MethodSignatureDumper.dumpMethodSignature(forTarget:agentProxy, selector:#selector(Worker.getVersionThenDo(_:)))
 MethodSignatureDumper.dumpMethodSignature(forTarget:agentProxy, selector:#selector(Worker.doWork(on:thenDo:)))

 In #selector(), the prefixes "self." and "GUIAppDel." are equivalent.  These
 prefixes are optional if the target method is in a class, but required
 if the target method is in a protocol, and in that case the protocol name,
 for example, "Worker", must be used explicitly.

 In the output log entry, in the list of arguments, argument 0 is the message
 receiver and argument 1 is the selector (method).  Argument types are given as
 encoded as "type codes".  To decode, look up the codes in Apple's
 Objective-C Runtime Programming Guide > Type Encodings
 https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html#//apple_ref/doc/uid/TP40008048-CH100
 */
+ (void)dumpMethodSignatureForTarget:(id)target
                            selector:(SEL)selector;

@end

NS_ASSUME_NONNULL_END
