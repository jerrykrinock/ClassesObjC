#import "SSYAppleScripter.h"

/* Constants from the Carbon SpenScripting Framework */
FourCharCode AppleScriptSuite = 'ascr';
FourCharCode AppleScriptSubroutineEvent = 'psbr';
FourCharCode AppleScriptSubroutineName = 'snam';

@implementation SSYAppleScripter

+ (void)executeScriptWithUrl:(NSURL* _Nullable)scriptUrl
                 handlerName:(NSString* _Nullable)handlerName
           handlerParameters:(NSArray* _Nullable)handlerParameters
             ignoreKeyPrefix:(NSString* _Nullable)ignoreKeyPrefix
                    userInfo:(NSObject* _Nullable)userInfo
        blockUntilCompletion:(BOOL) blockUntilCompletion
           completionHandler:(void (^)(
                                       id payload,
                                       id _Nullable userInfo,
                                       NSError * _Nullable scriptError))completionHandler {
    NSError* error = nil;
    NSUserAppleScriptTask* script = [[NSUserAppleScriptTask alloc] initWithURL:scriptUrl
                                                                         error:&error];

	NSAppleEventDescriptor* requestEvent = nil;
    if (handlerName) {
        ProcessSerialNumber psn = { 0, kCurrentProcess };
        NSAppleEventDescriptor* target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber
                                                                                        bytes:&psn
                                                                                       length:sizeof(ProcessSerialNumber)];
        /* Weirdness: the handler name passed to Apple event must be
         lowercase even if the name in the script has uppercase
         characters! */
        NSAppleEventDescriptor* handler = [NSAppleEventDescriptor descriptorWithString:[handlerName lowercaseString]];

        requestEvent = [NSAppleEventDescriptor appleEventWithEventClass:AppleScriptSuite
                                                                eventID:AppleScriptSubroutineEvent
                                                       targetDescriptor:target
                                                               returnID:kAutoGenerateReturnID
                                                          transactionID:kAnyTransactionID];
        [requestEvent setParamDescriptor:handler forKeyword:AppleScriptSubroutineName];

        NSAppleEventDescriptor* parmListDescriptor = nil;
        if (handlerParameters.count > 0) {
            parmListDescriptor = [NSAppleEventDescriptor listDescriptor];
            NSInteger i = 1; // AppleEvent list indexes start with 1d
            for (id parm in handlerParameters) {
                NSAppleEventDescriptor* parmDescriptor;

                if ([parm isKindOfClass:[NSString class]]) {
                    parmDescriptor = [NSAppleEventDescriptor descriptorWithString:(NSString*)parm];
                } else if ([parm isKindOfClass:[NSNull class]]) {
                    parmDescriptor = [NSAppleEventDescriptor nullDescriptor];
                    /* This branch does not work as expected.
                     See Note WhyEmptyString-WhyNotNull in SSYAppleScripter.h*/


                    /*  TODO add more else if branches to support more classes
                     (NSNumber, etc.) here. */

                } else {
                    NSString* errorDesc = [NSString stringWithFormat:
                                           @"Unsupported handler parameter class %@ at index %ld.  Easy to fix by adding a new branch to above code([parm isKindOfClass:[NSString class]]) {.",
                                           [parm className],
                                           (i-1)
                                           ];
                    error = [NSError errorWithDomain:@"SSYAppleScripterErrorDomain"
                                                code:298578
                                            userInfo:@{
                                                       NSLocalizedDescriptionKey : errorDesc
                                                       }];
                    break;
                }

                [parmListDescriptor insertDescriptor:parmDescriptor
                                             atIndex:i];
                i++;
            }
        }

        if (!error) {
            [requestEvent setParamDescriptor:parmListDescriptor forKeyword:keyDirectObject];
        }
    }

    if (error) {
        if (completionHandler) {
            completionHandler(nil, userInfo, error);
        }
    } else {
        dispatch_semaphore_t semaphore = nil;
        if (blockUntilCompletion) {
            semaphore = dispatch_semaphore_create(0);
        }
        [script executeWithAppleEvent:requestEvent
                    completionHandler:^(NSAppleEventDescriptor * _Nullable replyEvent, NSError * _Nullable scriptError) {
                        NSInteger i;
                        id payload = nil;
                        if (replyEvent.descriptorType == typeAERecord) {
                            NSMutableDictionary* answersMutant = [[NSMutableDictionary alloc] init];
                            for (i=1; i<=[replyEvent numberOfItems]; i++) {
                                /* Reply events typically contain an even
                                 number of items, arranged as key/value pairs */
                                NSAppleEventDescriptor* subdescriptor = [replyEvent descriptorAtIndex:i];
                                NSInteger nItems = [subdescriptor numberOfItems];
                                if ((nItems > 0) && (nItems%2 == 0)) {
                                    NSUInteger j;
                                    for(j=1; j<=[subdescriptor numberOfItems]/2; j++) {
                                        NSString* key = [[subdescriptor descriptorAtIndex:(2*j-1)] stringValue];
                                        if (ignoreKeyPrefix) {
                                            if ([key hasPrefix:ignoreKeyPrefix]) {
                                                key = [key substringFromIndex:ignoreKeyPrefix.length];
                                            }
                                        }

                                        NSString* value = [[subdescriptor descriptorAtIndex:(2*j)] stringValue];
                                        if (key && value) {
                                            [answersMutant setObject:value
                                                              forKey:key];
                                        }
                                    }
                                    break;
                                }
                            }

                            payload = [[NSDictionary alloc] initWithDictionary:answersMutant];
#if !__has_feature(objc_arc)
                            [answersMutant release];
                            [payload autorelease];
#endif
                        } else if (replyEvent.descriptorType == typeAEList) {
                            NSMutableArray* answersMutant = [[NSMutableArray alloc] init];
                            for (i=1; i<=[replyEvent numberOfItems]; i++) {
                                NSAppleEventDescriptor* subdescriptor = [replyEvent descriptorAtIndex:i];
                                [answersMutant addObject:subdescriptor.stringValue];
                            }
                            payload = [[NSArray alloc] initWithArray:answersMutant];
#if !__has_feature(objc_arc)
                            [answersMutant release];
                            [payload autorelease];
#endif
                        }

                        if (completionHandler) {
                            completionHandler(payload, userInfo, scriptError);
                        }
                        if (semaphore) {
                            dispatch_semaphore_signal(semaphore);
                        }
                    }];
        if (semaphore) {
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
#if !__has_feature(objc_arc)
            dispatch_release(semaphore);
#endif
        }
    }
#if !__has_feature(objc_arc)
    [script release];
#endif
}

+ (void)executeScriptSource:(NSString* _Nonnull)source
            ignoreKeyPrefix:(NSString* _Nullable)ignoreKeyPrefix
                   userInfo:(NSObject* _Nullable)userInfo
       blockUntilCompletion:(BOOL) blockUntilCompletion
          completionHandler:(void (^ _Nullable)(
                                                id _Nullable payload,
                                                id _Nullable userInfo,
                                                NSError* _Nullable scriptError))completionHandler {
    CFUUIDRef cfUUID = CFUUIDCreate(kCFAllocatorDefault) ;
#if __has_feature(objc_arc)
    NSString* uuid = (NSString*)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, cfUUID)) ;
#else
    NSString* uuid = (NSString*)CFUUIDCreateString(kCFAllocatorDefault, cfUUID) ;
#endif
    CFRelease(cfUUID) ;
    NSString* scriptTempFilePath = [[NSTemporaryDirectory() stringByAppendingPathComponent:uuid] stringByAppendingPathExtension:@"scpt"];
#if !__has_feature(objc_arc)
    [uuid release];
#endif
    BOOL ok;
    NSError* error = nil;
    ok = [source writeToFile:scriptTempFilePath
                  atomically:YES
                    encoding:NSUTF8StringEncoding
                       error:&error];
    if (!ok) {
        error = [NSError errorWithDomain:@"SSYAppleScripterErrorDomain"
                                    code:298577
                                userInfo:@{
                                           NSLocalizedDescriptionKey : @"Could not write temporary script file",
                                           NSUnderlyingErrorKey : error
                                           }];
        if (completionHandler) {
            completionHandler(nil, nil, error);
        }

    } else {
        NSURL* scriptUrl = [NSURL fileURLWithPath:scriptTempFilePath];
        [self executeScriptWithUrl:scriptUrl
                       handlerName:nil
                 handlerParameters:nil
                   ignoreKeyPrefix:ignoreKeyPrefix
                          userInfo:userInfo
              blockUntilCompletion:blockUntilCompletion
                 completionHandler:^(id  _Nullable payload, id  _Nullable userInfo, NSError * _Nullable scriptError) {
                     completionHandler(payload, userInfo, scriptError);
                     [[NSFileManager defaultManager] removeItemAtURL:scriptUrl
                                                               error:NULL];
                 }];
    }
}

@end
