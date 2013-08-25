#if MAC_OS_X_VERSION_MIN_REQUIRED > 1050
#define CPH_TASKMASTER_AVAILABLE 1
#else
#define CPH_TASKMASTER_AVAILABLE 0
#endif

#if CPH_TASKMASTER_AVAILABLE
#import "CPHTaskMaster+SetPermissions.h"
#import "CPHTaskMaster+StatPaths.h"
#endif

#import "SSYSuperFileManager.h"
#import <sys/stat.h>
#import "NSError+InfoAccess.h"
#import "NSError+MyDomain.h"

static SSYSuperFileManager* defaultManager = nil ;

@implementation SSYSuperFileManager

+ (SSYSuperFileManager*)defaultManager {
	@synchronized(self) {
        if (!defaultManager) {
            defaultManager = [[self alloc] init] ; 
        }
    }
	
	// No autorelease.  This sticks around forever.
    return defaultManager ;
}

- (BOOL)setPermissions:(mode_t)permissions
				  path:(NSString*)path
	changedPermissions:(NSMutableDictionary*)changedPermissions
			   error_p:(NSError**)error_p {
	
	NSNumber* oldPermissions = nil ;
#if CPH_TASKMASTER_AVAILABLE
	NSNumber* newPermissions = [NSNumber numberWithUnsignedShort:permissions] ;
	BOOL ok = [[CPHTaskmaster sharedTaskmaster] getPermissionNumber_p:&oldPermissions
															setPermissionNumber:newPermissions
																		   path:path
																		error_p:error_p] ;
#else
	BOOL ok = NO ;
	if (error_p) {
		*error_p = SSYMakeError(259101, @"Attempted an operation which is not supported in this old version of BookMacster") ;
	}
#endif

	if (!ok) {
		return NO ;
	}
	
	if (oldPermissions) {
		[changedPermissions setObject:oldPermissions
							   forKey:path] ;
	}
	
	return ok ;
}


/*!
 @brief    Returns whether or not an item exists at a given path, presenting
 an authentication dialog and changing permissions on its parent
 directory to octual 040777 if necessary to determine this existence.

 @param    path  The path to check for existence
 @param    changedPermissions  If it is not necessary to relax permissions
 on the parent directory, the passed-in dictionary will be untouched.  If
 it is necessary to relax permissions on the parent directory, and if
 this change was successful, the parent directory's path will be added as a
 key to this dictionary, with a value equal to an NSNumber whose unsigned
 short value is the original permissions of the parent directory before
 they were changed to octal 040777.
 @param    error_p  Pointer to an NSError which, if permissions needed to be
 changed and could not be, will point to an NSError instance explaining why
 permissions could not be changed.  Otherwise, this pointer will be
 untouched.
 @result   YES if the given path was determined to exist.  NO if it was
 determined to not exist, or if existence could not be determined because
 an error occurred when changing parent permissions.  In the latter case,
 error_p will be set to the relevant NSError instance.
*/
- (BOOL)fileExistsAtPath:(NSString*)path
	  changedPermissions:(NSMutableDictionary*)changedPermissions
				 error_p:(NSError**)error_p {
#if 0
	// Even though all we want to know is whether not not a file exists
	// at a given path, we use -attributesOfItemAtPath:error: instead of
	// -fileExistsAtPath because the former gives us an error output which
	// tells us whether or not we need to relax permissions on the parent.
	NSError* error = nil ;

	[self attributesOfItemAtPath:path
						   error:&error] ;

	if (
		([[error domain] isEqualToString:NSCocoaErrorDomain])
		&&
		([error code] == NSFileReadNoSuchFileError)  // == 260
		) {
		return NO ;
	}
	// else if (!isLastComponent) {
	// The following just caused false errors.  For some strange reason, it is not
	// possible to change permissions of a mounted disk in /Volumes.  Try it in
	// Terminal.  chmod returns no error but "just doesn't work".
	//mode_t perms = [[attributes objectForKey:NSFilePosixPermissions] unsignedShortValue] ;
	//if ((perms & S_IXOTH) == 0) {
	//	needToDigDeeperButWillBeStoppedByPermissions = YES ;
	//}
	//needToDigDeeperButWillBeStoppedByPermissions = ![self canExecuteDirectoryAtPath:path] ;
	//}
	
	if (!error) {
		return YES ;
	}
	
#endif
	if ([super fileExistsAtPath:path]) {
		return YES ;
	}
	
	NSString* parentPath = [path stringByDeletingLastPathComponent] ;
	unsigned short parentPermissions = [[[self attributesOfItemAtPath:parentPath
																error:NULL] objectForKey:NSFilePosixPermissions] unsignedShortValue] ;
	
	if (
		(
		 ((parentPermissions & S_IXOTH) == 0)
//		 [[error domain] isEqualToString:NSCocoaErrorDomain]
//		 &&
//		 [error code] == NSFileReadNoPermissionError
		 )
		) {
		// Inadequate permissions on parent
//		NSError* error = nil ;
		
		// Typically, the permissions on an inaccessible file's parent are:
		//      octal 040700 = 0x41C0 = decimal 16832
		// We change them temporarily to
		//      octal 040777 = 0x41FF = decimal 16895
		BOOL ok = [self setPermissions:040777
								 path:parentPath
				   changedPermissions:changedPermissions
							  error_p:error_p] ;
		if (!ok) {
			return NO ;
		}
		
		// Now that parent's permissions have been liberalized,
		// we try again to see if the file exists.
		BOOL answer = [self fileExistsAtPath:path] ;
		return answer ;
	}

	return NO ;
}

- (BOOL)setBulkPermissions:(NSDictionary*)permissions
				   error_p:(NSError**)error_p {
#if CPH_TASKMASTER_AVAILABLE
	return [[CPHTaskmaster sharedTaskmaster] getPermissions_p:NULL
														 setPermissions:permissions
																error_p:error_p] ;
#else
	if (error_p) {
		*error_p = SSYMakeError(259107, @"Attempted an operation which is not supported in this old version of BookMacster") ;
	}
	return NO ;
#endif
}

- (BOOL)setDeepPermissions:(mode_t)permissions
					  path:(NSString*)path
		changedPermissions:(NSMutableDictionary*)changedPermissions
				   error_p:(NSError**)error_p {
	
	NSNumber* oldPermissions = nil ;
#if CPH_TASKMASTER_AVAILABLE
	NSNumber* newPermissions = [NSNumber numberWithUnsignedShort:permissions] ;
	BOOL ok = [[CPHTaskmaster sharedTaskmaster] getPermissionNumber_p:&oldPermissions
															setPermissionNumber:newPermissions
																		   path:path
																		error_p:error_p] ;
#else
	BOOL ok = NO ;
	if (error_p) {
		*error_p = SSYMakeError(259102, @"Attempted an operation which is not supported in this old version of BookMacster") ;
	}
#endif
	
	if (!ok) {
		return NO ;
	}
	
	if (oldPermissions) {
		[changedPermissions setObject:oldPermissions
							   forKey:path] ;
	}
	
	return ok ;
}

- (BOOL)fileExistsAtPath:(NSString*)path
		   isDirectory_p:(BOOL*)isDirectory_p
			didElevate_p:(BOOL*)didElevate_p
				 error_p:(NSError**)error_p {
	NSArray* components = [path pathComponents] ;

	BOOL ok = YES ;
	BOOL exists = YES ;
	
	NSString* partialPath = @"" ;
	NSMutableDictionary* changedPermissions = [[NSMutableDictionary alloc] initWithCapacity:[components count]] ;
	for (NSString* component in components) {
		partialPath = [partialPath stringByAppendingPathComponent:component] ;
		
		ok = [self fileExistsAtPath:partialPath
				 changedPermissions:changedPermissions
							error_p:error_p] ;
		
		if (!ok) {
			exists = NO ;
			break ;
		}
	}
	
	if (didElevate_p) {
		*didElevate_p = ([changedPermissions count] > 0) ;
	}
	
	// Run -fileExistsAtPath:isDirectory: for the sole purpose of setting isDirectory_p
	[self fileExistsAtPath:path
			   isDirectory:isDirectory_p] ;
	
	// Restore old permissions (even if !ok)
	NSError* restoreError = nil ;
	BOOL restoredOk = YES ;
	
	if ([changedPermissions count] > 0) {
		ok = [self setBulkPermissions:changedPermissions
							  error_p:&restoreError] ;		
	}	
	[changedPermissions release] ;
	
	if (ok & !restoredOk) {
		if (error_p) {
			*error_p = restoreError ;
		}
		
	}
		
	return exists ;
}

- (BOOL)fileExistsAtPath:(NSString*)path
			didElevate_p:(BOOL*)didElevate_p
				 error_p:(NSError**)error_p {
	return [self fileExistsAtPath:path
					isDirectory_p:NULL
					 didElevate_p:didElevate_p
						  error_p:error_p] ;
}
	
- (BOOL)canExecutePath:(NSString *)fullPath
			   groupID:(uid_t)groupID
				userID:(uid_t)userID {
#if (MAC_OS_X_VERSION_MAX_ALLOWED < 1060) 
	NSDictionary* attributes = [self fileAttributesAtPath:fullPath
											 traverseLink:YES] ;
#else
	NSError* error = nil ;
	NSDictionary* attributes = [self attributesOfItemAtPath:fullPath
													  error:&error] ;
	if (error) {
		NSLog(@"Internal Error 529-2390 %@", error) ;
	}
#endif
BOOL canX = NO ;
	uint32_t posixPermissions = (uint32_t)[[attributes objectForKey:NSFilePosixPermissions] unsignedIntegerValue] ;
	// See if anyone can execute it
	if ((posixPermissions & S_IXOTH) != 0) {
		canX = YES ;
	}
	else {
		// See if given userID can execute it as owner
		uint32_t ownerID = (uint32_t)[[attributes objectForKey:NSFileOwnerAccountID] unsignedIntegerValue] ;
		if ( (ownerID==userID) && ((posixPermissions & S_IXUSR) != 0) ) {
			canX = YES ;
		}
		else {
			// See if given groupID can execute it as group
			uint32_t owningGroupID = [[attributes objectForKey:NSFileGroupOwnerAccountID] unsignedIntegerValue] ;
			if ( (owningGroupID==groupID) && ((posixPermissions & S_IXGRP) != 0) ) {
				canX = YES ;
			}
		}
	}

	return canX ;
}

- (NSDate*)modificationDateForPath:(NSString*)path
						   error_p:(NSError**)error_p {
	// For efficiency in case the caller expects the path may not exist,
	// and has passed error_p = NULL, we don't create a local error.
	NSDate* date = nil ;
	
	struct stat aStat ;
	BOOL ok = NO ;
	NSInteger result = stat([path fileSystemRepresentation], &aStat) ;
	if (result == 0) {
		ok = YES ;
	}
	else if (errno == EACCES) {
		// Permission denied.  Haul out the big gun.
#if CPH_TASKMASTER_AVAILABLE
		ok = [[CPHTaskmaster sharedTaskmaster] statPath:path
                                                   stat:&aStat
                                                error_p:error_p] ;
		if (!ok && error_p) {
			*error_p = [SSYMakeError(518383, @"Authorized stat failed") errorByAddingUnderlyingError:*error_p] ;
		}
#else
		ok = NO ;
		if (error_p) {
			*error_p = SSYMakeError(259103, @"Attempted an operation which is not supported in this old version of BookMacster") ;
		}
		
#endif
	}
	else if (error_p) {
		NSString* msg = [NSString stringWithFormat:
						 @"stat got errno %ld",
						 (long)errno] ;
		// The following error was 513560 until BookMacster 1.11 when I discovered
		// that it duplicated the same number in SSYSuperFileManager.
		*error_p = SSYMakeError(513504, msg) ;
	}
	
	if (ok) {
		time_t secs = aStat.st_mtimespec.tv_sec ;
		long nanosecs = aStat.st_mtimespec.tv_nsec ;
		NSTimeInterval timeSince1970 = secs + 1e-9 * nanosecs ;
		date = [NSDate dateWithTimeIntervalSince1970:timeSince1970] ;
	}
	
	return date ;
}

@end