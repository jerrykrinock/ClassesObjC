#import <Cocoa/Cocoa.h>

@class SSYVersionTriplet ;


@interface SSYSystemDescriber : NSObject {

}

+ (SSYVersionTriplet*)softwareVersionTriplet ;
+ (NSString*)softwareVersionString ;

/*!
 @result   Returns, for example, "MacBookAir6,2"
 */
+ (NSString*)hardwareModel;

/*!
 @brief    Returns system speed relative to a 2009 Mac Mini with 
 Core 2 Duo processor.

 @details  Takes 5 milliseconds to run.
 @result   Higher numbers are faster.
*/
+ (CGFloat)systemSpeed ;

@end
