#import "SSYDropboxGuy.h"
//#import "NSError+InfoAccess.h"
//#import "NSArray+SafeGetters.h"
//#import "NSString+Base64.h"
//#import "NSString+PythonPickles.h"
//#import "NSString+MorePaths.h"
#import "SSYOtherApper.h"
//#import "SSYShellTasker.h"
#import "SSWebBrowsing.h"
#import "NSFileManager+SomeMore.h"
#import "NSDate+NiceFormats.h"

NSString* const SSYDropboxGuyErrorDomain = @"SSYDropboxGuyErrorDomain" ;
NSString* const constDropboxBundleIdentifier = @"com.getdropbox.dropbox" ;

@implementation SSYDropboxGuy

+ (NSImage*)dropboxIcon {
	NSImage* image = [SSYOtherApper iconForAppWithBundleIdentifier:constDropboxBundleIdentifier] ;
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

+ (BOOL)wasReplacedByDropboxPath:(NSString*)path {
	return [path hasPrefix:[NSHomeDirectory() stringByAppendingPathComponent:@".dropbox/cache/"]] ;
}

+ (NSString*)defaultDropboxPath {
	NSString* path = [NSHomeDirectory() stringByAppendingPathComponent:@"Dropbox"] ;
	
	return path ;
}

+ (BOOL)dropboxIsAvailable {
#if 0
#warning Faking Dropbox not available
	return NO ;
#else
	return ([[NSFileManager defaultManager] fileIsPermanentAtPath:[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:constDropboxBundleIdentifier]]) ;
#endif
}

+ (NSInteger)isInDropboxPath:(NSString*)path {
    NSFileManager* fm = [NSFileManager defaultManager] ;
    do {
        path = [path stringByDeletingLastPathComponent] ;
        if ([path isEqualToString:NSHomeDirectory()]) {
            return NSOffState ;
        }
        
        NSError* error = nil ;
        NSArray* siblings = [fm contentsOfDirectoryAtPath:path
                                                    error:&error] ;
        if (error) {
            return NSMixedState ;
        }
        if ([siblings indexOfObject:@".dropbox.cache"] != NSNotFound) {
            return NSOnState ;
        }
        
    } while ([path length] > 2) ;
    
    return NSOffState ;
}



/*
 The following methods no longer work if user has Dropbox 1.2 or later, because
 Dropbox has encrypted their configuration database.  Sorry!
 
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
		dropboxPath = [self defaultDropboxPath] ;
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
 */

@end