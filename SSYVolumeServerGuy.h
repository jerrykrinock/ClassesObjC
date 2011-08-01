#import <Cocoa/Cocoa.h>


/*!
 @brief    Methods for getting information about the
 volume and server of paths rooted in mounted volumes.

 @details  Warning: All of these methods can hang for
 up to a few minutes if server connection has been
 interrupted (in Mac OS X 10.5.7).
*/
@interface SSYVolumeServerGuy : NSObject {
}

/*!
 @brief    Determines whether or not a the volume containing a
 given path is mounted locally or via a network connection.
 
 @details  Uses statfs.  Limitations:
 
 In macnetworkprog@lists.apple.com,

 At 02:49 +0100 2009-11-07, Stephane Sudre wrote:
 This does not deal with the mounted disk image hosted on a
 remote volume case IIRC.  There was an interesting thread on this
 topic on the darwin-dev or darwin-kernel mailing list sometimes ago.
 
 The next day, Quinn "The Eskimo" responded:  
 Right.  It really depends on why you're testing whether the volume is
 a network volume, which is something that I should've mentioned in
 my previous post.  Another challenge is cluster file systems, like Xsan,
 which provide a mixture of the characteristics of network and local
 file systems.
 @param    isLocal_p  Pointer which will, upon return, point
 to a BOOL indicating YES if the volume is mounted locally,
 NO if it is mounted via network connection.  Must not be NULL.
 @param    error_p  Pointer which will, upon return, if an error
 occurred and said pointer is not NULL, point to an NSError
 describing said error.
 @result   YES if the operation completed successfully,
 otherwise NO.
 */
+ (BOOL)path:(NSString*)path
   isLocal_p:(BOOL*)isLocal_p 
	 error_p:(NSError**)error_p ;

/*!
 @brief    Gets the volume reference number of the volume
 containing a given path in the filesystem.
 
 @details  This method is a wrapper around FSGetCatalogInfo,
 which does return an OSErr, but we don't return it because
 most of the time the error is simply that your path is not
 a currently-mounted volume, unless something really weird
 happened.
 @param    path  The path to a given mounted volume, or any
 child path rooted in this path.&nbsp; 
 Examples:
 *  @"/Volumes/MyVolume"
 *  @"/Volumes/MyVolume/"
 *  @"/Volumes/MyVolume/What/Ever.txt"
 will all return the volume reference number of MyVolume.
 May be nil (will return 0).
 @result   The volume reference number of the given path,
 or 0 if it could not be obtained for any reason.
 */
+ (FSVolumeRefNum)volumeRefNumberForPath:(NSString*)path ;

/*!
 @brief    Returns the name of the server from which a given
 path's volume was mounted.

 @details  Sends +hostnameForVolumeName and returns only the
 first path component of the result.
 @param    path  Same deal as for path in +volumeRefNumberForPath.
 @result   If path's volume is mounted  which is mounted via Apple
 Filing Protocol (afp://), will return the identifier of the host,
 not including the transport type and domain.&nbsp;  Example:
 "Suzie's Old Powerbook".&nbsp;  For paths on the current root
 volume, will return "localhost".
*/
+ (NSString*)afpServerDisplayNameForPath:(NSString*)path ;

@end
