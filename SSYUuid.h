#import <Cocoa/Cocoa.h>


@interface SSYUuid : NSObject {

}

/*!
 @brief    Returns a new UUID represented as an NSData object
 of 16 bytes.
*/
+ (NSData*)uuidData ;

/*!
 @brief    Returns a new UUID string of uppercase hex digits and dashes,
 for example: "EB66EB83-3B04-42F8-B1E0-E542ACA2655C"
*/
+ (NSString*)uuid ;

/*!
 @brief    Returns a new UUID string represented as 22 base64url characters,
 
 @details  Note that base64url, defined in RFC 4648, differs from conventional
 Base64 in that uses '-' and '_' instead of '/' and '+' as the 63rd and 64th
 characters.  This is because these are more "URL friendly"…
 *  https://tools.ietf.org/html/rfc4648#section-5
 
 This character set has also been adopted by Mozilla for bookmark GUID in
 Firefox:
 *  https://bugzilla.mozilla.org/show_bug.cgi?id=607115  (Comment 2010-11-22 11:19:21 PST)

 Prior to Novemeber 2016, this method used '-' and '+' as the 63rd and 64th
 characters.
*/
 + (NSString*)compactUuid ;

@end
