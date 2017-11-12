#import "SSYSystemDescriber.h"
#import "SSYVersionTriplet.h"
#import <sys/sysctl.h>

@implementation SSYSystemDescriber

+ (SSYVersionTriplet*)softwareVersionTriplet {
	NSInteger	major ;
	NSInteger	minor ;
	NSInteger	bugFix ;
    if ([NSProcessInfo instancesRespondToSelector:@selector(operatingSystemVersion)]) {
        // macOS 10.10 or later
        NSOperatingSystemVersion version =  [[NSProcessInfo processInfo] operatingSystemVersion] ;
        major = version.majorVersion ;
        minor = version.minorVersion ;
        bugFix = version.patchVersion ;
    }
    else {
        // Sorry, must do it the sleazy way.  Could also use the
        // old Gestalt(), but that gives a deprecation warning when
        // Deployment target is set to 10.8 or later.
        major = minor = bugFix = 0 ;
        NSDictionary* info = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"] ;
        NSString* versionString =  [info objectForKey:@"ProductVersion"] ;
        NSArray* versions = [versionString componentsSeparatedByString:@"."] ;
        NSUInteger count = [versions count] ;
        if (count > 0) {
            major = [[versions objectAtIndex:0] integerValue] ;
            if (count > 1) {
                minor = [[versions objectAtIndex:1] integerValue] ;
                if (count > 2) {
                    bugFix = [[versions objectAtIndex:2] integerValue] ;
                }
            }
        }
    }

	return [SSYVersionTriplet versionTripletWithMajor:major
												minor:minor
											   bugFix:bugFix] ;
}

/* Thanks to erkanyildiz.  See https://stackoverflow.com/questions/8299087/getting-the-machine-type-and-other-hardware-details-through-cocoa-api */
+ (NSString *) hardwareModel {
    size_t len = 0;
    sysctlbyname("hw.model", NULL, &len, NULL, 0);

    NSString* answer;
    if (len > 0) {
        char* model = malloc(len*sizeof(char));
        sysctlbyname("hw.model", model, &len, NULL, 0);
        answer = [NSString stringWithUTF8String:model];
        free(model);
    } else {
        answer = @"Could not get Mac model";
    }

    return answer;
}

+ (NSString*)softwareVersionString {
	return [NSString stringWithFormat:@"macOS version = %@",
			[[self softwareVersionTriplet] string]] ;
}

#define ITERATIONS_ACHIEVED_BY_2009_MAC_MINI_CORE_2_DUO 9500

+ (CGFloat)systemSpeed {
	NSInteger i = 0 ;
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init] ;
	NSTimeInterval endSeconds = [NSDate timeIntervalSinceReferenceDate] + .0049 ;
	NSMutableString* s = [NSMutableString string] ;
	while ([NSDate timeIntervalSinceReferenceDate] < endSeconds) {
		[s appendFormat:@"%ld", (long)i++] ;
	}
	[pool release] ;
	return (CGFloat)i/ITERATIONS_ACHIEVED_BY_2009_MAC_MINI_CORE_2_DUO ;
}
@end
