#import "SSYAboutPanelController.h"
#import "NSFancyPanel.h"
#import "NSString+LocalizeSSY.h"

//	Another approach would be to allow changing these through NSUserDefaults
#define SCROLL_AMOUNT_PIXELS	1.00	// amount to scroll in each animation frame
#define SCROLL_DELAY_SECONDS .03


@implementation SSYAboutPanelController

#pragma mark * PRIVATE INSTANCE METHODS

- (void) createPanelToDisplay
{
    //	Programmatically create the new panel
    panelToDisplay = [[NSFancyPanel alloc]
        initWithContentRect: [[panelInNib contentView] frame]
        styleMask: NSWindowStyleMaskBorderless
        backing: [panelInNib backingType]
        defer: NO];

    [panelToDisplay setBecomesKeyOnlyIfNeeded: NO];

    //	We want to know if the window is no longer key/main
    [panelToDisplay setDelegate: self];

    //	Move the guts of the nib-based panel to the programmatically-created one
    {
        NSView		*content;

        content = [[panelInNib contentView] retain];
        [content removeFromSuperview];
        [panelToDisplay setContentView: content];
        [content release];
    }
}

//	Take version information from standard keys in the application’s bundle dictionary
//	and display it.
- (void) displayVersionInfo
{
    NSString	*value;

    value = [[NSProcessInfo processInfo] processName] ;
    if (value != nil)
    {
        [shortInfoField setStringValue: value];
    }

    value = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] ;
    if (value != nil)
    {
        value = [@"Version " stringByAppendingString : value];
        [versionField setStringValue: value];
    }
}

//	Watch for notifications that the application is no longer active, or that
//	another window has replaced the About panel as the main window, and hide
//	on either of these notifications.
- (void) watchForNotificationsWhichShouldHidePanel
{
    //	This works better than just making the panel hide when the app
    //	deactivates (setHidesOnDeactivate:YES), because if we use that
    //	then the panel will return when the app reactivates.
    [[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(hidePanel)
												 name: NSApplicationWillResignActiveNotification
											   object: nil] ;
	
    //	If the panel is no longer main, hide it.
    //	(We could also use the delegate notification for this.)
    [[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(hidePanel)
												 name: NSWindowDidResignMainNotification
											   object: panelToDisplay] ;
}

//	Get and return the text to scroll. This implementation just loads the contents
//	of the “README.rtf” in the main bundle. You might choose a different file, or
//	a completely different implementation.
- (NSAttributedString *) textToScroll
{
    //	Locate the AboutPanel.rtf inside the application’s bundle.
    NSString* path = [[NSBundle mainBundle] pathForResource: @"AboutPanel"
													 ofType: @"rtf"];
	
    //	Suck the contents of the rich text file into a mutable “attributed string”.
	NSMutableAttributedString* theText ;
	if (path) {
		theText = [[NSMutableAttributedString alloc] initWithPath: path
												documentAttributes: NULL] ;
		//	Make up one newline
		NSAttributedString* newline = [[[NSAttributedString alloc] initWithString: @"\n"] autorelease];
		
		//	Append that one newline to the real text enough to fill the window
		NSInteger i ;
		for (i = 0; i < 13; i++)
		{
			[theText appendAttributedString:newline];
		}
	}
	else {
		theText = [[NSMutableAttributedString alloc] initWithString:@"Could not find AboutPanel.rtf\n"] ;
	}

	[theText addAttribute:NSForegroundColorAttributeName
                    value:NSColor.controlTextColor
                    range:NSMakeRange(0, theText.length)];
    return [theText autorelease] ;
}

//	Load the text to scroll into the scrolling text view. The odd thing here is
//	that we load not only the text you'd expect, but also a bunch of blank lines
//	at the end. The blank lines allow the real text to scroll out of sight.
- (void) loadTextToScroll
{
    NSMutableAttributedString	*textToScroll;
    NSInteger							i;

    //	Get whatever text we want to display
    textToScroll = [[self textToScroll] mutableCopy];


	//  The following is my attempt to make a horizontal line, centered.  It compiled but did not work.  Still on left.  ARGHHHHHH   WHY??
	/*
	NSAttributedString	*horizontalLine;
	NSMutableParagraphStyle* psCentered = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[psCentered setAlignment:NSTextAlignmentCenter] ;
	NSDictionary* dicCentered = [NSDictionary dictionaryWithObjectsAndKeys: psCentered, @"NSParagraphStyleAttributeName", nil] ;
    horizontalLine = [[[NSAttributedString alloc] initWithString: @"______________________________\n" attributes:dicCentered] autorelease];
    newline = [[[NSAttributedString alloc] initWithString: @"\n." attributes:dicCentered] autorelease];
	NSLog(@"%@", horizontalLine);
    */

	//	Repeat more times than anyone would care to read it
    for (i = 0; i < 20; i++)
    {
		//[textToScroll appendAttributedString: horizontalLine];
		[textToScroll appendAttributedString: [self textToScroll]];
	}
	
    //	Put the final result into the UI
    [[textView textStorage] setAttributedString: textToScroll];
	[textToScroll release] ;
	// Does not give correct number of lines because it ignores text wrapping:
	// nLines = [[[textToScroll string] componentsSeparatedByString:@"\n"] count] ;
	// NSLog(@"after, nLines = %i", nLines) ;
	// Gives the height of the size in IB, useless
	// This seems to give the height of each line (since default vertialLineScroll = 1 line)
	// NSLog(@"line height = %f", [textScrollView verticalLineScroll]) ;
}

//	Scroll to hide the top 'newAmount' pixels of the text
- (void) setScrollAmount: (CGFloat) newAmount
{
    //	Scroll so that (0, amount) is at the upper left corner of the scroll view
    //	(in other words, so that the top 'newAmount' scan lines of the text
    //	 is hidden).
	[[textScrollView documentView] scrollPoint: NSMakePoint (0.0, newAmount)];
	// NSLog(@"%f", newAmount) ;
    //	If anything overlaps the text we just scrolled, it won’t get redraw by the
    //	scrolling, so force everything in that part of the panel to redraw.
    {
        NSRect scrollViewFrame;

        //	Find where the scrollview’s bounds are, then convert to panel’s coordinates
        scrollViewFrame = [textScrollView bounds];
        scrollViewFrame = [[panelToDisplay contentView] convertRect: scrollViewFrame  fromView: textScrollView];

        //	Redraw everything which overlaps it.
        [[panelToDisplay contentView] setNeedsDisplayInRect: scrollViewFrame];
    }
}

//	If we don't already have a timer, start one messaging us regularly
- (void) startScrollingAnimation
{
   //	Already scrolling?
    if (scrollingTimer != nil)
        return;
	
    //	Start a timer which will send us a 'scrollOneUnit' message regularly
    scrollingTimer = [[NSTimer scheduledTimerWithTimeInterval: SCROLL_DELAY_SECONDS
													   target: self
													 selector: @selector(scrollOneUnit)
													 userInfo: nil
													  repeats: YES] retain];
}

//	Stop the timer and forget about it
- (void) stopScrollingAnimation
{
    [scrollingTimer invalidate];
	
    [scrollingTimer release];
    scrollingTimer = nil;
}

//	Scroll one frame of animation
- (void) scrollOneUnit
{
    CGFloat	currentScrollAmount;

    //	How far have we scrolled so far?
    currentScrollAmount = [textScrollView documentVisibleRect].origin.y;

	/* Alternative method to restart at beginnint when done, not used since instead I wrapped it 20 times
	//  Restart at beginning?
	if (currentScrollAmount > textHeight - 270)
	{
		currentScrollAmount = 0 ;
	
		// Restart scrolling animation to get delay at top
		[self stopScrollingAnimation] ;
		[self performSelector:@selector(startScrollingAnimation) withObject:nil afterDelay:2.0] ;
	}
	*/
	
    //	Scroll one unit more
    [self setScrollAmount: (currentScrollAmount + SCROLL_AMOUNT_PIXELS)];
}



#pragma mark * PUBLIC CLASS METHODS

+ (SSYAboutPanelController*) sharedInstance {
    static SSYAboutPanelController* sharedInstance = nil;
    
    if (sharedInstance == nil) {
        sharedInstance = [[self alloc] initWithWindowNibName:@"SSYAboutPanel"] ;
    }
    
    [sharedInstance showWindow:self] ;
    return sharedInstance ;
}


#pragma mark * PUBLIC INSTANCE METHODS

//	Show the panel, starting the text at the top with the animation going
- (void) showPanel
{
    //	Scroll to the top
    [self setScrollAmount: 0.0];

    [self performSelector:@selector(startScrollingAnimation) withObject:nil afterDelay:2.0];

    //	Make it the key window so it can watch for keystrokes
    [panelToDisplay makeKeyAndOrderFront: nil];
}

//	Stop scrolling and hide the panel. (We stop the scrolling only to avoid
//	wasting the processor, since if we kept scrolling it wouldn’t be visible anyway.)
- (void) hidePanel
{
    [self stopScrollingAnimation];

    [panelToDisplay orderOut: nil];
}

//	This method exists only because this is a developer example.
//	You wouldn’t want it in a real application.
- (void) setShowsScroller: (BOOL) newSetting
{
    [textScrollView setHasVerticalScroller: newSetting];
}


#pragma mark * PUBLIC INSTANCE METHODS -- NSNibAwaking INFORMAL PROTOCOL

- (void) awakeFromNib {
    //	Create 'panelToDisplay', a borderless window, using the guts of the more vanilla 'panelInNib'.
    [self createPanelToDisplay];

    //	Fill in text fields
    [self displayVersionInfo];

    [self loadTextToScroll];

	NSString* iconName = @"NSApplicationIcon" ;
	NSImage* imageIcon = [NSImage imageNamed:iconName] ;
	[iconView setImage:imageIcon] ;
	
	// Button titles
	[buttonClose setTitle:[NSString localize:@"close"]] ;
	[buttonInfo setTitle:[NSString stringWithFormat:
                          @"%@%C",
                          [NSString localize:@"more"],
                          (unsigned short)0x2026]] ; // 0x2026 = ellipsis
	[buttonHelp setTitle:[NSString stringWithFormat:@"%@%C",
                          [NSString localize:@"help"],
                          (unsigned short)0x2026]] ; // 0x2026 = ellipsis
	
    //	Make things look nice
    [panelToDisplay center];

    //	Make lots of other things dismiss the panel
    [self watchForNotificationsWhichShouldHidePanel];
}


#pragma mark * PUBLIC INSTANCE METHODS -- NSFancyPanel DELEGATE

- (BOOL) handlesKeyDown: (NSEvent *) keyDown
    inWindow: (NSWindow *) window
{
    //	We could also close on any key by deleting the
	//  next line
	if ([[keyDown characters] isEqualToString: @"\033"])
		[self hidePanel];
    return YES;
}

- (IBAction)close:(id)sender ;
{
	[self hidePanel] ;
}

/* Important: This will not work until after you have run
 Help Indexer to create a Help Index, and possibly Help Viewer Hammer!
 */
- (IBAction)help:(id)sender ;
{
	[NSApp showHelp:self] ;
}
	
- (IBAction)info:(id)sender ;
{
	[[NSHelpManager sharedHelpManager] openHelpAnchor:SSYAboutPanelHelpAnchorAcknowledgements
											   inBook:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleHelpBookName"]] ;
}


/*
 - (BOOL) handlesMouseDown: (NSEvent *) mouseDown
    inWindow: (NSWindow *) window
{
    //	Close the panel on any click
    [self hidePanel];
    return YES;
}
*/

@end
