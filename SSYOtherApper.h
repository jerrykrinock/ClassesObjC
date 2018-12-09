#import <Cocoa/Cocoa.h>

extern NSString* const SSYOtherApperErrorDomain ;

extern NSString* const SSYOtherApperKeyPid ;
extern NSString* const SSYOtherApperKeyUser ;
extern NSString* const SSYOtherApperKeyEtime ;
extern NSString* const SSYOtherApperKeyExecutable ;

/*!
 @brief    Enumeration of process states corresponding to those given by the
 unix 'ps' program.  See man ps.
 */
enum SSYOtherApperProcessState_enum {
    SSYOtherApperProcessUnknown         = -1, // This would be an error.
    SSYOtherApperProcessDoesNotExist    = 0,
    SSYOtherApperProcessStateZombie     = 1,  // Z
    SSYOtherApperProcessStateStopped    = 2,  // T
    SSYOtherApperProcessStateRunnable   = 3,  // R
    SSYOtherApperProcessStateIdle       = 4,  // I
    SSYOtherApperProcessStateWaiting    = 5,  // U
    SSYOtherApperProcessStateRunning    = 6,  // S
    } ;
typedef enum SSYOtherApperProcessState_enum SSYOtherApperProcessState ;


/*!
 @brief    A class of class methods for observing and controlling other applications.

 @detail   A couple of notes:

 ## ProcessSerialNumber is only for Apps

 Many of the methods in this class refer to a process' ProcessSerialNumber,
 which exists and therefore the methods work only upon "applications", defined
 as "things which can appear in the Dock that are not documents and are
 launched by the Finder or Dock". (See documentation of
 ProcessSerialNumber).

 ## Definition of "Executable"

 Many of the methods in this class refer to a process' Executable.  This is the
 string returned for the "comm" keyword of /bin/ps.  The documentation
 `man ps` defines this as the "command" of the process, and implies that it
 is the path to the running executable.  However, for some XPC Services, and
 this happens for BkmxAgent which is launched by SMLoginItemSetEnabled(),
 you get instead the bundle identifier of the XPC Service.  I don't know why.
 It looks like Arq Agent is similarly a Login Item of Arq (it is located at
 Arq.app/Library/LoginItems/Arq Agent.app), but its "command" shows in -ps as:
 /Applications/Arq.app/Contents/Library/LoginItems/Arq Agent.app/Contents/MacOS/Arq Agent,
 in other words, the path to the executable.
*/
__attribute__((visibility("default"))) @interface SSYOtherApper : NSObject {}


/*!
 @brief    Launches an application specified by its bundle path (i.e.
 /path/to/SomeApp.app) and optionally activates it (brings to to the
 front)

 @param    activate  If the specified application is not already
 launched, the newly-launched application is activated if YES, and
 if NO is not activated.  If the specified application is already
 launched, this parameter will activate or deactivate it.
 @param    hideGuardTime
 @param    error_p  If not NULL and if an error occurs, upon return,
           will point to an error object encapsulating the error.
 @result   YES if the method completed successfully, otherwise NO
*/
+ (BOOL)launchApplicationPath:(NSString*)path
					 activate:(BOOL)activate
                hideGuardTime:(NSTimeInterval)hideGuardTime
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
 AppKit.&nbsp; To get the pid of non-GUI apps use +pidOfProcessNamed:user:.
 @param    bundleIdentifier  The bundle identifier that the target app must have
 @result   The unix process identifier (pid), or 0 if no qualifying process exists.
*/
+ (pid_t)pidOfThisUsersAppWithBundleIdentifier:(NSString*)bundleIdentifier ;

+ (pid_t)pidOfThisUsersAppWithBundlePath:(NSString*)bundlePath ;

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
 @param    executableName  The last component of the process' command.  See
 class documentation for definition of "executable".
 @result   The unix process identifier (pid), or 0 if no qualifying process exists.
 */
+ (pid_t)pidOfMyRunningExecutableName:(NSString*)executableName ;

/*!
 @brief    Returns an NSArray of NSNumber whose integer values are the
 unix process IDs (PIDs) of running processes with given executable name
 and whose user is the current user..
 
 @details  If no such qualified processes exist, or if executableName is nil,
 returns an empty array.
 It launches an NSTask to do this; NSApp is not required.
 @param    executableName  The last component of the process' command.  See
 class documentation for definition of "command" vs. "executable".
 @param    zombies  If YES, results will include any qualifying zombie (Z) 
 and processes, and processes in uninterruptible wait (U or, more typicall, UE
 states.  If NO, will results will ignore these processes.
 @param    exactMatch  If YES, candidate's executable name must match the
 given executableName exactly.  Otherwise, candidate's executable name need
 only contain the givem executableName.
 @result   The unix process identifier (pid), or 0 if no qualifying process exists.
 */
+ (NSArray*)pidsOfMyRunningExecutablesName:(NSString*)executableName
                                   zombies:(BOOL)zombies
                                exactMatch:(BOOL)exactMatch;

/*!
 @brief    Returns a member of an enumeration which gives the current running
 or not running state of a given process, identified by its pid
*/
+ (SSYOtherApperProcessState)stateOfPid:(pid_t)pid ;

/*!
 @brief    Returns the major version which is believed to be the version of the
 package at a given bundle path, or 0 if no such version could be found
 
 @result   First, tries to parse the answer from 
 of the given
 bundlePath, and if that fails tries CFBundleVersion.  Usually the former is the one
 you want.  For example, today I find…
 
               CFBundleShortVersionString     CFBundleVersion
               --------------------------     ---------------
 *  Firefox    23.0a2                         2313.5.17
 *   Safari    6.0.5                          8536.30.1
 
 Given the above Info.plists, this method would return 23 for Firefox and 6 for Safari.
 */
+ (NSInteger)majorVersionOfBundlePath:(NSString*)bundlePath ;

/*!
 @brief    Returns the unix process ID (pid) of any process whose last path
 component matches a given process name, and whose user id is the same
 user id as the current process, or 0 if no such process is running.

 @details  Starting with BookMacster 1.9, this method is now based on
 -pidsExecutablesFull:, which is in turn based on /bin/ps, so that it gets
 all processes, regardless of background, bundle, app, or GUI.
 
 Prior to BookMacster 1.9, this method used the Carbon Process Manager and
 therefore did not find all such running processes.  For example, it would
 find QuicKeysBackgroundEngine, mdworker, SystemUIServer, SizzlingKeys4iTunes,
 loginwindow, and iTunesHelper.  But it would not find BookMacster-Quatch.
 Will not return zombie (Z) or (UEs) processes.  It also did not properly
 discriminate users.
 
 @param   user  The short name, that is, the Home directory name, of the user
 whose process we want the pid of.  Pass NSUserName() for the current user.
 Pass nil for any user.
 */
+ (pid_t)pidOfProcessNamed:(NSString*)processName
					  user:(NSString*)user ;

/*!
 @brief    Returns an array with one element for each running executable, with each element
 being a dictionary containing entries for pid, user, and command.
 
 @details  This method uses the unix "ps" instead of [[NSWorkspace sharedWorkspace] launchedApplications]
 The "advantage" of this is that it does not use AppKit, therefore does not invoke
 WindowServer, therefore does not raise an exception if the user is not the console user.
 The disadvantage is that it uses NSTask, and did not work in finding Bookwatchdog
 for a certain user.
 @param    fullExecutablePath  YES to return the full path to each executable as
 the value of the "command" key.  NO to return only the executable name
 (last path component).  See class documentation for definition of "executable".
 @result   The array of dictionaries.  Each dictionary contains four keys:
 *  SSYOtherApperKeyPid, whose value is an NSNumber
 *  SSYOtherApperKeyUser, whose value is an NSString, the short name of the user
 *  SSYOtherApperKeyEtime, whose value is an NSString, the "elapsed running
 time" of the process; see etime in man ps(1).  Unfortunately, the format
 is not specified.  It seems to be DD-HH:MM:SS, where the DD- is: omitted for
 processes which have been running less than 24 hours, "0N-" for processes
 running 1-10 days, presumably "NN-" for process running 10-100 days, presumably
 "NNN-" for processes running 100-1000 days.
 *  SSYOtherApperKeyExecutable, whose value is an NSString, either an
 executable name or a full path.  See class documentation for definition of
 "executable".
*/
+ (NSArray*)pidsExecutablesFull:(BOOL)fullExecutablePath ;

/*!
 @brief    Returns an array with one element for each running executable whose
 process path contains one or more given strings, and optionally whose user
 is a given user
 @param    processNames  The set of strings, one of which a process' path must
 contain for it to be included in the results.  See class documentation
 definition of "executable".
 @param    user  The short name, that is, the Home directory name, of the user
 whose processes we want to be in results.  Pass NSUserName() for the current
 user.  Pass nil for any user.
 @result   Same as for +pidsExecutablesFull:
 */
+ (NSSet*)infosOfProcessesNamed:(NSSet*)processNames
                           user:(NSString*)user ;

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
 @brief    Returns a string consisting of the command followed by the
 arguments of a process identified by a given pid, then its start time,
 then its elapsed time, and finally its percent of CPU usage.

 @details  You must use your knowledge of the expected result in order
 to parse out individual arguments, because command paths or arguments
 with spaces in them are neither quoted nor escaped in the returned
 result.
 @result   The expected string, or nil if the given pid is not
 that of a running process
*/
+ (NSString*)descriptionOfPid:(pid_t)pid ;

/*!
 @brief    Finds a running app, owned by the current user,
 with a given bundle path, sends it a "quit application" Apple Event message,
 and returns when the app is quit or timeout occurs, whichever comes first.
 
 @details  Will block the thread until the target app quits, or timeout.

 @param    bundle path  The bundle path of the application to be
 quit, or nil to no-op.
 @param    closeWindows  If YES, will tell the subject app to 'close windows'
 before quitting.

 Affirming closeWindows improves the probability that the quitting will work,
 and has been found to be effective with Google Chrome and Firefox in
 particular (June 2011).  It was suggested by Shane Stanley…
 http://lists.apple.com/archives/applescript-implementors/2011/Jun/msg00010.html

 With most apps, closeWindows will stop the state restoration of macOS from
 re-opening the closed windows upon relaunch.

 With some apps, for example Roccat, closeWindows will cause open tabs,
 which should be remembered for the next launch, to be forgotten.

 @param    killAfterTimeout  This parameter was added in BookMacster 1.9.8
 after I found Google Chrome in a state where it wouldn't quit, not even if
 you activated it and clicked "Quit" in its menu.  Then, I found that this only
 happened maybe 2/100 times.  Weird.

 @param    wasRunning_p  If not nil, on return, will point to a value
 indicating whether or not the target app was indeed running and needed
 to be quit, or NO if the given bundle path was nil

 @result   YES if the target app was not running, or if it quit within
 the allowed timeout, or if bundleIdentifier was nil.  NO if app was
 still running when timeout expired.
 */
+ (BOOL)quitThisUsersAppWithBundlePath:(NSString*)bundlePath
                          closeWindows:(BOOL)closeWindows
							   timeout:(NSTimeInterval)timeout
					  killAfterTimeout:(BOOL)killAfterTimeout
						  wasRunning_p:(BOOL*)wasRunning_p
							   error_p:(NSError**)error_p ;

/*!
 @brief    Finds a running process, owned by the current user,
 with a given process identifier (pid), sends it a "kill -9" BSD signal,
 and returns when the process is killed or timeout occurs, whichever comes
 first.

 @details  May block its thread up to the timeout.  Sleeps for 0.5
 seconds between polls.
 @param    pid  The process identifier of the process to be
 killed, or nil to no-op
 @result   YES if the target process was not running, or if it dies within
 the allowed timeout, or if passed in pid is 0.  NO if process was still
 running when timeout expired.
 */
+ (BOOL)killThisUsersProcessWithPid:(pid_t)pid
                                sig:(int)sig
                            timeout:(NSTimeInterval)timeout;

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
	  cpuPercent_p:(CGFloat*)cpuPercent_p
		   error_p:(NSError**)error_p ;

/*!
 @brief    Returns the full path to an application with the given
 bundle identifier, if such an app is running with the current user
 as the owner

 @details  If an app with the given bundleIdentifier is not
 running, returns nil.
*/
+ (NSString*)pathOfThisUsersRunningAppWithBundleIdentifier:(NSString*)bundleIdentifier ;

/*!
 @brief    Returns the number of seconds since a process with a given pid
 has launched, or -1 if no process with the given pid is running
*/
+ (NSInteger)secondsRunningPid:(pid_t)pid ;

@end

#if 0
// Test code for pidOfMyRunningExecutableName:

NSLog(@"pid=%ld", (long)[SSYOtherApper pidOfMyRunningExecutableName:@"Finder"]) ;
NSLog(@"pid=%ld", (long)[SSYOtherApper pidOfMyRunningExecutableName:@"loginwindow"]) ;
NSLog(@"pid=%ld", (long)[SSYOtherApper pidOfMyRunningExecutableName:@"Sheep-Sys-Quatch"]) ;
NSLog(@"pid=%ld", (long)[SSYOtherApper pidOfMyRunningExecutableName:@"Crap"]) ;
exit(0) ;	

#endif
