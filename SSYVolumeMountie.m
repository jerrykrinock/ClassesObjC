#import "SSYVolumeMountie.h"
#import "NSError+InfoAccess.h"
#import "NSError+LowLevel.h"
#import "NSError+MyDomain.h"

/*
 FROM : Bill Monk
 DATE : Tue Apr 22 01:07:21 2008
 
 On Apr 19, 2008, on Mon, 21 Apr 2008 10:06:47 +0530, JanakiRam wrote:
 
 >    This code works fine , but when i try to mount another volume/ 
 > account on the same server , this code doesn't seem to work.I'm  
 > always getting -43 error.If i unmount the earlier volume/account on  
 > the same server then i'm able to mount another volume on the server.
 
 
 What sort of server? Perhaps you should post some code. In general it  
 should works for any number of volumes on a server.
 
 Now, I have occasionally seen error -43 in a situation where  
 [[NSWorkspace sharedWorkspace] mountedLocalVolumePaths] (which,  
 somewhat contrary to its name, returns all mounted volumes including  
 servers) lists a particular server as being mounted, but that server  
 is not visible on the Desktop or in Finder window sidebars. Yet the  
 server is in fact mounted, as can be confirmed with various File  
 Manager API such as FSPathMakeRef(), reading/writing the volume by  
 any means, etc. Such volumes can be unmounted in Terminal with  
 umount, which succeeds without error. After that they can be mounted  
 again with no problem.
 
 Have only really noticed this under Tiger, with programmatically  
 mounted idisks. My guess is that it may sometimes fail to display new  
 volumes if several are mounted in very rapid succession. For my  
 purposes it didn't matter: if a volume is mounted and accessible,  
 that was good enough.
 
 Without seeing your code, couldn't say if this applies to your  
 situation. Possibly, sending         
 
 [[NSWorkspace sharedWorkspace]  
 noteFileSystemChanged:pathOfVolumeToMount];
 
 after a successful mount might help ensure the volume is visible in  
 Finder. Probably best to first check if a volume is already mounted  
 via mountedLocalVolumePaths anyway
 
 As Jens notes, logging into AFP servers as multiple users at the same  
 time may not always do what you'd expect.
 With Leopard client, for instance, you -can- programatically mount  
 the same volume for multiple logged-in accounts (assuming the volumes  
 are marked as sharable for each account in System prefs, or the  
 volume is the account's public folder). Doing this will succeed; no  
 error occurs. The vRefNum returned, however, will be the same for all  
 of them, and only the first appears in the Finder. This makes sense  
 from a concurrency standpoint.
 
 Not sure if any of the above addresses your -43 errors; http:// 
 lists.apple.com/mailman/listinfo/filesystem-dev would definitely be a  
 good place to ask about that.
 
 In any case your question prompted me to rework that old code;  
 passing a single dictionary for the many params is more  
 pleasant...perhaps it will be useful to someone. */


NSString* const SSYVolumeMountieServerNameKey = @"ServerName";
NSString* const SSYVolumeMountieVolumeNameKey = @"VolumeName";
NSString* const SSYVolumeMountieDirectoryKey = @"Directory";
NSString* const SSYVolumeMountieTransportNameKey = @"TransportName";
NSString* const SSYVolumeMountieUserNameKey = @"UserName";
NSString* const SSYVolumeMountiePasswordKey = @"Password";

@implementation SSYVolumeMountie

+ (BOOL)mountServer:(NSDictionary *)mountDictionary
			error_p:(NSError**)error_p {
	NSString *pathOfVolumeToMount;
	
	// To mount a volume quietly, without an authentication dialog, it's necessary
	// that FSMountServerVolumeSync's userName and password params *not* be NULL.
	// While it -is- possible to pass NULL for these (by encoding them into
	// the URL, see above), if the server doesn't exist, passing NULL for these params
	// causes the system to put up a "server is not available or may not be operational"
	// dialog even though the values are already encoded into the URL.
	//
	// Solution: pass userName and password directly to FSMountServerVolumeSync,
	// and leave them out of the URL. This will mount the volume if it's possible,
	// and if not, will quietly return an error. No authentication dialog will appear.
#define kNoPasswordInURL 1
#if kNoPasswordInURL
	// Construct string of the form:
	//   transportName://serverName/volumeName
	pathOfVolumeToMount = [NSString stringWithFormat:@"%@://%@/%@",
						   [mountDictionary objectForKey:SSYVolumeMountieTransportNameKey],
						   [mountDictionary objectForKey:SSYVolumeMountieServerNameKey],
						   [mountDictionary objectForKey:SSYVolumeMountieVolumeNameKey]];
#else
	// Construct string of the form:
	//    transportName://userName:password@serverName/volumeName
	pathOfVolumeToMount = [NSString stringWithFormat:@"%@://%@:%@@%@/%@",
							[mountDictionary objectForKey:SSYVolumeMountieTransportNameKey],
							[mountDictionary objectForKey:SSYVolumeMountieUserNameKey],
							[mountDictionary objectForKey:SSYVolumeMountiePasswordKey],
							[mountDictionary objectForKey:SSYVolumeMountieServerNameKey],
							[mountDictionary objectForKey:SSYVolumeMountieVolumeNameKey]];
#endif // kNoPasswordInURL
	
	// percent-escape any space characters in the URL string and create URL
	pathOfVolumeToMount = [pathOfVolumeToMount stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSURL *urlOfVolumeToMount = [NSURL URLWithString:pathOfVolumeToMount];
	
	// create NSURL for optional directory on server to mount; can also
	// just include the subdirectory in server URL (if that path is share-able).
	NSURL *mountDirectoryURL = NULL;
	NSString *mountDirectoryPath = [mountDictionary  
									objectForKey:SSYVolumeMountieDirectoryKey];
	if (mountDirectoryPath) {
		mountDirectoryPath = [NSString stringWithFormat:
							  @"/Volumes/%@/%@",
							  [mountDictionary objectForKey:SSYVolumeMountieVolumeNameKey],
							  mountDirectoryPath] ;
		mountDirectoryPath = [mountDirectoryPath  
							  stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		mountDirectoryURL = [NSURL URLWithString:mountDirectoryPath];
	}
	
	OSStatus err ;
	FSVolumeRefNum refNum;
	err = FSMountServerVolumeSync( (CFURLRef)urlOfVolumeToMount,
									(CFURLRef)mountDirectoryURL, // if NULL, default location is mounted.
									(CFStringRef)[mountDictionary objectForKey:SSYVolumeMountieUserNameKey],
									(CFStringRef)[mountDictionary objectForKey:SSYVolumeMountiePasswordKey],
									&refNum,
									0L /* OptionBits, currently unused */
									) ;
	
	NSError* error = nil ;
	if (!err) {
		// Experiment: see if -noteFileSystemChanged: has any effect on the occasional idisk
		// which mounts successfully but which is not visible in Finder window sidebars and,
		// sometimes, not even on the Desktop. (noticed with under Tiger)
		[[NSWorkspace sharedWorkspace] noteFileSystemChanged: [pathOfVolumeToMount stringByAppendingPathComponent:mountDirectoryPath]];
	}
	else {
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary] ;
		if (pathOfVolumeToMount) {
			[userInfo setObject:pathOfVolumeToMount
						 forKey:@"pathOfVolumeToMount"] ;
		}
		if (mountDirectoryPath) {
			[userInfo setObject:mountDirectoryPath
						 forKey:@"mountDirectoryPath"] ;
		}
		NSError* error_ = [NSError errorWithDomain:NSOSStatusErrorDomain
											  code:err
										  userInfo:userInfo] ;
		error = SSYMakeError(20280, @"SSYVolumeMountie failed to mount disk") ;
		error = [error errorByAddingUnderlyingError:error_] ;
	}
	
	if (error && error_p) {
		*error_p = error ;
	}
	return (!error) ;
}


+ (BOOL)unmountVolumePath:(NSString*)path
				  error_p:(NSError**)error_p {
    OSStatus status ;
    OSErr err ;
	NSInteger errCode = 0 ;
	NSInteger errCode_ = noErr ;
	NSString* failedFunction = nil ;
	
    const char *utf8VolumePath = [path fileSystemRepresentation] ;
    FSRef volumeFSRef ;
    // Warning: FSPathMakeRef may hang for a minute or so if mounted server is interrupted
    if ((status = FSPathMakeRef(
								(UInt8 *)utf8VolumePath,  
								&volumeFSRef,
								(Boolean*)NULL)
		) != noErr) {
		errCode = 23050 ;
		errCode_ = status ;
		failedFunction = @"FSPathMakeRef" ;
        goto end;
    }
	
    FSCatalogInfo catalogInfo;
    if ((err = FSGetCatalogInfo(
								&volumeFSRef,
								kFSCatInfoVolume,  
								&catalogInfo,
								NULL,
								NULL,
								NULL
		 )) != noErr) {
		errCode = 23051 ;
		errCode_ = err ;
		failedFunction = @"FSGetCatalogInfo" ;
        goto end ;
    }
	
    FSVolumeRefNum volumeRefNum = catalogInfo.volume ;
	
	pid_t dissenterPid = 0 ;
	if ((status = FSUnmountVolumeSync (
									   volumeRefNum,
									   0,
									   &dissenterPid
									   )) != noErr) {
		// It would be cool, at this point, to get the name of 
		// the process whose pid is dissenterPid and add it to
		// the returned NSError.  However, when I tried setting
		// up a dissenting pid (by cd to the target volume in
		// Terminal.app), FSUnmountVolumeSync failed as expected,
		// returning status -47, but dissenterPid was 0.
		// So, it appears that, at least in Mac OS X 10.5.7,
		// dissenterPid "just doesn't work".  So, I ignore it.
		errCode = 23052 ;
		errCode_ = status ;
		failedFunction = @"FSUnmountVolumeSync" ;
        goto end ;
	}		

end:
	if (errCode && error_p) {
		NSString* msg = [NSString stringWithFormat:
						 @"%@() returned underlying error",
						 failedFunction] ;
		*error_p = SSYMakeError(errCode, msg) ;
		NSError* error_ = [NSError errorWithMacErrorCode:(OSStatus)errCode_] ;
		*error_p = [*error_p errorByAddingUnderlyingError:error_] ;
	}
	
	return (errCode == 0) ;
}

#if 0
#warning Test Methods being compiled in SSYVolumeMountie.
// Used in test method.
+ (void)mountServers:(NSArray *)array
{
	if ( array == NULL ) return;
	
	NSUInteger i, count = [array count];
	for (i = 0; i < count; i++) {
		NSDictionary *thisServer = [array objectAtIndex:i];
		[self mountServer:thisServer];
	}
}

+ (IBAction)mountSomeServers:(id)sender {
	NSMutableArray *mountArray = [NSMutableArray array];
	
	NSDictionary *mountDictionary;
	
	// mount a file-shared volume on machine "MBPLeopard"
	mountDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
					   @"MBPLeopard.local", kServerNameKey,
					   @"volumeName", kVolumeNameKey,
					   @"afp", kTransportNameKey,
					   @"", kMountDirectoryKey,
					   @"username", kUserNameKey,
					   @"password", kPasswordKey,
					   [NSNumber numberWithBool:YES], kAsyncKey, NULL];
	[mountArray addObject:mountDictionary];
	
	// also mount user's home directory on the same server
	mountDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
					   @"MBPLeopar.local", kServerNameKey,
					   @"username", kVolumeNameKey, // home directory
					   @"afp", kTransportNameKey,
					   @"", kMountDirectoryKey,
					   @"username", kUserNameKey,
					   @"password", kPasswordKey,
					   [NSNumber numberWithBool:YES], kAsyncKey, NULL];
	[mountArray addObject:mountDictionary];
	
	// an idisk
	mountDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
					   @"idisk.mac.com", kServerNameKey,
					   @"youriDisk-Public", kVolumeNameKey,
					   @"http", kTransportNameKey,
					   @"", kMountDirectoryKey,
					   @"username", kUserNameKey,
					   @"", kPasswordKey,  // assumes no password sort on idisk public folder
					   [NSNumber numberWithBool:YES], kAsyncKey, NULL];
	[mountArray addObject:mountDictionary];
	
	// a subdirectory on the same idisk, without bothering
	//with the kMountDirectoryKey key
	mountDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
					   @"idisk.mac.com", kServerNameKey,
					   @"youriDisk-Public/SomeExistentFolder", kVolumeNameKey,
					   @"http", kTransportNameKey,
					   @"", kMountDirectoryKey,
					   @"username", kUserNameKey,
					   @"", kPasswordKey,
					   [NSNumber numberWithBool:YES], kAsyncKey, NULL];
	[mountArray addObject:mountDictionary];
	
	// mount servers in array
	[self mountServers:mountArray];
}
#endif

@end