#import <AppKit/AppKit.h>

extern NSString* const SSYAboutPanelHelpAnchorAcknowledgements ;

@class ScrollingTextView;

@interface SSYAboutPanelController : NSObject {
    //	This panel exists in the nib file, but the user never sees it, because
    //	we rip out its contents and place them in “panelToDisplay”.
    IBOutlet NSPanel			*panelInNib;

    //	This panel is not in the nib file; we create it programmatically.
    NSPanel						*panelToDisplay;

    //	Scrolling text: the scroll-view and the text-view itself
    IBOutlet NSScrollView		*textScrollView;
    IBOutlet NSTextView			*textView;

    //	Outlet we fill in using information from the application’s bundle
    IBOutlet NSTextField		*versionField;
    IBOutlet NSTextField		*shortInfoField;

	// Buttons
	IBOutlet NSButton			*buttonClose ;
	IBOutlet NSButton			*buttonInfo ;
	IBOutlet NSButton			*buttonHelp ;
    
	//	Timer to fire scrolling animation
    NSTimer						*scrollingTimer;
	
	/*
	 In -awakeFromNib, we look in main bundle resources for an image
	 with same name as CFBundleExecutable (name) and setImage of
	 iconView to it.
	 */
	IBOutlet NSImageView		*iconView ;
}


#pragma mark * PUBLIC CLASS METHODS

+ (SSYAboutPanelController *) sharedInstance;

#pragma mark * PUBLIC INSTANCE METHODS

//	Show the panel, starting the text at the top with the animation going
- (void) showPanel;

//	Stop scrolling and hide the panel.
- (void) hidePanel;

//  Buttons
- (IBAction)close:(id)sender ;
- (IBAction)info:(id)sender ;
- (IBAction)help:(id)sender ;

@end

