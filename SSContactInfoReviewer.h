#import <Cocoa/Cocoa.h>

@interface SSContactInfoReviewer : NSWindowController
{
    IBOutlet NSButton *buttonOK;
	IBOutlet NSButton *buttonCancel;

    IBOutlet NSTextField *labelEmail;
    IBOutlet NSTextField *labelIntro;
    IBOutlet NSTextField *labelName;
    IBOutlet NSTextField *labelAnythingElse;

    IBOutlet NSTextField *textEmail;
    IBOutlet NSTextField *textFirstName;
    IBOutlet NSTextField *textLastName;
    IBOutlet NSTextField *textUneditable;
    IBOutlet NSTextView *textAnythingElse;

	IBOutlet NSWindow *window;
	
	NSString* _displayText ;
	NSArray* _apps ;
	NSArray* _appVersions ;
	NSString* _runningVersion ;
	NSDictionary* _miscellaneousInfo ;
	BOOL sendIt ;
}

// This factory method:
//	initializes a SSContactInfoReviewer,
//  shows user the info in a modal window to allow some changes,
//  retrieves edited info from window and places into NSDictionary* info
//  destroys the SSContactInfoReviewer
//  returns the info

+ (NSDictionary*)infoWithDisplayText:(NSString*)displayText
				 appsToReportVersion:(NSArray*)apps
				   miscellaneousInfo:(NSDictionary*)miscellaneousInfo ;

	// display text is intro text to be shown to user.  Will not be further localized.
	// apps is a list of (string) app names whose version number will be included in info
	// miscellaneousInfo are strings of info to be shown to user and included in info.
	//    keys in miscellaneousInfo will be NSLocalized for showing to user
	//    keys in miscellaneousInfo will be translated accouring to TransmittedKeyForKey for transmitting


@end
