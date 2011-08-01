extern NSInteger const SSYShellTaskerErrorFailedLaunch  ;
extern NSInteger const SSYShellTaskerErrorTimedOut  ;

@interface SSYShellTasker : NSObject {
	NSTask* m_task ;
	NSConditionLock* m_lock ;
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
 completes.  See table above for more details.
 @param    error_p  If a non-NULL pointer is supplied, and an error occurs, this will
 point to an NSError describing the task result upon return.  See table above for more details.  See table above for more details.
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


