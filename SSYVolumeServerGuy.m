#import "SSYVolumeServerGuy.h"
#import "NSString+SSYExtraUtils.h"
#import <sys/param.h>
#import <sys/mount.h>
#import "NSError+LowLevel.h"


@implementation SSYVolumeServerGuy

+ (BOOL)path:(NSString*)path
   isLocal_p:(BOOL*)isLocal_p 
	 error_p:(NSError**)error_p {
	BOOL ok = YES ;
	struct statfs aStatfs ;
	NSInteger statErr = statfs([path fileSystemRepresentation], &aStatfs) ;
	if (statErr != 0) {
		ok = NO ;
		if (error_p) {
			*error_p = [NSError errorWithPosixErrorCode:errno] ;
		}
	}
	
	*isLocal_p = (aStatfs.f_flags & MNT_LOCAL) > 0 ;
	
	return ok ;
}

+ (FSVolumeRefNum)volumeRefNumberForPath:(NSString*)path {	
	// We only look at the first three components of the given path, because that's
	// all that's necessary to determine the volume it's on.  It it's on the root volume,
	// we only need the first component, "/".  But if it's in /Volumes/Whatever/..., we
	// need three components.  (The components in this case are "/", "Volumes", "Whatever".)
	NSArray* components = [path pathComponents] ;
	components = [components subarrayWithRange:NSMakeRange(0, MIN([components count], 3))] ;
	path = [NSString pathWithComponents:components] ;
	
    FSRef pathRef;
	
    // Warning: May hang for a minute or so if mounted server is interrupted
	FSPathMakeRef(
				  (UInt8*)[path fileSystemRepresentation],
				  &pathRef,
				  NULL
				  ) ;
	
    OSErr osErr;
	
    FSCatalogInfo catInfo;
    osErr = FSGetCatalogInfo(
							 &pathRef,
							 kFSCatInfoVolume,
							 &catInfo,
							 NULL,
							 NULL,
							 NULL
							 ) ;
	
    FSVolumeRefNum volumeRefNum = 0 ;
	
	if(osErr == noErr) {
        volumeRefNum = catInfo.volume;
    }
	
    return volumeRefNum ;
}

+ (NSString*)afpServerDisplayNameForPath:(NSString*)path {
	NSArray* components = [path pathComponents] ;
	NSString* serverName = nil ;
	
	// The path must be at least as long as "/Volumes/Whatever/"
	// The components in this case are "/", "Volumes", and "Whatever"
	if ([components count] < 3) {
		return nil ;
	}
	
	BOOL isLocal ;
	BOOL ok = [self path:path
			   isLocal_p:&isLocal 
				 error_p:NULL] ;
	
	if (!ok) {
		return nil ;
	}
		
	if (isLocal) {
		CFStringRef computerName = CSCopyMachineName() ;
		serverName = (NSString*)computerName ;
		return [serverName autorelease] ;
	}
		
	if ( &FSGetVolumeMountInfoSize == NULL ) {
		return nil ;
	}
	
	FSVolumeRefNum volRefNum = [SSYVolumeServerGuy volumeRefNumberForPath:path] ;
	if (!volRefNum) {
		return nil ;
	}
	
	OSErr err ;
	size_t                      volInfoSize;
	VolumeMountInfoHeaderPtr    volInfoBuffer;
	size_t                      junkSize;

	// Get the mount info from the file system.
	err = FSGetVolumeMountInfoSize(volRefNum, &volInfoSize);
	if (err != noErr) {
		return nil ;
	}

	volInfoBuffer = malloc(volInfoSize);
	if (volInfoBuffer == NULL) {
		return nil ;
	}

	err = FSGetVolumeMountInfo(volRefNum, (BytePtr) volInfoBuffer, volInfoSize, &junkSize);
		
	if (err != noErr) {
		free(volInfoBuffer);
		return nil ;
	}
	
	if (volInfoBuffer->media == AppleShareMediaType) {
		const void * fieldPtr = (((char *) volInfoBuffer) + offsetof(AFPVolMountInfo, serverNameOffset)) ;
		short fieldValue = *((const short *) fieldPtr) ;
		const UInt8 * pascalStringPtr = ((const UInt8*)fieldPtr) - ((size_t)(void*)offsetof(AFPVolMountInfo, serverNameOffset)) + fieldValue ;
		serverName = [NSString stringWithPascalString:pascalStringPtr
											 encoding:kCFStringEncodingMacRoman] ;
	}

	free(volInfoBuffer);
	
	return serverName ;
}



@end