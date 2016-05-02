#import <Foundation/Foundation.h>

/*!
 @brief    Returns whether or not the receiver can be used without raising
 an exception
 
 @details  If the user sets a row in NSPredicateEditor to the "matches"
 predicate type and fills in an invalid regular expression pattern such as this
 one:
   (*(
 the predicate returned by -[NSPredicateRuleEditor objectValue] be an invalid
 and an exception will be raised if such a predicate is passed to, for example,
 -[NSArrayController setFilterPredicate:], an exception will be raised :(
 
 This method preflights such a predicate so you can avoid such an exception. */
@interface NSPredicate (SSYValidate)

- (BOOL)preflightValidate ;

@end
