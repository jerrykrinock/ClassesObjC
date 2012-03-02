#import "SSYVersionTriplet.h"

@implementation SSYVersionTriplet

+ (NSString*)rawVersionStringFromBundle:(NSBundle*)bundle {
	NSString* versionNumberString = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ;

	// Shiira does not have a CFBundleShortVersionString, but it has CFBundleVersion
	if (versionNumberString == nil) {
		versionNumberString = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"] ;
	}
	
	return versionNumberString;
}

+ (NSString*)rawVersionStringFromBundleIdentifier:(NSString*)bundleIdentifier {
	NSString* bundlePath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:bundleIdentifier] ;
	// Note: The above is more reliable than -fullPathForApplication,
	// but still not reliable enough.  The problem is that its behavior
	// when more than one version of an app is installed is not defined.
	// BookMacster Beta Tester says that the behavior matches that of
	// LSFindApplicationForInfo, which, according to documentation, is
	// the proper way to locate bundles.  Moreover, the bundle methods are
	// governed by some preference rules:
	//    http://developer.apple.com/mac/library/documentation/Carbon/Conceptual/LaunchServicesConcepts/LSCConcepts/LSCConcepts.html#//apple_ref/doc/uid/TP30000999-CH202-BABBJJEF
	// According to the above, bundles in the main disk are preferred, and,
	// I am so sorry that I forgot to mention that, I am using FileVault, so
	// the bundle in my '~/Applications' is not preferred even if it is a
	// later version, due to 'late mounted' (another mount) effect of FileVault.
	// Nevertheless, I noticed that the Adobe bundled Opera is located inside
	// 'Device Central.app' and probably it got registered by the application or
	// its installer with LSRegisterFSRef, so I rebuilt the Launch Services database
	// using lsregister (/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister)
	// with the option -r, so not to recurse in packages, and
	// now the test detection system and the BookMacster application work perfectly.
	// Concluding, there are problems with
	//  (a) App installed in FileVault
	//  (b) App installed in ~/Applications
	
	NSBundle* bundle = [NSBundle bundleWithPath:bundlePath] ;
	
	NSString* versionNumberString = [self rawVersionStringFromBundle:bundle] ;


	return versionNumberString ;
}

+ (SSYVersionTriplet*)versionTripletFromString:(NSString*)versionString {
	SSYVersionTriplet* versionTriplet = nil ;
	
	BOOL hasADecimalDigit = [versionString rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location != NSNotFound ;
	
	if ((versionString != nil)  && hasADecimalDigit) {		
		NSArray* parts = [versionString componentsSeparatedByString:@"."] ;
		
		int major = 0 ;
		int minor = 0 ;
		int bugFix = 0 ;
		
		NSInteger nParts = [parts count] ;
		NSArray* majorWords = [[parts objectAtIndex:0] componentsSeparatedByString:@" "] ;
		major = [[majorWords lastObject] intValue] ;
		
		if (nParts>1)
		{
			minor = [[parts objectAtIndex:1] intValue] ;
			
			if (nParts>2)
				bugFix = [[parts objectAtIndex:2] intValue] ;
		}
		
		versionTriplet = [SSYVersionTriplet versionTripletWithMajor:major
															  minor:minor
															 bugFix:bugFix] ;		
	}
	
	return versionTriplet ;
}

+ (SSYVersionTriplet*)versionTripletFromBundleIdentifier:(NSString*)bundleIdentifier {
	NSString* versionString = [self rawVersionStringFromBundleIdentifier:bundleIdentifier] ;
	return [self versionTripletFromString:versionString] ;
}

- (void)setMajor:(int)value {
	versionStruct_ivar.major = value ;
}

- (void)setMinor:(int)value {
	versionStruct_ivar.minor = value ;
}

- (void)setBugFix:(int)value {
	versionStruct_ivar.bugFix = value ;
}

- (int)major {
	return versionStruct_ivar.major ;
}

- (int)minor {
	return versionStruct_ivar.minor ;
}

- (int)bugFix {
	return versionStruct_ivar.bugFix ;
}

- (id)initWithStruct:(SSYVersionStruct const)versionStruct {
	self = [super init] ;
	if (self != nil) {
		versionStruct_ivar = versionStruct ;
	}
	
	return self ;
}

+ (SSYVersionTriplet*)versionTripletWithStruct:(SSYVersionStruct const)versionStruct {
	SSYVersionTriplet* instance = [[SSYVersionTriplet alloc] initWithStruct:versionStruct] ;
	return [instance autorelease] ;
	
}

+ (SSYVersionTriplet*)versionTripletWithMajor:(int)major
										minor:(int)minor
									   bugFix:(int)bugFix {
	SSYVersionStruct versionStruct ;
	versionStruct.major = major ;
	versionStruct.minor = minor ;
	versionStruct.bugFix = bugFix ;
	
	SSYVersionTriplet* instance = [[SSYVersionTriplet alloc] initWithStruct:versionStruct] ;
	return [instance autorelease] ;
}

+ (SSYVersionTriplet*)zeroVersionTriplet {
	return [self versionTripletWithMajor:0 minor:0 bugFix:0] ;
}

- (enum SSYVersionTripletComparisonResult)compare:(SSYVersionTriplet*)otherTriplet {
	enum SSYVersionTripletComparisonResult result ;
	
	if (versionStruct_ivar.major == [otherTriplet major]) {
		// Majors are equal, could be a minor or a bug fix
		if (versionStruct_ivar.minor == [otherTriplet minor]) {
			// Major and minor are equal, could be a bug fix
			if (versionStruct_ivar.bugFix > [otherTriplet bugFix]) {
				result = SSYDescendingBugFix ;
			}
			else if (versionStruct_ivar.bugFix < [otherTriplet bugFix]) {
				result = SSYAscendingBugFix ;
			}
			else {
				result = SSYEqual ;
			}
		}
		else {
			// Majors are equal but minors are not
			if (versionStruct_ivar.minor < [otherTriplet minor]) {
				result = SSYAscendingMinor ;
			}
			else {
				result = SSYDescendingMinor ;
			}
		}
	}
	else {
		// Majors are unequal
		if (versionStruct_ivar.major < [otherTriplet major]) {
			result = SSYAscendingMajor ;
		}
		else {
			result = SSYDescendingMajor ;
		}
	}
	
	return result ;
}

- (BOOL)isEarlierThan:(SSYVersionTriplet*)otherTriplet {
	return ([self compare:otherTriplet] > SSYEqual) ;
}
	
- (BOOL)isLaterThan:(SSYVersionTriplet*)otherTriplet {
	return ([self compare:otherTriplet] < SSYEqual) ;
}

- (BOOL)isEqual:(id)otherTriplet {
	return ([self compare:otherTriplet] == SSYEqual) ;
}

// Documentation says to override -hash if you override -isEqual:
- (NSUInteger)hash {
	return [[self string] hash] ;
}

- (NSString*)string {
	return [NSString stringWithFormat:@"%d.%d.%d",
			[self major],
			[self minor],
			[self bugFix]] ;
}

- (NSString*)description {
	return [self string] ;
}

+ (NSString*)cleanVersionStringFromBundleIdentifier:(NSString*)bundleIdentifier {
	SSYVersionTriplet* vt = [self versionTripletFromBundleIdentifier:bundleIdentifier] ;
	return [vt string] ;
}

@end