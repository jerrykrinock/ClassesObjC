#import <Cocoa/Cocoa.h>

extern NSString* const SSYDropboxGuyErrorDomain ;

__attribute__((visibility("default"))) @interface SSYDropboxGuy : NSObject

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

+ (NSString*)defaultDropboxPath ;

+ (BOOL)dropboxIsAvailable ;

/*!
 @brief    Returns whether or not a given path is in the user's Dropbox folder
 
 @details  Operates by looking for the presence of a .dropbox.cache folder in
 any of the path's ancestors.  Probably 99% reliable, until Dropbox changes
 their design.
 
 @result   If the path is in Dropbox, returns NSOnState.  If the path is not in
 Dropbox, returns NSOffState.  If the answer cannot be determined because of an
 error, returns NSMixedState.
 */
+ (NSInteger)isInDropboxPath:(NSString*)path ;

/*!
 @brief    Returns whether or not a given path is probably in the user's
 Dropbox "cache", which is its "Trash".
 
 @details  A folder gets in the Dropbox "Trash" if it is trashed on another
 computer, or replaced on another computer.
 
 This method detects whether or not any of the given path's ancester
 folders are ".dropbox.cache".  Therefore, it can return a false positive if
 some user creates such a folder of their own accord and puts stuff in it.
 
 If path is nil, returns NO.
 */
+ (NSInteger)isInDropboxTrashPath:(NSString*)path ;


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


