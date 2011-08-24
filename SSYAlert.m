#import "SSYAlert.h"

#import "SSYAppLSUI.h"
#import "SSYMailto.h"
#import "SSYSheetManager.h"
#import "SSYSystemDescriber.h"
#import "SSYWrappingCheckbox.h"

#import "NSError+SSYAdds.h"
#import "NSInvocation+Quick.h"
#import "NSString+Clipboard.h"
#import "NSString+LocalizeSSY.h"
#import "NSString+Truncate.h"
#import "NSView+Layout.h"
#import "NSWindow+Sizing.h"

NSObject <SSYAlertErrorHideManager> * gSSYAlertErrorHideManager = nil ;
static SSYAlert *sharedAlert = nil ;

NSString* const SSYAlertDidRecoverInvocationKey = @"SSYAlertDidRecoverInvocationKey" ;
NSString* const SSYAlert_ErrorSupportEmailKey = @"SSYAlert_ErrorSupportEmail" ;
NSString* const SSYAlertDidProcessErrorNotification = @"SSYAlertDidProcessErrorNotification" ;

#pragma mark > How to Add a Feature
/* 
 Most new features will require an instance variable.
 Use the following checklist when adding a feature:
 - In .h, add an instance variable.
 - In .h, or in .m SSYAlert Class Extension, add ivar declaration.
 - In .m, add a @synthesize or getter/setter implementation.
 - In .m, if an object, -[SSYAlert dealloc], release it.
 - In .m, -[SSYAlert cleanSlate], set to a default value.
 - In .m, -[SSAlert display], read the ivar value and affect the content accordingly.
 */


@interface NSView (StringsInSubviews)


- (NSInteger)longestStringLengthInAnySubview ;

@end

@implementation NSView (StringsInSubviews)

- (NSInteger)stringLengthInAnySubviewLongerThan:(NSInteger)length {
	SEL selector ;
	selector = @selector(string) ;
	if ([self respondsToSelector:selector]) {
		length = MAX(length, [[self performSelector:selector] length]) ;

	}
	selector = @selector(stringValue) ;
	if ([self respondsToSelector:selector]) {
		// Because NSImageView has a -stringValue describing each of its sizes...
		if (![self isKindOfClass:[NSImageView class]]) {
			length = MAX(length, [[self performSelector:selector] length]) ;
		}
	}
	
	// Recursion into documentView, if any
	selector = @selector(documentView) ;
	if ([self respondsToSelector:selector]) {
		length = [[self performSelector:selector] stringLengthInAnySubviewLongerThan:length] ;
	}
	
	// Recursion into subviews, if any:
	for (NSView* subview in [self subviews]) {
		length = [subview stringLengthInAnySubviewLongerThan:length] ;
	}
	
	return length ;
}

- (NSInteger)longestStringLengthInAnySubview {
	return [self stringLengthInAnySubviewLongerThan:0] ;
}


@end



@interface NSArray (SimpleDeepCopy) 

- (id <NSCoding>)simpleDeepCopy ;

@end

@implementation NSArray (SimpleDeepCopy)

- (id <NSCoding>)simpleDeepCopy {
	NSData* archive ;
	id copy ;
	@try {
		if (![self respondsToSelector:@selector(encodeWithCoder:)]) {
			NSException* ex = [NSException exceptionWithName:@"Can't copy"
													  reason:@"Can't archive"
													userInfo:nil];
			[ex raise] ;
		}
		archive = [NSKeyedArchiver archivedDataWithRootObject:self] ;		
		copy = [NSKeyedUnarchiver unarchiveObjectWithData:archive] ;
	}
	@catch (NSException* ex) {
		NSLog(@"Error: %@: Exception: %@.  Returning self since could not archive/copy %@", NSStringFromSelector(_cmd), ex, self) ;
		copy = self ;
	}
	@finally { }
	
	return [copy retain] ;
}

@end


@interface NSTextView (SSYAlertUsage)

- (void)configureForSSYAlertUsage ;

@end

@implementation NSTextView (SSYAlertUsage)

- (void)configureForSSYAlertUsage {
	[self setEditable:NO] ;
	[self setDrawsBackground:NO] ;
	[self setSelectable:NO] ;

	// The next two lines are very important.  Took me many months to learn that,
	// by default, NSTextViews will resize themselves automatically to accomodate
	// a changed text size, and what's even more confusing is that they do so
	// when you (or a superview) invoke -setNeedsDisplay: or -display on them.
	// When used in SSYAlert, SSYAlert wants to set their size manually, in its
	// -display method.  In particular, if SSYAlert's ivar allowsShrinking is set
	// to NO, in fact we want them to maintain their height when automatic resizing
	// would tell them to shrink.
	[self setVerticallyResizable:NO] ;
	[self setHorizontallyResizable:NO] ;
}

@end


@interface SSYAlertWindow : NSWindow

@end

@implementation SSYAlertWindow


#pragma mark * 

// At one time, I thought that NSWindow's keyboard loop was
// broken in a programmatically-created window.
/* - (void)sendEvent:(NSEvent *)event {
	int tab = 0 ;
	if ([event type] == NSKeyDown) {
		unichar character = [[event characters] characterAtIndex:0] ;
		if (character == 9) {
			tab = 1 ;
		}
		else if (character == 25) {
			tab = -1 ;
		}
	}
	
	if (YES) {///if (!tab) {
		[super sendEvent:event] ;
	}
	else {
		NSView* firstResponder = (NSView*)[self firstResponder] ;
		if (![[[self contentView] subviews] containsObject:firstResponder]) {
			// Aha! Must be a sneaky field editor!!
			// In this case, we replace it with the delegate of the
			// field editor, which is the "actual" field (i.e., NSTextField)
			// being edited by the field editor
			if ([firstResponder respondsToSelector:@selector(delegate)]) {
				// The above if() is just for safety; it should always
				// be true as far as far as I can imagine, but my
				// imagination is limited.
				firstResponder = [(NSTextView*)firstResponder delegate] ;
			}
		}
		// Now, we want the next responder in the chain.  However, the
		// "actual" object being edited may not itself be in the responder
		// chain, because it may be a subview of a higher level view
		// (for example, SSYLabelledTextField) which is in the chain.
		// In this case, its -nextKeyView and -previousKeyView
		// will be nil.  If it is, we recursively try its superview.		
		NSView* nextResponder = nil ;
		while (!nextResponder && firstResponder) {
			nextResponder = (tab > 0)
				? [firstResponder nextKeyView] 
				: [firstResponder previousKeyView] ;
			firstResponder = [firstResponder superview] ;
		}
		
		[self makeFirstResponder:nextResponder] ;
	}
}
 */

@end

@interface NSView (KeyboardLooping)

- (void)makeNextKeyViewOfWindow:(NSWindow*)window
				 firstResponder:(NSView**)hdlFirstResponder
			  previousResponder:(NSView**)hdlPreviousResponder ;

@end

@implementation NSView (KeyboardLooping)

- (void)makeNextKeyViewOfWindow:(NSWindow*)window
				 firstResponder:(NSView**)hdlFirstResponder
			  previousResponder:(NSView**)hdlPreviousResponder {
	if (!*hdlFirstResponder) {
		if ([window makeFirstResponder:self]) { 
			[window setInitialFirstResponder:self] ; 
			*hdlFirstResponder = self ;
			*hdlPreviousResponder = self ;
		}
	}
	else {
		[*hdlPreviousResponder setNextKeyView:self] ;
		*hdlPreviousResponder = self ;
	}
}

@end


@interface NSButton (SSYAlertStuff) 

- (void)sizeToFitIncludingNiceMargins ;
// Stupid -sizeToFit does not look good for NSButtons, so I add more margin

@end

@implementation NSButton (SSYAlertStuff)

- (void)sizeToFitIncludingNiceMargins {
	[self sizeToFit] ;
	[self deltaX:0.0
		  deltaW:6.0] ;
}

@end

#pragma mark * Class Extension of SSYAlert

@interface SSYAlert ()

@property (retain) NSImageView* icon ;
@property (retain) NSProgressIndicator* progressBar ; // readonly in public @interface
@property (retain) NSTextView* titleTextView ; // readonly in public @interface
@property (retain) NSTextView* smallTextView ; // readonly in public @interface
@property (retain) NSButton* helpButton ;
@property (retain) NSButton* supportButton ;
@property (retain) SSYWrappingCheckbox* checkbox ;
@property (retain) NSButton* button1 ;
@property (retain) NSButton* button2 ;
@property (retain) NSButton* button3 ;
@property (copy) NSString* helpAnchorString ;
@property (retain) NSError* errorPresenting ;
@property (retain) NSImageView* iconInformational ;
@property (retain) NSImageView* iconCritical ;
@property (retain) NSButton* buttonPrototype ;
@property (copy) NSString* wordAlert ;
// @property (copy) NSString* whyDisabled ; // in public @interface
// @property (assign) isEnabled ; // in public @interface
@property (assign) BOOL isRetainedForSheet ;
@property (assign) BOOL isVisible ;
@property (assign) NSInteger nDone ;
@property (assign) NSInteger alertReturn ; // readonly in public @interface
// @property (assign) float rightColumnMinimumWidth ; // in public @interface
// @property (assign) float rightColumnMaximumWidth ; // in public @interface
// @property (assign) BOOL allowsShrinking ; // in public @interface
// @property (assign) NSInteger titleMaxChars ; // in public @interface
// @property (assign) NSInteger smallTextMaxChars ; // in public @interface
// @property (assign) BOOL progressBarShouldAnimate ; // in public @interface
@property (assign) BOOL isDoingModalDialog ;
@property (assign) NSModalSession modalSession ;
@property (assign) NSPoint windowTopCenter ;
@property (assign) BOOL doNotDisplayNextPop ;
@property (assign) NSTimeInterval nextProgressUpdate ;
// @property (retain, readonly) NSMutableArray* otherSubviews ; // in public @interface

@end


@implementation SSYAlert : NSWindowController


+ (NSString*)supportEmailString {
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:SSYAlert_ErrorSupportEmailKey] ;
}

- (id)clickObject {
    return [[clickObject retain] autorelease];
}

- (void)setClickObject:(id)value {
    if (clickObject != value) {
        [clickObject release];
        clickObject = [value retain];
    }
}

#pragma mark * Accessors

@synthesize icon ;
@synthesize progressBar ;
@synthesize titleTextView ;
@synthesize smallTextView ;
@synthesize helpButton ;
@synthesize supportButton ;
@synthesize checkbox ;
@synthesize button1 ;
@synthesize button2 ;
@synthesize button3 ;
@synthesize helpAnchorString ;
@synthesize errorPresenting ;
@synthesize iconInformational ;
@synthesize iconCritical ;
@synthesize buttonPrototype ;
@synthesize wordAlert ;
@synthesize documentWindow ;

@synthesize isRetainedForSheet ;
@synthesize isVisible ;
@synthesize nDone ;
@synthesize rightColumnMinimumWidth = m_rightColumnMinimumWidth ; 
@synthesize allowsShrinking ;
@synthesize titleMaxChars ;
@synthesize smallTextMaxChars ;
@synthesize clickTarget ;
@synthesize clickSelector ;
@synthesize clickObject ;
@synthesize checkboxInvocation = m_checkboxInvocation ;
@synthesize isDoingModalDialog ;
@synthesize modalSession ;
@synthesize windowTopCenter ;
@synthesize progressBarShouldAnimate ;
@synthesize doNotDisplayNextPop ;
@synthesize nextProgressUpdate ;

- (float)rightColumnMaximumWidth {
	float rightColumnMaximumWidth ;
	@synchronized(self) {
		rightColumnMaximumWidth = m_rightColumnMaximumWidth ; ;
	}
	return rightColumnMaximumWidth ;
}

- (void)setRightColumnMaximumWidth:(CGFloat)width {
	@synchronized(self) {
		m_rightColumnMaximumWidth = width ;
	}

    [[self checkbox] setMaxWidth:width] ;
	
	for (NSView* view in [self otherSubviews]) {
		if ([view respondsToSelector:@selector(setMaxWidth:)]) {
			// Sleazy, lying typecast to avoid compiler warning
			[(SSYWrappingCheckbox*)view setMaxWidth:width] ;
		}
	}
}

- (void)setRightColumnWidth:(CGFloat)width {
	[self setRightColumnMinimumWidth:width] ;
	[self setRightColumnMaximumWidth:width] ;
}

@synthesize alertReturn = m_alertReturn ;


- (BOOL)isEnabled {
	BOOL isEnabled ;
	@synchronized(self) {
		isEnabled = m_isEnabled ; ;
	}
	return isEnabled ;
}

- (void)setIsEnabled:(BOOL)isEnabled {
	[[self button1] setEnabled:isEnabled] ;
	[[self button1] display] ;
	@synchronized(self) {
		m_isEnabled = isEnabled ;
	}
}

- (NSString*)whyDisabled {
	NSString* whyDisabled ;
	@synchronized(self) {
		whyDisabled = [[m_whyDisabled copy] autorelease] ; ;
	}
	return whyDisabled ;
}

- (void)setWhyDisabled:(NSString*)whyDisabled {
	[[self button1] setToolTip:whyDisabled] ;

	@synchronized(self) {
		if (whyDisabled != m_whyDisabled) {
			[m_whyDisabled release] ;
			m_whyDisabled = [whyDisabled copy] ;
		}
	}
}

- (NSMutableArray *)otherSubviews {
    if (!otherSubviews) {
        otherSubviews = [[NSMutableArray alloc] init];
    }
    return [[otherSubviews retain] autorelease];
}

#pragma mark * Class Methods returning Constants

+ (NSFont*)titleTextFont {
	return [NSFont boldSystemFontOfSize:13] ;
}

+ (NSFont*)smallTextFont {
	return [NSFont systemFontOfSize:12] ;
}

+ (float)titleTextHeight {
	return 17 ;
}

+ (float)smallTextHeight {
	return 14 ;
}

+ (NSString*)contactSupportToolTip {
	return [NSString stringWithFormat:@"%@ | %@",
			[NSString localize:@"supportContact"],
			[[NSString localize:@"email"] capitalizedString]] ;
}

+ (NSButton*)newButton {
	NSButton* button = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 49, 49)] ;
	[button setFont:[NSFont systemFontOfSize:13]] ;
	[button setBezelStyle:NSRoundedBezelStyle] ;
	return [button autorelease] ;
}


#pragma mark * Private Methods

/*!
 @brief    Translates from the 'recovery option' as expressed in our -doLayoutError:
 method to the 'recovery option index' expressed in Cocoa's error presentation method,
 -presentError:.

 @details  Cocoa's arrangement allows an unlimited number of error recovery options,
 indexed from 0.  Our -doLayoutError: method only allows three options, which are
 indexed like the buttons in NSAlert.  In particular, note that the values 
 represented by 0 and 1 are reversed.
*/
+ (NSUInteger)recoveryOptionIndexForRecoveryOption:(NSInteger)recoveryOption {
	NSUInteger recoveryOptionIndex ;
	switch (recoveryOption) {
		case NSAlertDefaultReturn /* 1 */ :
			recoveryOptionIndex = 0 ;
			break;
		case NSAlertAlternateReturn /* 0 */ :
			recoveryOptionIndex = 1 ;
			break;
		case NSAlertOtherReturn /* -1 */ :
			recoveryOptionIndex = 2 ;
			break;
		default:
			// This should never happen since we only have 3 buttons and return
			// one of the above three values like NSAlert.
			NSLog(@"Warning 520-3840 %d", recoveryOption) ;
			recoveryOptionIndex = recoveryOption ;
			break;
	}
	
	return recoveryOptionIndex ;
}

+ (NSInteger)tryRecoveryAttempterForError:(NSError*)error
						   recoveryOption:(NSUInteger)recoveryOption
							  contextInfo:(NSMutableDictionary*)infoDictionary {
	NSUInteger result = SSYAlertRecoveryNotAttempted ;
	NSError* docOpeningError = nil ;
	
	NSError* deepestRecoverableError = [error deepestRecoverableError] ;
	id recoveryAttempter = [deepestRecoverableError openRecoveryAttempterForRecoveryOption:recoveryOption
																				   error_p:&docOpeningError] ;
	if (recoveryAttempter) {
		// Try the sheet method, attemptRecoveryFromError::::: first, since, in my
		// opinion, it gives a better user experience.  If the recoveryAttempter
		// does not respond to that, try the window method, attemptRecoveryFromError::
		if ([recoveryAttempter respondsToSelector:@selector(attemptRecoveryFromError:recoveryOption:delegate:didRecoverSelector:contextInfo:)]) {
			NSInvocation* invocation = [error didRecoverInvocation] ;
			id delegate = [invocation target] ;
			SEL didRecoverSelector = [invocation selector] ;
			// I put the whole invocation into the context info, believing it to be alot cleaner.
			if (invocation) {
				// Before we invoke the didRecoverInvocation, we also put it into the
				// current infoDictionary in case an error occurs again and we need
				// to re-recover.
				[infoDictionary setObject:invocation
								   forKey:SSYAlertDidRecoverInvocationKey] ;
			}
			[recoveryAttempter attemptRecoveryFromError:[[deepestRecoverableError retain] autorelease]
										 recoveryOption:recoveryOption
											   delegate:delegate   
									 didRecoverSelector:didRecoverSelector
											contextInfo:[[infoDictionary retain] autorelease]] ;
			// Also, the retain] autorelease] is probably not necessary since I'm invoking attemptRecoveryFromError:::::
			// directly, but I'm always fearful of crashes due to invalid contextInfo.
			result = SSYAlertRecoveryAttemptedAsynchronously ;
		}
		else if ([recoveryAttempter respondsToSelector:@selector(attemptRecoveryFromError:optionIndex:delegate:didRecoverSelector:contextInfo:)]) {
			/* This is an error produced by Cocoa.
			 In particular, in Mac OS X 10.7, it might be one like this:
			 Error Domain = NSCocoaErrorDomain
			 Code = 67000
			 UserInfo = {
			 •   NSLocalizedRecoverySuggestion=Click Save Anyway to keep your changes and save the
			 changes made by the other application as a version, or click Revert to keep the changes from the other
			 application and save your changes as a version.
			 •   NSLocalizedFailureReason=The file has been changed by another application.
			 •   NSLocalizedDescription=This document’s file has been changed by another application.
			 •   NSLocalizedRecoveryOptions = ("Save Anyway", "Revert")
			 }
			*/
			NSInvocation* invocation = [error didRecoverInvocation] ;
			id delegate = [invocation target] ;
			SEL didRecoverSelector = [invocation selector] ;
			// I put the whole invocation into the context info, believing it to be alot cleaner.
			if (invocation) {
				// Before we invoke the didRecoverInvocation, we also put it into the
				// current infoDictionary in case an error occurs again and we need
				// to re-recover.
				[infoDictionary setObject:invocation
								   forKey:SSYAlertDidRecoverInvocationKey] ;
			}
			NSInteger recoveryOptionIndex = [self recoveryOptionIndexForRecoveryOption:recoveryOption] ;
			
			[recoveryAttempter attemptRecoveryFromError:[[deepestRecoverableError retain] autorelease]
											optionIndex:recoveryOptionIndex
											   delegate:delegate   
									 didRecoverSelector:didRecoverSelector
											contextInfo:[[infoDictionary retain] autorelease]] ;
			// Also, the retain] autorelease] is probably not necessary since I'm invoking attemptRecoveryFromError:::::
			// directly, but I'm always fearful of crashes due to invalid contextInfo.
			result = SSYAlertRecoveryAttemptedAsynchronously ;
		}
		else if ([recoveryAttempter respondsToSelector:@selector(attemptRecoveryFromError:recoveryOption:)]) {
			BOOL ok = [recoveryAttempter attemptRecoveryFromError:deepestRecoverableError
												   recoveryOption:recoveryOption] ;
			
			result = ok ? SSYAlertRecoverySucceeded : SSYAlertRecoveryFailed ;
		}
		else if ([recoveryAttempter respondsToSelector:@selector(attemptRecoveryFromError:optionIndex:)]) {
			// This is an error produced by Cocoa.
			NSInteger recoveryOptionIndex = [self recoveryOptionIndexForRecoveryOption:recoveryOption] ;
			BOOL ok = [recoveryAttempter attemptRecoveryFromError:deepestRecoverableError
													  optionIndex:recoveryOptionIndex] ;
			
			result = ok ? SSYAlertRecoverySucceeded : SSYAlertRecoveryFailed ;
		}
		else {
			NSLog(@"Internal Error 342-5587.  Given Recovery Attempter %@ does not respond to either attemptRecoveryFromError:... method", recoveryAttempter) ;
		}
	}
	else if (docOpeningError) {
		[self alertError:docOpeningError] ;
	}
	
	return result ;
}

- (IBAction)help:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:[self helpAnchorString]
											   inBook:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleHelpBookName"]] ;
}

- (IBAction)support:(id)sender {
	[SSYAlert supportError:[self errorPresenting]] ;
}

+ (void)supportError:(NSError*)error {
	NSString* appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"] ;
	// Note: If you'd prefer the app name to be localized, use "CFBundleName" instead.
	NSString* appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] ;
	NSString* appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ;
	NSString* systemDescription = [SSYSystemDescriber softwareVersionAndArchitecture] ;
	NSString* mailableDescription ;
	if (
		([error respondsToSelector:@selector(longDescription)])
		&&
		([error respondsToSelector:@selector(mailableLongDescription)])
		) {
		mailableDescription = [error performSelector:@selector(mailableLongDescription)] ;
		if ([mailableDescription hasSuffix:SSYDidTruncateErrorDescriptionTrailer]) {
			// We'll write a file to package the error's longDescription which was too long to
			// fit in the email, and ask the user to zip and attach it.
			NSString* longDescription = [error performSelector:@selector(longDescription)] ;

			NSString* filename = [NSString stringWithFormat:
								  @"%@-Error-%x.txt",
								  [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"],
								  (int)[NSDate timeIntervalSinceReferenceDate]] ;
			NSString* filePath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"] stringByAppendingPathComponent:filename] ;
			NSError* writeError = nil ;
			NSString* text = [NSString stringWithFormat:
							  @"%@ %@.\n\n%@\n%@\n%@\n\n%@",
							  @"*** Note to user***  It is possible that this file may have some of your private "
							  @"information in it, bookmarks in particular.  Please skim through it before sending.  "
							  @"Delete anything which is too private, add a little note in its place, then save this file.\n\n"
							  @"To zip this file, select it in Finder, then execute a secondary click.  A secondary click "
							  @"can also be produced by clicking it with the right/secondary mouse button, or holding down "
							  @"the 'control' key while clicking on it.  From the contextual menu which appears, click 'Compress...' "
							  @"A new file with a name ending in .zip will appear.\n\n"
							  @"Please send the .zip file to our support crew, and thank you for helping us to support",
							  appName,
							  appVersion,
							  appVersionString,
							  systemDescription,
							  longDescription] ;
			BOOL writeOk = [text writeToFile:filePath
								  atomically:YES
									encoding:NSUTF8StringEncoding
									   error:&writeError] ;
			if (writeOk) {
				NSString* msg = [NSString localizeFormat:
								 @"additionalInfoZipX",
								 filename] ;
				[SSYAlert runModalDialogTitle:nil
									  message:msg
									  buttons:nil] ;
				
				mailableDescription = [NSString stringWithFormat:
									   @"*** Please review, zip and attach file %@. ***",
									   filename] ;
			}
			else {
				mailableDescription = [mailableDescription stringByAppendingString:
									   @"\n\n*** The above description was truncated to fit in an email, but writing it to a file failed."] ;
			}
			
		}
	}
	else {
		mailableDescription = [error description] ;
	}

	NSMutableString* body = [NSMutableString stringWithFormat:@"%@\n\n\n\n%@ %@ (%@)\n%@\n\n%@",
							 [NSString localize:@"additionalInfoAsk"],
							 appName,
							 appVersionString,
							 appVersion,
							 systemDescription,
							 mailableDescription] ;
	
	[SSYMailto emailTo:[SSYAlert supportEmailString]
			   subject:[NSString stringWithFormat:
						@"%@ Error %d",
						appName,
						[error code]]
				  body:body] ;
}

/*!
 @brief    This method will *always* run when a button is clicked
 
 @details  -sheetDidEnd::: *may* also run when a button is clicked,
 and if it does, it will run a little prior to this one, in the same
 run loop cycle.
 */
- (IBAction)clickedButton:(id)sender {	
	// In case executing the clickSelector method will remove our last retainer...
	[self retain] ;
	
	// Remember:
	// Button1 --> tag=NSAlertDefaultReturn = 1
	// Button2 --> tag=NSAlertAlternateReturn = 0
	// Button3 --> tag=NSAlertOtherReturn = -1
	[self setAlertReturn:[sender tag]] ;

	[self goAway] ;
	
	if ([self clickTarget]) {
		[[self clickTarget] performSelector:[self clickSelector]
								 withObject:self] ;
		[self setIsDoingModalDialog:NO] ;
	}
	
	if ([self checkboxState] == NSOnState) {
		[[self checkboxInvocation] invoke] ;
	}
	
	// Balance the -retain, above.
	[self release] ;
}

- (void)setTargetActionForButton:(NSButton*)button {
	[button setTarget:self] ;
	[button setAction:@selector(clickedButton:)] ;
}

- (void)stealObjectsFromAppleAlerts {
	NSPanel* panel ;

	panel = NSGetAlertPanel(nil, @"dummyInfoText", @"OK", nil, nil) ;
	NSArray* subviews = [[panel contentView] subviews] ;
	for (NSView* subview in subviews) {
		if ([subview isKindOfClass:[NSImageView class]]) {
			self.iconInformational = (NSImageView*)subview ;
		}
		else if ([subview isKindOfClass:[NSTextField class]]) {
			NSString* string  = [(NSTextField*)subview stringValue] ;
			if ([string isEqualToString:@"dummyInfoText"]) {
			}
			else {
				self.wordAlert = string ;
			}
		}
	}
	
	// Now, go back and get the critical-badged icon
	panel = NSGetCriticalAlertPanel(@"", @"", @"OK", nil, nil) ;
	subviews = [[panel contentView] subviews] ;
	for (NSView* subview in subviews) {
		if ([subview isKindOfClass:[NSImageView class]]) {
			self.iconCritical = (NSImageView*)subview ;
			break ;
		}
	}
}


#pragma mark * Public Methods for Setting views

- (void)setSupportEmail {
	if ([SSYAlert supportEmailString] != nil) {
		NSButton* button ;
		if (!(button = [self supportButton])) {
			// The image is 32 and the bezel border on each side is 2*2=4.
			// However, testing shows that we need 38.  Oh, well.
			NSRect frame = NSMakeRect(0, 0, 38.0, 38.0) ;
			NSButton* button = [[NSButton alloc] initWithFrame:frame] ;
			[button setBezelStyle:NSRegularSquareBezelStyle] ;
			[button setTarget:self] ;
			[button setAction:@selector(support:)] ;
			NSString* imagePath = [[NSBundle mainBundle] pathForResource:@"support"
																  ofType:@"tif"] ;
			NSImage* image = [[NSImage alloc] initByReferencingFile:imagePath] ;
			[button setImage:image] ;
			[image release] ;
			NSString* toolTip = [[self class] contactSupportToolTip] ;								 
			[button setToolTip:toolTip] ;
			[self setSupportButton:button] ;
			[[[self window] contentView] addSubview:button] ;
			[button release] ;	
		}
		
		[button setEnabled:YES] ;
	}
	else {
		[[self supportButton] removeFromSuperviewWithoutNeedingDisplay] ;
		[self setSupportButton:nil] ;
	}
}

//#define DEFAULT_MIN_TEXT_FIELD_WIDTH 250.0
- (void)cleanSlate {
	[self setWindowTitle:nil] ; // Defaults to mainBundle's CFBundleName (which should be the localized name of the app)
	[self setShowsProgressBar:NO] ;
	[self setTitleText:nil] ;
	[self setSmallText:nil] ;
	[self setIconStyle:SSYAlertIconNoIcon] ;
	[self setButton1Title:nil] ;
	[self setButton2Title:nil] ;
	[self setButton3Title:nil] ;
	[self setHelpAnchor:nil] ;
	[self setCheckboxTitle:nil] ;
	[self setWhyDisabled:nil] ;
	[self removeAllOtherSubviews] ;

	// The following is a holdover from when SSYAlert support a
	// configuration stack, and may no longer be needed...
	// Now, there may still be some subviews left in the view...
	// The -removeAllOtherSubviews only removed those which are in
	// the current self.otherSubviews array.  But if the configuration has
	// been pushed, self.otherSubviews will be a new, empty array.
	// Therefore, we now ask the -contentView if it has any more subviews
	// left and if so remove them...
	NSView* contentView = [[self window] contentView] ;
	// We use a regular C loop since -removeFromSuperviewWithoutNeedingDisplay
	// mutates the [contentView subviews] and therefore we cannot 
	// use an enumeration
	NSArray* subviews = [contentView subviews] ;
	NSInteger i ;
	for (i=[subviews count]-1; i>=0; i--) {
		NSView* subview = [subviews objectAtIndex:i] ;
		[subview removeFromSuperviewWithoutNeedingDisplay] ;
	}
	
	self.allowsShrinking = YES ;
	[self setIsEnabled:YES] ;
	self.isVisible = YES ;
	self.progressBarShouldAnimate = NO ;
	[self setRightColumnMinimumWidth:0.0] ;
	[self setRightColumnMaximumWidth:FLT_MAX] ;
}

- (void)setWindowTitle:(NSString*)title {
	if (!title) {
		title = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"] ; // CFBundleName may be localized
	}
	
	[[self window] setTitle:title] ;
}

- (void)setShowsProgressBar:(BOOL)showsProgressBar {
	NSProgressIndicator* progressBar_ = [self progressBar] ;
	if (showsProgressBar) {
		if (!progressBar_) {
			// Add progress bar
			progressBar_ = [[NSProgressIndicator alloc] initWithFrame:NSZeroRect] ;
			[progressBar_ setControlSize:NSSmallControlSize] ;
			[progressBar_ setStyle:NSProgressIndicatorBarStyle] ;
			[progressBar_ sizeToFit] ;
			[progressBar_ setUsesThreadedAnimation:YES] ;
			[self setProgressBar:progressBar_] ;
			[[[self window] contentView] addSubview:progressBar_] ;
			[progressBar_ release] ;
		}
	}
	else if (progressBar_) {
		[progressBar_ removeFromSuperviewWithoutNeedingDisplay] ;
		[self setProgressBar:nil] ;
	}
}

- (void)setTitleText:(NSString*)text {
	NSTextView* textView = [self titleTextView] ;
	if (text) {
		if (!textView) {
			textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 100, [SSYAlert titleTextHeight])] ;
			[textView setFont:[SSYAlert titleTextFont]] ;
			[textView configureForSSYAlertUsage] ;
			[self setTitleTextView:textView] ;
			[textView release] ;
			[[[self window] contentView] addSubview:textView] ;
		}
		
		[textView setString:[text stringByTruncatingMiddleToLength:self.titleMaxChars
														wholeWords:YES]] ;
	}
	else {
		[textView removeFromSuperviewWithoutNeedingDisplay] ;
		[self setTitleTextView:nil] ;
	}
}

- (void)setTitleToDefaultAlert {
	[self setTitleText:[self wordAlert]] ;
}

- (NSTextView*)smallTextViewPrototype {
	NSTextView* textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 100, [SSYAlert smallTextHeight])] ;
	[textView setFont:[SSYAlert smallTextFont]] ;
	[textView configureForSSYAlertUsage] ;
	return [textView autorelease] ;
}

- (void)setSmallText:(NSString*)text {
	NSTextView* textView = [self smallTextView] ;
	if (text) {
		if (!textView) {
			textView = [self smallTextViewPrototype] ;
			[self setSmallTextView:textView] ;
			[[[self window] contentView] addSubview:textView] ;
		}
		
		// Commented out in BookMacster 1.3.5.  I need a better way to do this.
		// NSString* truncatedText = [text stringByTruncatingMiddleToLength:self.smallTextMaxChars] ;
		[textView setString:text] ;
	}
	else {
		[textView removeFromSuperviewWithoutNeedingDisplay] ;
		[self setSmallTextView:nil] ;
	}
}

- (void)setIconStyle:(int)iconStyle {
	NSImageView* icon_ ;
	switch (iconStyle) {
		case SSYAlertIconNoIcon:
			icon_ = nil ;
			break ;
		case SSYAlertIconInformational:
			icon_ = [self iconInformational] ;
			break ;
		case SSYAlertIconCritical:
			icon_ = [self iconCritical] ;
			break ;
	}
	
	if (icon_ != [self icon]) {
		// Remove existing icon, if any
		[[self icon] removeFromSuperviewWithoutNeedingDisplay] ;
		
		// Set new icon
		[self setIcon:icon_] ;
		if (icon_) {
			[[[self window] contentView] addSubview:icon_] ;
		}
	}
}

- (void)setButton1Title:(NSString*)title {
	if (title) {
		NSButton* button ;
		
		if (!(button = [self button1])) {
			button = [SSYAlert newButton] ;
			[button setKeyEquivalent:@"\r"] ;
			[button setTag:NSAlertDefaultReturn] ;
			[self setTargetActionForButton:button] ;
			[self setButton1:button] ;
			[[[self window] contentView] addSubview:button] ;
		}
		
		[button setEnabled:YES] ;
		[button setTitle:title] ;
		[button sizeToFitIncludingNiceMargins] ;
	}
	else if (title && ![title length]) {
		[[self button1] setEnabled:NO] ;
	}
	else {
		[[self button1] removeFromSuperviewWithoutNeedingDisplay] ;
		[self setButton1:nil] ;
	}
	
}

- (void)setButton2Title:(NSString*)title {
	if (title) {
		NSButton* button ;
		if (!(button = [self button2])) {
			button = [SSYAlert newButton] ;
			[button setKeyEquivalent:@"\e"] ;  // escape key
			[button setTag:NSAlertAlternateReturn] ;
			[self setTargetActionForButton:button] ;
			[self setButton2:button] ;
			[[[self window] contentView] addSubview:button] ;
		}	
		
		[button setEnabled:YES] ;
		[button setTitle:title] ;
		//[button setWidthToFitTitlePlusTotalMargins:40] ;
		[button sizeToFitIncludingNiceMargins] ;
	}
	else if (title && ![title length]) {
		[[self button2] setEnabled:NO] ;
	}
	else {
		[[self button2] removeFromSuperviewWithoutNeedingDisplay] ;
		[self setButton2:nil] ;
	}
}

- (void)setButton3Title:(NSString*)title {
	if (title) {
		NSButton* button ;
		if (!(button = [self button3])) {
			button = [SSYAlert newButton] ;
			[button setTag:NSAlertOtherReturn] ;
			[self setTargetActionForButton:button] ;
			[self setButton3:button] ;
			[[[self window] contentView] addSubview:button] ;
		}
		
		[button setEnabled:YES] ;
		[button setTitle:title] ;
		//[button setWidthToFitTitlePlusTotalMargins:40] ;
		[button sizeToFitIncludingNiceMargins] ;
	}
	else if (title && ![title length]) {
		[[self button3] setEnabled:NO] ;
	}
	else {
		[[self button3] removeFromSuperviewWithoutNeedingDisplay] ;
		[self setButton3:nil] ;
	}
}

- (void)setHelpAnchor:(NSString*)anchor {
	// This one is tricky since we've got two ivars to worry about:
	// NSButton* helpButton and NSString* helpAnchorString
	if (anchor) {
		NSButton* button ;
		if (!(button = [self helpButton])) {
			NSRect frame = NSMakeRect(0, 0, 21.0, 23.0) ;
				// because help button in Interface Builder is 21x23
				// It seems there should be an NSHelpButtonSize constant,
				// but I can't find any.
			NSButton* button = [[NSButton alloc] initWithFrame:frame] ;
			[button setBezelStyle:NSHelpButtonBezelStyle] ;
			[button setTarget:self] ;
			[button setAction:@selector(help:)] ;
			[button setTitle:@""] ;
			[self setHelpButton:button] ;
			[[[self window] contentView] addSubview:button] ;
			[button release] ;	
		}
		
		[button setEnabled:YES] ;
	}
	else {
		[[self helpButton] removeFromSuperviewWithoutNeedingDisplay] ;
		[self setHelpButton:nil] ;
	}
	[self setHelpAnchorString:anchor] ;
}
	
- (void)setButton1Enabled:(BOOL)enabled {
	NSButton* button = [self button1] ;
	[button setEnabled:enabled] ;
	[button setNeedsDisplay] ;
}

- (void)setButton2Enabled:(BOOL)enabled {
	NSButton* button = [self button2] ;
	[button setEnabled:enabled] ;
	[button setNeedsDisplay] ;
}

- (void)setButton3Enabled:(BOOL)enabled {
	NSButton* button = [self button3] ;
	[button setEnabled:enabled] ;
	[button setNeedsDisplay] ;
}

- (void)setCheckboxTitle:(NSString*)title {
	if (title) {
		SSYWrappingCheckbox* button ;
		if (!(button = [self checkbox])) {
			button = [[SSYWrappingCheckbox alloc] initWithTitle:title
													   maxWidth:[self rightColumnMaximumWidth]] ;
			[self setCheckbox:button] ;
			[[[self window] contentView] addSubview:button] ;
			[button release] ;	
		}
		
		[button setEnabled:YES] ;
	}
	else if (title && ![title length]) {
		[[self checkbox] setEnabled:NO] ;
	}
	else {
		[[self checkbox] removeFromSuperviewWithoutNeedingDisplay] ;
		[self setCheckbox:nil] ;
	}
}

- (void)addOtherSubview:(NSView*)subview atIndex:(int)index {
	[[self otherSubviews] insertObject:subview atIndex:index] ;
	[[[self window] contentView] addSubview:subview] ;
}

- (void)removeOtherSubviewAtIndex:(int)index {
	NSMutableArray* otherSubviews_ = [self otherSubviews] ;
	NSView* otherSubview = [otherSubviews_ objectAtIndex:index] ;
	[otherSubviews_ removeObjectAtIndex:index] ;
	[otherSubview removeFromSuperviewWithoutNeedingDisplay] ;
}

- (void)removeAllOtherSubviews {
	NSMutableArray* otherSubviews_ = [self otherSubviews] ;
	int n = [otherSubviews_ count] - 1 ;
	for ( ; n>=0; n--) {
		[self removeOtherSubviewAtIndex:n] ;
	}
}

- (void)setIndeterminate:(BOOL)indeterminate {
	[[self progressBar] setUsesThreadedAnimation:YES] ;
	[[self progressBar] setIndeterminate:indeterminate] ;
}

- (void)setMaxValue:(double)value {
	[[self progressBar] setMaxValue:value] ;
}

- (void)setDoubleValue:(double)value {
	[[self progressBar] setDoubleValue:value] ;
	NSTimeInterval secondsNow = [NSDate timeIntervalSinceReferenceDate] ;
	if (secondsNow > self.nextProgressUpdate) {
		self.nextProgressUpdate = secondsNow + .05 ;
		[[self progressBar] display] ;
	}
}

- (void)incrementDoubleValueBy:(double)increment {
	NSProgressIndicator* progressBar_ = [self progressBar] ;
	double oldValue = [progressBar_ doubleValue] ;
	[progressBar setDoubleValue:(oldValue + increment)] ;
}

- (void)incrementDoubleValueByObject:(NSNumber*)increment {
	[self incrementDoubleValueBy:[increment doubleValue]] ;
}

- (void)setSmallTextAlignment:(NSTextAlignment)alignment {
	NSTextView* smallTextView_ = [self smallTextView] ;
	if (!smallTextView_) {
		[self setSmallText:@""] ;
	}
	[[self smallTextView] setAlignment:alignment] ;
}

- (void)setCheckboxState:(NSCellStateValue)state {
	[[self checkbox] setState:state] ;
}

#pragma mark * Public Methods for Displaying and Running

- (void)errorSheetDidEnd:(NSWindow *)sheet
			  returnCode:(int)returnCode
			 contextInfo:(void *)contextInfo {
	// Note: At this point, returnCode is always 0, no matter which 
	// button the user clicks.  I'm not sure what Apple had in mind,
	// or what the corect idiom is.  But this fixes it:
	returnCode = [self alertReturn] ;
	// Could also have used [[sheet windowController] alert return]
   
	[sheet orderOut:self];

	[[self class] tryRecoveryAttempterForError:[self errorPresenting]
								   recoveryOption:returnCode
								   contextInfo:contextInfo] ;
	
	// Balance self-retain in alertError:onWindow:modalDelegate:didEndSelector:contextInfo:
	// But autorelease, not immediately, because -goAway and then -clickedButton:
	// usually run later.  I'm not sure why they are later.
	if ([self isRetainedForSheet]) {
		[self autorelease] ;
		[self setIsRetainedForSheet:NO] ;
	}
}

/*!
 @brief    This method *may* run when a button is clicked

 @details  It does not run (by design) if the receiver was given a different
 clickTarget and clickAction.  It also seems to not run (I'm not sure why) if
 the receiver is shown as a sheet
 
 -clickedButton: will *always* run when a button is clicked, a little later
*/
- (void)sheetDidEnd:(NSWindow *)sheet
		 returnCode:(int)returnCode
		contextInfo:(void *)contextInfo {
	[self setAlertReturn:returnCode] ;
    [sheet orderOut:self] ;

	// Balance self-retain in runModalSheetOnWindow:modalDelegate:didEndSelector:contextInfo
	// But autorelease, not immediately, because -goAway and then -clickedButton:
	// usually run later.  I'm not sure why they run later.
	if ([self isRetainedForSheet]) {
		[self autorelease] ;
		[self setIsRetainedForSheet:NO] ;
	}
}

- (void)setDontAddOkButton {
	m_dontAddOkButton = YES ;
}

- (void)setButton1IfNeeded {
	if (![self button1] && !m_dontAddOkButton) {
		[self setButton1Title:[NSString localize:@"ok"]] ;
	}
}

- (void)runModalSheetOnWindow:(NSWindow*)documentWindow_
		   modalDelegate:(id)modalDelegate
		  didEndSelector:(SEL)didEndSelector
			 contextInfo:(void*)contextInfo {
	if (documentWindow_) {
		[self setButton1IfNeeded] ;
		
		// if () conditions added in BookMacster 1.5.7 since button1 target and action
		// should always be set by setButton1Title:
		// If the debugger stops here, figure out why!!
		if (([[self button1] target] == nil) && !m_dontAddOkButton) {
			[[self button1] setTarget:self] ;
#if DEBUG
			NSLog(@"Internal Error 928-9983") ;
			Debugger() ;
#endif
		}
		if (([[self button1] action] == NULL) && !m_dontAddOkButton) {
			[[self button1] setAction:@selector(clickedButton:)] ;
#if DEBUG
			NSLog(@"Internal Error 135-5614") ;
			Debugger() ;
#endif
		}
		
		NSAssert(((modalDelegate != nil) == (didEndSelector != nil)), @"222 modalDelegate vs. didEndSelector inconsistency.") ;
		if (!modalDelegate) {
			modalDelegate = self ;
		}
		
		[self setIsRetainedForSheet:YES] ;
		[self retain] ;
		
		if (!didEndSelector) {
			didEndSelector = @selector(sheetDidEnd:returnCode:contextInfo:) ;
		}
		
		[self doLayout] ;
		
		if ([self progressBarShouldAnimate]) {
			[[self progressBar] startAnimation:self] ;
		}
		
		[self setIsDoingModalDialog:YES] ;

		[self setDocumentWindow:documentWindow_] ;
		
		[SSYSheetManager enqueueSheet:[self window]
					   modalForWindow:documentWindow_
						modalDelegate:modalDelegate
					   didEndSelector:didEndSelector
						  contextInfo:contextInfo] ;
	}
}

/*- (oneway void)release {
	NSLog(@"RebugLog:  Before releasing, rc=%i for %@", [self retainCount], self) ;
	[super release] ;
	return ;
}	

- (id)retain {
	[super retain] ;
	NSLog(@"RebugLog:  After retaining, rc=%i for %@", [self retainCount], self) ;
	return self ;
}
*/

- (void)runModalDialog {
	// End current modal session, if any
	[self endModalSession] ;
	
	[self setButton1IfNeeded] ;	
	[self doLayout] ;
	
	BOOL progressBarWasAnimating ;
	
	if (self.progressBarShouldAnimate) {
		progressBarWasAnimating = YES ;
		[[self progressBar] stopAnimation:self] ;
	}
	
	[self setIsDoingModalDialog:YES] ;	

	// In case this is not the active application, we need to activate
	// We want to activate only this alert window.  Because the following
	// call to SetFrontProcessWithOptions() will bring forward the front
	// window only, we want to make sure that our window is front.
	// It will be, when we -runModalForWindow, but that might be too late.
	// So we -orderFrontRegardless before SetFrontProcessWithOptions().
	[[self window] orderFrontRegardless] ;
	ProcessSerialNumber psn = { 0, kCurrentProcess } ;
	SetFrontProcessWithOptions(
							   &psn,
							   kSetFrontProcessFrontWindowOnly
							   ) ;
	
	// The following method will also make the window "key" and "visible" 
	[NSApp runModalForWindow:[self window]] ;
	
	// Will block here until user clicks a button //
	
	if (progressBarWasAnimating) {
		[[self progressBar] startAnimation:self] ;
	}
}	

- (void)runModalSession {
	if (![self modalSession]) {
		NSWindow* currentModalWindow = [NSApp modalWindow] ;
		if (currentModalWindow) {
			NSLog(@"Internal Error 355-3207  Window '%@' in rect %@ is already modal",
				  [currentModalWindow title],
				  NSStringFromRect([currentModalWindow frame])) ;
		}
		else {
			NSModalSession session = [NSApp beginModalSessionForWindow:[self window]] ;
			[self setModalSession:session] ;		
			[NSApp runModalSession:session] ;
			[self setAlertReturn:NSNotFound] ;
		}
	}
	else {
		NSLog(@"Internal Error 359-0751  Modal session %p already in progress", [self modalSession]) ;
	}
}

- (void)endModalSession {
	if ([self modalSession]) {
		int response = [NSApp runModalSession:[self modalSession]] ;
		BOOL done = (response != NSRunContinuesResponse) ;
		if (!done) {
			// if() since re-sending -stopModal might cause a crash
			[NSApp stopModal] ;
		}
		
		// In BookMacster, if you launch the application and immediately begin
		// hitting the 'enter' key fast and repeatedly, you will first respond
		// 'Open a Recent Document' to the "Welcome" dialog, and then choose the
		// first document in the list shown by SSYListPicker.  Sometimes,
		// that causes this method to be invoked twice; I'm not exactly sure how
		// it happens, but the second time modalSession = 0x0 which will cause
		// -endModalSession to crash without the following if().  Fixed in
		// BookMacster 0.1.7.
		if (modalSession) {
			[NSApp endModalSession:[self modalSession]] ;
		}
		
		[self setModalSession:0] ;
	}
}	

#define MIN_TEXT_FIELD_WIDTH 250.0
#define MAX_TEXT_FIELD_WIDTH 500.0

- (void)setRightColumnMinimumWidthForNiceAspectRatio {
	NSInteger nChars = [[[self window] contentView] longestStringLengthInAnySubview] ;
	CGFloat	width = 16 * sqrt(nChars) ;
	// Subject to upper and lower bounds...
	width = MAX(MIN_TEXT_FIELD_WIDTH, width) ;
	width = MIN(MAX_TEXT_FIELD_WIDTH, width) ;
	[self setRightColumnMinimumWidth:width] ;
}

#define BUTTON_SPACING 3.0
#define CANCEL_BUTTON_SPACING 20.0
#define WINDOW_EDGE_SPACING 17.0
#define SUBFRAME_SPACING 24.0
#define CONTROL_VERTICAL_SPACING 14.0

- (void)doLayout {
	// used for looping through other subviews
	NSEnumerator* e ;
	NSView* subview ;
	
	
	// X-AXIS LAYOUT
	
	// In the x-axis, the window consists of two columns,
	// left and right
	
	float t ; // temporary variable
	
	// Reference to left edge to the widest subview which is present.
	// Then center the remaining subview(s) to the widest.
	// Then advance t to the next column of subviews.
	if ([self icon] != nil) {
		// Icon is already positioned
		// Reference support and help to icon
		[self.supportButton setCenterX:[self.icon centerX]] ;
		[self.helpButton setCenterX:[self.icon centerX]] ;
		t = [self.icon rightEdge] ;
		t += SUBFRAME_SPACING ;
	}
	else if (self.supportButton != nil) { 
		[self.supportButton setLeftEdge:WINDOW_EDGE_SPACING] ;
		[self.helpButton setCenterX:[self.supportButton centerX]] ;
		t = [self.supportButton rightEdge] ;
		t += SUBFRAME_SPACING ;
	}
	else if (self.helpButton != nil) { 
		[self.helpButton setLeftEdge:WINDOW_EDGE_SPACING] ;
		t = [self.helpButton rightEdge] ;
		t += SUBFRAME_SPACING ;
	}
	else {
		t = WINDOW_EDGE_SPACING ;
	}
	
	[self.titleTextView setLeftEdge:t] ;
	[self.progressBar setLeftEdge:t] ;
	[self.smallTextView setLeftEdge:t] ;
	[self.checkbox setLeftEdge:t] ;
	e = [self.otherSubviews objectEnumerator] ;
	while((subview = [e nextObject])) {
		[subview setLeftEdge:t] ;
	}
	[self.button2 setLeftEdge:t] ;
	
	float rightSubframeWidth = 0.0 ;
	if (self.button1) {
		rightSubframeWidth += [button1 width] ;
	}
	if (self.button2) {
		rightSubframeWidth += [button2 width] ;
		rightSubframeWidth += CANCEL_BUTTON_SPACING ;
	}
	if (self.button3) {
		rightSubframeWidth += [button3 width] ;
		rightSubframeWidth += BUTTON_SPACING ;
	}
	
	if ([self rightColumnMinimumWidth] == 0) {
		[self setRightColumnMinimumWidthForNiceAspectRatio] ;
	}
	
	// The width of the right column (the stuff in the right of the window)
	// will be the width of either
	//	(a) the row of buttons (just calculated)
	//	(b) the width of the checkbox
	//  (c) self.rightColumnMinimumWidth
	// whichever is greater...
	rightSubframeWidth = MAX(rightSubframeWidth, [checkbox width]) ;
	rightSubframeWidth = MAX(rightSubframeWidth, self.rightColumnMinimumWidth) ;
	// and then constrained by its maximum
	rightSubframeWidth = MIN(rightSubframeWidth, self.rightColumnMaximumWidth) ;
	
	[self.progressBar setWidth:rightSubframeWidth] ;
	[self.titleTextView setWidth:rightSubframeWidth] ;
	[self.smallTextView setWidth:rightSubframeWidth] ;
	[self.checkbox setWidth:rightSubframeWidth] ;
	e = [self.otherSubviews objectEnumerator] ;
	while ((subview = [e nextObject])) {
		[subview setWidth:rightSubframeWidth] ;
		if ([subview respondsToSelector:@selector(sizeToFit)]) {
			[(NSControl*)subview sizeToFit] ;
		}
	}
	
	t += rightSubframeWidth ;
	float contentWidth = t + WINDOW_EDGE_SPACING ;
	[self.button1 setRightEdge:t] ;
	
	t = [self.button1 leftEdge] - BUTTON_SPACING ;
	[self.button3 setRightEdge:t] ;
	
	// Y-AXIS LAYOUT
	// First, we have to set the final height of the variable-height subviews.
	// Note that we could not have done this until now, because the height of
	// the text fields depends on their width, which was just set in the 
	// previous section of code.
	[self.titleTextView sizeHeightToFitAllowShrinking:self.allowsShrinking] ;
	[self.smallTextView sizeHeightToFitAllowShrinking:self.allowsShrinking] ;
	for (subview in self.otherSubviews) {
		[(NSView*)subview sizeHeightToFitAllowShrinking:self.allowsShrinking] ;
	}
	
	// The height of the contentView
	// will be the width of either
	//	(a) the stuff in the left column
	//	(b) the stuff in the right column
	// whichever is greater...
	int nSubviews ;
	
	// Compute required height of left column
	nSubviews = 0 ;
	float leftHeight = 0 ;
	if (self.icon) {
		leftHeight += [self.icon height] ;
		nSubviews++ ;
	}
	if (self.helpButton) {
		leftHeight += [self.helpButton height] ;
		nSubviews++ ;
	}
	if (self.supportButton) {
		leftHeight += [self.supportButton height] ;
		nSubviews++ ;
	}
	leftHeight += (nSubviews - 1) * CONTROL_VERTICAL_SPACING ;
	
	// Compute required height of right column
	nSubviews = 0 ;
	float rightHeight = 0 ;
	if (self.titleTextView != nil) {
		rightHeight += [self.titleTextView height] ;
		nSubviews++ ;
	}
	if (self.progressBar != nil) {
		rightHeight += [self.progressBar height] ;
		nSubviews++ ;
	}
	if (self.smallTextView != nil) {
		rightHeight += [self.smallTextView height] ;
		nSubviews++ ;
	}
	if (self.checkbox != nil) {
		rightHeight += [self.checkbox height] ;
		nSubviews++ ;
	}
	if (self.button1 != nil) {
		rightHeight += [self.button1 height] ;
		nSubviews++ ;
	}
	for (subview in self.otherSubviews) {
		rightHeight += [subview height] ;
		nSubviews++ ;
	}
	rightHeight += (nSubviews - 1) * CONTROL_VERTICAL_SPACING ;
	
	// Choose left or right
	float contentHeight = MAX(leftHeight, rightHeight) + 2 * WINDOW_EDGE_SPACING ;
	
	// Set y position of each subview
	if (self.icon) {
		[self.icon setTop:(contentHeight - WINDOW_EDGE_SPACING)] ;
	}
	
	
	// It is true that the bottom of the three buttons should already be set
	// correctly  as they were stolen from the Apple alert.
	// However, in order to have a uniform look in the case where
	// there are no buttons, I start over from 0 at the bottom.
	// and figure it out myself using my WINDOW_EDGE_SPACING (Bookdog 4.4.0)
	t = WINDOW_EDGE_SPACING ;
	
	if (self.button1 != nil) {
		[self.button1 setBottom:t] ;
		[self.button2 setBottom:t] ;
		[self.button3 setBottom:t] ;
		t += ([self.button1 height] + CONTROL_VERTICAL_SPACING) ;
	}
	
	if (self.checkbox != nil) {
		[self.checkbox setBottom:t] ;
		t += ([self.checkbox height] + CONTROL_VERTICAL_SPACING) ;
	}
	
	if (self.button1 != nil) {
		if (self.supportButton != nil) {
			[self.supportButton setCenterY:[self.button1 centerY]] ;
			[self.helpButton setBottom:([self.supportButton top] + CONTROL_VERTICAL_SPACING)] ;
		}
		else {
			[self.helpButton  setCenterY:[self.button1 centerY]] ;
		}
	}
	else {  // Is this needed?  Can button1 ever be nil during layout?
		if (self.supportButton != nil) {
			[self.supportButton setBottom:WINDOW_EDGE_SPACING] ;
			[self.helpButton setBottom:([supportButton top] + CONTROL_VERTICAL_SPACING)] ;
		}
		else {
			[self.helpButton setBottom:WINDOW_EDGE_SPACING] ;
		}
	}
	
	// Build top part of right side from the top down
	
	t = contentHeight - WINDOW_EDGE_SPACING ;
	
	if (self.titleTextView != nil) {
		[self.titleTextView setTop:t] ;
		t -= ([self.titleTextView height] + CONTROL_VERTICAL_SPACING) ;
	}
	
	if (self.progressBar != nil) {
		[self.progressBar setTop:t] ;
		t -= ([self.progressBar height] + CONTROL_VERTICAL_SPACING) ;
	}
	
	if (self.smallTextView != nil) {
		[self.smallTextView setTop:t] ;
		t -= ([self.smallTextView height] + CONTROL_VERTICAL_SPACING) ;
	}
	
	e = [self.otherSubviews objectEnumerator] ;
	while ((subview = [e nextObject]) != nil) {
		[subview setTop:t] ;
		t -= ([subview height] + CONTROL_VERTICAL_SPACING) ;
	}
	
	// Check and do damage control if too much height content
	float availableHeight = [[self.window screen] visibleFrame].size.height ;
	float overflowHeight = contentHeight - availableHeight + WINDOW_EDGE_SPACING;
	if (overflowHeight > 0) {
		// Whoops.  Move the buttons up so that they are on screen.
		// Will cover other fields, but at least user won't have to force quit.
		// This is what Apple's alerts do.
		[self.button1 deltaY:overflowHeight deltaH:0.0] ;
		[self.button2 deltaY:overflowHeight deltaH:0.0] ;
		[self.button3 deltaY:overflowHeight deltaH:0.0] ;
		[self.helpButton deltaY:overflowHeight deltaH:0.0] ;
		[self.supportButton deltaY:overflowHeight deltaH:0.0] ;
	}
	
	// Next, we'll resize the window's contentView
	// First, make sure that none of the subviews will move 
	// due to autoresizing.  (If this window were resizable, we'd
	// store the autoresize mask values in an array, to restore later)
	e = [[self.window.contentView subviews] objectEnumerator] ;
	while ((subview = [e nextObject])) {
		[subview setAutoresizingMask:NSViewNotSizable] ;
	}
	[self.window.contentView setWidth:contentWidth] ;
	[self.window.contentView setHeight:contentHeight] ;
	
	// Now that all otherSubviews have been initialized and presumably run 
	// through their validation routines and sent us messages to set our ivars
	// isEnabled and whyDisabled, we can access and forward them to button1.
	[self.button1 setEnabled:[self isEnabled]] ;
	[self.button1 setToolTip:[self whyDisabled]] ;
	
	// Now, set up the keyboard loop for tabbing
	e = [self.otherSubviews objectEnumerator] ;
	NSView* firstResponder = nil ; // redundant but necessary because I don't see any safe way to set the the first responder of a NSWindow to nil or other convenient known object.  -resignFirstResponder says "Never invoke this method directly".
	NSView* previousResponder = nil ;
	NSView* responder = nil ;
	while ((responder = [e nextObject])) {
		[responder makeNextKeyViewOfWindow:self.window
							firstResponder:&firstResponder
						 previousResponder:&previousResponder] ;
	}
	responder = self.checkbox ;
	[responder makeNextKeyViewOfWindow:self.window
						firstResponder:&firstResponder
					 previousResponder:&previousResponder] ;
	responder = self.helpButton ;
	[responder makeNextKeyViewOfWindow:self.window
						firstResponder:&firstResponder
					 previousResponder:&previousResponder] ;
	responder = self.supportButton ;
	[responder makeNextKeyViewOfWindow:self.window
						firstResponder:&firstResponder
					 previousResponder:&previousResponder] ;
	responder = self.button2 ;
	[responder makeNextKeyViewOfWindow:self.window
						firstResponder:&firstResponder
					 previousResponder:&previousResponder] ;
	responder = self.button3 ;
	[responder makeNextKeyViewOfWindow:self.window
						firstResponder:&firstResponder
					 previousResponder:&previousResponder] ;
	responder = self.button1 ;
	[responder makeNextKeyViewOfWindow:self.window
						firstResponder:&firstResponder
					 previousResponder:&previousResponder] ;
	[responder setNextKeyView:firstResponder] ; // Close the loop
	
	// Resize the window itself, and display window and views as needed
	[self.window setFrameToFitContentViewThenDisplay:YES] ;
	// argument must be YES to avoid flicker.  Counterintuitive,
	// but it took me the better part of a day to discover that.
	
	// Reposition the window so that the title bar remains at the original "top center"
	NSRect frame = [self.window frame] ;
	frame.origin.x = self.windowTopCenter.x - frame.size.width/2 ;
	frame.origin.y = MAX(self.windowTopCenter.y - frame.size.height, 0.0) ;
	[self.window setFrame:frame display:NO] ; // This "display" is only "ifNeeded"
	
	// This took me a couple hours to figure out...
	// If you send an NSProgressIndicator -startAnimation:, and then
	// run through the above methods, which probably reframes it, and
	// then send -startAnimation: again, it won't animate.  Possibly
	// it stops animating when it is reframed, but -isAnimating
	// doesn't know that it stopped animating, so the second
	// -startAnimation: message is ignored.
	// Anyhow, the solution is to only start/stop animating
	// at the end of this method.
	if (self.progressBarShouldAnimate) {
		[self.progressBar stopAnimation:self] ;
		[self.progressBar startAnimation:self] ;
	}
	else {
		[self.progressBar startAnimation:self] ;
		[self.progressBar stopAnimation:self] ;
	}
}	

- (void)display {	
	[self doLayout] ;
	// Next, invoke -display to update subviews and any areas where subviews have
	// been removed from, which will not necessarily be done
	// by displaying the window.  To increase efficiency by
	// eliminating all unnecessary redrawing, could track vacated areas
	// when subviews are moved or removed with -setNeedsDisplayInRect,
	// and also -setNeedsDisplay when subviews are changed, but I
	// don't think there's a need to win any efficiency contests for
	// my little alert.  Most of it is going to be hosed most of the
	// time anyhow
	// See discussion:
	// http://www.cocoabuilder.com/archive/message/cocoa/2007/4/9/181560
	[[self window] display] ;
	[[self window] makeKeyAndOrderFront:self] ;
}

- (void)goAway {
	// In case we are only being retained as the attachedSheet of our documentWindow...
	[self retain] ;
	
	[self endModalSession] ;
	
	if ([self isDoingModalDialog]) {
		[NSApp stopModal] ;
		[self setIsDoingModalDialog:NO] ;
	}
	
	NSWindow* documentWindow_ = [self documentWindow] ;
	if (documentWindow_) {
		// We're on a sheet
		
		// Clear for next usage.  Before 20090526, I did this after endSheet:returnCode:,
		// but this cleared a ^new^ document window in case endSheet:returnCode:
		// starts a new session, as does 
		// -[Bkmslf legacyArtifactDialogDidEnd:returnCode:contextInfo:].
		[self setDocumentWindow:nil] ;
		// Without the retain above (or an external retain)
		// the following will cause self to be dealloced
		
		NSWindow* sheet = [documentWindow_ attachedSheet] ;

		// Roll up and close the sheet.
		[sheet orderOut:self];
		[sheet close] ;

		// Note that, since Cocoa does not support piling multiple
		// sheets onto a window, we rolled up the sheet before 
		// invoking endSheet:returnCode:, because that method
		// will run the didEndSelector which may want to show
		// a new sheet.
		
		[sheet retain] ;

		// The following will cause the didEndSelector to execute.
		if (sheet) {
			[NSApp endSheet:sheet
				 returnCode:[self alertReturn]] ;
		}
		[sheet release] ;
		// We return here after the didEndSelector has completed
	}
	else {
		// We're a freestanding dialog
		[[self window] close] ;
	}
	
	[self release] ;  // Balances retain, above
}

#pragma mark * Public Methods for Getting Status

- (BOOL)modalSessionRunning {
	BOOL running ;
	if ([self modalSession]) {
		int response = [NSApp runModalSession:[self modalSession]] ;
		running = (response == NSRunContinuesResponse) ;
	}
	else {
		running = NO ;
	}

	return running ;	
}

- (NSCellStateValue)checkboxState {
	return [[self checkbox] state] ;
}


#pragma mark * Public Methods for Creating and Destroying

#define WINDOW_PROTOTYPE_WIDTH 200.0
#define WINDOW_PROTOTYPE_HEIGHT 486.0
// On my display, which is 1000 pixels high not including the menu bar, due to the
// action of [window center], 
//         windowTopCenter.y = MIN(657 + WINDOW_PROTOTYPE_HEIGHT/2, 970)
// Probably 970 is calculated for different displays as 
//         screenHeightNotIncludingMenuBar - 30
// The value WINDOW_PROTOTYPE_HEIGHT = 486 places it at 900, 100 pixels from the 
// bottom of the menu bar.

- init {
	if (!NSApp || [SSYAppLSUI isLSUIElement]) {
		// See http://lists.apple.com/archives/Objc-language/2008/Sep/msg00133.html ...
		// Actually, this is unsafe, as pointed out by Quincey Morris…
		// http://lists.apple.com/archives/Cocoa-dev/2011/May/msg00814.html
		// But it hasn't caused any trouble so far.
		[super dealloc] ;
		return nil ;
	}
	
	// Create window
	NSRect initialRect = NSMakeRect(0, 0, WINDOW_PROTOTYPE_WIDTH, WINDOW_PROTOTYPE_HEIGHT) ;
	// WINDOW_PROTOTYPE_WIDTH is because: If I use NSZeroRect, [window center] places
	// it at (0,0).  A bug, I would say.  The WINDOW_PROTOTYPE_HEIGHT
	// is to make [window center] think it is a tall window and place it up
	// fairly high on the screen.
	NSWindow* window = [[SSYAlertWindow alloc] initWithContentRect:initialRect
														 styleMask:NSTitledWindowMask
														   backing:NSBackingStoreBuffered
															 defer:NO] ;
	NSString* appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"] ; // CFBundleName may be localized
	if (appName) {
		[window setTitle:appName] ;
	}
	[self setWindow:window] ;
	[window setWindowController:self] ;
	[window setReleasedWhenClosed:NO] ;
	// The above is so that when we tell it to close in -goAway, it only hides.
	// Unlike the default NSWindow, this one is going to get a lot of re-use.
	[window center] ;

	// Invoke designated initializer for super, NSWindowController
	self = [super initWithWindow:window] ;
	[window release] ;
	
	if (self) {
		[self stealObjectsFromAppleAlerts] ;
		
		// Default values
//		self.rightColumnMinimumWidth = DEFAULT_MIN_TEXT_FIELD_WIDTH ;
		self.rightColumnMaximumWidth = FLT_MAX ;
		self.allowsShrinking = YES ;
		self.titleMaxChars = 500 ;
		self.smallTextMaxChars = 1500 ;
		self.isEnabled = YES ;
		
		NSPoint windowTopCenter_ = [window frame].origin ;
		windowTopCenter_.x += WINDOW_PROTOTYPE_WIDTH/2 ;
		windowTopCenter_.y += WINDOW_PROTOTYPE_HEIGHT ;  // move from bottom to top
		self.windowTopCenter = windowTopCenter_ ;
	}

	return self ;
}

- (void)doLayoutError:(NSError*)error {
	[self cleanSlate] ;
	[self setErrorPresenting:error] ;

	NSInteger iconStyle = [error isOnlyInformational] ? SSYAlertIconInformational : SSYAlertIconCritical ;
	[self setIconStyle:iconStyle] ;

	if ([error shouldShowSupportEmailButton] ) {
		[self setSupportEmail] ;
	}
	
	// Set title
	{
		NSString* title = [error localizedTitle] ;
		if (!title && ![error isOnlyInformational]) {
			title = [NSString stringWithFormat:
					 @"%@ %@",
					 [NSString localize:@"errorColon"],
					 [NSString stringWithFormat:@"%d", [error code]]] ;
		}
		[self setTitleText:title] ;			
	}
	
	// Set Help Anchor
	{
		NSString* helpAnchor = [error helpAnchor] ;
		if (helpAnchor) {
			[self setHelpAnchor:helpAnchor] ;
		}
	}
	
	// Set smallText
	[self setSmallText:[error localizedDeepDescription]] ;
	
	// Set buttons
	{
		NSError* deepestRecoverableError = [error deepestRecoverableError] ;
		NSArray* recoveryOptions = [[deepestRecoverableError userInfo] objectForKey:NSLocalizedRecoveryOptionsErrorKey] ;
		// Note that button number vs. position is like NSAlert and
		// SSYAlert, not like Apple's -presentError.
		if (recoveryOptions) {
			// Recovery option(s) are attemptable
			[self setButton1Title:[recoveryOptions objectAtIndex:0]] ;
			
			if ([recoveryOptions count] > 1) {
				[self setButton2Title:[recoveryOptions objectAtIndex:1]] ;
			}
			if ([recoveryOptions count] > 2) {
				[self setButton3Title:[recoveryOptions objectAtIndex:2]] ;
			}				
		}
		else {
			// No recovery options
			[self setButton1Title:[NSString localize:@"ok"]] ;
		}
	}
}

- (void)noteError:(NSError*)error {
	if (![error isOnlyInformational]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:SSYAlertDidProcessErrorNotification
															object:error] ;
	}
}

+ (SSYAlert*)sharedAlert {
	@synchronized(self) {
        if (sharedAlert == nil) {
            sharedAlert = [[self alloc] init] ; 
        }
	}
    return sharedAlert ;
}

+ (SSYAlert*)alert {
	SSYAlert* alert ;
	
	if (NSApp != nil) {
		alert = [[[self alloc] init] autorelease] ; 
	}
	else {
		alert = nil ;
	}

	return alert ;
}

- (void)returnToScriptError:(NSError*)error {
	[[NSScriptCommand currentCommand] setScriptErrorNumber:[error code]] ;
	[[NSScriptCommand currentCommand] setScriptErrorString:[error localizedDescription]] ;
}

- (void)alertError:(NSError*)error
		  onWindow:(NSWindow*)documentWindow_
	 modalDelegate:(id)modalDelegate
	didEndSelector:(SEL)didEndSelector
	   contextInfo:(void*)contextInfo {
	if (!error) {
		return ;
	}
	
	if ([NSScriptCommand currentCommand] != nil) {
		[self returnToScriptError:error] ;
		return ;
	}
	
	if (
		![gSSYAlertErrorHideManager shouldHideError:error]
		&&
		!(([[error domain] isEqualToString:NSCocoaErrorDomain]) && ([error code] == NSUserCancelledError))
		) {
		[self doLayoutError:error] ;
		
		NSAssert(((modalDelegate != nil) == (didEndSelector != nil)), @"111 modalDelegate vs. didEndSelector inconsistency") ;
		if (!modalDelegate) {
			modalDelegate = self ;
			didEndSelector = @selector(errorSheetDidEnd:returnCode:contextInfo:) ;
		}
		
		[self runModalSheetOnWindow:documentWindow_
					  modalDelegate:modalDelegate
					 didEndSelector:didEndSelector
						contextInfo:contextInfo] ;		
	}
	
	[self noteError:error] ;
}

- (SSYAlertRecovery)alertError:(NSError*)error {
	if (!error) {
		return SSYAlertRecoveryThereWasNoError ;
	}
	
	int alertReturn ;

	if ([gSSYAlertErrorHideManager shouldHideError:error]) {
		alertReturn = SSYAlertRecoveryErrorIsHidden ;
	}
	else if ([[error domain] isEqualToString:NSCocoaErrorDomain] && ([error code] == NSUserCancelledError)) {
		alertReturn = SSYAlertRecoveryAppleScriptCodeUserCancelledPreviously ;
	}
	else {
		[self doLayoutError:error] ;
		[self display] ;
		
		// End current modal session, if any
		[self endModalSession] ;
		
		[self setIsDoingModalDialog:YES] ;
		[NSApp runModalForWindow:[self window]] ;
		// Will block here until user clicks a button

		alertReturn = [self alertReturn] ;
		NSInteger recoveryResult = [SSYAlert tryRecoveryAttempterForError:error
														   recoveryOption:alertReturn
															  contextInfo:nil] ;
		if (recoveryResult != SSYAlertRecoveryNotAttempted) {
			alertReturn = recoveryResult ;
		}
	}
	
	[self noteError:error] ;
	
	return alertReturn ;
}

+ (SSYAlertRecovery)alertError:(NSError*)error {
	// In BookMacster 1.1.10, I found that Core Data migration, specifically
	// -[Bkmx007-008MigrationPolicy createDestinationInstancesForSourceInstance:::]
	// was spending 99% of its time creating SSYAlerts for nil errors!  Fix…
	if (!error) {
		return SSYAlertRecoveryThereWasNoError ;
	}
	
	return [[SSYAlert alert] alertError:error] ;
}

+ (void)alertError:(NSError*)error
		  onWindow:(NSWindow*)documentWindow_
	 modalDelegate:(id)modalDelegate
	didEndSelector:(SEL)didEndSelector
	   contextInfo:(void*)contextInfo {
	
	// Get alert, configure, display and run
	SSYAlert* alert = [SSYAlert alert] ;
	
	[alert alertError:error
			 onWindow:documentWindow_
		modalDelegate:modalDelegate
	   didEndSelector:didEndSelector
		  contextInfo:contextInfo] ;
}


+ (int)runModalDialogTitle:(NSString*)title
				   message:(NSString*)msg
				   buttons:(NSString*)button1Title, ... {
	NSMutableArray* buttonsArray = [[NSMutableArray alloc] initWithCapacity:3] ;
	
	va_list argPtr ;
	if (button1Title != nil) {
		[buttonsArray addObject:button1Title] ;
		va_start(argPtr, button1Title) ;
		NSString* buttonTitle ;
		while ((buttonTitle = va_arg(argPtr, NSString*)) != nil) {
			[buttonsArray addObject:buttonTitle] ;
		}
		va_end(argPtr) ;
	}
	
	NSArray* buttonsArrayOut = [buttonsArray copy] ;
	[buttonsArray release] ;
	
	return [self runModalDialogTitle:title
							 message:msg
						buttonsArray:[buttonsArrayOut autorelease]] ;	
}

+ (int)runModalDialogTitle:(NSString*)title
				   message:(NSString*)msg
			  buttonsArray:(NSArray*)buttonsArray {
	SSYAlert* alert = [self alert] ;
	if ([buttonsArray count] > 0) {
		[alert setButton1Title:[buttonsArray objectAtIndex:0]] ;
	}
	if ([buttonsArray count] > 1) {
		[alert setButton2Title:[buttonsArray objectAtIndex:1]] ;
	}
	if ([buttonsArray count] > 2) {
		[alert setButton3Title:[buttonsArray objectAtIndex:2]] ;
	}
	
	[alert setIconStyle:SSYAlertIconInformational] ;
	if (title == nil) {
		title = [alert wordAlert] ;
	}	
	[alert setTitleText:title] ;
	[alert setSmallText:msg] ;
	[alert display] ;
	
	[alert runModalDialog] ;
	return [alert alertReturn] ;
}



#pragma mark * Basic Infrastructure

- (void)dealloc {
	[icon release] ;
	[progressBar release] ;
	[titleTextView release] ;
	[smallTextView release] ;
	[helpButton release] ;
	[supportButton release] ;
	[checkbox release] ;
	[button1 release] ;
	[button2 release] ;
	[button3 release] ;
	[helpAnchorString release] ;
	[errorPresenting release] ;
	[iconInformational release] ;
	[iconCritical release] ;
	[buttonPrototype release] ;
	[wordAlert release] ;
	[documentWindow release] ;
	
	[otherSubviews release] ;
	
	[clickTarget release] ;
	[clickObject release] ;
	[m_checkboxInvocation release] ;
	
	[super dealloc] ;
}

- (BOOL)acceptsFirstResponder {
	return YES ;
}


@end