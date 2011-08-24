#import "SSYAppInfo.h"

NSString * const constKeyLastVersion = @"lastVersion" ;

static SSYAppInfo *sharedInfo = nil ;


@implementation SSYAppInfo

+ (SSYAppInfo*)sharedInfo {
	@synchronized(self) {
        if (sharedInfo == nil) {
            sharedInfo = [[self alloc] init] ; 
        }
	}
    return sharedInfo ;
}

+ (enum SSYAppInfoUpgradeState)upgradeStateForCurrentVersionTriplet:(SSYVersionTriplet*)currentVersion
											 previousVersionTriplet:(SSYVersionTriplet*)previousVersion {    
	enum SSYAppInfoUpgradeState upgradeState ;

	if (previousVersion == nil) {
		upgradeState = SSYNewUser ;
	}
	else {
		upgradeState = (enum SSYAppInfoUpgradeState)[previousVersion compare:currentVersion] ;
	}
	
	return upgradeState ;	
}

- (SSYVersionTriplet *)previousVersionTriplet {
    return _previousVersionTriplet ;
}

- (void)setPreviousVersionTriplet:(SSYVersionTriplet *)value {
    if (_previousVersionTriplet != value) {
        [_previousVersionTriplet release];
        _previousVersionTriplet = [value retain];
    }
}

- (SSYVersionTriplet *)currentVersionTriplet {
    return _currentVersionTriplet ;
}

- (void)setCurrentVersionTriplet:(SSYVersionTriplet *)value {
    if (_currentVersionTriplet != value) {
        [_currentVersionTriplet release];
        _currentVersionTriplet = [value retain];
    }
}

- (enum SSYAppInfoUpgradeState)upgradeState {
	return _upgradeState ;
}

- (void)setUpgradeState:(enum SSYAppInfoUpgradeState)upgradeState {
	_upgradeState = upgradeState ;
}

// Keep this method private, vecause it gives the value from User Defaults, which
// will already have been changed to the current version after the SSYAppInfo
// singleton instance has been created, which is probably not what you expect.
// You probably want +previousVersionTriplet instead.
+ (SSYVersionTriplet*)rawPreviousVersionTriplet {
	NSString* string = [[NSUserDefaults standardUserDefaults] stringForKey:constKeyLastVersion] ;
	SSYVersionTriplet* triplet = [SSYVersionTriplet versionTripletFromString:string] ;
	return triplet ;
}

+ (SSYVersionTriplet*)rawCurrentVersionTriplet {
	// Prior BookMacster 1.6.8/1.7.0, we used this:
	// 	SSYVersionTriplet* cvt = [SSYVersionTriplet versionTripletFromBundleIdentifier:[[NSBundle mainBundle] bundleIdentifier]] ;
	// which was bad because it allowed Launch Services to give us the bundle, which
	// may have been from a different app instance if different versions of thisapp
	// are installed on this Mac.  That was pretty stupid, but probably is because
	// originally that method was used to get versions of *other* apps.
	NSString* versionString = [SSYVersionTriplet rawVersionStringFromBundle:[NSBundle mainBundle]] ; 
	SSYVersionTriplet* cvt = [SSYVersionTriplet versionTripletFromString:versionString] ;
	return cvt ;
}


- (id)init {
	self = [super init];
	if (self != nil) {
		SSYVersionTriplet* previousVersionTriplet = [SSYAppInfo rawPreviousVersionTriplet] ;
		[self setPreviousVersionTriplet:previousVersionTriplet] ;
		[self setCurrentVersionTriplet:[SSYAppInfo rawCurrentVersionTriplet]] ;
		_upgradeState = [SSYAppInfo upgradeStateForCurrentVersionTriplet:[self currentVersionTriplet] 
												  previousVersionTriplet:[self previousVersionTriplet]] ;
		if (_upgradeState != SSYCurrentRev) {
			// Get a nice, clean, filtered versionString of the form "major.minor.bugFix" using SSVersionTriplet methods
			SSYVersionTriplet* currentVersionTriplet = [SSYVersionTriplet versionTripletFromBundleIdentifier:[[NSBundle mainBundle] bundleIdentifier]] ;
			NSString* currentVersionString = [currentVersionTriplet string] ;

			// Record currently-launched version into prefs
			// Note that this must be done AFTER the above reading,
			// or else the pref constKeyLastVersion will be written as the previous version!
			NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults] ;
			[userDefaults setObject:currentVersionString
							 forKey:constKeyLastVersion] ;
			[userDefaults synchronize] ;
		}
	}
	return self;
}


+ (BOOL)isNewUser {
	return ([[self sharedInfo] upgradeState] >= SSYNewUser) ;
}

+ (BOOL)didUpgradeSinceLastRun {
	return ([[self sharedInfo] upgradeState] > SSYCurrentRev) ;
}

+ (SSYVersionTriplet*)currentVersionTriplet {
	return [[self sharedInfo] currentVersionTriplet] ;
}

+ (SSYVersionTriplet*)previousVersionTriplet {
	return [[self sharedInfo] previousVersionTriplet] ;
}


@end