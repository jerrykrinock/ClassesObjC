#import <Cocoa/Cocoa.h>

@class SSYVersionTriplet ;


@interface SSYSystemDescriber : NSObject {

}

+ (SSYVersionTriplet*)softwareVersionTriplet ;
+ (NSString*)softwareVersionString ;
+ (NSString*)architectureString ;
+ (NSString*)softwareVersionAndArchitecture ;

@end
