#import "SSYDigester.h"
#include <openssl/err.h>

NSString* const msgSSYDigesterContextIsDefunct = @"Context is defunct." ;

@implementation SSYDigester

- (id)initWithAlgorithm:(SSYDigesterAlgorithm)algorithm {
	self = [super init] ;
	if (self) {
		switch (algorithm) {
			case SSYDigesterAlgorithmMd5:
				EVP_DigestInit(&m_context, EVP_md5()) ;
				break;
			case SSYDigesterAlgorithmSha1:
				EVP_DigestInit(&m_context, EVP_sha1()) ;
				break;
		}
	}
	
	return self ;
}

- (void)updateWithData:(NSData*)data {
	EVP_DigestUpdate(&m_context, [data bytes], [data length]) ;
}


- (void)updateWithString:(NSString*)string
				encoding:(NSStringEncoding)encoding {
	if (!string) {
		return ;
	}
	
	NSInteger length ;
	const char* cString = [string cStringUsingEncoding:encoding] ;
	if (
		(encoding == NSASCIIStringEncoding) ||
		(encoding == NSUTF8StringEncoding)
		) {
		if (cString) {
			length = (strlen(cString)) ;
		}
		else {
			length = 0 ;
		}
	}
	else if (
			 (encoding == NSUnicodeStringEncoding) || // aka NSUTF16StringEncoding
			 (encoding == NSUTF16BigEndianStringEncoding) ||
			 (encoding == NSUTF16LittleEndianStringEncoding) 
			 ) {
		length = 2 * ([string length]) ;
	}
	else {
		NSLog(@"Internal Error 214-4190") ;
	}

	NSData* data = [NSData dataWithBytes:cString
								  length:length] ;
	EVP_DigestUpdate(&m_context, [data bytes], [data length]) ;	
}

- (NSData*)finalizeDigest {
	int unsigned length ;
	unsigned char value[EVP_MAX_MD_SIZE] ;

	EVP_DigestFinal(&m_context, value, &length) ;
	EVP_MD_CTX_cleanup(&m_context) ;
	return [NSData dataWithBytes:value
						  length:length];
}

@end