#import <Cocoa/Cocoa.h>


@interface SSYLinearFileWriter : NSObject {
	NSFileHandle* m_fileHandle ;
}


/*!
 @brief    Closes the file of any existing singleton, and 
 creates a new one set to write to a given path

 @details  Creates parent directory path if necessary, deleting any regular
 file which may exist at the parent directory path
*/
+ (void)setToPath:(NSString*)path ;

/*!
 @brief    Writes a given line of text to the singleton's file
 handle
 
 @details  The line is encoded to UTF8 and a unix line feed is appended.
 
 If no path has been set for the file handle, logs an internal error.
 */
+ (void)writeLine:(NSString*)line ;

/*!
 @brief    Closes the file of any existing singleton.
*/
+ (void)close ;



@end
