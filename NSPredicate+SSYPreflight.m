#import "NSPredicate+SSYPreflight.h"

@implementation NSPredicate (SSYValidate)

- (BOOL)preflightValidate {
    BOOL answer = YES ;
    if ([self isKindOfClass:[NSComparisonPredicate class]]) {
        if ([(NSComparisonPredicate*)self predicateOperatorType] == NSMatchesPredicateOperatorType) {
            NSExpression* expression = [(NSComparisonPredicate*)self rightExpression] ;
            if ([expression expressionType] == NSConstantValueExpressionType) {
                id constantValue = [expression constantValue] ;
                if ([constantValue isKindOfClass:[NSString class]]) {
                    NSError* error = nil ;
                    NSRegularExpression* regex = [[NSRegularExpression alloc] initWithPattern:constantValue
                                                                                      options:0
                                                                                        error:&error] ;
                    /* The error returned does not usually give much
                     additional information.  Here is an example:
                     Error Domain=NSCocoaErrorDomain Code=2048 "The value “(*(” is invalid." UserInfo={NSInvalidValue=(*(}
                     So, we don't bother passing it up. */
                    if (!regex || (error != nil)) {
                        answer = NO ;
                    }
                    [regex release] ;
                }
            }
        }
    }
    else if ([self respondsToSelector:@selector(subpredicates)]) {
        for (NSPredicate* predicate in [(NSCompoundPredicate*)self subpredicates]) {
            if (![predicate preflightValidate]) {
                answer = NO ;
                break ;
            }
        }
    }
    else {
        /*SSYDBL*/ NSLog(@"Whoooops: %@", [self className]) ;
        /* Could be something like NSTruePredicate */
    }
    
    return answer ;
}

@end
