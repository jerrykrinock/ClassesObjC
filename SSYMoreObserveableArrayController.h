#import "SSYMoreObserveableArrayController.h"

@interface SSYMoreObserveableArrayController : NSArrayController

/*!
 @brief    Workaround for Apple Bug ID 7827354, which was closed as a duplicate
 of 3404770, in NSArrayController
 
 @details  Provides two properties for observing content.  However,
 even these don't work if you stick them into +keyPathsForValuesAffecting<Key>.
 You must observe them directly.
 */

@property (readonly) BOOL hasSelection ;
@property (readonly) NSInteger countOfArrangedObjects ;

@end
