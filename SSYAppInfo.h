#import <Cocoa/Cocoa.h>
#import "SSYVersionTriplet.h"

extern NSString* const constKeyLastVersion ;

/*!
 @enum       SSYAppInfoUpgradeState
 @brief    Used to quantify the comparison between the currently-running
 version of the current app versus the version that was run during the
 prior launch of this app.

 @details  So that these constants may be conveniently typecast
 with enum SSYVersionNumbersComparisonResult, constants that have
 similar meanings between these two enumerations have the same value.
 */
enum SSYAppInfoUpgradeState  {
	// Similar to SSYVersionNumbersComparisonResult:
	SSYDowngradeMajor = -4,
	SSYDowngradeMinor = -3,
	SSYDowngradeBugFix = -2,
	SSYDowngrade = -1,  // unspecified if bugFix, minor or major
	SSYCurrentRev = 0,
	SSYUpgrade = 1,  // unspecified if bugFix, minor or major
	SSYUpgradeBugFix = 2,
	SSYUpgradeMinor = 3,
	SSYUpgradeMajor = 4,
	
	// Additional constants:
	SSYNewUser = 15,
	SSYNotDefined = NSNotFound
} ;


/*!
 @brief    Right now, gives info on app version and app version run during
 previous launch.  I'm not sure where I'm going with this class right now.  Might
 add other "features" later.

 @details
 Regarding version strings, this class uses what I call "SSYSimpleVersioningSystem" instead
 of Apple Generic Versioning.  In SSYSimpleVersioningSystem, CFBundleVersion contains two-dot
 string of three integers, major.minor.bugfix.  So, for example in the About box your
 application will appear as "MyApp 1.2.3 (1.2.3)"  I use this because I have two issues with
 Apple Generic Versioning
    (1) It is too confusing to have separate marketing and engineering
           versions.  Why confuse customers reporting bugs etc. with two numbers?
           Is Engineering trying to hide things from Marketing, which is trying
           to hide things from users?  I say, let's all use the same numbers!
    (2) Don't like agvtool.  Why does Chris Hanson instruct you to quit Xcode before 
           invoking it?  The man page does not say that.  Why could they have not built
		   agvtool into Xcode?  Also, man agvtool says that you get two global variables,
           one of them unnamed, the other CURRENT_PROJECT_VERSION, but this is not found
           when I try to either compile or link (extern) to it.  I give up on it.
*/
@interface SSYAppInfo : NSObject {
	SSYVersionTriplet* _previousVersionTriplet ;
	SSYVersionTriplet* _currentVersionTriplet ;
	enum SSYAppInfoUpgradeState _upgradeState ;
}

/*!
 @brief    Returns whether or not user has used ^this^ application

 @details  ultra-convenience method, actually invokes the shared singleton
*/
+ (BOOL)isNewUser ;

/*!
 @brief    Returns whether or not app's version has been upgraded since last run

 @details  ultra-convenience method, actually invokes the shared singleton
*/
+ (BOOL)didUpgradeSinceLastRun ;

+ (SSYVersionTriplet*)currentVersionTriplet ;

+ (SSYVersionTriplet*)previousVersionTriplet ;

/*
 @brief    Sets the current upgrade state in the receiver's shared instance,
 and updates the constKeyLastVersion in the user defaults to the current
 version found in the app's main bundle.
 
 @details  This method must be invoked before you invoke any other methods
 in this class, such as early in -applicaitonDidFinishLaunching, or else
 other methods will give wrong answers.
 
 The current upgrade state is calculated by comparing the
 last-run version found in standard user defaults' constKeyLastVersion
 with the current version found in the main bundle, and remembers it.
 
 The reason for setting the current upgrade state (it's an instance variable)
 is that, after the user defaults' constKeyLastVersion has been updated to the
 current version, it can no longer be calculated.
 */
+ (void)calculateUpgradeState ;

@end

