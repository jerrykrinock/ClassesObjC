#import <Cocoa/Cocoa.h>


@interface SSYUuid : NSObject {

}

/*!
 @brief    Returns a new UUID represented as an NSData object
 of 16 bytes.
*/
+ (NSData*)uuidData ;

/*!
 @brief    Returns a new UUID string of hex digits and dashes.
*/
+ (NSString*)uuid ;

/*!
 @brief    Returns a new UUID string represented as 22 base 64 characters
 (except with "/" replaced by "-").
*/
 + (NSString*)compactUuid ;

@end
