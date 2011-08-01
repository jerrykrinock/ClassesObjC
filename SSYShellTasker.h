extern NSInteger const SSYShellTaskerErrorFailedLaunch  ;
extern NSInteger const SSYShellTaskerErrorTimedOut  ;

@interface SSYShellTasker : NSObject {
}

/*!
 @brief    A wrapper around NSTask to launch a command-line process, with a timeout.

 @details  Only use this function after you have searched far and wide for a Cocoa, CoreFoundation,
 Carbon, or any built-in API to do what you want to do.&nbsp;   That is because this function will spawn
 another process which often leads to trouble.&nbsp;   Use it sparingly.&nbsp;  Examine the return value,
 stdout_p and stderr_p and write code to recover from errors. 
 
 TIMEOUT   Narrated result       result     *stdoutData_p    *stderrData_p    *error_p  
   0.0     Launch failed     ..FailedLaunch   not set          not set        NSError
           Launch succeeded      0            not set          not set        not set  
  >0.0     Launch failed     ..FailedLaunch   not set          not set        NSError
           Task timed out      ..TimeOut      not set          not set        NSError  
           Task completed     task result    taskStdout       taskStderr      not set

 If timeout > 0.0, method runs an NSTask in a new thread which it creates, so that it can run a run
 loop with the timeout.  If timeout = 0.0, NSTask runs in the invoker's thread.  In either case,
 NSTask is run with a local autorelease pool so that this method can be invoked repeatedly in the
 same application run loop cycle without running out of system filehandles (pipes).
 
 Here is Chris Kane's explanation of why this class should not work:
 
 On Sep 14, 2009, at 6:29 PM, Jerry Krinock wrote:
 
 [task launch] ;
 if ([task isRunning]) {
 // Write data to stdin file/pipe
 // ...
 // ...
 }
 
 NSDate* limitTime = [NSDate dateWithTimeIntervalSinceNow:timeout] ;
 [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
 beforeDate:limitTime] ;
 // The above will block and be run to here either due to
 // the posting of an NSTaskDidTerminateNotification, or the
 // passing of limitTime, whichever occurs first.
 
 Chris Kane wrote:
 
 That is not a valid assumption (described in the comments and apparent from the rest of the code).
 Just do the loop, checking the time and isRunning.  Running the run loop once is not necessarily sufficient.
 
 Keep in mind that isRunning can start returning NO before (or after) the notification gets delivered.
 There's no necessary correlation between the two.  If you actually care that the notification has
 been posted, you should register an observer and change some shared state in the handler method,
 which the looping can check for.
 
 
 if (![task isRunning]) {
 taskResult = [task terminationStatus] ;
 
 // Read stdout and stderr
 // ...
 // ...
 }
 else {
 taskResult = SSYShellTaskerErrorTimedOut ;
 
 // Clean up
 kill([task processIdentifier], SIGKILL) ;
 
 // Set NSError indicating timeout
 // ...
 // ...
 }
 
 Actually, I originally was doing this on the main thread, except that the -[NSRunLoop runMode:beforeDate] was in a while() loop.  When the loop ran, I would check and see if there was a timeout, task was finished, or neither (presumably some other input source triggered the run).  But then I found an obscure bug: If I had disabled undo registration in order to do some behind-the-scenes changes, it would re-enable undo registration.  Uh, yeah, it took me a while to track that one down.  Apparently, running a run loop that is already running is not a good idea.  I suppose I could also have done it with a timer.
 
 
 If I interpret your explanation of the previous code correctly and it was similar to the code above, the problem here, in a sense, is more your desire to block until the task is finished or a timeout expires.  Go back to the main thread.  Setup a oneshot NSTimer for the timeout period.  Setup a notification handler to listen for the NSTaskDidTerminateNotification.  If the timer fires first, kill the task, unregister the notification handler, etc.  If the notification happens first, invalidate the timer, unregister the notification handler, etc.  Don't run the run loop yourself.  Let your code be event-driven.
 
 A run loop can be run re-entrantly, but as Jens said, usually it is done in a private mode, to prevent (say) the default mode stuff from happening at times which are surprising to that stuff (breaking assumptions or requirements it has), and possibly surprising to your app (breaking assumptions or requirements it has). However in this case, the task death notification, if you need that, requires the default run loop mode to be run to get delivered.
 
 
 Chris Kane
 Cocoa Frameworks, Apple
 
 
 @param    command  The command, not including its arguments.  A full path to the desired tool
 is recommended.  Example: @"/bin/launchctl"
 @param    arguments  The array of arguments which should be passed with the command.  Each element
 of the array should be an NSString, one of the space-separated "words" that you would type on the
 command line if you were performing this task via Terminal.app.  For example, to perform the task
 /bin/launchctl -load /Users/me/LaunchAgents/MyTask.plist
 The 'command' would be @"/bin/launchctl/" and the 'arguments' would be an array of two strings,
 @"-load" and @"/Users/me/LaunchAgents/MyTask.plist" in that order.  If the command does not use
 a space between its argument "letter" and its text, for example "-oPath/To/Output", this would
 be entered as a single string element in 'arguments'.
 If the command has no arguments, pass nil.  Arguments can be very tricky.  For example, I have
 never found a way to pass in pipe redirects.  I tried this suggestion once:
 http://www.cocoabuilder.com/archive/message/cocoa/2005/2/24/129019
 but could not get it to work.
 @param    inDirectory  The working directory in which the command will be launched.  You
 may pass nil.  In that case,  the tasks's current directory is inherited from this process, which,
 for applications, appears to be the root level of the startup drive.  Run command "pwd" if you
 need to be sure.  To avoid problems, I'd say never pass inDirectory = nil unless you're giving
 a full path in 'command'.
 @param    stdinData  The stdin data to be passed to the command.  If nil, the tasks's standard
 input is inherited from this process.  I suppose that could be interesting.
 @param    stdoutData_p  If you want the stdout from the task, pass an NSData*.  On output it
 will point to an NSData object containing the stdout.  Otherwise, pass NULL.  In that case
 the stdout is written to the stdout location of the calling process (usually the system console)
 and will not be returned.  See table above for more details.
 @param    stderrData_p  If you want the stderr from the task, pass an NSData*.  On output it
 will point to an NSData object containing the stderr.  Otherwise, pass NULL.  In that case
 the stdout is written to the stderr location of the calling process (usually the system console)
 and will not be returned.  See table above for more details.
 @param    timeout  The maximum time you are allowing for this method to block while the process
 completes, or 0.0 to indicate that you want this method to return immediately without
 waiting for the spawned process.
 @param    error_p  If a non-NULL pointer is supplied, and an error occurs, this will
 point to an NSError describing the task result upon return.  See table above for more details.
 @result   See table above.
 */
+ (NSInteger)doShellTaskCommand:(NSString*)command
					  arguments:(NSArray*)arguments
					inDirectory:(NSString*)inDirectory
					  stdinData:(NSData*)stdinData
				   stdoutData_p:(NSData**)stdoutData_p
				   stderrData_p:(NSData**)stderrData_p
						timeout:(NSTimeInterval)timeout 
						error_p:(NSError**)error_p ;

@end


