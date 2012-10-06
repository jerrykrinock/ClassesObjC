#import "SSYBrowserPaths.h"
#import "NSString+MorePaths.h"
#import "NSString+Base64.h" 
#import "NSData+FileAlias.h"
#import "NSFileManager+TempFile.h"
#import "CPHTaskMaster+CopyPaths.h"
#import "NSObject+MoreDescriptions.h"

NSString* const SSYBrowserPathsErrorDomain = @"SSYBrowserPathsErrorDomain" ;

NSString* BrowserSupportPath(NSString* appSupportRelativePath, NSString* homePath) {
	return [[NSString applicationSupportPathForHomePath:homePath] stringByAppendingPathComponent:appSupportRelativePath] ;
}

NSString* ProfilesIniPath(NSString* appSupportRelativePath, NSString* homePath) {
	return [BrowserSupportPath(appSupportRelativePath, homePath)
			stringByAppendingPathComponent:@"profiles.ini"] ;
}

@implementation SSYBrowserPaths

+ (NSArray*)profileNamesForAppSupportRelativePath:(NSString*)appSupportRelativePath
						  homePath:(NSString*)homePath {
	NSString* filepathProfilesIni = ProfilesIniPath(appSupportRelativePath, homePath) ;
	
	NSString* strungFile = [[[NSString alloc] initWithContentsOfFile:filepathProfilesIni
                                                        usedEncoding:NULL
                                                               error:NULL] autorelease] ;
	
	NSArray* names = nil ;
	
	if (strungFile) {
		// There is a profiles.ini file.  Parse it.
		// (Browser is Firefox)
		NSScanner* scanner = nil ;
		NSMutableArray* outbasket = [[NSMutableArray alloc] init] ;
		NSString* name ;
		
		if(strungFile) {
			scanner = [[NSScanner alloc] initWithString:strungFile] ;
			
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
		
	return names ;
}

+ (NSString*)profilePathForAppSupportRelativePath:(NSString*)appSupportRelativePath
									  profileName:(NSString*)profileName
										 homePath:(NSString*)homePath
										  error_p:(NSError**)error_p {
	NSString* fullPath = nil ;
	BOOL ok = YES ;
	NSError* error = nil ;

	NSString* filepathProfilesIni = ProfilesIniPath(appSupportRelativePath, homePath) ;
	NSString* strungFile = [[NSString alloc] initWithContentsOfFile:filepathProfilesIni
                                                       usedEncoding:NULL
                                                              error:NULL] ;
	if (!strungFile) {
		// This may happen if desired profile is on an Other Mac Account,
		// where we don't have read permission.  
		// Try copying the file to a temporary location using
		// a privileged-if-necessary Helper tool
		NSString* tempPath = [[NSFileManager defaultManager] temporaryFilePath] ;
		ok = [[CPHTaskmaster sharedTaskmaster] copyPath:filepathProfilesIni
														   toPath:tempPath
														  error_p:&error] ;
		if (!ok) {
			goto end ;
		}
		
		// Now try reading the copied temporary file
		strungFile = [[NSString alloc] initWithContentsOfFile:tempPath
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

	
	if (strungFile) {
		NSScanner* scanner = [[NSScanner alloc] initWithString:strungFile] ;
		
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
			fullPath = [BrowserSupportPath(appSupportRelativePath, homePath) stringByAppendingPathComponent:pathFromDisk] ;
		}
		else {
			// In this case, pathFromDisk is a base64 encoded alias record
			NSData* aliasRecord = [pathFromDisk dataBase64Decoded] ;
			fullPath = [aliasRecord pathFromAliasRecordWithTimeout:3.0
														   error_p:NULL] ;
			if (!fullPath) {
				NSLog(@"Internal Error 234-5245  Could not get path from alias record in %@ profile %@.\nPossible corruption in %@", appSupportRelativePath, profileName, filepathProfilesIni) ;
			}
		}
		
		[scanner release] ;
		[nameLine release] ;

	}	
	[strungFile release] ;

end:;
	if (!ok && !error) {
		NSString* msg = [NSString stringWithFormat:
						 @"%@ cannot access file at path:\n%@",
						 [[NSProcessInfo processInfo] processName],
						 filepathProfilesIni] ;
		error = [NSError errorWithDomain:SSYBrowserPathsErrorDomain
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

@end