#import "SSYDigester.h"

NSString* const msgSSYDigesterContextIsDefunct = @"Context is defunct." ;

@implementation SSYDigester

- (id)initWithAlgorithm:(SSYDigesterAlgorithm)algorithm {
	self = [super init] ;
	if (self) {
		switch (algorithm) {
			case SSYDigesterAlgorithmMd5:
                m_algorithm = SSYDigesterAlgorithmMd5 ;
                CC_MD5_Init(&m_context_md5) ;
				break;
            case SSYDigesterAlgorithmSha1:;
                m_algorithm = SSYDigesterAlgorithmSha1 ;
                CC_SHA1_Init(&m_context_sha1) ;
				break;
		}
	}
	
	return self ;
}

- (void)updateWithData:(NSData*)data {
    switch (m_algorithm) {
        case SSYDigesterAlgorithmMd5:
            CC_MD5_Update(&m_context_md5, [data bytes], (CC_LONG)[data length]) ;
            break ;
        case SSYDigesterAlgorithmSha1:
            CC_SHA1_Update(&m_context_sha1, [data bytes], (CC_LONG)[data length]) ;
            break ;
    }
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
        length = 0 ;
	}

	NSData* data = [NSData dataWithBytes:cString
								  length:length] ;
    [self updateWithData:data] ;
}

- (NSData*)finalizeDigest {
    NSMutableData* hash ;
    switch (m_algorithm) {
        case SSYDigesterAlgorithmMd5:;
            hash = [[NSMutableData alloc] initWithLength:CC_MD5_DIGEST_LENGTH] ;
            CC_MD5_Final([hash mutableBytes], &m_context_md5) ;
            break ;
        case SSYDigesterAlgorithmSha1:;
            hash = [[NSMutableData alloc] initWithLength:CC_SHA1_DIGEST_LENGTH] ;
            CC_SHA1_Final([hash mutableBytes], &m_context_sha1) ;
            break ;
    }
	NSData* answer =  [NSData dataWithData:hash] ;
    [hash release] ;
    return answer ;
}

@end