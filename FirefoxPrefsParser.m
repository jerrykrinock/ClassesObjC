#import "FirefoxPrefsParser.h"

@implementation FirefoxPrefsParser

+ (NSString*)stringFromStart:(NSInteger)startIndex
                     scanner:(NSScanner*)scanner {
    NSRange range = NSMakeRange(startIndex, scanner.scanLocation - startIndex - 1) ;
    // The -1 is to remove the delimiter at the end.
    NSString* string = [scanner.string substringWithRange:range] ;
    /* At this point, key may be enclosed in escaped
     doublequotes, for example: \"Foobar\" */
    return string ;
}

+ (NSString*)stringByTrimmingString:(NSString*)string {
    if ([string hasPrefix:@"\\\""]) {
        string = [string substringFromIndex:2] ;
    }
    if ([string hasSuffix:@"\\\""]) {
        string = [string substringToIndex:(string.length - 2)] ;
    }

    return string ;
}

+ (NSInteger)answerFromStart:(NSInteger)start
                     scanner:(NSScanner*)scanner {
    NSString* value = [self stringFromStart:start
                                    scanner:scanner] ;
    value = [self stringByTrimmingString:value] ;
    return [value integerValue] ;
}

+ (NSInteger)integerValueFromFirefoxPrefs:(NSString*)prefs
                               identifier:(NSString*)targetIdentifier
                                      key:(NSString*)targetKey {
    BOOL ok = YES ;
    NSInteger answer = 0 ;
    NSScanner* scanner = [[NSScanner alloc] initWithString:prefs] ;
    NSCharacterSet* delimiters = [NSCharacterSet characterSetWithCharactersInString:@":,{}\""] ;
    NSInteger bracketLevel = 0 ;
    BOOL inQuotes = NO ;

    if (ok) {
        [scanner scanUpToString:@"user_pref(\"extensions.xpiState\","
                     intoString:NULL] ;
        ok = (!scanner.isAtEnd) ;
    }

    if (ok) {
        [scanner scanUpToString:@"\\\"app-profile\\\":"
                     intoString:NULL] ;
        ok = (!scanner.isAtEnd) ;
    }

    if (ok) {
        [scanner scanUpToString:@"{"
                     intoString:NULL] ;
        ok = (!scanner.isAtEnd) ;
    }

    if (ok) {
        // Scan past the "{" which opens the set of app-profile values
        scanner.scanLocation = scanner.scanLocation + 1 ;

        bracketLevel = 1 ;
        NSInteger itemIdentifierStart = scanner.scanLocation ;
        NSInteger keyStart = 0 ;  // defensive initialization
        NSInteger valueStart = 0 ;  // defensive initialization
        NSInteger scannerState = 0 ;
        /* scannerState values:
         0 = scanning for identifier
         1 = scanning for key
         2 = scanning for value
         */
        BOOL inTargetObject = NO ;
        BOOL targetValueIsNext = NO ;
        NSString* itemIdentifier = nil ;
        NSString* key = nil ;
        while (bracketLevel > 0) {
            NSString* scannedChars = nil ;
            [scanner scanUpToCharactersFromSet:delimiters
                                    intoString:NULL] ;
            if ([scanner isAtEnd]) {
                break ;
            }
            [scanner scanCharactersFromSet:delimiters
                                intoString:&scannedChars] ;

            unichar scannedChar = [scannedChars characterAtIndex:0] ;

            NSInteger charactersScannedGreaterThan1 = [scannedChars length] - 1 ;
            if (charactersScannedGreaterThan1 > 0) {
                scanner.scanLocation = scanner.scanLocation - charactersScannedGreaterThan1 ;
            }

            if (!inQuotes && scannedChar == '{') {
                bracketLevel++ ;
                scannerState = 1 ;
                keyStart = scanner.scanLocation ;
            }
            else if (!inQuotes && scannedChar == '}') {
                bracketLevel-- ;
                if ((scannerState == 2) && (bracketLevel == 1)) {
                    if (inTargetObject) {
                        /* We are popping out of the target object and,
                         apparently, did not find the target key.  Even though
                         we failed, there is no sense in going any further.  */
                        break ;
                    }

                    if (targetValueIsNext) {
                        // Success, done! (1 of 2 possibilities)
                        answer = [self answerFromStart:valueStart
                                               scanner:scanner] ;
                        break ;
                    }
                    scannerState = 0 ;
                    itemIdentifierStart = scanner.scanLocation ;
                }
            }
            else if (!inQuotes && scannedChar == ',') {
                if (scannerState == 0) {
                    itemIdentifierStart = [scanner scanLocation] ;
                    /* Typically this adds 1 to itemIdentifierStart. This is
                     so that itemIdentifier will not have the comma prepended
                     to it. */
                }
                else if (scannerState == 2) {
                    if (targetValueIsNext) {
                        // Success, done! (2 of 2 possibilities)
                        answer = [self answerFromStart:valueStart
                                               scanner:scanner] ;
                        break ;
                    }
                    scannerState = 1 ;
                    keyStart = scanner.scanLocation ;
                }
            }
            else if (!inQuotes && scannedChar == ':') {
                if (scannerState == 0) {
                    itemIdentifier = [self stringFromStart:itemIdentifierStart
                                                   scanner:scanner] ;
                    itemIdentifier = [self stringByTrimmingString:itemIdentifier] ;
                    if ([itemIdentifier isEqualToString:targetIdentifier]) {
                        inTargetObject = YES ;
                    }
                    scannerState = 1 ;
                }
                else if (scannerState == 1) {
                    key = [self stringFromStart:keyStart
                                        scanner:scanner] ;
                    key = [self stringByTrimmingString:key] ;
                    if (inTargetObject) {
                        if ([key isEqualToString:targetKey]) {
                            targetValueIsNext = YES ;
                        }
                    }
                    scannerState = 2 ;
                    valueStart = [scanner scanLocation] ;
                }
            }
            else if (scannedChar == '"') {
                inQuotes = !inQuotes ;
            }
        }
    }

#if !__has_feature(objc_arc)
    [scanner release] ;
#endif
    
    return answer ;
}

@end
