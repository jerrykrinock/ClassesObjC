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
			cpuString = [NSString stringWithFormat:@"Unknown architecture: %d", arch] ;
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

@end
