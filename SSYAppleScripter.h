#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SSYAppleScripter : NSObject

/*!
 @brief    Executes an AppleScript from a file and returns result to a
 completion handler, optionally waiting for the script and completion
 handler to return

 @details  This is a wrapper around NSAppleScriptTask.

 TODO: Add support for more handler parameter types.  See string in source
 code: "Unsupported handler parameter class…".

 Note WhyEmptyString-WhyNotNull

 Using +[NSAppleDescriptor nullDescriptor] to represent a nil value (which
 in AppleScript parlance should be `missing value`) in a parameter list to an
 AppleScript handler does not work as expected.  When the receiving app gets
 the NSScriptCommand and sends it the message -evaluatedArguments, the
 value of that key in the returned dictionary is not a NSNull but is instead,
 at least in my test case. the name of the sending process!  I have not tried
 to explain that.  In general, I would say that the value is "not what you
 expect".  So, for nil strings, I send an empty string instead.

 I did not add a timeout feature because you can get that effect by wrapping
 your script's commands in a *with timeout …" block.

 @param    scriptUrl  URL to the script file to be executed.  Must have
 extension ".scpt".  For sandboxed apps, scriptUrl file be in
 NSApplicationScriptsDirectory in NSUserDomainMask
 (~/Library/Application Scripts).  For nonsandoxed apps, scriptUrl may be in
 any accessible location, including within your app's own Contents/Resources.

 @param    handlerName  Name of subroutine ("foo" in "on foo") in the script
 file to be executed.  You use this when you the script file is a "library" of
 subroutines and you want to execute one.  More commonly, you want to exeucte
 the script.  For that case, you may pass nil.

 @param    handlerParameters  Ordered set of parameters you want passed to the
 script handler.  Ignored if handlerName is nil.  If the handler has no
 parameters, you may pass nil or an empty array.

 @param    ignoreKeyPrefix  String which, if script returns a record (and this
 method returns a dictionary as payload to the completion handler) this value
 is found to be a prefix of any of the keys of the record, will be stripped
 from the keys when transferring to the `payload` dictionary to be passed to
 completion handler.  This is in case you want your `answers` to contain keys
 such as `name` or `url` (commonly used in Cocoa) which are unfortunately
 reserved words in AppleScript.  You can achieve this if you, for example,
 write your script to return a record containing keys `zname` and `zurl`, and
 pass @"z" to ignoredKeyPrefix.

 If the script does not return an AppleScript record, this value is ignored.

 @param    userInfo  Object which is simply passed through to the completion
 handler

 @param    blockUntilCompletion  If YES, this method returns immediately.  If
 NO, this method blocks until the script returns and, if you pass in a
 completion handler, after your completion handler returns too.

 @param    completionHandler  Function to be run asynchronously when script
 returns.  It gets the following parameters:

 • `payload`: Cocoa representation of the object returned by the script
 •          If script returns type       payload will be
 •              nothing                     nil
 •              record                      NSDictionary
 •              list                        NSArray
 • `userInfo`: the userInfo you passed in to this method
 • `scriptError`: any error returned by the script.

 For "fire and forget" usage, completion handler may be nil.
 */
+ (void)executeScriptWithUrl:(NSURL* _Nullable)scriptUrl
                 handlerName:(NSString* _Nullable)handlerName
           handlerParameters:(NSArray* _Nullable)handlerParameters
             ignoreKeyPrefix:(NSString* _Nullable)ignoreKeyPrefix
                    userInfo:(NSObject* _Nullable)userInfo
        blockUntilCompletion:(BOOL) blockUntilCompletion
           completionHandler:(void (^ _Nullable)(
                                       id _Nullable payload,
                                       id _Nullable userInfo,
                                       NSError* _Nullable scriptError))completionHandler;

/*!
 @brief    Same as -executeSriptWithUrl:::::::, except executes a script file
 created by writing given source code to a temporary file

 @details  This is replacement for -[NSAppleScript executeAndReturnError:],
 which does not work between applications in macOS 10.14.  Except, of course,
 this method can be asynchronous if you pass NO to blockUntilCompletion.

 Although I don't know how significant the difference is, this method must
 be considerably slower than -executeSriptWithUrl:::::::.  I conclude this
 because this method requires three preparatory steps:

 (1) Write the source text to a file.
 (2) Read the source text back to NSUserAppleScriptTask
 (3) Compile the script.

 but -executeSriptWithUrl::::::: only needs to do step (3).

 By the way, I was expecting that an additional step between (1) and (2)
 would be required, to *compile* the script with an NSTask calling
 /usr/bin/osacompile.  However, to my surprise, that is not necessary.
 Apparently, -[NSUserAppleScriptTask initWithURL:error:] recognizes if a .scpt
 file whose URL it is passed contains plain text, and if so, compiles it,
 and if the .scpt file is a real already-compiled script file, it does not!
 The documentation says merely that you must pass it a "script file".  ???

 @param    userInfo  Same as in executeScriptWithUrl:::::::.
 @param    blockUntilCompletion  Same as in executeScriptWithUrl:::::::.
 @param    completionHandler  Same as in executeScriptWithUrl:::::::.
 */
+ (void)executeScriptSource:(NSString* _Nonnull)source
             ignoreKeyPrefix:(NSString* _Nullable)ignoreKeyPrefix
                    userInfo:(NSObject* _Nullable)userInfo
        blockUntilCompletion:(BOOL) blockUntilCompletion
           completionHandler:(void (^ _Nullable)(
                                                 id _Nullable payload,
                                                 id _Nullable userInfo,
                                                 NSError* _Nullable scriptError))completionHandler;

@end

NS_ASSUME_NONNULL_END
