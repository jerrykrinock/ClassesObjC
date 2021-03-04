#import <Cocoa/Cocoa.h>

extern NSString* const SSYTroubleZipperErrorDomain ;
extern NSString* const constKeySSYTroubleZipperURL ;

/*!
 @brief    Class with one method, for downloading, unzipping,
 and running a Trouble Zipper app.
*/
@interface SSYTroubleZipper : NSObject {
}

/*!
 @brief    Downloads, unzips, and runs the designated
 Trouble Zipper app.
 
 @details   The Trouble Zipper app is expected to be an
 application, with filename extension "app", compressed
 into a zip archive, with filename extension "zip",
 available for download from the URL which is the value for
 key constKeySSYTroubleZipperURLin this app's main
 bundle's Info.plist.
 
 This method immediately spawns another thread where
 the download and control occurs.  No progress is given
 unless something fails, in which case an error is
 displayed via an SSYAlert.  The Trouble Zipper is
 downloaded to a temporary directory, unzipped to a
 temporary file, then upon launching Trouble Zipper,
 the zip archive is deleted but the unzipped app
 is not deleted, in case it contains resources which
 are needed during execution.  It is left in a 
 uniquely-named subdirectory in the temporary
 directory and is therefore never re-used unless the
 user hunts it down.  Subsequent invocations of this
 method always cause a new Trouble Zipper to be
 downloaded and run.  That is by design, in case Trouble
 Zipper is updated.  Trouble Zippers will be deleted when
 temporary directories are destroyed by the system,
 which is when the user logs out.
 
 So, you can pretty much just invoke this method in
 an action method, and then forget it.
 
 If an error occurs, be sure to look for an underlyingError.
*/
+ (void)getAndRun ;

@end
