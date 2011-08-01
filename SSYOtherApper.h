#import <Cocoa/Cocoa.h>

extern NSString* const SSYOtherApperErrorDomain ;

extern NSString* const SSYOtherApperKeyExecutable ;
extern NSString* const SSYOtherApperKeyPid ;

/*!
 @brief    A class of class methods for observing and controlling other applications.

 @detail   Many of the methods in this class work upon a process' ProcessSerialNumber,
 which exists and therefore the methods work only upon "applications", defined as
 "things which can appear in the Dock that are not documents and are launched by the Finder or Dock".
 (See documentation of ProcessSerialNumber).
*/
@interface SSYOtherApper : NSObject {}

/*!
 @brief    Launches an application specified by its bundle path (i.e. 
 /path/to/SomeApp.app) and optionally activates it (brings to to the 
 front)

 @param    activate  If the specified application is not already
 launched, the newly-launched application is activated if YES, and
 if NO is not activated.  If the specified application is already
 launched, this parameter is ignored and the application is activated.
 @param    error_p  If not NULL and if an error occurs, upon return,
           will point to an error object encapsulating the error.
 @result   YES if the method completed successfully, otherwise NO
*/
+ (BOOL)launchApplicationPath:(NSString*)path
					 activate:(BOOL)activate
					  error_p:(NSError**)error_p ;
	
+ (NSImage*)iconForAppWithBundleIdentifier:(NSString*)bundleIdentifier ;

/*!
 @brief    Returns the full path to the application indicated by a given
 bundle identifier, or nil if it cannot be found.

 @details  Uses -[NSWorkspace absolutePathForAppBundleWithIdentifier].
 This is much more reliable than -fullPathForApplication, especially for Firefox,
 DeerPark, BonEcho, Minefield, etc. -- but I believe for others too.
*/
+ (NSString*)fullPathForAppWithBundleIdentifier:(NSString*)bundleIdentifier ;

/*!
 @brief    Returns unix process ID (PID) of running app with given bundleIdentifier
 and the same user ID as this process

 @details  If no such qualified process exists, or if bundleIdentifier is nil,
 returns 0.&nbsp;   The target app must be a normal GUI app, not a faceless background
 application.&nbsp;   This method invokes NSWorkspace and thus requires Cocoa
 AppKit.&nbsp; To get the pid of non-GUI apps use +pidOfThisUsersProcessNamed:.
 @param    bundleIdentifier  The bundle identifier that the target app must have
 @result   The unix process identifier (pid), or 0 if no qualifying process exists.
*/
+ (pid_t)pidOfThisUsersAppWithBundleIdentifier:(NSString*)bundleIdentifier ;

/*!
 @brief    Returns unix process ID (PID) of a running process with given
 executable name, whose user is the current user.
 
 @details  If no such qualified process exists, or if executableName is nil,
 returns 0.  If more than one such process exists, returns the first one found.
 Note that this method considers all processes for all users: anything that shows
 by executing the unix 'ps' command.  It launches an NSTask to do this; therefore
 AppKit is not required.
 
 In testing, on an admin account, I see that it will return results for processes
 owned by other users, and for processes owned by root.  But I have not confirmed
 this theoretically.  See test code below.
 @param    executableName  The last component of the process' command path.
 @result   The unix process identifier (pid), or 0 if no qualifying process exists.
 */
+ (pid_t)pidOfMyRunningExecutableName:(NSString*)executableName ;

/*!
 @brief    Returns an NSArray of NSNumber whose integer values are the
 unix process IDs (PIDs) of running processes with given executable name
 and whose user is the current user..
 
 @details  If no such qualified processes exist, or if executableName is nil,
 returns an empty array.  Will even return zombie (Z) and (UEs) processes.
 It launches an NSTask to do this; NSApp is not required.
 @param    executableName  The last component of the process' command path.
 @result   The unix process identifier (pid), or 0 if no qualifying process exists.
 */
+ (NSArray*)pidsOfMyRunningExecutablesName:(NSString*)executableName ;

/*!
 @brief    Returns the major version which is believed to be the version of the
 package at a given bundle path, or 0 if no such version could be found
 
 @result   First, tries to parse the answer from CFBundleVersion of the given
 bundlePath, and if that fails tries CFBundleShortVersionString.
 */
+ (NSInteger)majorVersionOfBundlePath:(NSString*)bundlePath ;

/*!
 @brief    Gets the unix process ID (pid) of a process with a given process name
 which must have the same user id as this process.

 @details  If no such process exists, returns 0.  I think that the name is the
 CFBundleName, but it may be CFExecutableName.  Finds some background processes but
 not all.  For example, finds QuicKeysBackgroundEngine, mdworker, SystemUIServer,
 SizzlingKeys4iTunes, loginwindow, iTunesHelper.  But does not find BookMacster-Quatch.
 Go figure.  Will not return zombie (Z) or (UEs) processes.  Uses Carbon > Process Manager.
 */
+ (pid_t)pidOfThisUsersProcessNamed:(NSString*)processName ;

/*!
 @brief    Returns an array of unix process ID (pid) of all processes with
 a given executable path, which have the same user id as this process.
 
 @details  If no such process exists, returns an empty array.
 */
+ (NSArray*)pidsOfThisUsersProcessPath:(NSString*)processName ;

/*!
 @brief    Gets the bundle pathof a process with a given process name
 which must have the same user id as this process.
 
 @details  If no such process exists, returns 0.  I think that the name is the
 CFBundleName, but it may be CFExecutableName.  Finds some background processes but
 not all.  For example, finds QuicKeysBackgroundEngine, mdworker, SystemUIServer,
 SizzlingKeys4iTunes, loginwindow, iTunesHelper.  But does not find BookMacster-Quatch.
 Go figure.  Will not return zombie (Z) or (UEs) processes.  Uses Carbon > Process Manager.
 */
+ (NSString*)bundlePathForProcessName:(NSString*)processName ;

/*!
 @brief    Returns an array of NSNumbers representing all unix process ID (pid)
 of a process with a given process name which must have the same user id as this process.
 
 @details  If no such process exists, returns an empty array.  I think that the name is the
 CFBundleName, but it may be CFExecutableName.  Finds some background processes but
 not all.  For example, finds QuicKeysBackgroundEngine, mdworker, SystemUIServer,
 SizzlingKeys4iTunes, loginwindow, iTunesHelper.  But does not find BookMacster-Quatch.
 Go figure.  Will not return zombie (Z) or (UEs) processes.  Uses Carbon > Process Manager.
 */
+ (NSArray*)pidsOfThisUsersProcessesNamed:(NSString*)processName ;

/*!
 @brief    Returns an array with one element for each running executable, with each element
 being a dictionary containing entries for pid, user, and command.
 
 @details  This method uses the unix "ps" instead of [[NSWorkspace sharedWorkspace] launchedApplications]
 The "advantage" of this is that it does not use AppKit, therefore does not invoke
 WindowServer, therefore does not raise an exception if the user is not the console user.
 The disadvantage is that it uses NSTask, and did not work in finding Bookwatchdog
 for user Michael Sherwin <mdsherwin@mac.com>
 @param    fullExecutablePath  YES to return the full path to each executable as the
 value of the "command" key.  NO to return only the executable name.
 @result   The array of dictionaries.  Each dictionary contains three keys:
 *  @"pid", whose value is an NSNumber
 *  @"user", whose value is an NSString
 *  processInfoDic, whose value is an NSString
*/
+ (NSArray*)pidsExecutablesFull:(BOOL)fullExecutablePath ;

+ (struct ProcessSerialNumber)processSerialNumberForAppWithBundleIdentifier:(NSString*)bundleIdentifier ;

/*!
 @brief    Returns the process serial number of an *app* given its
 unix process ID (pid).

 @details  Will return {0,0} if the process whose
 pid is 'pid' does not have a PSN.  To find if a process has a PSN, in Terminal
 command "ps -alxww".  Processes which have a PSN are apps, and *some* helper
 tools.  Basic unix executables such as launchd, kextd, etc. do *not* have a PSN.
 BookMacster-Worker does *not* have a PSN.  iChatAgent *does* have a PSN.
 
 @param    pid  
 @result   The process serial number of the target process, or struct values
 {0,0} if no such process exists.
*/
+ (struct ProcessSerialNumber)processSerialNumberForAppWithPid:(pid_t)pid ;

/*!
 @brief    Returns the unix process identifier (pid) of a process with a given
 bundle path with the same user ID as the current process.

 @detail  	Although it's not documented, I have tested and confirmed that
 the GetProcessForPID() function which this method invokes under the hood
 will return error -600 procNotFound, and psn will be {0, 0}, for processes whose
 uid are other users than the current user (502, 503, whatever) or root (0),
 or some other system guy like 65.
 
 @param    bundlePath  The bundle path with the result must have
 @result   The pid of the target process, or 0 if no qualifying process exists.
*/
+ (pid_t)pidOfThisUsersProcessWithBundlePath:(NSString*)bundlePath ;

/*!
 @brief    Returns whether or not a process with a given unix process
 identifier (pid) is running.

 @details  Uses the system command 'ps'.  Works for *any* type of process.
 
 @param    thisUserOnly  YES to return NO if the indicated process is
 running but its owner is another user.  Note: This method does *not*
 require admin privileges to inquire about other users' processes.
 That is, if you pass NO, you *will* get the correct answer even if the
 process is that of another user and the current user does *not* have
 administrator priviliges.  If you are sure that the target process is
 owned by the current user, passing YES may be slightly more efficient.
*/
+ (BOOL)isProcessRunningPid:(pid_t)pid
			   thisUserOnly:(BOOL)thisUserOnly ;

/*!
 @brief    Returns whether or not this user has an *app* running
 with a given pid.  Will return NO if pid is a basic unix executable.
 May return YES if running for some kinds of helper tools.
 
 @details  Will return NO if the process whose
 pid is 'pid' does not have a PSN.  To find if a process has a PSN, in Terminal
 command "ps -alxww".  Processes which have a PSN are apps, and *some* helper
 tools.  Basic unix executables such as launchd, kextd, etc. do *not* have a PSN.
 BookMacster-Worker does *not* have a PSN.  iChatAgent *does* have a PSN.
*/
+ (BOOL)isThisUsersAppRunningWithPID:(pid_t)pid ;

/*!
 @brief    Finds a running app, owned by the current user,
 with a given bundle path, sends it a "quit application" Apple Event message,
 and returns when the app is quit or timeout occurs, whichever comes first.
 
 @details  Will block the thread until the target app quits, or timeout.
 
 This method works by sending a "tell application Xxx to quit" AppleScript message.
 According to the latest AppleScript Language Guide ▸ Control Statements Reference ▸
 tell Statements, "A tell statement that targets a local application doesn’t cause
 it to launch, if it is not already running".  I tested that in Mac OS X 10.6
 and found it to be true, but I seem to remember that it *did* cause the app to
 launch if it was not running in earlier Mac OS X versions.  So I'm not sure.
 
 @param    bundle path  The bundle path of the application to be 
 quit, or nil to no-op.

 @result   YES if the target app was not running, or if it quit within
 the allowed timeout, or if bundleIdentifier was nil.  NO if app was
 still running when timeout expired.
 */
+ (BOOL)quitThisUsersAppWithBundlePath:(NSString*)bundlePath
							   timeout:(NSTimeInterval)timeout
							   error_p:(NSError**)error_p ;

/*!
 @brief    An Objective-C wrapper around Process Manager's KillProcess()
*/
+ (BOOL)killProcessWithProcessSerialNumber:(ProcessSerialNumber)psn ;

/* This was stupid.  Use kill(pid, SIGKILL).
+ (void)killProcessPID:(pid_t)pid
		 waitUntilExit:(BOOL)wait ;
 */

/*!
 @brief    Finds a running app, owned by the current user,
 with a given bundle identifier, sends it a "kill -9" BSD signal,
 and returns when the app is killed or timeout occurs, whichever comes first.
 
 @details  May block its thread up to the timeout.  Sleeps for 0.5
 seconds between polls.
 @param    bundleIdentifier  The bundle identifier of the application to be 
 killed, or nil to no-op.
 @result   YES if the target app was not running, or if it dies within
 the allowed timeout, or if bundleIdentifier is nil.  NO if app was still
 running when timeout expired.
 */
+ (BOOL)killThisUsersAppWithBundleIdentifier:(NSString*)bundleIdentifier
									 timeout:(NSTimeInterval)timeout ;



/*!
 @brief    Returns the name of the user's default web browser, for example,
 "Safari"
*/
+ (NSString*)nameOfDefaultWebBrowser ;

/*!
 @brief    Returns the name of the user's default email client, for example,
 "Eudora"
 */
+ (NSString*)nameOfDefaultEmailClient ;

+ (NSString*)bundleIdentifierOfDefaultEmailClient ;

/*!
 @brief    A wrapper around the unix 'ps' command which returns the current
 CPU percent usage of a process with a given pid

 @details  See man ps(1) to see what "CPU percent usage" means
 @param    pid  Unix process identifier of the target process
 @param    cpuPercent_p  If no error occurs, upon return, will point to a 
 float which will be the current cpu percent, on a scale from 0.0 to 100.0
 or infrequently more than 100.0.
 @param    error_p  Pointer which will, upon return, if the method
 was not able to determine cpuPercent_p and error_p is not
 NULL, point to an NSError describing said error.
 @result   YES if the method was able to determine cpuPercent_p,
 otherwise NO.
 */
+ (BOOL)processPid:(pid_t)pid
		   timeout:(NSTimeInterval)timeout
	  cpuPercent_p:(float*)cpuPercent_p
		   error_p:(NSError**)error_p ;

+ (NSString*)bundlePathOfSenderOfEvent:(NSAppleEventDescriptor*)event ;

/*!
 @brief    Returns the full path to an application with the given
 bundle identifier, if such an app is running with the current user
 as the owner

 @details  If an app with the given bundleIdentifier is not
 running, returns nil.
*/
+ (NSString*)pathIfRunningForThisUserBundleIdentifier:(NSString*)bundleIdentifier ;

/*!
 @brief    Activates a specified app

 @details  Will use either bundlePath or bundleIdentifier,
 preferring bundlePath if it is given.
*/
+ (BOOL)activateAppWithBundlePath:(NSString*)bundlePath
				 bundleIdentifier:(NSString*)bundleIdentifier ;

@end

#if 0
// Test code for pidOfMyRunningExecutableName:

NSLog(@"pid=%d", [SSYOtherApper pidOfMyRunningExecutableName:@"Finder"]) ;
NSLog(@"pid=%d", [SSYOtherApper pidOfMyRunningExecutableName:@"loginwindow"]) ;
NSLog(@"pid=%d", [SSYOtherApper pidOfMyRunningExecutableName:@"BookMacster-Quatch"]) ;
NSLog(@"pid=%d", [SSYOtherApper pidOfMyRunningExecutableName:@"Crap"]) ;
exit(0) ;	

#endif