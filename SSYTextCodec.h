#import <Cocoa/Cocoa.h>


@interface SSYTextCodec : NSObject {

}

/*!
 @brief    Attempts to decode data read in from a supposed text
 file into a string, by detecting the encoding.

 @detail  
 @param    fileDataIn  The data in the file
 @param    textStringOut  A pointer, or nil.&nbsp;   On output, if non-nil,
 will point to the decoded string.
 @param    stringEncodingStated  A pointer, or NULL.&nbsp;  On output, 
 if non-NULL, points to the type of string encoding stated in the
 file header.
 @param    stringEncodingStated  A pointer, or NULL.&nbsp;  On output, 
 if non-NULL, points to to the  type of encoding actually used to decode
 the data.
 @param    newLinesFound  A pointer, or nil.&nbsp; On output, if non-nil,
 points to a short string which is the line endings found in the data.
 @param    error_p  A pointer, or nil.&nbsp; If non-nil, on output, if an
 error occurred, points to the relevant NSError.  
 @result   YES if the data could be decoded, otherwise NO.
*/
+ (BOOL)decodeTextData:(NSData*)fileDataIn
	   decodedString_p:(NSString**)decodedString_p
stringEncodingStated_p:(NSStringEncoding*)stringEncodingStated_p
  stringEncodingUsed_p:(NSStringEncoding*)stringEncodingUsed_p
	   newLinesFound_p:(NSString**)newLinesFound_p 
			   error_p:(NSError**)error_p ;

/*!
 @brief    Returns a string expressing the name of the encoding represented
 by an NSStringEncoding constant.
*/
+ (NSString*)humanReadableStringEncoding:(NSStringEncoding)stringEncoding ;

@end
