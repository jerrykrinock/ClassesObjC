#import <Cocoa/Cocoa.h>

extern NSString* const SSYDropboxGuyErrorDomain ;

@interface SSYDropboxGuy : NSObject

/*!
 @brief    Returns the icon of the Dropbox application, or the
 system icon named "NSNetwork" if the Dropbox application is not
 properly installed on current Mac.
*/
+ (NSImage*)dropboxIcon ;

/*!
 @brief    Opens the getdropbox.com website in the user's default
 web browser and activates said web browser

 @details  This is used to help the user sign up for a
 Dropbox account.
*/
+ (void)getDropbox ;

/*!
 @brief    Returns whether or not a given path is in the Dropbox
 archive, indicating that it was replaced by Dropbox.
*/
+ (BOOL)wasReplacedByDropboxPath:(NSString*)path ;

/*!
 @brief    Blocks until the Dropbox application appears to be not busy.

 @details  The criteria used is that first the CPU usage of the Dropbox
 application, returned by /bin/ps, is measured once per 2 seconds for 10
 seconds.  If the average of these five measurements is less than 1.0 percent,
 then three more measurements are taken at 1-second intervals.  If all
 three of these are less than 0.25 percent, then isIdle_p is set to point
 to YES and the method returns.  If either of these tests fail, then
 they are repeated, and this continues until the timeout.
 
 When Dropbox is idle, this method usually returns the affirmative result
 after 13-39 seconds.  When Dropbox is receiving a file, it will not
 return an affirmative result until Dropbox is idle.  Also when Time
 Machine is doing a backup, this usually keeps Dropbox active enough
 to not return an affirmative result for a minute or two.  But you
 probably don't want to be messing with Dropbox while Time Machine
 is doing its thing anyhow.
 
 This method sleeps the thread between measurements, so it's not a
 CPU hog, just a thread hog.
 
 @param    timeout  time to wait for Dropbox to become idle.  However,
 one measurement cycle, which takes about 15 seconds, will always
 execute.  So this method will always block for at least about 15
 seconds no matter what value you pass here.
 @param    isIdle_p  Pointer which will, upon return, if not nil,
 point to YES if Dropbox is idle and no error occurred
 @param    error_p  Pointer which will, upon return, if the method
 was not able to determine isIdle_p and error_p is not
 NULL, point to an NSError describing said error.
 @result   YES if the method was able to set isIdle_p,
 otherwise NO.
*/
+ (BOOL)waitForIdleDropboxTimeout:(NSTimeInterval)samplePeriod
						   isIdle:(BOOL*)isIdle_p
						  error_p:(NSError**)error_p ;

+ (NSString*)defaultDropboxPath ;

+ (BOOL)dropboxIsAvailable ;

#if 0
/*
 The following methods no longer work if user has Dropbox 1.2 or later, because
 Dropbox has encrypted their configuration database.  Sorry!
 */
/*!
 @brief    Gets the path to the current user's Dropbox directory
  @details  Determined by reading the user's Dropbox database file.
 @param    error_p  Pointer to an NSError* or NULL.  Upon return,
 if value is not NULL and if an error occurred while
 reading the user's Dropbox database, the pointer will be set to
 an NSError describing said error.  Otherwise, if value is not NULL,
 pointer will be set to nil.
 @result   If the user has a Dropbox database which can be read without
 error, returns the user's Dropbox path.  Otherwise, returns nil.
 */
+ (NSString*)dropboxPathError_p:(NSError**)error_p ;
/*!
 @brief    Returns whether or not the user has a Dropbox available.
 @param    error_p  Pointer which will, upon return, if an error
 occurred and said pointer is not NULL, point to an NSError
 describing said error.
 @result   If an error occurs, the result is not defined.
 */
+ (BOOL)userHasDropboxError_p:(NSError**)error_p ;
/*!
 @brief    Returns whether or not a given path is in the user's
 Dropbox folder
 @param    path  The path in question.  May be nil.
 @result   Whether or not the given path is in the user's Dropbox
 folder.  If no Dropbox folder, or if path is nil, returns NO.
*/
+ (BOOL)pathIsInDropbox:(NSString*)path ;
#endif

@end


/*  Test Code  

 while (YES) {
 BOOL isIdle ;
 NSError* error = nil ;
 BOOL ok = [SSYDropboxGuy waitForIdleDropboxTimeout:(NSTimeInterval)300
 isIdle:&isIdle
 error_p:&error] ;
}
 */