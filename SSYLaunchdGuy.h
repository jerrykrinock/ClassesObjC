#import <Cocoa/Cocoa.h>

extern NSString* const SSYLaunchdGuyErrorDomain ;

/*!
 @brief    A class for manipulating launchd agents.  All methods in this
 class manipulate only launchd agents in the current user's Mac account.

 @details   Agent names will be of the form:
    identifier.agentIndex
 where identifier is of the form
    tld.company.appName.docID
*/
@interface SSYLaunchdGuy : NSObject {
}

+ (NSString*)homeLaunchAgentsPath ;

/*!
 @brief    Returns a set of all labels (that is, filenames without the 
 .plist filename extension) in this user's Launch Agents
 directory that have a given prefix, possibly an empty set.
 
 @param    The target prefix.  May be nil; if so, method returns empty set.
 Assumes that the plist files are named using the convention stated in
 man launchd.plist(5) "for launchd property list files to be named <Label>.plist",
 because this method extracts the label from the filename.
*/
+ (NSSet*)installedLaunchdAgentLabelsWithPrefix:(NSString*)prefix ;

/*!
 @brief    Returns a dictionary of dictionaries, with each dictionary representing
 the data in one of this user's Launch Agents, named with a given prefix, and 
 each key is one of the members returned by -installedLaunchdAgentLabelsWithPrefix:.
 
 @param    The target prefix.  May be nil; if so, method returns empty dictionary.
 */
+ (NSDictionary*)installedLaunchdAgentsWithPrefix:(NSString*)prefix ;

/*!
 @brief    Installs a launchd agent and, usually, loads it
 
 @details  If an agent contains a "RunAtLoad" key and does
 not contain any of the keys "OnDemand", "KeepAlive",
 "StartOnMount", "StartInterval", "StartCalendarInterval", 
 "WatchPaths", "QueueDirectories", then the agent is *not*
 loaded.  The thinking is that if "RunAtLoad" is the only 
 trigger key, your desire is that the job will run at
 the user's next login/startup.   Otherwise, you wouldn't
 be using launchd; you'd just run the command yourself!
 @param    agentDic  A dictionary contains the launchd
 attributes and values the desired launchd agent.
 @param    error_p  If not NULL and if an error occurs, upon return,
 will point to an error object encapsulating the error.
 @result   YES if the method completed successfully, otherwise NO
 */
+ (BOOL)addAgent:(NSDictionary*)agentDic
		 error_p:(NSError**)error_p ;

/*!
 @brief    Installs an array of launchd agents and,
 usually, loads them.

 @details  Same details as given for addAgent:error_p: apply to this
 method.
 @param    agents  An array of dictionaries.  Each
 dictionary contains the launchd attributes and values
 for one launchd agent.
 @param    error_p  If not NULL and if an error occurs, upon return,
 will point to an error object encapsulating the error.
 @result   YES if the method completed successfully, otherwise NO
*/
+ (BOOL)addAgents:(NSArray*)agents
		  error_p:(NSError**)error_p ;

/*!
 @brief    Removes and unloads all launchd agents whose filenames
 begin with a given prefix.
 
 @details  Unloads the agents using launchctl.  Any processes
 started by an unloaded agent will be terminated or killed.
 @param    prefix  The target prefix, or nil.  If nil, the
 method does nothing and returns YES.
 @param    afterDelay  See explanation of 'afterDelay' parameter in
 +removeAgentWithLabel::::
 @param    timeout  See explanation of 'timeout' parameter in
 +removeAgentWithLabel::::
 @param    successes  If timeout > 0.0, and if this parameter is
 not nil, the full paths to any agent's plist file which was
 successfully deleted are added as strings to this parameter.
 If timeout = 0.0, this parameter is ignored.
 @result   YES if all attempted operations were successful,
 otherwise NO.  YES if no such agents were found
 */
+ (BOOL)removeAgentsWithPrefix:(NSString*)prefix
					afterDelay:(NSInteger)delay
					   timeout:(NSTimeInterval)timeout
					 successes:(NSMutableSet*)successes
					  failures:(NSMutableSet*)failures ;

/*!
 @brief    Unloads and removes the plist file, or else unloads and then
 reloads, an existing launchd agent, in a separate process.

 @details  If no plist file exists for the given label, this method does
 nothing.  It will not try to unload the agent, because launchctl will fail
 with error saying no such file.  It is possible to load an agent and then
 delete its file.  The agent will remain loaded until the user logs out,
 but I don't know how to unload such an orphan agent.
 
 If the plist file exists for the given label but the agent is not loaded,
 the file will be removed and launchctl will log an error message such as the
 following to stderr:
 "launchctl: Error unloading: com.sheepsystems.BookMacster.4299B333-C47D-4473-B329-41F43E22E886.000.000.doSoon.84110"
 
 The reason for the separate process is so that, if used
 carefully, this method can unload the agent which launched the process
 that called it.
 
 This method writes to a temporary file a shell
 script which does the following:
 * Waits for an optional delay
 * Unloads the specified agent from launchd, using launchctl
 * Either removes the specified agent's plist file or sleeps for 1 second and then reloads it
 * Removes the temporary file
 
 If a timeout is given, this method
 then launches another process to wait until the plist file has
 been actually deleted from the filesystem before returning or timing out.
 Otherwise, it returns YES immediately.
 
 Executing the shell script in a separate process is important
 because, when unloading a job,
 launchctl will either not return until any running process launched
 by the agent to be unloaded has exitted, or quit that process,
 or after a timeout whose default value is 25 seconds, and kill that
 process.  Therefore, if you want to remove the agent which started
 the calling process, you need to know T = how much more time your
 process might need before it exits, and then…

 *  Make sure that T < 25 seconds
 *  Pass delay: > T
 *  Pass timeout = 0.0
 
 One usage is to work around the fact that launchd does not support
 a "one shot" Agent.  You can invoke this method near the end of the launched
 task, following the above rules, to make your agent "one shot".
 
 The purpose of the justReload option is in case you are superstitious,
 as I am, that launchd sometimes will fail to launch your task repeatedly,
 and that unloading and reloading the task will help.  You can invoke this
 method with justReload = YES whenever you're feeling insecure about launchd.
 I call this operation to "revitalize" the agent.
 
 @param    label  A string which is used to specify the path
 to the plist file.  After appending the file extension "plist"
 to the given label, per the convention stated in man launchd.plist(5)
 "for launchd property list files to be named <Label>.plist",
 the path to the user's Launch Agents, i.e. ~/Library/LaunchAgents/,
 is prepended.  If the given label is nil, or if the file in
 ~/Library/LaunchAgents which it indicates does not exist, this method
 returns YES immediately and does not unload, reload nor remove anything.
 @param    delay  Time in seconds which the script will sleep
 before unloading the agent.
 @param    justReload  If YES, will not remove the specified
 agent but will instead unload it, wait 1 second, and then reload
 it.  See "revitalize" in the Details section.
 @param    timeout  If greater than 0.0, this method will block
 until the plist file to be deleted from the filesystem, or up to
 timeout seconds, before returning.  Otherwise, this method will
 return immediately.  Note that if you pass justReload=YES, there
 is a built-in delay of 1 second, so timeout should be more than
 1 second.
 @result   NO if 'timeout' is > 0.0 and the
 agent's plist file is not deleted before the timeout;
 otherwise, YES.
*/
+ (BOOL)removeAgentWithLabel:(NSString*)label
				  afterDelay:(NSInteger)delaySeconds
				  justReload:(BOOL)justReload
					 timeout:(NSTimeInterval)timeout ;

/*!
 @brief    Returns whether or not the user's LaunchAgents includes any
 whose label has a give prefix, and whose triggers include a
 StartCalendarInterval
 
 @details  Todo: Verify whether or not the next date
 indicated by the StartCalendarInterval was not already past, and/or
 to return the next fire date.  To do that, one could use a Python
 package written by Matsumoto Taichi (taichino@gmail.com), 'croniter'…
 http://pypi.python.org/pypi/croniter, or this PHP project by
 Michael Dowling… https://github.com/mtdowling/cron-expression
 which was apparently spawned by this article…
 http://stackoverflow.com/questions/321494/calculate-when-a-cron-job-will-be-executed-then-next-time
 
 This method is not used at this time.
*/
+ (BOOL)isScheduledLaunchdAgentWithPrefix:(NSString*)prefix ;

/*!
 @brief    Tries to load or unload a specified launchd agent, ignoring
 if the requested status is already existing, or if there is no plist
 file to load 

 @details  If 'load' is YES and the agent is already loaded, or if
 'load' is NO and the agent is not loaded, or if 'load' is YES
 but the required plist file is not available, that is deemed a 
 success; this method does nothing and returns YES.
 
 This method will probably give unexpected results if you attempt
 to unload the job which launched the invoking process.  If you want to do
 that, read and use removeAgentWithLabel:::: instead.
 @param    load  YES to load, NO to unload
 @param    label  A string which is used to specify the path
 to the plist file.  After appending the file extension "plist"
 to the given label, per the convention stated in man launchd.plist(5)
 "for launchd property list files to be named <Label>.plist",
 the path to the user's Launch Agents, i.e. ~/Library/LaunchAgents/,
 is prepended.
 @param    error_p  If not NULL and if an error occurs, upon return,
           will point to an error object encapsulating the error.
 @result   YES if the method completed successfully, otherwise NO
*/
+ (BOOL)tryAgentLoad:(BOOL)load
			   label:(NSString*)label
			 error_p:(NSError**)error_p ;

@end
