#import <Foundation/Foundation.h>

extern NSString* SSYTaskerErrorDomain ;

enum SSYTaskerErrorCodes_enum {
    SSYTaskerErrorCodeExceptionOccurredWhileReading = 442001,
    SSYTaskerErrorCodeUnixCommandError = 442002,
    SSYTaskerErrorCodeCouldNotCreateThreadForStdin = 442003,
    SSYTaskerErrorCodeCouldNotDetachThreadForStdin = 442004
} ;

extern NSInteger SSYTaskerMetaErrorCode ;

typedef enum SSYTaskerErrorCodes_enum SSYTaskerErrorCodes ;

@protocol SSYTaskerProgressDelegate

- (void)gotBytesCount:(NSInteger)bytesCount
             pipeName:(NSString*)pipeName ;

@end



/*!
 @brief    A wrapper around NSTask which runs a task synchronously, as in
 -[NSTask waitUntilExit], but is more robust.
 
  @details
 This is substantially an update of work by Torsten Curdt:
 https://gist.github.com/atr000/621601
 
 This class features the following improvements over -[NSTask waitUntilExit]
 • The stdin, stdout, or stderr can handle large data objects without stalling
 • Handles exceptions while reading stdin or stdout
 • Handles the "NSTask Stealth Bug"
 • Returns errors as NSError objects
 
 I do not know whether or not the "NSTask Stealth Bug" from 2006 is still
 an issue:
 http://www.cocoabuilder.com/archive/cocoa/173348-nstask-stealth-bug-in-readdataoflength.html#173647
 
 This class assumes Objective-C Automatic Reference Counting (ARC).
 */
@interface SSYTasker : NSObject {
    NSObject <SSYTaskerProgressDelegate> * __weak m_delegate ;
}

@property NSObject <SSYTaskerProgressDelegate> * __weak delegate ;

/*!
 @brief    Runs a shell task synchronously and robustly
 
 @details  After this method returns, you may send -stdoutFromLastRun, 
 -stderrFromLastRun or -errorFromLastRun to get results

 @param    launchPath  The command to run.  See -[NSTask setLaunchPath:].
 @param    arguments  The arguments passed to the command.  See
 -[NSTask setArguments:].  May be nil.
 @param    stdinData  Data to be passed to the command's stdin.  May be nil.
 
 @result   The exit status from running the command, or if a higher level error
 occurred, SSYTaskerMetaErrorCode.  Higher level errors are available from
 -errorFromLastRun.
 */
- (NSInteger)runCommand:(NSString*)launchPath
              arguments:(NSArray*)arguments
              stdinData:(NSData*)stdinData
              workingIn:(NSString*)workingDirectory ;

- (NSData*)stdoutFromLastRun ;
- (NSData*)stderrFromLastRun ;
- (NSError*)errorFromLastRun ;

@end

#if 0

 // * TEST CODE
 
 // ** TEST FOR stdin
 
 // Open a Terminal.app window.  Execute this code and you should see the
 // message broadcast to your Terminal session.
 
 NSData* stdinData = [@"SSYTasker stdin works!" dataUsingEncoding:NSUTF8StringEncoding] ;
 SSYTasker* tasker = [[SSYTasker alloc] init] ;
 [tasker runCommand:@"/usr/bin/wall"
      arguments:nil
      stdinData:stdinData] ;

#endif

 
