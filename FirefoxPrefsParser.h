#import <Foundation/Foundation.h>

@interface FirefoxPrefsParser : NSObject

/*!
 @details  The prefs.js file apparently contains a deep JavaScript object,
 expressed in JavaScript code, with everything quoted with escaped quotes.  I
 don't know of any parser to handle that, so I wrote my own.  I suppose I could
 have gotten something out of Firefox' open-source code, but would that have
 been any faster??
 */
+ (NSInteger)integerValueFromFirefoxPrefs:(NSString*)prefs
                               identifier:(NSString*)targetIdentifier
                                      key:(NSString*)targetKey ;

@end
