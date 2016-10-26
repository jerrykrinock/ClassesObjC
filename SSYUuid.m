#import "SSYUuid.h"
#import "NSData+Base64.h" 


@implementation SSYUuid

+ (NSData*)uuidData {
	CFUUIDRef cfUUID = CFUUIDCreate(kCFAllocatorDefault) ;
	CFUUIDBytes bytes = CFUUIDGetUUIDBytes(cfUUID) ;
    CFRelease(cfUUID) ;
	NSMutableData* data = [NSMutableData dataWithCapacity:16] ;
	// Why does Apple define this silly 16-member struct?
	// Why don't they just give me the 16 bytes in a buffer
	// I provide, like most normal functions returning bytes?
	[data appendBytes:&(bytes.byte0) length:1] ;
	[data appendBytes:&(bytes.byte1) length:1] ;
	[data appendBytes:&(bytes.byte2) length:1] ;
	[data appendBytes:&(bytes.byte3) length:1] ;
	[data appendBytes:&(bytes.byte4) length:1] ;
	[data appendBytes:&(bytes.byte5) length:1] ;
	[data appendBytes:&(bytes.byte6) length:1] ;
	[data appendBytes:&(bytes.byte7) length:1] ;
	[data appendBytes:&(bytes.byte8) length:1] ;
	[data appendBytes:&(bytes.byte9) length:1] ;
	[data appendBytes:&(bytes.byte10) length:1] ;
	[data appendBytes:&(bytes.byte11) length:1] ;
	[data appendBytes:&(bytes.byte12) length:1] ;
	[data appendBytes:&(bytes.byte13) length:1] ;
	[data appendBytes:&(bytes.byte14) length:1] ;
	[data appendBytes:&(bytes.byte15) length:1] ;

	return [NSData dataWithData:data] ;
}

+ (NSString*)uuid {
	CFUUIDRef cfUUID = CFUUIDCreate(kCFAllocatorDefault) ;
	NSString* uuid = (NSString*)CFUUIDCreateString(kCFAllocatorDefault, cfUUID) ;
	CFRelease(cfUUID) ;
	return [uuid autorelease] ;
}

 + (NSString*)compactUuid {
     CFUUIDRef cfUUID = CFUUIDCreate(kCFAllocatorDefault) ;
     CFUUIDBytes uuidBytes = CFUUIDGetUUIDBytes(cfUUID) ;
     CFRelease(cfUUID) ;
     NSData* data = [NSData dataWithBytes:(const void*)&uuidBytes
                                   length:16] ;
     NSMutableString* s = [NSMutableString stringWithString:[data stringBase64Encoded]] ;
     
     // Remove the padding at the end
     [s replaceOccurrencesOfString:@"="
                        withString:@""
                           options:0
                             range:NSMakeRange(0, [s length])] ;
     
     // Change from standard Base64 to base64url (RFC4648) character set
     [s replaceOccurrencesOfString:@"/"
                        withString:@"-"
                           options:0
                             range:NSMakeRange(0, [s length])] ;
     [s replaceOccurrencesOfString:@"+"
                        withString:@"_"
                           options:0
                             range:NSMakeRange(0, [s length])] ;
     
     return [NSString stringWithString:s] ;
}

@end
