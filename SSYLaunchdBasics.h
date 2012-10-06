#import <Cocoa/Cocoa.h>


/*!
 @brief    Some basic methods for finding out about installed
 launchd agents

 @details  I refactored these methods out of SSYLaunchdGuy so
 I could use them in the CTypes dylib in our Firefox extension
 without including a ton of other crap.
*/
@interface SSYLaunchdBasics : NSObject {
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
 
 @details  We program defensively when reading files!  Each entry is checked to
 make sure it is a dictionary before adding to the returned dictionary.
 @param    The target prefix.  May be nil; if so, method returns empty dictionary.
 */
+ (NSDictionary*)installedLaunchdAgentsWithPrefix:(NSString*)prefix ;

@end
