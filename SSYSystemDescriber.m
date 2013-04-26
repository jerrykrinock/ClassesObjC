#import "SSYSystemDescriber.h"
#import "SSYVersionTriplet.h"

@implementation SSYSystemDescriber

+ (SSYVersionTriplet*)softwareVersionTriplet {
	SInt32	major ;
	SInt32	minor ;
	SInt32	bugFix ;
	Gestalt(gestaltSystemVersionMajor, &major) ;
	Gestalt(gestaltSystemVersionMinor, &minor) ;
	Gestalt(gestaltSystemVersionBugFix, &bugFix) ;
	return [SSYVersionTriplet versionTripletWithMajor:major
												minor:minor
											   bugFix:bugFix] ;
}

+ (NSString*)softwareVersionString {
	return [NSString stringWithFormat:@"Mac OS X version = %@",
			[[self softwareVersionTriplet] string]] ;
}

+ (NSString*)architectureString {
	SInt32 arch ;
	Gestalt(gestaltSysArchitecture, &arch) ;
	NSString* cpuString ;
	switch (arch) {
		case 1:
			cpuString = @"68K" ;
			break;
		case 2:
			cpuString = @"PowerPC" ;
			break;
		case 10:
			cpuString = @"Intel" ;
			break;
		default:
			cpuString = [NSString stringWithFormat:@"Unknown architecture: %ld", (long)arch] ;
			break;
	}
	return [NSString stringWithFormat:@"Architecture: %@",
			cpuString] ;
}

+ (NSString*)softwareVersionAndArchitecture {
	return [NSString stringWithFormat:@"%@\n%@",
			[self softwareVersionString],
			[self architectureString]] ;
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
