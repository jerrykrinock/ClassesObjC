#import <Cocoa/Cocoa.h>


@interface SSYIOKit : NSObject

+ (NSData*)primaryMACAddressData;
+ (NSData*)hashedMACAddress;
+ (NSData*)hashedMACAddressAndShortUserName;

//+ (NSData*)machineSerialNumberData ;

@end
