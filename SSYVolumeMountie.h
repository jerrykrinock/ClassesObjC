#import <Cocoa/Cocoa.h>

extern NSString* const SSYVolumeMountieServerNameKey ;
extern NSString* const SSYVolumeMountieVolumeNameKey ;
extern NSString* const SSYVolumeMountieDirectoryKey ;
extern NSString* const SSYVolumeMountieTransportNameKey ;
extern NSString* const SSYVolumeMountieUserNameKey ;
extern NSString* const SSYVolumeMountiePasswordKey ;

/*!
 @brief    Class for programatically mounting/unmounting a volume/server.
 
*/
@interface SSYVolumeMountie : NSObject {
}

/*!
 @brief    Synchronously mounts a specified volume/server with a specified
 transport protocol, optionally with a given username and password.

 @details  This method was adapted from code written by Bill Monk:
 http://www.cocoabuilder.com/archive/message/cocoa/2008/4/22/204837

 @param    mountDictionary  A dictionary containing values for the
 SSYVolumeMountieXXXKey keys.
 The SSYVolumeMountieTransportNameKey is typically @"afp".
 For SSYVolumeMountieVolumeNameKey, if you do not know the name of 
 the volume you want (usually because you don't know what volumes
 are available), you may pass @"" and the system will present a
 dialog asking the user to choose which volume they want to mount.
 For further work, you can find what volumes are available with the
 FPGetSrvrParms command/function/??
 
 The following keys are optional:
 *  SSYVolumeMountieDirectoryKey
 *  SSYVolumeMountieUserNameKey
 *  SSYVolumeMountiePasswordKey
 
 If userName or password are not provided, system will present an
 authentication dialog.
 
 @param    error_p  Pointer which will, upon return, if an error
 occurred and said pointer is not NULL, point to an NSError
 describing said error.
 @result   YES if the method executed without error, otherwise NO.
*/
+ (BOOL)mountServer:(NSDictionary *)mountDictionary
			error_p:(NSError**)error_p ;

/*!
 @brief    Unmounts a given volume

 @details  Warning: This method FSPathMakeRef may hang for a minute
 or so if mounted server the physical connection to a mounted
 server has been interrupted.
 @param    path  The path to the target volume, in the form
 @"/Volumes/TargetVolume"
 @param    error_p  Pointer which will, upon return, if an error
 occurred and said pointer is not NULL, point to an NSError
 describing said error.
 @result   YES if the method executed without error, otherwise NO.
*/
+ (BOOL)unmountVolumePath:(NSString*)path
				  error_p:(NSError**)error_p ;

@end


