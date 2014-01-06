#import <Cocoa/Cocoa.h>


@interface SSYFirefoxProfiler : NSObject {
}


+ (NSArray*)profileNamesForHomePath:(NSString*)homePath ;
    
+ (NSString*)displayedSuffixForProfileName:(NSString*)profileName
                                  homePath:(NSString*)homePath ;
    
/*!
 @brief    Gets path to the Firefox profile folder for a given Firefox profile
 name and home folder, or nil if a failure occurs
 
 @details  Operates by finding the Firefox profiles.ini file in a given home
 folder, parsing its entries to find the one pertaining to the given profile
 name, and resolving the profile folder path indicated by this entry.
 
 This method performs the inverse of -profileNameForPath:error_p:.
 */
+ (NSString*)pathForProfileName:(NSString*)profileName
                       homePath:(NSString*)homePath
                        error_p:(NSError**)error_p ;

/*
 @brief    Returns the Firefox profile name given a Firefox profile path
 @details  Although I did this for years by simply taking the last path
 component of the profile path and un-tweaking it, in January 2014 I have
 evidence from at least one user that this doesn't always work.  Specifically,
 his profile name is "Default" but the path to his profile is
    ~/Library/Application Support/Firefox/Profiles
 That's correct, all of the 3-dozen-or-so files and folders containing his
 profile data are in the parent folder "Profiles" instead of in a subfolder.
 However, his profiles.ini file contains the correct information in the 
 following entry…
 
 [Profile0]
 Name=Default
 IsRelative=1
 Path=Profiles
 Default=1

 Oh, well.  So, after several hours, I have written this method which finds the
 Firefox profiles.ini file which is in the same Home folder that the given
 profile path is in, parses the entries in it until it finds the entry whose
 path description resolves to the given profile path, and finally extracts from
 that entry the profile name.
 
 The old code which is 99% simpler but only works for 99+% of users, is given
 as a comment in the implementation file.
 
 This method performs the inverse of -pathForProfileName:homePath:error_p:
 */
+ (NSString*)profileNameForPath:(NSString*)path
                        error_p:(NSError**)error_p ;
@end
