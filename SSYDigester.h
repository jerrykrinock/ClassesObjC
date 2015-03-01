#import <Cocoa/Cocoa.h>
#include <openssl/evp.h>

enum SSYDigesterAlgorithm_enum {
	SSYDigesterAlgorithmMd5,
	SSYDigesterAlgorithmSha1
} ;
typedef enum SSYDigesterAlgorithm_enum SSYDigesterAlgorithm ;

/*!
 @brief    A class for computing message digests incrementally.

 @details  
*/
@interface SSYDigester : NSObject {
	EVP_MD_CTX m_context ;
}

/*!
 @brief    Initializes a new message digest with a given
 algorithm type.
*/
- (id)initWithAlgorithm:(SSYDigesterAlgorithm)algorithm ;

/*!
 @brief    Incrementally updates the message digest to
 account for additional given data.
*/
- (void)updateWithData:(NSData*)data ;

/*!
 @brief    Incrementally updates the message digest to
 account for an additional given string which is first
 converted to a C string with a given encoding.
 
 @details  The NULL terminator on the C string *is*
 included in the additional data.
 
 @param    encoding  The string encoding to be used to
 convert the given string to data.  Must be one of the
 following:
 *  NSUTF8StringEncoding
 *  NSASCIIStringEncoding 
 *  NSUnicodeStringEncoding
 *  NSUTF16StringEncoding
 *  NSUTF16BigEndianStringEncoding
 *  NSUTF16LittleEndianStringEncoding
 */
- (void)updateWithString:(NSString*)string
				encoding:(NSStringEncoding)encoding ;

/*!
 @brief    Returns the final message digest.

 @details  After sending this message to the receiver,
 you should release/deallocate it.  Sending a
 further message to the receiver afer sending -finalize
 for the first time will result in an assertion being
 raised.
*/
- (NSData*)finalizeDigest ;

@end

void TestSSYDigester() {
    SSYDigester* digester = [[SSYDigester alloc] init] ;
    
}
