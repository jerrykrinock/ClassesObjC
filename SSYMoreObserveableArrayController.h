#import "SSYMoreObserveableArrayController.h"

@interface SSYMoreObserveableArrayController : NSArrayController

/*!
 @brief    Workaround for Apple Bug ID 7827354, which was closed as a duplicate
 of 3404770, in NSArrayController
 
 @details  Provides a -hasSelection property which actually works.
 */

@property (assign, readonly) BOOL hasSelection ;

@end
