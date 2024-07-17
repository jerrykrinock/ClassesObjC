#import "SSYSystemUptimer.h"
@import SSYSwift;

NSString* const SSYSystemUptimerErrorDomain = @"SSYSystemUptimerErrorDomain";
NSInteger const SSYSystemUptimerSystemCommandFailedErrorCode = 214751;
NSInteger const SSYSystemUptimerCouldNotParseSystemResponse = 214752;

@implementation SSYSystemUptimer

+ (NSDate*)lastWakeFromSleepError_p:(NSError**)error_p {
    NSDate* answer = nil;
    NSError* error = nil;

    /* I tested using "/usr/bin/pmset -g log", but that seemed to generate
     much more stdout than this:  */
    NSString* command = @"/usr/sbin/sysctl";
    NSArray* args = [NSArray arrayWithObjects:
                     @"-a",
                     nil];
    NSData* stdoutData = nil;
    NSDictionary* programResults = [SSYTask run:[NSURL fileURLWithPath:command]
                                      arguments:args
                                    inDirectory:nil
                                       stdinput:nil
                                        timeout:0.0];
    NSInteger exitStatus = [[programResults objectForKey:SSYTask.exitStatusKey] integerValue];
    NSError* underlyingError = [programResults objectForKey:SSYTask.errorKey];
    if (exitStatus != EXIT_SUCCESS) {
        error = [NSError errorWithDomain:SSYSystemUptimerErrorDomain
                                    code:SSYSystemUptimerSystemCommandFailedErrorCode
                                userInfo:@{
                                           NSLocalizedDescriptionKey: NSLocalizedString(@"System command failed", nil),
                                           @"Command": command,
                                           @"Arguments": args,
                                           @"Result": [NSNumber numberWithInteger:exitStatus]
                                           }];
        if (underlyingError) {
            error = [error errorByAddingUnderlyingError:underlyingError];
        }
    } else {
        NSString* stdoutString = [[NSString alloc] initWithData:stdoutData
                                                       encoding:NSUTF8StringEncoding] ;
        NSArray* lines = [stdoutString componentsSeparatedByString:@"\n"];
        for (NSString* line in lines) {
            if ([line rangeOfString:@"waketime"].location != NSNotFound) {
                NSScanner* scanner = [[NSScanner alloc] initWithString:line];
                [scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet]
                                        intoString:NULL];
                NSString* timeString = nil;
                [scanner scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet]
                                    intoString:&timeString];
                [scanner release];
                NSTimeInterval timeSeconds = [timeString integerValue];
                answer = [NSDate dateWithTimeIntervalSince1970:timeSeconds];
                break;
            }
        }

        if (!answer) {
            error = [NSError errorWithDomain:SSYSystemUptimerErrorDomain
                                        code:SSYSystemUptimerCouldNotParseSystemResponse
                                    userInfo:@{
                                               NSLocalizedDescriptionKey: NSLocalizedString(@"Could not parse system response", nil)
                                               }];
        }

        [stdoutString release];
    }

    if (error && error_p) {
        *error_p = error ;
    }

    return answer;
}

@end
