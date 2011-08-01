#import "SSContactInfoReviewer.h"
#import <AddressBook/ABAddressBook.h>
#import <AddressBook/ABMultiValue.h>
#import "SSApp/SSUtils.h"
#import "SSApp/SSUtilityCategories.h"
#import "SSYLocalize/NSString+Localize.h"

extern NSString* gCFBundleVersion ;

NSString* TransmittedKeyForKey(NSString* key) {
	NSString* txKey ;
	
	if ([key isEqualToString:@"failed"]) {
		txKey = @"ProblemWith" ;
	}
	else {
		txKey = [key capitalizedString] ;
	}
	
	return txKey ;
}

@implementation SSContactInfoReviewer

SSAOm( NSString*, displayText, setDisplayText) 
SSAOm( NSDictionary*, miscellaneousInfo, setMiscellaneousInfo)
SSAOm( NSArray*, apps, setApps)
SSAOm( NSArray*, appVersions, setAppVersions)
SSAOm( NSString*, runningVersion, setRunningVersion)

- (id)initWithDisplayText:(NSString*)displayText
  appsToReportVersion:(NSArray*)apps
	miscellaneousInfo:(NSDictionary*)miscellaneousInfo {
	SSLog(5, "Prolog SSContactInfoReviewer init") ;
	self = [super initWithWindowNibName:@"SSContactInfoWindow"];
	
	if (self != 0)  // Make sure it worked!
	{
		[self setDisplayText:displayText] ;
		[self setApps:apps] ;
		[self setMiscellaneousInfo:miscellaneousInfo] ;
	}
	
	SSLog(5, "Epilog SSContactInfoReviewer init") ;
	return self;
}

- (void)dealloc {
	[self setDisplayText:nil] ;
	[self setApps:nil] ;
	[self setAppVersions:nil] ;
	[self setRunningVersion:nil] ;
	[self setMiscellaneousInfo:nil] ;
	
	[super dealloc] ;
}

- (void)awakeFromNib
{
	SSLog(5, "Prolog SSContactInfoReviewer awakeFromNib") ;
	ABPerson* me = [[ABAddressBook sharedAddressBook] me] ;
	
	ABMultiValue *emails = [me valueForProperty:kABEmailProperty]; 
	NSString* email = [emails valueAtIndex:[emails indexForIdentifier:[emails primaryIdentifier]]];
	
	NSString* firstName = [me valueForProperty:kABFirstNameProperty]; 
	NSString* lastName = [me valueForProperty:kABLastNameProperty];
	
	if (!firstName)
		firstName = @"" ;
	if (!lastName)
		lastName = @"" ;
	if (!email)
		email = @"" ;
	
	/* More info (tested but not used)
	ABMultiValue *addresses = [me valueForProperty:kABAddressProperty] ;
	NSDictionary* address = [addresses valueAtIndex:[addresses indexForIdentifier:[addresses primaryIdentifier]]];
	
	NSString* street = [address objectForKey:kABAddressStreetKey] ;
	NSString* city = [address objectForKey:kABAddressCityKey] ;
	NSString* state = [address objectForKey:kABAddressStateKey] ;
	NSString* zip = [address objectForKey:kABAddressZIPKey] ;
	NSString* country = [address objectForKey:kABAddressCountryKey] ;
	NSString* countryCode = [address objectForKey:kABAddressCountryCodeKey] ;
	
	ABMultiValue *phones = [me valueForProperty:kABPhoneProperty] ;
	NSString* phone = [phones valueAtIndex:[phones indexForIdentifier:[phones primaryIdentifier]]] ;
	*/
	
	[[self window] setTitle:[NSString localize:@"report"]] ;
	
	[buttonOK setTitle:[NSString localize:@"ok"]] ;
	[buttonCancel setTitle:[NSString localize:@"cancel"]] ;
	
	[labelIntro setStringValue:[self displayText]] ;
	[labelEmail setStringValue:[NSString localize:@"email"]] ;
	[labelName setStringValue:[[NSString localize:@"name"] capitalizedString]] ;
	[labelAnythingElse setStringValue:[NSString localize:@"anythingElse"]] ;
	
	[textEmail setStringValue:email] ;
	[textFirstName setStringValue:firstName] ;
	[textLastName setStringValue:lastName] ;
	
	// Fill contents of textUneditable
	NSMutableString* uneditableText = [[NSMutableString alloc] init] ;
	NSString* aLineOfText ;
	// 1.  Get Running Version (also, set ivar runningVersion)
	NSBundle* mainBundle = [NSBundle mainBundle] ;
	NSString* runningVersion = [NSString stringWithFormat:@"%@ %@ (%@)",
								[mainBundle objectForInfoDictionaryKey:@"CFBundleName"], // CFBundleName may be localized
								[mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
								[mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"]] ;
	[uneditableText appendFormat:@"Running: %@\n", runningVersion] ;
	[self setRunningVersion:runningVersion] ;
	// 2.  Installed app versions (also, set ivar appVersions)
	NSMutableArray* appVersions = [[NSMutableArray alloc] init] ;
	NSEnumerator* e = [[self apps] objectEnumerator] ;
	NSString* app ;
	while ((app = [e nextObject])) {
		NSString* appVersion = SSVersionStringForAppNamed(app) ;
		NSString* lineItem = [NSString localizeFormat:@"version%0%1",
							  app,
							  appVersion] ;
		[uneditableText appendString:lineItem] ;
		[appVersions addObject:appVersion] ;
		[uneditableText appendString:@"\n"] ;
	}
	[self setAppVersions:appVersions] ;
	[appVersions release] ;
	// 3.  add appKit version
	aLineOfText = [NSString localizeFormat:@"version%0%1",
														@"@f",
														@"Cocoa AppKit",
														[NSString stringWithFormat:@"%f", NSAppKitVersionNumber]] ;
	[uneditableText appendString:aLineOfText] ;
	[uneditableText appendString:@"\n"] ;
	// 4.  add date
	aLineOfText = [[NSString alloc] initWithFormat:@"%@: %@\n",
		[NSString localize:@"date"],
		[NSDate date] ] ;
	[uneditableText appendString:aLineOfText] ;
	[aLineOfText release] ;
	// 5.  add language
	aLineOfText = [[NSString alloc] initWithFormat:@"%@: %@\n",
		[NSString localize:@"languageCode"],
		[NSString languageCodeLoaded]] ;
	[uneditableText appendString:aLineOfText] ;
	[aLineOfText release] ;
	// 6.  add miscellaneous info
	[uneditableText appendString:[[self miscellaneousInfo] formatAsList]] ;
	// 7.  set to UI and clean up
	[textUneditable setStringValue:uneditableText] ;
	[uneditableText release] ;

	[textAnythingElse setFont:[NSFont systemFontOfSize:12.0]] ;
	// above uses the setFont: method of NSText, of which NSTextView is a subclass
	SSLog(5, "Epilog SSContactInfoReviewer awakeFromNib") ;
}	

- (NSDictionary*)info
{
	SSLog(5, "Prolog SSContactInfoReviewer info") ;
	[NSApp runModalForWindow:[self window]] ;
	// The above causes this thread to block.
	
	// User corrects the fields in the windows
	// and pushes a button which sets the value of sendIt
	
	// Now, send the corrected info if user wanted it send
	NSMutableDictionary* info ;
	if (sendIt)
	{
		// Build the info dictionary
		NSDictionary* someItems ;
		
		// 1.  Start with the values from the editable fields in the window
		info = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
			[textLastName stringValue], SSSafeString(@"LastName"),
			[textFirstName stringValue],SSSafeString(@"FirstName"),
			[textEmail stringValue], SSSafeString(@"Email"),
			[[textAnythingElse textStorage] string], @"AnythingElse",
			nil] ;

		// 2.  Add the miscellaneousInfo
		NSArray* miscellaneousKeys = [[self miscellaneousInfo] allKeys] ;
		NSArray* miscellaneousValues = [[self miscellaneousInfo] allValues] ;
		// Translate keys to transmittedKeys
		NSEnumerator * e = [miscellaneousKeys objectEnumerator] ;
		NSMutableArray* miscellaneousTransmittedKeys = [[NSMutableArray alloc] init] ;
		NSString* key ;
		while ((key = [e nextObject])) {
			[miscellaneousTransmittedKeys addObject:TransmittedKeyForKey(key)] ;
		}
		someItems =
			[[NSDictionary alloc] initWithObjects:miscellaneousValues
										  forKeys:miscellaneousTransmittedKeys] ;
		[miscellaneousTransmittedKeys release] ;
		[info addEntriesFromDictionary:someItems] ;
		[someItems release] ;
		
		// 3.  Add the language code and AppKitVersion
		someItems = [[NSDictionary alloc] initWithObjectsAndKeys:
			[NSString languageCodeLoaded], @"Language",
			[NSString stringWithFormat:@"%f", NSAppKitVersionNumber], @"AppKit",
			nil] ;
		[info addEntriesFromDictionary:someItems] ;
		[someItems release] ;
		
		// 4.  Add the app versions
		someItems = [[NSDictionary alloc] initWithObjects:[self appVersions] forKeys:[self apps]] ;
		[info addEntriesFromDictionary:someItems] ;
		[someItems release] ;
		
		// 5.  Add the Running Version
		[info setObject:[self runningVersion]
				 forKey:@"RunningVersion"] ;
	}
	else
		info = nil ;
	
	NSDictionary* output = [info copy] ;
	[info release] ;
	
	SSLog(5, "Epilog SSContactInfoReviewer info returning:\n%@", output) ;
	return [output autorelease] ;
}

- (IBAction)ok:(id)sender
{	
	sendIt = YES ;
	[NSApp stopModal] ;
	[[self window] close] ;
}

- (IBAction)cancel:(id)sender
{
	sendIt = NO ;
	[NSApp stopModal] ;
	[[self window] close] ;
}

+ (NSDictionary*)infoWithDisplayText:(NSString*)displayText
				 appsToReportVersion:(NSArray*)apps
				   miscellaneousInfo:(NSDictionary*)miscellaneousInfo {
	SSContactInfoReviewer* instance = [[SSContactInfoReviewer alloc]
		initWithDisplayText:displayText
		appsToReportVersion:(NSArray*)apps
		  miscellaneousInfo:(NSDictionary*)miscellaneousInfo ] ;
	
	
	// Do search
	NSDictionary* info = [instance info] ;
	[instance release] ;
	
	return info ;
}

@end
