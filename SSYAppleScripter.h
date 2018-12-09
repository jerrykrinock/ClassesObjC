#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SSYAppleScripter : NSObject

/*!
 @brief    Executes an AppleScript from a file and returns result to a
 completion handler, optionally waiting for the script and completion
 handler to return

 @details  This is a wrapper around NSAppleScriptTask.

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
 @brief    Same as executeSriptWithUrl:::::::, except executes a script file
 created by writing given source code to a temporary file

 @details  This is replacement for -[NSAppleScript executeAndReturnError:],
 which does not work between applications in macOS 10.14.  Except, of course,
 this method can be asynchronous if you pass NO to blockUntilCompletion.

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
