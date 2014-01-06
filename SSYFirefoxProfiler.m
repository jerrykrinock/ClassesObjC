#import "SSYFirefoxProfiler.h"
#import "NSString+MorePaths.h"
#import "NSFileManager+TempFile.h"
#import "NSError+MoreDescriptions.h"
#import "NSString+Base64.h"
#import "NSData+FileAlias.h"
#import "NSError+MyDomain.h"

@implementation SSYFirefoxProfiler

+ (NSString*)appSupportRelativePath {
    return @"Firefox" ;
}

+ (NSString*)defaultProfileName {
    return @"default" ;
}

+ (NSString*)browserSupportPathForHomePath:(NSString*)homePath {
    if (!homePath) {
        // Default to the current user's Mac account
        homePath = NSHomeDirectory() ;
    }

	return [[NSString applicationSupportPathForHomePath:homePath] stringByAppendingPathComponent:[self appSupportRelativePath]] ;
}

+ (NSString*)profilesFilePathForHomePath:(NSString*)homePath {
	return [[self browserSupportPathForHomePath:homePath] stringByAppendingPathComponent:@"profiles.ini"] ;
}

+ (NSArray*)profileNamesForHomePath:(NSString*)homePath {
	NSString* filepathProfilesIni = [self profilesFilePathForHomePath:homePath] ;
	
	NSString* profilesIniContents = [[NSString alloc] initWithContentsOfFile:filepathProfilesIni
                                                                usedEncoding:NULL
                                                                       error:NULL] ;
	
	NSArray* names = nil ;
	
	if (profilesIniContents) {
		// There is a profiles.ini file.  Parse it.
		NSScanner* scanner = nil ;
		NSMutableArray* outbasket = [[NSMutableArray alloc] init] ;
		NSString* name ;
		
		if(profilesIniContents) {
			scanner = [[NSScanner alloc] initWithString:profilesIniContents] ;
			
			while((![scanner isAtEnd])) {
				[scanner scanUpToString:@"Name=" intoString:NULL] ;
				if ([scanner scanString:@"Name=" intoString:NULL]) {
					[scanner scanUpToString:@"\n" intoString:&name] ;
					[outbasket addObject:name] ;
					// Without the "if" above, it will add the last name found to outbasket twice
				}
			}
		}
		
		names = [NSArray arrayWithArray:outbasket] ;
		[outbasket release] ;
		[scanner release] ;
	}
    
    [profilesIniContents release] ;
    
	return names ;
}

+ (NSString*)displayedSuffixForProfileName:(NSString*)profileName
                                  homePath:(NSString*)homePath {
    NSString* suffix ;
    if ([[self profileNamesForHomePath:homePath] count] > 1) {
        suffix = [NSString stringWithFormat:
                  @" (%@)",
                  profileName] ;
    }
    else {
        suffix = @"" ;
    }
    
    return suffix ;
}


+ (NSString*)randomProfilePrefix {
    // Emulate what Firfox does; 8 characters randomly selected from the set
    // of lower-case Roman alphas, and decimal digits.  These are ASCII values
    // 97-122 and 48-57.
    unichar chars[8] ;
    for (NSInteger i=0; i<8; i++) {
        NSInteger c = random() ;
        // There are 36 characters in our alpha+num alphabet
        c = c % 36 ;
        if (c<10) {
            // Make it a decimal digit
            c += 48 ;
        }
        else {
            // Make it a lower-case Roman
            c += (97 - 10) ;
        }
        chars[i] = (unichar)c ;
    }
    
    return [NSString stringWithCharacters:chars
                                   length:8] ;
}

+ (NSString*)profilesIniContentsForHomePath:(NSString*)homePath
                                    error_p:(NSError**)error_p {
    BOOL ok = YES ;
    NSError* error = nil ;
	NSString* filepathProfilesIni = [self profilesFilePathForHomePath:homePath] ;
	NSString* contents = [[NSString alloc] initWithContentsOfFile:filepathProfilesIni
                                                                usedEncoding:NULL
                                                                       error:NULL] ;
	if (!contents  && ![homePath isEqualToString:NSHomeDirectory()]) {
        // That second qualification above was added in BookMacster 1.13.2,
        // so that we can handle having the profiles.ini file not exist at this
        // at this point, if we're talking about this user's home bookmarks.
        
		// This may happen if desired profile is on an Other Mac Account,
		// where we don't have read permission.
		// Try copying the file to a temporary location using
		// a privileged-if-necessary Helper tool
		NSString* tempPath = [[NSFileManager defaultManager] temporaryFilePath] ;
#if CPH_TASKMASTER_AVAILABLE
		ok = [[CPHTaskmaster sharedTaskmaster] copyPath:filepathProfilesIni
                                                 toPath:tempPath
                                                error_p:&error] ;
#else
		ok = [[NSFileManager defaultManager]  copyItemAtPath:filepathProfilesIni
													  toPath:tempPath
													   error:&error] ;
#endif
		if (!ok) {
			goto end ;
		}
		
		// Now try reading the copied temporary file
		contents = [[NSString alloc] initWithContentsOfFile:tempPath
                                               usedEncoding:NULL
                                                      error:NULL] ;
		
		// Delete the temporary file
		BOOL trivialOk = [[NSFileManager defaultManager] removeItemAtPath:tempPath
                                                                    error:&error] ;
		if (!trivialOk) {
			// Unable to delete temporary file.  Unimportant error.
			// Do not display to user, just log it.
			NSLog(@"Internal Error 635-8292 %@", [error longDescription]) ;
		}
	}
    
end:
    if (error && error_p) {
        *error_p = error ;
    }
    
    return [contents autorelease] ;
}

+ (NSString*)pathForProfileName:(NSString*)profileName
                       homePath:(NSString*)homePath
                        error_p:(NSError**)error_p {
	NSString* fullPath = nil ;
	BOOL ok = YES ;
	NSError* error = nil ;
    
    NSString* profilesIniContents = [self profilesIniContentsForHomePath:homePath
                                                                 error_p:&error] ;
    if (error) {
        goto end ;
    }
    
	if (profilesIniContents) {
		NSScanner* scanner = [[NSScanner alloc] initWithString:profilesIniContents] ;
		
		NSString* nameLine = [[NSString alloc] initWithFormat:@"Name=%@\n", profileName] ;
		NSInteger isRelative = 1 ; //  Try and fail safe; since I have always seen it as = 1.
		NSString* pathFromDisk = nil;
		
		[scanner scanUpToString:nameLine intoString:NULL] ;
		[scanner scanString:nameLine intoString:NULL] ;
		[scanner scanString:@"IsRelative=" intoString:NULL] ;
		[scanner scanInteger:&isRelative] ;
		[scanner scanString:@"Path=" intoString:NULL] ;
		[scanner scanUpToString:@"\n" intoString:&pathFromDisk] ;
		
		if (isRelative) {
			// In this case, pathFromDisk is a "plain text" path
			fullPath = [[self browserSupportPathForHomePath:homePath] stringByAppendingPathComponent:pathFromDisk] ;
		}
		else {
			// In this case, pathFromDisk is a base64 encoded alias record
			NSData* aliasRecord = [pathFromDisk dataBase64Decoded] ;
			fullPath = [aliasRecord pathFromAliasRecordWithTimeout:3.0
														   error_p:NULL] ;
			if (!fullPath) {
				NSString* appSupportRelativePath = [self appSupportRelativePath] ;
                NSLog(@"Internal Error 234-5245  Could not get path from alias record in %@ profile %@.\nPossible corruption in %@",
                      appSupportRelativePath,
                      profileName,
                      [self profilesFilePathForHomePath:homePath]) ;
			}
		}
		
		[scanner release] ;
		[nameLine release] ;
        
	}
    else {
        // Added in BookMacster 1.13.2
        // Make one up.
        fullPath = [self browserSupportPathForHomePath:homePath] ;
        fullPath = [fullPath stringByAppendingPathComponent:@"Profiles"] ;
        NSString* folderName = [[self randomProfilePrefix] stringByAppendingPathExtension:[self defaultProfileName]] ;
        fullPath = [fullPath stringByAppendingPathComponent:folderName] ;
        
        // Also make up and install a profiles.ini file which points to it.
        NSString* profileText = [NSString stringWithFormat:
                                 @"[General]\n"
                                 @"StartWithLastProfile=1\n"
                                 @"\n"
                                 @"[Profile0]\n"
                                 @"Name=%@\n"
                                 @"IsRelative=1\n"
                                 @"Path=Profiles/%@\n"
                                 @"Default=1\n",
                                 [self defaultProfileName],
                                 folderName] ;
        NSString* filepathProfilesIni = [self profilesFilePathForHomePath:homePath] ;
        [[NSFileManager defaultManager] createDirectoryAtPath:[filepathProfilesIni stringByDeletingLastPathComponent]
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL] ;
        [profileText writeToFile:filepathProfilesIni
                      atomically:YES
                        encoding:NSUTF8StringEncoding
                           error:NULL] ;
    }
    
end:;
	if (!ok && !error) {
		NSString* msg = [NSString stringWithFormat:
						 @"%@ cannot access file at path:\n%@",
						 [[NSProcessInfo processInfo] processName],
						 [self profilesFilePathForHomePath:homePath]] ;
		error = [NSError errorWithDomain:[NSError myDomain]
									code:254938
								userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
										  msg, NSLocalizedDescriptionKey,
										  @"The above file is a required piece of Firefox.  Make sure it is there.  If not, launch Firefox to create a new user profile.", NSLocalizedRecoverySuggestionErrorKey,
										  nil]] ;
	}
    
	if (error_p) {
		*error_p = error ;
	}
	
	return fullPath ;
}

+ (NSString*)profileNameForPath:(NSString*)path
                        error_p:(NSError**)error_p {
	NSString* profileName = nil ;
	BOOL ok = YES ;
	NSError* error = nil ;
    
    /*
     We need to extract the "home" path from the given path.  We assume it
     will be a substring of the given path, starting from the beginning and
     including one path component beyond "Users".  OK, if the home path is
     on a mounted volume that is named "Users", for example /Volumes/Users/,
     so that the correct answer is, for example,  "/Volumes/Users/Users/suzie",
     then this code will give the wrong answer, "/Volumes/Users/Users".
     Does anyone know a better way to do this?
     */
    NSString* homePath = nil ;
    NSArray* pathComponents = [path pathComponents] ;
    NSMutableArray* homePathComponents = [[NSMutableArray alloc] init] ;
    BOOL gotHome = NO ;
    for (NSInteger i=0; i<([pathComponents count] - 1);) {
        NSString* component = [pathComponents objectAtIndex:i++] ;
        [homePathComponents addObject:component] ;
        if ([component isEqualToString:@"Users"]) {
            [homePathComponents addObject:[pathComponents objectAtIndex:i]] ;
            gotHome = YES ;
            break ;
        }
    }
    if (gotHome) {
        homePath = [homePathComponents componentsJoinedByString:@"/"] ;
        if ([homePath hasPrefix:@"//"]) {
            homePath = [homePath substringFromIndex:1] ;
        }
    }
    [homePathComponents release] ;
    
    NSString* profilesIniContents = [self profilesIniContentsForHomePath:homePath
                                                                 error_p:&error] ;
    if (error) {
        goto end ;
    }
	
	if (profilesIniContents) {
		NSScanner* scanner = [[NSScanner alloc] initWithString:profilesIniContents] ;
        [scanner setCharactersToBeSkipped:nil] ;
        while (![scanner isAtEnd] && !profileName) {
            NSString* thisProfileString = nil ;
            [scanner scanUpToString:@"[Profile" intoString:NULL] ;
            [scanner scanUpToString:@"\n" intoString:NULL] ;
            [scanner scanString:@"\n" intoString:NULL] ;
            [scanner scanUpToString:@"[Profile" intoString:&thisProfileString] ;
            
            NSScanner* subscanner = [[NSScanner alloc] initWithString:thisProfileString] ;
            BOOL thisProfileDone = NO ;
            NSString* thisProfileName = nil ;
            NSString* thisRawPath = nil ;
            NSInteger thisIsRelative = -1 ;
            while (!thisProfileDone) {
                if (!thisProfileName) {
                    [subscanner scanUpToString:@"Name=" intoString:NULL] ;
                    [subscanner scanString:@"Name=" intoString:NULL] ;
                    [subscanner scanUpToString:@"\n" intoString:&thisProfileName] ;
                    [subscanner scanString:@"\n" intoString:NULL] ;
                }
                if (!thisRawPath) {
                    [subscanner setScanLocation:0] ;
                    [subscanner scanUpToString:@"Path=" intoString:NULL] ;
                    [subscanner scanString:@"Path=" intoString:NULL] ;
                    [subscanner scanUpToString:@"\n" intoString:&thisRawPath] ;
                    [subscanner scanString:@"\n" intoString:NULL] ;
                }
                if (thisIsRelative == -1) {
                    [subscanner setScanLocation:0] ;
                    [subscanner scanUpToString:@"IsRelative=" intoString:NULL] ;
                    [subscanner scanString:@"IsRelative=" intoString:NULL] ;
                    [subscanner scanInteger:&thisIsRelative] ;
                    [subscanner scanString:@"\n" intoString:NULL] ;
                }
                
                if (thisProfileName && thisRawPath && (thisIsRelative != -1)) {
                    thisProfileDone = YES ;
                    NSString* thisFullPath = NO ;
                    NSString* filepathProfilesIni = [self profilesFilePathForHomePath:homePath] ;

                    if (thisIsRelative == 1) {
                        // In this case, pathFromDisk is a "plain text" path
                        thisFullPath = [[self browserSupportPathForHomePath:homePath] stringByAppendingPathComponent:thisRawPath] ;
                        
                    }
                    else if (thisIsRelative == 0) {
                        // In this case, pathFromDisk is a base64 encoded alias record
                        NSData* aliasRecord = [thisRawPath dataBase64Decoded] ;
                        thisFullPath = [aliasRecord pathFromAliasRecordWithTimeout:3.0
                                                                           error_p:NULL] ;
                        if (!thisFullPath) {
                            NSString* appSupportRelativePath = [self appSupportRelativePath] ;
                            NSLog(@"Internal Error 234-5897  Could not get path from alias record in %@ profile %@.\nPossible corruption in %@",
                                  appSupportRelativePath,
                                  thisProfileName,
                                  filepathProfilesIni) ;
                        }
                        
                    }
                    else {
                        NSLog(@"Internal Error 502-9595 for %@", filepathProfilesIni) ;
                    }
                    
                    if (strcmp([thisFullPath fileSystemRepresentation], [path fileSystemRepresentation]) == 0) {
                        profileName = thisProfileName ;
                    }
                }
                
                if ([subscanner isAtEnd]) {
                    thisProfileDone = YES ;
                }
            }
            
            [subscanner release] ;
        }
        
		[scanner release] ;
	}
    
end:;
	if (!ok && !error) {
		NSString* msg = [NSString stringWithFormat:
						 @"%@ cannot access file at path:\n%@",
						 [[NSProcessInfo processInfo] processName],
						 [self profilesFilePathForHomePath:homePath]] ;
		error = [NSError errorWithDomain:[NSError myDomain]
									code:254938
								userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
										  msg, NSLocalizedDescriptionKey,
										  @"The above file is a required piece of Firefox.  Make sure it is there.  If not, launch Firefox to create a new user profile.", NSLocalizedRecoverySuggestionErrorKey,
										  nil]] ;
	}
    
	if (error_p) {
		*error_p = error ;
	}
	
	return profileName ;
    
#if 0
    // Old code which is 99% simpler but only works for 99+% of users
    /*
     I've seen the last path component can come in three different forms…
     *           lastPathComponent
                   of profile path     We want to extract
     -           -----------------     ------------------
     *  Form 1:  ieri3hz1.default      default
     *  Form 2:  odi44oee.Joe-Doe      Joe-Doe
     *  Form 3:  Joe-Doe               Joe-Doe
     
     Those names could also have spaces instead of dashes.
     Until version 286 (May 2012, BookMacster 1.11), we examined the
     -pathExtension and if it was "default", extracted the profile name as
     "default", otherwise simply passed through the lastPathComponent.
     That worked for Forms 1 and 3, but not 2 where we got an unwanted prefix.
     Then until version 295, we always extracted the path extension.  That
     worked for Forms 1 and 2 but broke it for Form 3, where we got an empty
     string.  Starting with version 295, for God's sake this seems to cover all
     3 cases.
     */
DEFUNCT CODE:
    NSString* profileNameFromPath(NSString* path) {
        NSString* lastPathComponent = [path lastPathComponent] ;
        NSString* extension = [lastPathComponent pathExtension] ;
        NSString* extractedProfileName ;
        if ([extension length] > 0) {
            // Form 1 or 2
            extractedProfileName = extension ;
        }
        else {
            // Form 3
            extractedProfileName = lastPathComponent ;
        }
        
        return extractedProfileName ;
    }
#endif
}


@end