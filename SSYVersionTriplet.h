#import <Cocoa/Cocoa.h>

#define SSYMakeVersionTriplet(x,y,z) [SSYVersionTriplet versionTripletWithMajor:x minor:y bugFix:z]

enum SSYVersionTripletComparisonResult  {
	SSYDescendingMajor = -4,
	SSYDescendingMinor = -3,
	SSYDescendingBugFix = -2,
	SSYEqual = 0,
	SSYAscendingBugFix = 2,
	SSYAscendingMinor = 3,
	SSYAscendingMajor = 4,
} ;

/*!
 @brief    The struct which underlies the SSYVersionTriplet class

 @field      major The most significant "point digit"
 @field      minor The middle significant "point digit"
 @field      bugFix The least significant "point digit"
 */
struct SSYVersionStruct_struct {
	NSInteger major ;
	NSInteger minor ;
	NSInteger bugFix ;
} ;

/*!
    @typedef    SSYVersionStruct
    @brief    Convenience typedef for 'struct SSYVersionStruct_struct'
*/
typedef struct SSYVersionStruct_struct SSYVersionStruct ;

/*!
 @brief    A triplet of integers, as in major.minor.bugFix,
 describing the version of an application or other project
 @details  Methods for creating, including parsing from bundles,
 and comparing version numbers are provided.
 */
@interface SSYVersionTriplet : NSObject {
	SSYVersionStruct versionStruct_ivar ;
} 

/*!
 @brief    For a given bundle , gets 
 CFBundleShortVersionString if found.  Otherwise, gets CFBundleVersion if found.
 Then reformats the string by using +versionTripletFromString followed
 by - string.
 @result   The value of either CFBundleShortVersionString or CFBundleVersion, or nil
 */
+ (NSString*)rawVersionStringFromBundle:(NSBundle*)bundle ;

/*!
 @brief    For a given bundle identifier on the system, gets 
 CFBundleShortVersionString if found.  Otherwise, gets CFBundleVersion if found.
 Then reformats the string by using +versionTripletFromString followed
 by - string.
 @details  This method is not reliable, particularly if more than one instance
 of the app is installed on the system, because it relies on Launch Services
 to get the path for the given bundle identifier.  If you've got the bundle,
 use +rawVersionStringFromBundle: instead.
 @param    bundleIdentifier The bundle identifier of the target bundle
 @result   The value of either CFBundleShortVersionString or CFBundleVersion, or nil
 */
+ (NSString*)rawVersionStringFromBundleIdentifier:(NSString*)bundleIdentifier ;

/*!
 @brief    Parses a string to get a version number triplet.
 @details  versionString should be something like "some wordOrWords 123.456.78".
 some wordOrWords are optional, but if there are there they must end in a space.
 There must be no periods (dots) in some wordOrWords.
 The minor number and bugFix numbers, and the dots that must go with them are optional.
 If the string is nil or does not contain at least one decimal digit, this method
 returns nil.  If the string contains only one decimal digit 'n', the returned value
 will have major=n, minor=0, bugFix=0.  If the string contains only two decimal digits
 of the form 'm.n, the returned value will have major=m, minor=n, bugFix=0.
 @param    versionString  The string to be parsed
 @result   An autoreleased version triplet, or nil. 
 */
+ (SSYVersionTriplet*)versionTripletFromString:(NSString*)versionString ;

/*!
 @brief    Returns an autoreleased version triplet from a bundle
 @details  Version number string is found as described in 
 rawVersionTripletFromBundleIdentifier: and then version numbers in triplet are parsed
 as described in versionTripletFromString:
 
 @details  This function is not reliable because it relies on -rawVersionStringFromBundleIdentifier
 which is also not reliable.  If you've got the bundle, use +rawVersionStringFromBundle: instead.
 @param    bundleIdentifier The bundle identifier of the target bundle
 @result   An autoreleased version triplet, or nil. 
 */
+ (SSYVersionTriplet*)versionTripletFromBundleIdentifier:(NSString*)bundleIdentifier ;

/*!
    @brief    Gets the major value of the receiver {major,minor,bugFix}
    @result   the value
*/
- (NSInteger)major ;

/*!
 @brief    Gets the minor value of the receiver {major,minor,bugFix}
 @result   the value
 */
- (NSInteger)minor ;

/*!
 @brief    Gets the bugFix value of the receiver {major,minor,bugFix}
 @result   the value
 */
- (NSInteger)bugFix ;

/*!
 @brief    Returns an autoreleased version triplet with value {major,minor,bugFix}
*/
+ (SSYVersionTriplet*)versionTripletWithStruct:(SSYVersionStruct const)versionStruct ;

/*!
 @brief    Returns an autoreleased version triplet with value {major,minor,bugFix}
 */
+ (SSYVersionTriplet*)versionTripletWithMajor:(NSInteger)major
										minor:(NSInteger)minor
									   bugFix:(NSInteger)bugFix ;

/*!
 @brief    Returns an autoreleased version triplet with value {0,0,0}
 */
+ (SSYVersionTriplet*)zeroVersionTriplet ;

/*!
 @brief    Compares receiver to another SSYVersionTriplet
 @param    otherTriplet other triplet to be compared
 @result   Any "ascending" result, > SSYEqual, means that the receiver
 is earlier than otherTriplet.  Any "descending" result, < SSYEqual,
 means that the receiver is later than the otherTriplet.
 */
- (enum SSYVersionTripletComparisonResult)compare:(SSYVersionTriplet*)otherTriplet ;

/*!
 @brief    Calculates whether or not the receiver is earlier than another triplet
 @param    otherTriplet The other triplet
 @result   YES or NO
 */
- (BOOL)isEarlierThan:(SSYVersionTriplet*)otherTriplet ;

/*!
 @brief    Calculates whether or not the receiver is later than another triplet
 @param    otherTriplet The other triplet
 @result   YES or NO
 */
- (BOOL)isLaterThan:(SSYVersionTriplet*)otherTriplet ;

/*!
 @brief    Calculates whether or not the receiver's values equal those of another triplet
 @param    otherTriplet The other triplet
 @result   YES or NO
 */
- (BOOL)isEqual:(id)otherTriplet ;

/*!
 @brief    Returns a string "major.minor.bugFix" using values from the receiver
 @result   The string produced
 */
- (NSString*)string ;

/*!
 @brief    For a given bundle on the system, gets version triplet using
 +versionTripletFromBundleIdentifier.  Then reformats it using -string.
 @param    bundleIdentifier The bundle identifier of the target bundle
 @result   The value of either CFBundleShortVersionString or CFBundleVersion, or nil
 */
+ (NSString*)cleanVersionStringFromBundleIdentifier:(NSString*)bundleIdentifier ;

@end

