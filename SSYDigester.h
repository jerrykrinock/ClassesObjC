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

#if 0
+ (void)testSSYDigester {
    SSYDigester* digester ;
    NSData* data ;
    NSData* expected ;
    
    digester = [[SSYDigester alloc] initWithAlgorithm:SSYDigesterAlgorithmMd5] ;
    data = [@"Foo One" dataUsingEncoding:NSUTF8StringEncoding] ;
    [digester updateWithData:data] ;
    [digester updateWithString:@"Foo Two"
                      encoding:NSUTF8StringEncoding] ;
    data = [@"Foo Three" dataUsingEncoding:NSUTF8StringEncoding] ;
    [digester updateWithData:data] ;
    [digester updateWithString:@"Foo Four!!"
                      encoding:NSUTF8StringEncoding] ;
    data = [digester finalizeDigest] ;
    NSLog(@" md5 result = %@", data) ;
    [digester release] ;
    
    char bytes[20] ;
    bytes[0] = 0x0c ;
    bytes[1] = 0xab ;
    bytes[2] = 0x25 ;
    bytes[3] = 0x8a ;
    bytes[4] = 0xbb ;
    bytes[5] = 0xc7 ;
    bytes[6] = 0x16 ;
    bytes[7] = 0xdf ;
    bytes[8] = 0x72 ;
    bytes[9] = 0x5e ;
    bytes[10] = 0x83 ;
    bytes[11] = 0xd9 ;
    bytes[12] = 0x53 ;
    bytes[13] = 0xa8 ;
    bytes[14] = 0xaf ;
    bytes[15] = 0x21 ;
    expected = [[NSData alloc] initWithBytes:bytes
                                      length:16] ;
    NSLog(@" md5 expect = %@", expected) ;
    NSLog(@"md5 test %@", [data isEqual:expected] ? @"passed" : @"failed") ;
    
    digester = [[SSYDigester alloc] initWithAlgorithm:SSYDigesterAlgorithmSha1] ;
    data = [@"Foo One" dataUsingEncoding:NSUTF8StringEncoding] ;
    [digester updateWithData:data] ;
    [digester updateWithString:@"Foo Two"
                      encoding:NSUTF8StringEncoding] ;
    data = [@"Foo Three" dataUsingEncoding:NSUTF8StringEncoding] ;
    [digester updateWithData:data] ;
    [digester updateWithString:@"Foo Four!!"
                      encoding:NSUTF8StringEncoding] ;
    data = [digester finalizeDigest] ;
    NSLog(@"sha1 result = %@", data) ;
    [digester release] ;
    
    bytes[0] = 0x97 ;
    bytes[1] = 0x59 ;
    bytes[2] = 0xf0 ;
    bytes[3] = 0xd1 ;
    bytes[4] = 0xc0 ;
    bytes[5] = 0x71 ;
    bytes[6] = 0xb2 ;
    bytes[7] = 0x30 ;
    bytes[8] = 0xdd ;
    bytes[9] = 0x98 ;
    bytes[10] = 0x2c ;
    bytes[11] = 0x0a ;
    bytes[12] = 0x27 ;
    bytes[13] = 0xb3 ;
    bytes[14] = 0xff ;
    bytes[15] = 0x16 ;
    bytes[16] = 0x10 ;
    bytes[17] = 0x4a ;
    bytes[18] = 0xe9 ;
    bytes[19] = 0x33 ;
    expected = [[NSData alloc] initWithBytes:bytes
                                      length:20] ;
    NSLog(@"sha1 expect = %@", expected) ;
    NSLog(@"sha1 test %@", [data isEqual:expected] ? @"passed" : @"failed") ;
    
}

#endif