#import "SSYDropboxGuy.h"
#import "SSYSqliter.h"
#import "NSError+SSYAdds.h"
#import "NSArray+SafeGetters.h"
#import "NSString+Base64.h"
#import "SSYDropboxGuy.h"
#import "NSString+PythonPickles.h"
#import "NSString+MorePaths.h"
#import "SSYOtherApper.h"
#import "SSYShellTasker.h"
#import "SSWebBrowsing.h"

NSString* const SSYDropboxGuyErrorDomain = @"SSYDropboxGuyErrorDomain" ;

#define THRESHOLD_AVERAGE_CPU_PERCENT 1.0

@implementation SSYDropboxGuy

+ (NSImage*)dropboxIcon {
	NSImage* image = [SSYOtherApper iconForAppWithBundleIdentifier:@"com.getdropbox.dropbox"] ;
	if (!image) {
		image = [NSImage imageNamed:NSImageNameNetwork] ;
	}
	
	return image ;
}

+ (void)getDropbox {
	[SSWebBrowsing browseToURLString:@"http://getdropbox.com"
			 browserBundleIdentifier:nil
							activate:YES] ;
}

NSString* const constConfigDir = @".dropbox" ;
NSString* const constOldFilename = @"dropbox" ;
NSString* const constNewFilename = @"config" ;
NSString* const constFileExtension = @"db" ;

+ (NSString*)databasePathNew:(BOOL)new {
	NSString* filename = new ? constNewFilename : constOldFilename ;
	return [[[NSHomeDirectory() stringByAppendingPathComponent:constConfigDir]
			 stringByAppendingPathComponent:filename]
			stringByAppendingPathExtension:constFileExtension] ;
}

+ (NSString*)dropboxPathError_p:(NSError**)error_p  {
	if (error_p) {
		*error_p = nil ;
	}
	
	NSString* databasePath = nil ;

	databasePath = [self databasePathNew:YES] ;
	BOOL hasNewDatabase = [[NSFileManager defaultManager] fileExistsAtPath:databasePath] ;
	
	BOOL hasOldDatabase ;
	if (!hasNewDatabase) {
		databasePath = [self databasePathNew:NO] ;
		hasOldDatabase = [[NSFileManager defaultManager] fileExistsAtPath:databasePath] ;
	}
	
	if (!hasNewDatabase && !hasOldDatabase) {
		return nil ;
	}
	
	NSError* underlyingError = nil ;
	
	SSYSqliter* sqliter = [[SSYSqliter alloc] initWithPath:databasePath
												   error_p:&underlyingError] ;
	if (!sqliter) {
		// User has a Dropbox but database cannot be read
		if (error_p) {
			*error_p = [NSError errorWithDomain:SSYDropboxGuyErrorDomain
										   code:651101
									   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
												 @"Dropbox database couldn't be opened", NSLocalizedDescriptionKey,
												 underlyingError, NSUnderlyingErrorKey, // may be nil
												 nil]] ;
		}
		return nil ;
	}
	
	NSArray* queryResults = [sqliter selectColumn:@"value"
											 from:@"config"
									  whereColumn:@"key"
											   is:@"dropbox_path"
											error:&underlyingError] ;
	// Memory leak (and sqlite database left open) fixed in BookMacster version 1.3.19…
	[sqliter release] ;
	
	if (underlyingError) {
		if (error_p) {
			*error_p = [NSError errorWithDomain:SSYDropboxGuyErrorDomain
										   code:651102
									   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
												 @"Error reading Dropbox configuration", NSLocalizedDescriptionKey,
												 underlyingError, NSUnderlyingErrorKey, // may be nil
												 nil]] ;
		}
		return nil ;
	}
	
	NSString* queryResult = [queryResults firstObjectSafely] ;
	
	NSString* dropboxPath= nil ;

	if (!queryResult) {
		// There is no 'dropbox_path' in table 'config' of the user's dropbox
		// database.  This means that they are using the default dropbox
		// location, which is ...
		if (error_p) {
			*error_p = nil ;
		}
		dropboxPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Dropbox"] ;
	}
	else if (hasNewDatabase) {
		dropboxPath = queryResult ;
	}
	else if (hasOldDatabase) {
		// In the old database, the dropbox path in the database was first
		// encoded as a Python pickle and then base64 encoded.  We must
		// undo those two encodings.  Example:
		// queryResult = @"Vi9Vc2Vycy9qay9Ecm9wYm94Mi9Ecm9wYm94CnAxCi4="
		// pythonPickle = @"V/Users/jk/Dropbox2/Dropbox\np1\n.\n"
		// dropboxPath = @"/Users/jk/Dropbox2/Dropbox"
		
		// Base64 Decoding
		NSString* pythonPickle = [queryResult stringBase64Decoded] ;
		if (!pythonPickle) {
			if (error_p) {
				*error_p = [NSError errorWithDomain:SSYDropboxGuyErrorDomain
											   code:651103
										   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
													 @"Error base64 decoding Dropbox path", NSLocalizedDescriptionKey,
													 queryResult, @"base64",
													 nil]] ;
			}
			return nil ;
		}
		
		// Unpickling
		dropboxPath = [pythonPickle pythonUnpickledError_p:&underlyingError] ;
		if (!dropboxPath && error_p) {
			*error_p = [NSError errorWithDomain:SSYDropboxGuyErrorDomain
										   code:651104
									   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
												 @"Error unpickling Dropbox path", NSLocalizedDescriptionKey,
												 pythonPickle, @"pickle",
												 nil]] ;
		}
	}		
	
	// So now we've got the supposed path out of the database.  Now, let's
	// make sure that folder exists at the supposed path.
	BOOL isDir ;
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:dropboxPath
													   isDirectory:&isDir] ;
	
	if (!exists || !isDir) {
		if (error_p) {
			NSString* msg1 = [NSString stringWithFormat:@"Dropbox folder is missing.  Expected at:\n\n%@",
							  dropboxPath] ;
			NSString* msg2 = @"Launch Dropbox app and follow their instructions." ;
			*error_p = [NSError errorWithDomain:SSYDropboxGuyErrorDomain
										   code:651105
									   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
												 msg1, NSLocalizedDescriptionKey,
												 msg2, NSLocalizedRecoverySuggestionErrorKey,
												 nil]] ;
		}
	
		dropboxPath = nil ;
	}
	
	return dropboxPath ;
}

+ (BOOL)userHasDropboxError_p:(NSError**)error_p {
	NSError* error = nil ;
	NSString* path = [self dropboxPathError_p:&error] ;
	if (error && error_p) {
		*error_p = error ;
	}

	return (path != nil) ;
}

+ (BOOL)wasReplacedByDropboxPath:(NSString*)path {
	return [path hasPrefix:[NSHomeDirectory() stringByAppendingPathComponent:@".dropbox/cache/"]] ;
}

#define LOG_STATS_DUING_WAIT_FOR_IDLE_DROPBOX 0
#if LOG_STATS_DUING_WAIT_FOR_IDLE_DROPBOX
#warning Will log stats during -[SSYDropboxGuy waitForIdleDropboxTimeout:::]
#endif

+ (BOOL)waitForIdleDropboxTimeout:(NSTimeInterval)timeout
						   isIdle:(BOOL*)isIdle_p
						  error_p:(NSError**)error_p {
	// Since the Dropbox app does not appear in the Dock, I'm somehwat sure, we
	// get 0 pid from +[SSYOtherApper pidOfThisUsersAppWithBundleIdentifier:].  So
	// we use +[SSYOtherApper pidOfThisUsersProcessWithBundlePath:] instead
	NSString* bundlePath = [[NSWorkspace sharedWorkspace] fullPathForApplication:@"Dropbox"] ;
	pid_t dropboxPid = [SSYOtherApper pidOfThisUsersProcessWithBundlePath:bundlePath] ;
	if (dropboxPid == 0) {
		// Dropbox app is not running
		if (isIdle_p) {
			*isIdle_p = YES ;
		}
		
		return YES ;
	}
	
	BOOL ok ;

	NSDate* outerEndDate = [NSDate dateWithTimeIntervalSinceNow:timeout] ;
	NSString* const errorDescription = @"Could not get Dropbox CPU Usage" ;
	do {
		NSTimeInterval const innerLoopPeriod = 10.0 ;
		NSDate* innerEndDate = [NSDate dateWithTimeIntervalSinceNow:innerLoopPeriod] ;
		NSInteger n = 0 ;
		float total = 0.0 ;
		float cpuPercent ;
		do {
			ok = [SSYOtherApper processPid:dropboxPid
								   timeout:innerLoopPeriod  // better be much less than this, to get lots of samples
							  cpuPercent_p:&cpuPercent
								   error_p:error_p] ;
#if LOG_STATS_DUING_WAIT_FOR_IDLE_DROPBOX
				printf("%0.1f ", *cpuPercent) ;
#endif
			if (ok) {
				total += cpuPercent ;
				n++ ;
			}
			else {
				if (error_p) {
					*error_p = [NSError errorWithDomain:SSYDropboxGuyErrorDomain
												   code:651106
											   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
														 errorDescription, NSLocalizedDescriptionKey,
														 [NSNumber numberWithInt:dropboxPid], "PID",
														 *error_p, NSUnderlyingErrorKey,
														 nil]] ;
				}				
				break ;
			}
			
			usleep(1800000) ; // 1.8 seconds
		} while ([(NSDate*)[NSDate date] compare:innerEndDate] == NSOrderedAscending) ;
		
		if (ok) {
			float avgCpuUsage = total/n ;
#if LOG_STATS_DUING_WAIT_FOR_IDLE_DROPBOX
			printf("\nDropbox avgCpuUsage = %0.3f\n", avgCpuUsage) ;
#endif
			if (avgCpuUsage < THRESHOLD_AVERAGE_CPU_PERCENT) {
				NSInteger i ;
				for (i=0; i<3; i++) {
					// See if we can get three more in a row with CPU usage 0.25 percent or less
					ok = [SSYOtherApper processPid:dropboxPid
										   timeout:innerLoopPeriod  // better be much less than this, to get lots of samples
									  cpuPercent_p:&cpuPercent
										   error_p:error_p] ;
#if LOG_STATS_DUING_WAIT_FOR_IDLE_DROPBOX
					printf("%0.1f ", *cpuPercent) ;
#endif
					if (cpuPercent > 0.25) {
#if LOG_STATS_DUING_WAIT_FOR_IDLE_DROPBOX
						printf(" Failed 3x retest") ;
#endif
					}
					
					if (!ok) {
						if (error_p) {
							*error_p = [NSError errorWithDomain:SSYDropboxGuyErrorDomain
														   code:651107
													   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																 errorDescription, NSLocalizedDescriptionKey,
																 [NSNumber numberWithInt:dropboxPid], "PID",
																 *error_p, NSUnderlyingErrorKey,
																 nil]] ;
						}				
						break ;
					}
					
					sleep(1.0) ;
				}
				
#if LOG_STATS_DUING_WAIT_FOR_IDLE_DROPBOX
				printf("\n Got i=%d\n", i) ;
#endif
				if (i==3) {
					if (isIdle_p) {
						*isIdle_p = YES ;
						break ;
					}
				}
			}
		}
		else {
			break ;
		}
	} while ([(NSDate*)[NSDate date] compare:outerEndDate] == NSOrderedAscending) ;

#if LOG_STATS_DURING_WAIT_FOR_IDLE_DROPBOX
	printf("RESULT:  ok=%d  isIdle=%d  err=%s\n\n", ok, *isIdle_p, [[*error_p longDescription] UTF8String]) ;
#endif	
	return ok ;
}

+ (BOOL)pathIsInDropbox:(NSString*)path {
	if (!path) {
		return NO ;
	}
	
	NSString* dropboxPath = [SSYDropboxGuy dropboxPathError_p:NULL] ;
	if (!dropboxPath) {
		return NO ;
	}
	
	BOOL isIn = [path pathIsDescendantOf:dropboxPath] ;
	if (!isIn) {
		// There is some kind of bug in the system whereby if this document's
		// file path is /Users/jk/Cloud/Dropbox/Dropbox/DeleteTest.bkmslf,
		// on my old 32-bit Mac Mini, path will at this point be instead
		// /Users/jk/Cloud/dropbox/dropbox/DeleteTest.bkmslf.  The same 
		// thing happens in BookMacster-Worker, where the path is obtained
		// from -[BkmxDocumentController pathOfDocumentWithUuid:::], which
		// gets it from a stored alias record.
		// So if that didn't work, we morph and retest it.
		NSMutableString* morphedPath = [path mutableCopy] ;
		NSString* priorPath ;
		do {
			priorPath = [NSString stringWithString:morphedPath] ;
			[morphedPath replaceOccurrencesOfString:@"/dropbox/"
										 withString:@"/Dropbox/"
											options:0
											  range:NSMakeRange(0, [morphedPath length])] ;
			isIn = [morphedPath pathIsDescendantOf:dropboxPath] ;
		} while (!isIn && ![priorPath isEqualToString:morphedPath]) ;
		
		[morphedPath release] ;
	}
	
	return isIn ;
}

@end