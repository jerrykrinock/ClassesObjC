#import <Cocoa/Cocoa.h>

/*!
 @brief    A transformer to patch over the fact that stupid NSTokenField
 cannot be bound to NSSet but only NSArray.  Used in BookMacster's
 Inspector field to display 'tags'.
*/
@interface SSYTransformSetToArray : NSValueTransformer {
}

@end
