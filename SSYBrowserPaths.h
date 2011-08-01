#import <Cocoa/Cocoa.h>


extern NSString* const SSYBrowserPathsErrorDomain ;


@interface SSYBrowserPaths : NSObject {

}

/*!
 @brief    Gets profile names for a given browser and user home

 @details  Returns empty array if profiles.ini cannot be read
 @param    appSupportRelativePath  The path, relative to the user's 
 Application Support directory, at which either a profiles.ini file
 or profile subdirectories will be found.  Examples: "Firefox", "Google/Chrome"
 @param    homePath  The home path of the users for which profiles are desired
 @result   The array of profile names, or an empty array
 */
+ (NSArray*)profileNamesForAppSupportRelativePath:(NSString*)browserName
						  homePath:(NSString*)homePath ;


+ (NSString*)profilePathForAppSupportRelativePath:(NSString*)browserName
									  profileName:(NSString*)profileName
										 homePath:(NSString*)homePath
										  error_p:(NSError**)error_p ;

@end
