#import <Cocoa/Cocoa.h>


@interface SSYIOKit : NSObject

+ (NSData*)primaryMACAddressOrMachineSerialNumberData;
+ (NSData*)hashedMACAddress;
+ (NSData*)hashedMACAddressAndShortUserName;

//+ (NSData*)machineSerialNumberData ;

@end
