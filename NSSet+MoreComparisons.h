#import <Cocoa/Cocoa.h>


@interface NSSet (MoreComparisons)

/*!
 @brief    Compares two set values for equality
 
 @details  Use this instead of -isEqualToSet:
 if it is possible that both sets are nil, because,
 unlike -isEqualToSet:, it will give the correct answer
 of YES.
 @param    set1  One of two sets to be compared.  May be nil.
 @param    set2  One of two sets to be compared.  May be nil.
 @result   If neither argument is nil, the value returned by sending
 -isEqualToSet: to either of them.  If one argument is nil and the other
 is not nil, NO.  If both arguments are nil, YES.
 Otherwise, NO
 */
+ (BOOL)isEqualHandlesNilSet1:(NSSet*)set1
						 set2:(NSSet*)set2 ;

@end
