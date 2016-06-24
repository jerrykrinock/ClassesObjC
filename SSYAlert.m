#import "SSYAlert.h"

#import "SSYMailto.h"
#import "SSYSystemDescriber.h"
#import "SSYWrappingCheckbox.h"

#import "NSError+InfoAccess.h"
#import "NSString+Truncate.h"
#import "NSView+Layout.h"
#import "NSWindow+Sizing.h"
#import "NSError+MoreDescriptions.h"
#import "NSError+Recovery.h"
#import "NSError+SSYInfo.h"
#import "NSBundle+MainApp.h"
#import "NSObject+RecklessPerformSelector.h"
#import "SSYVectorImages.h"
#import "NSString+LocalizeSSY.h"
#import "NSInvocation+Quick.h"
#import "NS(Attributed)String+Geometrics.h"

NSObject <SSYAlertErrorHideManager> * gSSYAlertErrorHideManager = nil ;

NSMutableSet* static_alertHangout = nil ;

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
        NSInteger minLength = [[self recklessPerformSelector:selector] length] ;
        if (length < minLength) {
            length = minLength ;
        }
	}
	selector = @selector(stringValue) ;
	if ([self respondsToSelector:selector]) {
		// Because NSImageView has a -stringValue describing each of its sizes...
		if (![self isKindOfClass:[NSImageView class]]) {
            NSInteger minLength = [[self recklessPerformSelector:selector] length] ;
            if (length < minLength) {
                length = minLength ;
            }
		}
	}
	
	// Recursion into documentView, if any
	selector = @selector(documentView) ;
	if ([self respondsToSelector:selector]) {
		length = [[self recklessPerformSelector:selector] stringLengthInAnySubviewLongerThan:length] ;
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
	
#if !__has_feature(objc_arc)
    [copy retain] ;
#endif
    return copy ;
}

@end


@interface NSTextView (SSYAlertUsage)

- (void)configureForSSYAlertUsage ;

@end

@implementation NSTextView (SSYAlertUsage)

- (void)configureForSSYAlertUsage {
	[self setEditable:NO] ;
	[self setDrawsBackground:NO] ;
    // Changed in BookMacster 1.21.  Why not allow text to be copied?
	[self setSelectable:YES] ;

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


#define WINDOW_EDGE_SPACING 17.0


#pragma mark * Class Extension of SSYAlert

@interface SSYAlert ()

@property (retain) NSImageView* icon ;
@property (retain) NSProgressIndicator* progressBar ; // readonly in public @interface
@property (retain) NSTextView* titleTextView ; // readonly in public @interface
@property (retain) NSTextView* smallTextView ; // readonly in public @interface
@property (retain) NSScrollView* smallTextScrollView ;
@property (retain) NSButton* helpButton ;
@property (retain) NSButton* supportButton ;
@property (retain) SSYWrappingCheckbox* checkbox ;
@property (retain) NSButton* button1 ;
@property (retain) NSButton* button2 ;
@property (retain) NSButton* button3 ;
@property (retain) NSButton* button4 ;
@property (copy) NSString* helpAnchorString ;
@property (retain) NSError* errorPresenting ;
@property (retain) NSImageView* iconInformational ;
@property (retain) NSImageView* iconWarning ;
@property (retain) NSImageView* iconCritical ;
@property (retain) NSButton* buttonPrototype ;
@property (copy) NSString* wordAlert ;
// @property (copy) NSString* whyDisabled ; // in public @interface
// @property (assign) isEnabled ; // in public @interface
@property (assign) BOOL isVisible ;
@property (assign) NSInteger nDone ;
// @property (assign) float rightColumnMinimumWidth ; // in public @interface
// @property (assign) float rightColumnMaximumWidth ; // in public @interface
// @property (assign) BOOL allowsShrinking ; // in public @interface
// @property (assign) NSInteger titleMaxChars ; // in public @interface
// @property (assign) NSInteger smallTextMaxChars ; // in public @interface
// @property (assign) BOOL progressBarShouldAnimate ; // in public @interface
@property (assign) BOOL isDoingModalDialog ;
@property (assign) NSModalSession modalSession ;
@property (assign) NSPoint windowTopCenter ;
@property (assign) NSTimeInterval nextProgressUpdate ;
// @property (retain, readonly) NSMutableArray* otherSubviews ; // in public @interface

@end


@implementation SSYAlertWindow

/*!
 @brief    Override of base class method which does damage control in the
 event that the content exceeds the available height on the screen.

 @details  Damage control is done by moving the critical controls up onto
 the screen.  Note that they will cover other subviews, but it's more
 important that the user see the critical controls.  This is what Apple's
 alerts do when there is a similar overflow.
 
 This was added in BookMacster 1.9.5 to replace code in -doooLayout which
 did not work properly.
*/
- (void)setFrameOrigin:(NSPoint)frameOrigin {
	[super setFrameOrigin:frameOrigin] ;

	SSYAlert* alert = [self windowController] ;

	// Defensive Programming
	if (![alert isKindOfClass:[SSYAlert class]]) {
		NSLog(@"Warning 624-2948  Expected SSYAlert") ;
		return ;
	}

	CGFloat overflowHeight ;
		
	if ([self isSheet]) {
		// This branch was added in BookMacster 1.9.8.
		// If there is space between the top of the parent window and the menu bar,
		// Cocoa will move the window up into that extra height in order to make
		// room for the sheet, and unfortunately this has not been done yet.  So
		// I need to, arghhh, predict what Cocoa is going to do…
		NSWindow* parentWindow = [[self windowController] documentWindow] ;
		CGFloat useableScreenHeight = [[parentWindow screen] visibleFrame].size.height ;
		// useableScreenHeight does not include menu bar and does not include the Dock.
		CGFloat tootlebarHeight = [parentWindow tootlebarHeight] ;
		CGFloat availableHeight = useableScreenHeight - tootlebarHeight ;
		overflowHeight = [self frame].size.height - availableHeight ;
	}
	else {
		overflowHeight = WINDOW_EDGE_SPACING - [self frame].origin.y ;
	}
	
	if (overflowHeight > 0.0) {
		[[alert button1] deltaY:overflowHeight deltaH:0.0] ;
		[[alert button2] deltaY:overflowHeight deltaH:0.0] ;
		[[alert button3] deltaY:overflowHeight deltaH:0.0] ;
        [[alert button4] deltaY:overflowHeight deltaH:0.0] ;
		[[alert helpButton] deltaY:overflowHeight deltaH:0.0] ;
		[[alert supportButton] deltaY:overflowHeight deltaH:0.0] ;
		[[alert checkbox] deltaY:overflowHeight deltaH:0.0] ;
	}
}

- (NSInteger)checkboxState {
    NSInteger state = NSMixedState ; // default answer in case we can't find checkbox
    BOOL didFindCheckbox = NO ;
    for (NSView* view in [[self contentView] subviews]) {
        if ([view isKindOfClass:[SSYWrappingCheckbox class]]) {
            SSYWrappingCheckbox* checkbox = (SSYWrappingCheckbox*)view ;
            state = [checkbox state] ;
            didFindCheckbox = YES ;
            break ;
        }
    }
    
    if (!didFindCheckbox) {
        // Until BookMacster 1.22.4, logged Internal Error 624-9382
        state = NSOffState ;
    }
    
    return state ;
}

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
				 firstResponder:(NSView**)firstResponder_p
			  previousResponder:(NSView**)previousResponder_p {
    if ([self acceptsFirstResponder]) {
        if (!*firstResponder_p) {
            // No first responder yet
            if ([window makeFirstResponder:self]) {
                [window setInitialFirstResponder:self] ;
                *firstResponder_p = self ;
                *previousResponder_p = self ;
            }
        }
        else {
            [*previousResponder_p setNextKeyView:self] ;
            *previousResponder_p = self ;
        }
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


@implementation SSYAlert : NSWindowController

+ (void)load {
    static_alertHangout = [[NSMutableSet alloc] init] ;
}


+ (NSString*)supportEmailString {
	return [[NSBundle mainAppBundle] objectForInfoDictionaryKey:SSYAlert_ErrorSupportEmailKey] ;
}

- (id)clickObject {
#if !__has_feature(objc_arc)
	[[clickObject retain] autorelease] ;
#endif
	
    return clickObject ;
}

- (void)setClickObject:(id)value {
    if (clickObject != value) {
#if !__has_feature(objc_arc)
    [clickObject release] ;
    [value retain] ;
#endif
    clickObject = value ;
    }
}

#pragma mark * Accessors

@synthesize icon ;
@synthesize progressBar ;
@synthesize titleTextView ;
@synthesize smallTextView ;
@synthesize smallTextScrollView ;
@synthesize helpButton ;
@synthesize supportButton ;
@synthesize checkbox ;
@synthesize button1 ;
@synthesize button2 ;
@synthesize button3 ;
@synthesize button4 ;
@synthesize helpAnchorString ;
@synthesize errorPresenting ;
@synthesize iconInformational ;
@synthesize iconWarning;
@synthesize iconCritical ;
@synthesize buttonPrototype ;
@synthesize wordAlert ;
@synthesize documentWindow ;

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
@synthesize dontGoAwayUponButtonClicked = m_dontGoAwayUponButtonClicked ;
@synthesize nextProgressUpdate ;

- (CGFloat)rightColumnMaximumWidth {
	CGFloat rightColumnMaximumWidth ;
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
		whyDisabled = [m_whyDisabled copy] ;
#if !__has_feature(objc_arc)
        [whyDisabled autorelease] ;
#endif
	}
	return whyDisabled ;
}

- (void)setWhyDisabled:(NSString*)whyDisabled {
	[[self button1] setToolTip:whyDisabled] ;

	@synchronized(self) {
		if (whyDisabled != m_whyDisabled) {
#if !__has_feature(objc_arc)
			[m_whyDisabled release] ;
#endif
			m_whyDisabled = [whyDisabled copy] ;
		}
	}
}

- (NSMutableArray *)otherSubviews {
    if (!otherSubviews) {
        otherSubviews = [[NSMutableArray alloc] init];
    }
#if !__has_feature(objc_arc)
    [[otherSubviews retain] autorelease] ;
#endif
    return otherSubviews ;
}

#pragma mark * Class Methods returning Constants

+ (NSFont*)titleTextFont {
	return [NSFont boldSystemFontOfSize:13] ;
}

+ (NSFont*)smallTextFont {
	return [NSFont systemFontOfSize:12] ;
}

+ (CGFloat)titleTextHeight {
	return 17 ;
}

+ (CGFloat)smallTextHeight {
	return 14 ;
}

+ (NSString*)contactSupportToolTip {
	return [NSString stringWithFormat:@"%@ | %@",
			[NSString localize:@"supportContact"],
			[[NSString localize:@"email"] capitalizedString]] ;
}

+ (NSButton*)makeButton {
	NSButton* button = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 49, 49)] ;
	[button setFont:[NSFont systemFontOfSize:13]] ;
	[button setBezelStyle:NSRoundedBezelStyle] ;
#if !__has_feature(objc_arc)
    [button autorelease] ;
#endif
	return button ;
}


#pragma mark * Private Methods

/*!
 @brief    Translates from the 'recovery option' as expressed in our
 -doLayoutError: method to the 'recovery option index' expressed in Cocoa's
 error presentation method, -presentError:
*/
+ (NSUInteger)recoveryOptionIndexForRecoveryOption:(NSInteger)recoveryOption {
	NSUInteger recoveryOptionIndex ;
	switch (recoveryOption) {
		case NSAlertFirstButtonReturn :
			recoveryOptionIndex = 0 ;
			break;
		case NSAlertSecondButtonReturn :
			recoveryOptionIndex = 1 ;
			break;
		case NSAlertThirdButtonReturn :
			recoveryOptionIndex = 2 ;
			break;
        case SSYAlertFourthButtonReturn :
            recoveryOptionIndex = 3 ;
            break;
	default:
			// This should never happen since we only have 3 buttons and return
			// one of the above three values like NSAlert.
			NSLog(@"Warning 520-3840 %ld", (long)recoveryOption) ;
			recoveryOptionIndex = recoveryOption ;
			break;
	}
	
	return recoveryOptionIndex ;
}

+ (NSInteger)tryRecoveryAttempterForError:(NSError*)error
						   recoveryOption:(NSUInteger)recoveryOption
							  contextInfo:(NSMutableDictionary*)infoDictionary {
	NSUInteger result = SSYAlertRecoveryNotAttempted ;
	
	NSError* deepestRecoverableError = [error deepestRecoverableError] ;
    id recoveryAttempter ;
    if ([[[error userInfo] objectForKey:SSYRecoveryAttempterIsAppDelegateErrorKey] boolValue]) {
        recoveryAttempter = [NSApp delegate] ;
    }
    else {
        recoveryAttempter = [error recoveryAttempter] ;
    }
    
    if (!recoveryAttempter) {
        NSURL* recoveryAttempterUrl = [[error userInfo] objectForKey:SSYRecoveryAttempterUrlErrorKey] ;
        if (recoveryAttempterUrl) {
            // recoveryOption NSAlertSecondButtonReturn is assumed to mean "Cancel".
            if (recoveryOption == NSAlertFirstButtonReturn) {
                result = SSYAlertRecoveryAttemptedAsynchronously ;
                [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:recoveryAttempterUrl
                                                                                       display:YES
                                                                             completionHandler:^void(
                                                                                                     NSDocument* newDocument,
                                                                                                     BOOL documentWasAlreadyOpen,
                                                                                                     NSError* documentOpeningError) {
                                                                                 if (newDocument) {
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
                                                                                         [recoveryAttempter attemptRecoveryFromError:deepestRecoverableError
                                                                                                                      recoveryOption:recoveryOption
                                                                                                                            delegate:delegate
                                                                                                                  didRecoverSelector:didRecoverSelector
                                                                                                                         contextInfo:(__bridge void *)(infoDictionary)] ;
                                                                                     }
                                                                                     else if ([recoveryAttempter respondsToSelector:@selector(attemptRecoveryFromError:optionIndex:delegate:didRecoverSelector:contextInfo:)]) {
                                                                                         /* This is an error produced by Cocoa.
                                                                                          In particular, in macOS 10.7, it might be one like this:
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
                                                                                         
                                                                                         [recoveryAttempter attemptRecoveryFromError:deepestRecoverableError
                                                                                                                         optionIndex:recoveryOptionIndex
                                                                                                                            delegate:delegate
                                                                                                                  didRecoverSelector:didRecoverSelector
                                                                                                                         contextInfo:(__bridge void *)(infoDictionary)] ;
                                                                                     }
                                                                                     else if ([recoveryAttempter respondsToSelector:@selector(attemptRecoveryFromError:recoveryOption:)]) {
                                                                                         [recoveryAttempter attemptRecoveryFromError:deepestRecoverableError
                                                                                                                      recoveryOption:recoveryOption] ;
                                                                                     }
                                                                                     else if ([recoveryAttempter respondsToSelector:@selector(attemptRecoveryFromError:optionIndex:)]) {
                                                                                         // This is an error produced by Cocoa.
                                                                                         NSInteger recoveryOptionIndex = [self recoveryOptionIndexForRecoveryOption:recoveryOption] ;
                                                                                         [recoveryAttempter attemptRecoveryFromError:deepestRecoverableError
                                                                                                                         optionIndex:recoveryOptionIndex] ;
                                                                                     }
                                                                                     else if (recoveryAttempter != nil) {
                                                                                         NSLog(@"Internal Error 342-5587.  Given Recovery Attempter %@ does not respond to any attemptRecoveryFromError:... method", recoveryAttempter) ;
                                                                                     }
                                                                                 }
                                                                             }] ;
            }
        }
    }
	
	return result ;
}

- (IBAction)help:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:[self helpAnchorString]
											   inBook:[[NSBundle mainAppBundle] objectForInfoDictionaryKey:@"CFBundleHelpBookName"]] ;
}

- (IBAction)support:(id)sender {
	[SSYAlert supportError:[self errorPresenting]] ;
}

+ (void)supportError:(NSError*)error {
	NSString* appName = [[NSBundle mainAppBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"] ;
	// Note: If you'd prefer the app name to be localized, use "CFBundleName" instead.
	NSString* appVersion = [[NSBundle mainAppBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] ;
	NSString* appVersionString = [[NSBundle mainAppBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ;
	NSString* systemDescription = [SSYSystemDescriber softwareVersionString] ;
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
			NSString* longDescription = [error longDescription] ;

			NSString* filename = [NSString stringWithFormat:
								  @"%@-Error-%lx.txt",
								  [[NSBundle mainAppBundle] objectForInfoDictionaryKey:@"CFBundleName"],
								  (long)[NSDate timeIntervalSinceReferenceDate]] ;
			NSString* filePath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"] stringByAppendingPathComponent:filename] ;
			NSError* writeError = nil ;
			NSString* text = [NSString stringWithFormat:
							  @"%@ %@.\n\n%@\n%@\n%@\n\n%@",
							  @"*** Note to user***  It is possible that this file may have some of your private "
							  @"information in it.  Please skim through it before sending.  "
							  @"Replace any text you don't want to send with the word 'REDACTED', then save this file.\n\n"
							  @"To zip this file, select it in Finder, then execute a secondary click.  (A secondary click "
							  @"means to click it while holding down the 'control' key, or to tap with two fingers if you "
                              @"have a trackpad, or to use the secondary button if you have a multi-button mouse.)  "
							  @"From the contextual menu which appears, click 'Compress...' "
							  @"A new file with a name ending in .zip will appear.\n\n"
							  @"Please send the .zip file to our support team.  Thank you for helping us to support",
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
				NSString* msg = [[NSString alloc] initWithFormat:
                                 NSLocalizedString(@"A file named \"%@\" has just been written to your desktop.\n\nThe extended error information in this file may help our Support crew to solve the problem.\n\nPlease review this file for any too-sensitive information, zip it, and then attach the .zip to your email.", nil),
                                 filename] ;
				[SSYAlert runModalDialogTitle:nil
									  message:msg
									  buttons:nil] ;
#if !__has_feature(objc_arc)
                [msg release] ;
#endif
                
				mailableDescription = [NSString stringWithFormat:
									   @"******   I M P O R T A N T   I N S T R U C T I O N S   ******\n\n"
									   @"*** Please look on your Desktop and find the file named %@ ***\n"
                                       @"Review for your privacy, zip and ATTACH it before sending this.\n"
                                       @"To zip a file, perform a secondary click (right-click or control-click)\n"
                                       @"on it, then from the contextual menu which appears, click 'Compress ...'.\n"
                                       @"Attach the .zip file which appears.  Thank you.\n",
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
							 NSLocalizedString(@"Please insert any additional information regarding what happened that might help us to investigate this problem:", nil),
							 appName,
							 appVersionString,
							 appVersion,
							 systemDescription,
							 mailableDescription] ;
	
	[SSYMailto emailTo:[SSYAlert supportEmailString]
			   subject:[NSString stringWithFormat:
						@"%@ Error %ld",
						appName,
						(long)[error code]]
				  body:body] ;
}

/*!
 @brief    This method will *always* run when a button is clicked
 
 @details  -sheetDidEnd::: *may* also run when a button is clicked,
 and if it does, it will run a little prior to this one, in the same
 run loop cycle.
 */
- (IBAction)clickedButton:(id)sender {	
	// For classic button layout
	// Button1 --> tag=NSAlertFirstButtonReturn
	// Button2 --> tag=NSAlertSecondButtonReturn
	// Button3 --> tag=NSAlertThirdButtonReturn
	[self setAlertReturn:[sender tag]] ;

	if (m_dontGoAwayUponButtonClicked) {
        if ([self isDoingModalDialog]) {
            [NSApp stopModal] ;
            [self setIsDoingModalDialog:NO] ;
        }
    }
    else {
		[self goAway] ;
	}
	
	if ([self clickTarget]) {
        [[self clickTarget] recklessPerformSelector:[self clickSelector]
                                             object:self] ;
		[self setIsDoingModalDialog:NO] ;
	}
	
	if ([self checkboxState] == NSOnState) {
		[[self checkboxInvocation] invoke] ;
	}

}

- (void)setTargetActionForButton:(NSButton*)button {
	[button setTarget:self] ;
	[button setAction:@selector(clickedButton:)] ;
}

- (void)stealObjectsFromAppleAlerts {
    NSAlert* nsAlert = [[NSAlert alloc] init] ;
    
    NSImageView* iconView ;
    NSRect frame = NSMakeRect(0.0, 0.0, 64.0, 64.0) ;
    NSImage* badge ;
    
    // Steal localized word for "alert"
    [self setWordAlert:[nsAlert messageText]] ;

    // Steal the icon.  (Could also get this from NSBundle I suppose.)
    NSImage* rawIcon = [nsAlert icon] ;
#if !__has_feature(objc_arc)
    [nsAlert release] ;
#endif
    NSImage* image = [[NSImage alloc] initWithSize:(NSMakeSize(64.0, 64.0))] ;
    [image lockFocus] ;
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    CGFloat borderWength = 8.0 ;
    [rawIcon drawInRect:NSMakeRect(
                                   borderWength,
                                   borderWength,
                                   [image size].width - 2 * borderWength,
                                   [image size].height - 2 * borderWength)
               fromRect:NSZeroRect
              operation:NSCompositeSourceOver
               fraction:1.0] ;
    [image unlockFocus] ;
    
    // Set raw icon as "informational"
    iconView = [[NSImageView alloc] initWithFrame:frame] ;
    NSImage* imageCopy = [image copy] ;
    iconView.image = imageCopy ;
    [self setIconInformational:iconView] ;
#if !__has_feature(objc_arc)
    [iconView release] ;
    [imageCopy release] ;
#endif
    
    // Badge with yellow and set as "warning"
    badge = [SSYVectorImages imageStyle:SSYVectorImageStyleHexagon
                                 wength:64.0
                                  color:[NSColor yellowColor]
                          rotateDegrees:90.0
                                  inset:0.0] ;
    [image lockFocus] ;
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    [badge drawInRect:NSMakeRect(
                                 [image size].width / 2,
                                 0,
                                 [image size].width / 2,
                                 [image size].height / 2)
             fromRect:NSZeroRect
            operation:NSCompositeSourceOver
             fraction:0.75] ;
    [image unlockFocus] ;
    iconView = [[NSImageView alloc] initWithFrame:frame] ;
    imageCopy = [image copy] ;
    iconView.image = imageCopy ;
    [self setIconWarning:iconView] ;
#if !__has_feature(objc_arc)
    [iconView release] ;
    [imageCopy release] ;
#endif
    
    // Badge with red and set as "critical"
    badge = [SSYVectorImages imageStyle:SSYVectorImageStyleHexagon
                                 wength:64.0
                                  color:[NSColor redColor]
                          rotateDegrees:90.0
                                  inset:0.0] ;
    [image lockFocus] ;
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    [badge drawInRect:NSMakeRect(
                                 [image size].width / 2,
                                 0,
                                 [image size].width / 2,
                                 [image size].height / 2)
             fromRect:NSZeroRect
            operation:NSCompositeSourceOver
             fraction:0.75] ;
    [image unlockFocus] ;
    iconView = [[NSImageView alloc] initWithFrame:frame] ;
    imageCopy = [image copy] ;
    iconView.image = imageCopy ;
    [self setIconCritical:iconView] ;
#if !__has_feature(objc_arc)
    [iconView release] ;
    [image release] ;
    [imageCopy release] ;
#endif

    /* Thanks to Brian Dunagan for the few lines of compositing code used above.
     http://bdunagan.com/2010/01/25/cocoa-tip-nsimage-composites/ */
}


#pragma mark * Public Methods for Setting views

- (void)setSupportEmail {
	if ([SSYAlert supportEmailString] != nil) {
		NSButton* button = [self supportButton] ;
		if (!button) {
			// The image is 32 and the bezel border on each side is 2*2=4.
			// However, testing shows that we need 38.  Oh, well.
			NSRect frame = NSMakeRect(0, 0, 38.0, 38.0) ;
			button = [[NSButton alloc] initWithFrame:frame] ;
			[button setBezelStyle:NSRegularSquareBezelStyle] ;
			[button setTarget:self] ;
			[button setAction:@selector(support:)] ;
			NSString* imagePath = [[NSBundle mainAppBundle] pathForResource:@"support"
																  ofType:@"tif"] ;
			NSImage* image = [[NSImage alloc] initByReferencingFile:imagePath] ;
			[button setImage:image] ;
			NSString* toolTip = [[self class] contactSupportToolTip] ;
			[button setToolTip:toolTip] ;
			[self setSupportButton:button] ;
			[[[self window] contentView] addSubview:button] ;
#if !__has_feature(objc_arc)
            [image release] ;
            [button release] ;
#endif
		}
		
		[button setEnabled:YES] ;
	}
	else {
		[[self supportButton] removeFromSuperviewWithoutNeedingDisplay] ;
		[self setSupportButton:nil] ;
	}
}

- (void)setWindowTitle:(NSString*)title {
	if (!title) {
		title = [[NSBundle mainAppBundle] objectForInfoDictionaryKey:@"CFBundleName"] ; // CFBundleName may be localized
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
#if !__has_feature(objc_arc)
			[progressBar_ release] ;
#endif
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
			[[[self window] contentView] addSubview:textView] ;
#if !__has_feature(objc_arc)
            [textView release] ;
#endif
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
#if !__has_feature(objc_arc)
    [textView autorelease] ;
#endif
    return textView ;
}

#define MIN_TEXT_FIELD_WIDTH 250.0
#define MAX_TEXT_FIELD_WIDTH 500.0
#define MAX_TEXT_FIELD_HEIGHT 450.0

- (void)setSmallText:(NSString*)text {
    [self.smallTextScrollView removeFromSuperviewWithoutNeedingDisplay] ;
    [self setSmallTextScrollView:nil] ;
    [self setSmallTextView:nil] ;

    CGFloat width = [self rightColumnMinimumWidth] ;
    if (width < MIN_TEXT_FIELD_WIDTH) {
        width = MIN_TEXT_FIELD_WIDTH ;
    }
    if (width > [self rightColumnMaximumWidth]) {
        width = [self rightColumnMaximumWidth] ;
    }
    if (text) {
        NSRect scrollViewFrame = NSMakeRect(0.0, 0.0, width, MAX_TEXT_FIELD_HEIGHT) ;
        NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:scrollViewFrame] ;
        NSSize contentSize = [scrollView contentSize] ;
        
        [scrollView setBorderType:NSNoBorder] ;
        scrollView.autohidesScrollers = YES ;
        [scrollView setHasVerticalScroller:YES] ;
        [scrollView setHasHorizontalScroller:NO] ;
        [scrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable] ;
        scrollView.drawsBackground = NO ;
        
        NSTextView* textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height)] ;
        [textView setMinSize:NSMakeSize(0.0, contentSize.height)] ;
        [textView setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)] ;
        textView.editable = NO ;
        textView.selectable = YES ;
        [textView setVerticallyResizable:YES] ;
        [textView setHorizontallyResizable:NO] ;
        [textView setAutoresizingMask:NSViewWidthSizable] ;
        [textView.textContainer setContainerSize:NSMakeSize(contentSize.width, FLT_MAX)] ;
        [textView.textContainer setWidthTracksTextView:YES] ;
        textView.string = text ;
        textView.drawsBackground = NO ;
        textView.font = [SSYAlert smallTextFont] ;

        /*
         The following line will sometimes print to the console, 14 times:
         CGAffineTransformInvert:
         */
        [scrollView setDocumentView:textView] ;
        [self.window.contentView addSubview:scrollView] ;
        self.smallTextScrollView = scrollView ;
        self.smallTextView = textView ;
#if !__has_feature(objc_arc)
        [scrollView release] ;
        [textView release] ;
#endif
    }
}

- (NSString*)smallText {
	return [[self smallTextView] string] ;
}

- (void)setIconStyle:(NSInteger)iconStyle {
	NSImageView* icon_ ;
	switch (iconStyle) {
		case SSYAlertIconNoIcon:
			icon_ = nil ;
			break ;
		case SSYAlertIconInformational:
			icon_ = [self iconInformational] ;
			break ;
        case SSYAlertIconWarning:
            icon_ = [self iconWarning] ;
            break ;
		case SSYAlertIconCritical:
        default:
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
			button = [SSYAlert makeButton] ;
			[button setTag:NSAlertFirstButtonReturn] ;
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
			button = [SSYAlert makeButton] ;
			[button setTag:NSAlertSecondButtonReturn] ;
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
			button = [SSYAlert makeButton] ;
			[button setTag:NSAlertThirdButtonReturn] ;
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

- (void)setButton4Title:(NSString*)title {
    if (title) {
        NSButton* button ;
        if (!(button = [self button4])) {
            button = [SSYAlert makeButton] ;
            [button setTag:SSYAlertFourthButtonReturn] ;
            [self setTargetActionForButton:button] ;
            [self setButton4:button] ;
            [[[self window] contentView] addSubview:button] ;
        }
        
        [button setEnabled:YES] ;
        [button setTitle:title] ;
        //[button setWidthToFitTitlePlusTotalMargins:40] ;
        [button sizeToFitIncludingNiceMargins] ;
    }
    else if (title && ![title length]) {
        [[self button4] setEnabled:NO] ;
    }
    else {
        [[self button4] removeFromSuperviewWithoutNeedingDisplay] ;
        [self setButton4:nil] ;
    }
}

- (void)setHelpAnchor:(NSString*)anchor {
	// This one is tricky since we've got two ivars to worry about:
	// NSButton* helpButton and NSString* helpAnchorString
	if (anchor) {
		NSButton* button = [self helpButton] ;
		if (!button) {
			NSRect frame = NSMakeRect(0, 0, 21.0, 23.0) ;
				// because help button in Interface Builder is 21x23
				// It seems there should be an NSHelpButtonSize constant,
				// but I can't find any.
			button = [[NSButton alloc] initWithFrame:frame] ;
			[button setBezelStyle:NSHelpButtonBezelStyle] ;
			[button setTarget:self] ;
			[button setAction:@selector(help:)] ;
			[button setTitle:@""] ;
			[self setHelpButton:button] ;
			[[[self window] contentView] addSubview:button] ;
#if !__has_feature(objc_arc)
			[button release] ;
#endif
		}
		
		[button setEnabled:YES] ;
	}
	else {
		[[self helpButton] removeFromSuperviewWithoutNeedingDisplay] ;
		[self setHelpButton:nil] ;
	}
	[self setHelpAnchorString:anchor] ;
}

- (NSString*)helpAnchor {
    return [self helpAnchorString] ;
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

- (void)setButton4Enabled:(BOOL)enabled {
    NSButton* button = [self button4] ;
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
#if !__has_feature(objc_arc)
			[button release] ;
#endif
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

- (void)addOtherSubview:(NSView*)subview atIndex:(NSInteger)index {
    if (index > [[self otherSubviews] count]) {
        index = [[self otherSubviews] count] ;
    }
	[[self otherSubviews] insertObject:subview
							   atIndex:index] ;
	[[[self window] contentView] addSubview:subview] ;
}

- (void)removeOtherSubviewAtIndex:(NSInteger)index {
	NSMutableArray* otherSubviews_ = [self otherSubviews] ;
	NSView* otherSubview = [otherSubviews_ objectAtIndex:index] ;
	[otherSubviews_ removeObjectAtIndex:index] ;
	[otherSubview removeFromSuperviewWithoutNeedingDisplay] ;
}

- (void)removeAllOtherSubviews {
	NSMutableArray* otherSubviews_ = [self otherSubviews] ;
	NSInteger n = [otherSubviews_ count] - 1 ;
	for ( ; n>=0; n--) {
		[self removeOtherSubviewAtIndex:n] ;
	}
}

- (void)setIndeterminate:(BOOL)indeterminate {
    NSAssert([self progressBar], @"Internal Error 423-9496.  For %s to work, you must *first* -setShowsProgressBar:YES", __PRETTY_FUNCTION__) ;
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
    [self setButton4Title:nil] ;
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
	[self setRightColumnMaximumWidth:CGFLOAT_MAX] ;
}

#pragma mark * Public Methods for Displaying and Running

- (void)errorSheetDidEnd:(NSWindow *)sheet
			  returnCode:(NSInteger)returnCode
			 contextInfo:(void *)contextInfo {
	// Note: At this point, returnCode is always 0, no matter which 
	// button the user clicks.  I'm not sure what Apple had in mind,
	// or what the corect idiom is.  But this fixes it:
	returnCode = (NSInteger)[self alertReturn] ;
	// Could also have used [[sheet windowController] alert return]
   
	[sheet orderOut:self];

	[[self class] tryRecoveryAttempterForError:[self errorPresenting]
								   recoveryOption:returnCode
								   contextInfo:(__bridge NSMutableDictionary *)(contextInfo)] ;
}

/*!
 @brief    This method *may* run when a button is clicked

 @details  It does not run (by design) if the receiver was given a different
 clickTarget and clickAction.  It also seems to not run (I'm not sure why) if
 the receiver is shown as a sheet
 
 -clickedButton: will *always* run when a button is clicked, a little later
*/
- (void)sheetDidEnd:(NSWindow *)sheet
		 returnCode:(NSInteger)returnCode
		contextInfo:(void *)contextInfo {
	[self setAlertReturn:returnCode] ;
    [sheet orderOut:self] ;
}

- (void)setDontAddOkButton {
	m_dontAddOkButton = YES ;
}

- (void)setButton1IfNeeded {
	if (![self button1] && !m_dontAddOkButton) {
		[self setButton1Title:[NSString localize:@"ok"]] ;
	}
}

- (void)prepareAsSheetOnWindow:(NSWindow*)docWindow {
    [self setButton1IfNeeded] ;
    
    // if () conditions added in BookMacster 1.5.7 since button1 target and action
    // should always be set by setButton1Title:
    // If the debugger stops here, figure out why!!
    if (([[self button1] target] == nil) && !m_dontAddOkButton) {
        [[self button1] setTarget:self] ;
#if DEBUG
        NSLog(@"Internal Error 928-9983") ;
#endif
    }
    if (([[self button1] action] == NULL) && !m_dontAddOkButton) {
        [[self button1] setAction:@selector(clickedButton:)] ;
#if DEBUG
        NSLog(@"Internal Error 135-5614") ;
#endif
    }
    
    [self doooLayout] ;
    
    if ([self progressBarShouldAnimate]) {
        [[self progressBar] startAnimation:self] ;
    }
    
    [self setIsDoingModalDialog:YES] ;
    
    [self setDocumentWindow:docWindow] ;
}

- (void)runModalSheetOnWindow:(NSWindow*)docWindow
            completionHandler:(void (^)(NSModalResponse returnCode))handler {
    if (docWindow) {
        [self prepareAsSheetOnWindow:docWindow];
        
        [docWindow beginSheet:[self window]
            completionHandler:handler] ;
    }
}

- (void)runModalSheetOnWindow:(NSWindow*)docWindow
                modalDelegate:(id)modalDelegate
               didEndSelector:(SEL)didEndSelector
                  contextInfo:(void*)contextInfo {
	if (docWindow) {
        NSAssert(((modalDelegate != nil) == (didEndSelector != nil)), @"222 modalDelegate vs. didEndSelector inconsistency.") ;
        if (!modalDelegate) {
            modalDelegate = self ;
        }
        
        if (!didEndSelector) {
            didEndSelector = @selector(sheetDidEnd:returnCode:contextInfo:) ;
        }
        
        [self prepareAsSheetOnWindow:docWindow];
		
        [docWindow beginSheet:[self window]
            completionHandler:^void(NSModalResponse modalResponse) {
                NSWindow* window = [self window] ;
                NSInvocation* invocation = [NSInvocation invocationWithTarget:modalDelegate
                                                                     selector:didEndSelector
                                                              retainArguments:YES
                                                            argumentAddresses:&window, &modalResponse, &contextInfo] ;
                [invocation invoke] ;
            }] ;
	}
}

- (void)retainToStatic {
    [static_alertHangout addObject:self] ;
}

- (void)releaseFromStatic {
    [static_alertHangout removeObject:self] ;
}

- (void)runModalDialog {
	// End current modal session, if any
	[self endModalSession] ;
	
	[self setButton1IfNeeded] ;	
	[self doooLayout] ;
	
	BOOL progressBarWasAnimating = NO ;
	
	if (self.progressBarShouldAnimate) {
		progressBarWasAnimating = YES ;
		[[self progressBar] stopAnimation:self] ;
	}
	
	[self setIsDoingModalDialog:YES] ;	

	[[self window] orderFrontRegardless] ;
    [NSApp activateIgnoringOtherApps:YES] ;  // was deprecated SetFrontProcessWithOptions()
    NSWindow* window = [self window] ;
    if (window) {
        // The following method will also make the window "key" and "visible"
        [NSApp runModalForWindow:[self window]] ;
        
        // Will block here until user clicks a button //
        
        if (progressBarWasAnimating) {
            [[self progressBar] startAnimation:self] ;
        }
    }
    else {
        NSLog(@"Internal Error 624-9229 Don't re-use SSYAlert instances!") ;
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
		NSLog(@"Internal Error 359-0751  Modal session %p already in progress", (void*)[self modalSession]) ;
	}
}

- (void)endModalSession {
	if ([self modalSession]) {
		NSInteger response = [NSApp runModalSession:[self modalSession]] ;
		BOOL done = (response != NSModalResponseContinue) ;
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

- (void)setRightColumnMinimumWidthForNiceAspectRatio {
	NSInteger nChars = [[[self window] contentView] longestStringLengthInAnySubview] ;
	CGFloat	width = 16 * sqrt(nChars) ;
	// Subject to upper and lower bounds...
    if (width < MIN_TEXT_FIELD_WIDTH) {
        width = MIN_TEXT_FIELD_WIDTH ;
    }
    if (width > MAX_TEXT_FIELD_WIDTH) {
        width = MAX_TEXT_FIELD_WIDTH ;
    }
	[self setRightColumnMinimumWidth:width] ;
}

#define BUTTON_SPACING 3.0
#define CANCEL_BUTTON_SPACING 20.0
#define SUBFRAME_SPACING 24.0
#define CONTROL_VERTICAL_SPACING 14.0

/*!
 @details  Name of this method has been designed to avoid confusion and/or
 conflict with Cocoa's -doLayout method.
 */
- (void)doooLayout {
	// used for looping through other subviews
	NSEnumerator* e ;
	NSView* subview ;
	
	
	// X-AXIS LAYOUT
	
	// In the x-axis, the window consists of two columns,
	// left and right
	
	CGFloat t ; // temporary variable
	
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
	[self.smallTextScrollView setLeftEdge:t] ;
	[self.checkbox setLeftEdge:t] ;
	e = [self.otherSubviews objectEnumerator] ;
	while((subview = [e nextObject])) {
		[subview setLeftEdge:t] ;
	}
	
    if (self.buttonLayout == SSYAlertButtonLayoutClassic) {
        [self.button2 setLeftEdge:t] ;
    }
	
	CGFloat rightSubframeWidth = 0.0 ;
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
    if (self.button4) {
        rightSubframeWidth += [button4 width] ;
        rightSubframeWidth += BUTTON_SPACING ;
    }
	
	if ([self rightColumnMinimumWidth] == 0) {
		[self setRightColumnMinimumWidthForNiceAspectRatio] ;
	}
	
	// The width of the right column (the stuff in the right of the window)
	// will be the width of
	//	(a) the row of buttons (just calculated)
	//	(b) the width of the checkbox
	//  (c) self.rightColumnMinimumWidth
	// whichever is greatest...
    if (rightSubframeWidth < checkbox.width) {
        rightSubframeWidth = checkbox.width ;
    }
    if (rightSubframeWidth < self.rightColumnMinimumWidth) {
        rightSubframeWidth = self.rightColumnMinimumWidth ;
    }
    
	// and then constrained by its maximum
    if (rightSubframeWidth > self.rightColumnMaximumWidth) {
        rightSubframeWidth = self.rightColumnMaximumWidth;
    }
	
	[self.progressBar setWidth:rightSubframeWidth] ;
	[self.titleTextView setWidth:rightSubframeWidth] ;
	[self.smallTextScrollView setWidth:rightSubframeWidth] ;
	[self.checkbox setWidth:rightSubframeWidth] ;
	e = [self.otherSubviews objectEnumerator] ;
	while ((subview = [e nextObject])) {
		[subview setWidth:rightSubframeWidth] ;
		if ([subview respondsToSelector:@selector(sizeToFit)]) {
			[(NSControl*)subview sizeToFit] ;
		}
	}
	
	t += rightSubframeWidth ;
	CGFloat contentWidth = t + WINDOW_EDGE_SPACING ;

    
    NSMutableArray* buttonsLeftToRight = [[NSMutableArray alloc] init] ;
    if (self.buttonLayout == SSYAlertButtonLayoutClassic) {
        if (self.button1) {
            [self.button1 setRightEdge:t] ;
            t = [self.button1 leftEdge] - BUTTON_SPACING ;
            [buttonsLeftToRight addObject:self.button1] ;
        }
        if (self.button2) {
            // Button 2 goes on the left, was placed earlier
            [buttonsLeftToRight insertObject:self.button2
                                     atIndex:0] ;
        }
        if (self.button3) {
            [self.button3 setRightEdge:t] ;
            t = [self.button3 leftEdge] - BUTTON_SPACING ;
            [buttonsLeftToRight insertObject:self.button3
                                     atIndex:1] ;
        }
        if (self.button4) {
            [self.button4 setRightEdge:t] ;
            [buttonsLeftToRight insertObject:self.button2
                                     atIndex:1] ;
        }
    }
    else {
        if (self.button1) {
            [self.button1 setRightEdge:t] ;
            t = [self.button1 leftEdge] - BUTTON_SPACING ;
            [buttonsLeftToRight insertObject:self.button1
                                     atIndex:0] ;
        }
        if (self.button2) {
            [self.button2 setRightEdge:t] ;
            t = [self.button2 leftEdge] - BUTTON_SPACING ;
            [buttonsLeftToRight insertObject:self.button2
                                     atIndex:0] ;
        }
        if (self.button3) {
            [self.button3 setRightEdge:t] ;
            t = [self.button3 leftEdge] - BUTTON_SPACING ;
            [buttonsLeftToRight insertObject:self.button3
                                     atIndex:0] ;
        }
        if (self.button4) {
            [self.button4 setRightEdge:t] ;
            [buttonsLeftToRight insertObject:self.button4
                                     atIndex:0] ;
        }
    }
	
	// Y-AXIS LAYOUT
	// First, we have to set the final height of the variable-height subviews.
	// Note that we could not have done this until now, because the height of
	// the text fields depends on their width, which was just set in the 
	// previous section of code.
	[self.titleTextView sizeHeightToFitAllowShrinking:self.allowsShrinking] ;
	[self.smallTextScrollView sizeHeightToFitAllowShrinking:self.allowsShrinking] ;
	for (subview in self.otherSubviews) {
		[(NSView*)subview sizeHeightToFitAllowShrinking:self.allowsShrinking] ;
	}
	
	// The height of the contentView
	// will be the width of either
	//	(a) the stuff in the left column
	//	(b) the stuff in the right column
	// whichever is greater...
	NSInteger nSubviews ;
	
	// Compute required height of left column
	nSubviews = 0 ;
	CGFloat leftHeight = 0 ;
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
	CGFloat rightHeight = 0 ;
	if (self.titleTextView != nil) {
		rightHeight += [self.titleTextView height] ;
		nSubviews++ ;
	}
	if (self.progressBar != nil) {
		rightHeight += [self.progressBar height] ;
		nSubviews++ ;
	}
	if (self.smallTextScrollView != nil) {
		rightHeight += [self.smallTextScrollView height] ;
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
    NSInteger otherSubviewIndex = 0 ;
	for (subview in self.otherSubviews) {
        otherSubviewIndex++ ;
        rightHeight += [subview height] ;
        if (![self noSpaceBetweenOtherSubviews] || otherSubviewIndex == self.otherSubviews.count) {
            nSubviews++ ;
        }
	}
	rightHeight += (nSubviews - 1) * CONTROL_VERTICAL_SPACING ;
	
    CGFloat contentHeight = leftHeight ;
    if (contentHeight < rightHeight) {
        contentHeight = rightHeight ;
    }
    
    contentHeight += 2 * WINDOW_EDGE_SPACING ;
    
	// Set y position of each subview
	if (self.icon) {
		[self.icon setTop:(contentHeight - WINDOW_EDGE_SPACING)] ;
	}
	
	
	// It is true that the bottom of the three buttons should already be set
	// correctly  as they were stolen from the Apple alert.
	// However, in order to have a uniform look in the case where
	// there are no buttons, I start over from 0 at the bottom.
	// and figure it out myself using my WINDOW_EDGE_SPACING
    t = WINDOW_EDGE_SPACING ;
	
	if (self.button1 != nil) {
		[self.button1 setBottom:t] ;
		[self.button2 setBottom:t] ;
		[self.button3 setBottom:t] ;
        [self.button4 setBottom:t] ;
		t += ([self.button1 height] + CONTROL_VERTICAL_SPACING) ;
	}
	
	if (self.checkbox != nil) {
		[self.checkbox setBottom:t] ;
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
	
	if (self.smallTextScrollView != nil) {
		[self.smallTextScrollView setTop:t] ;
		t -= ([self.smallTextScrollView height] + CONTROL_VERTICAL_SPACING) ;
	}
	
	e = [self.otherSubviews objectEnumerator] ;
    otherSubviewIndex = 0 ;
	while ((subview = [e nextObject]) != nil) {
        otherSubviewIndex++ ;
		[subview setTop:t] ;
		t -= [subview height] ;
        if (!self.noSpaceBetweenOtherSubviews || otherSubviewIndex == self.otherSubviews.count) {
            t -= CONTROL_VERTICAL_SPACING ;
        }
	}
	
	// Next, we'll resize the window's contentView
	// First, make sure that none of the subviews will move 
	// due to autoresizing.  (If this window were resizable, we'd
	// store the autoresize mask values in an array, to restore later)
	e = [[self.window.contentView subviews] objectEnumerator] ;
	while ((subview = [e nextObject])) {
		[subview setAutoresizingMask:NSViewNotSizable] ;
	}
	[(NSView*)[[self window] contentView] setWidth:contentWidth] ;
	[(NSView*)[[self window] contentView] setHeight:contentHeight] ;
	
	// Now that all otherSubviews have been initialized and presumably run 
	// through their validation routines and sent us messages to set our ivars
	// isEnabled and whyDisabled, we can access and forward them to button1.
	[self.button1 setEnabled:[self isEnabled]] ;
	[self.button1 setToolTip:[self whyDisabled]] ;

    // Set up the keyboard loop for tabbing
    NSView* firstResponder = nil ; // redundant but necessary because I don't see any safe way to set the the first responder of a NSWindow to nil or other convenient known object.  -resignFirstResponder says "Never invoke this method directly".
    NSView* previousResponder = nil ;
    NSView* responder = nil ;
    NSView* aResponder ;
    for (aResponder in self.otherSubviews) {
        [aResponder makeNextKeyViewOfWindow:self.window
                             firstResponder:&firstResponder
                          previousResponder:&previousResponder] ;
        responder = aResponder ;
    }
    if (self.checkbox) {
        responder = self.checkbox ;
        [responder makeNextKeyViewOfWindow:self.window
                            firstResponder:&firstResponder
                         previousResponder:&previousResponder] ;
    }
    if (self.helpButton) {
        responder = self.helpButton ;
        [responder makeNextKeyViewOfWindow:self.window
                            firstResponder:&firstResponder
                         previousResponder:&previousResponder] ;
    }
    if (self.supportButton) {
        responder = self.supportButton ;
        [responder makeNextKeyViewOfWindow:self.window
                            firstResponder:&firstResponder
                         previousResponder:&previousResponder] ;
    }
    for (aResponder in buttonsLeftToRight) {
        [aResponder makeNextKeyViewOfWindow:self.window
                             firstResponder:&firstResponder
                          previousResponder:&previousResponder] ;
        responder = aResponder ;
    }
    // End.  Close the loop
	[responder setNextKeyView:firstResponder] ;
    
    // Set key equivalents of buttons
    [[buttonsLeftToRight lastObject] setKeyEquivalent:@"\r"] ;
    if (self.buttonLayout == SSYAlertButtonLayoutClassic) {
        [self.button2 setKeyEquivalent:@"\033"] ;  // escape key
    }

#if !__has_feature(objc_arc)
    [buttonsLeftToRight release] ;
#endif
    
    // Resize the window itself, and display window and views as needed
	[self.window setFrameToFitContentViewThenDisplay:YES] ;
	// argument must be YES to avoid flicker.  Counterintuitive,
	// but it took me the better part of a day to discover that.
	
	// Reposition the window so that the title bar remains at the original "top center"
	NSRect frame = [self.window frame] ;
	frame.origin.x = self.windowTopCenter.x - frame.size.width/2 ;
	frame.origin.y = self.windowTopCenter.y - frame.size.height ;
    if (frame.origin.y < 0.0) {
        frame.origin.y = 0.0 ;
    }

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
	[self doooLayout] ;
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
	[self endModalSession] ;
	
	if ([self isDoingModalDialog]) {
		[NSApp stopModal] ;
		[self setIsDoingModalDialog:NO] ;
	}
	
	if ([[self window] isSheet]) {
		[self setDocumentWindow:nil] ;
        
        if (self.window) {
            [self.window.sheetParent endSheet:self.window
                                   returnCode:[self alertReturn]] ;
            /* Completion handler has executed and returned. */
        }

        [self.window close] ;
        [self.window orderOut:self] ;
    }
	else {
		/* We're a freestanding dialog. */
		[self.window close] ;
	}

    [self releaseFromStatic] ;
}

- (void)someWindowDidBecomeKey:(NSNotification*)note {
    if ([note object] != [self window]) {
        [self goAway] ;
    }
}

- (void)startObservingOtherWindowsToBecomeKey {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(someWindowDidBecomeKey:)
                                                 name:NSWindowDidBecomeKeyNotification
                                               object:nil] ;
}

- (void)stopObservingOtherWindowsToBecomeKey {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSWindowDidBecomeKeyNotification
                                                  object:nil] ;
    
}

- (void)setGoAwayWhenAnotherWindowBecomesKey:(BOOL)yn {
    if (yn) {
        [self startObservingOtherWindowsToBecomeKey] ;
    }
    else {
        [self stopObservingOtherWindowsToBecomeKey] ;
    }
}

#pragma mark * Public Methods for Getting Status

- (BOOL)modalSessionRunning {
	BOOL running ;
	if ([self modalSession]) {
		NSInteger response = [NSApp runModalSession:[self modalSession]] ;
		running = (response == NSModalResponseContinue) ;
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

- (id)init {
	if (!NSApp) {
		// See http://lists.apple.com/archives/Objc-language/2008/Sep/msg00133.html ...
        //TODO: Should also go here if process is background type, but API ProcessInformationCopyDictionary() I've used to do that has been deprecated :(
#if !__has_feature(objc_arc)
		[super dealloc] ;
#endif
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
    /* NSWindow has nonstandard memory management.  Note that, under non-ARC,
     we do *not* release this alloc-initted 'window', and the static analyzer
     does not complain about this!  If we do [window release], then the static
     analyzer does not complain either (!!), but we get a runtime crash when
     this window is autoreleased!  Read comments in my project NSWindowLifer. */
	NSString* appName = [[NSBundle mainAppBundle] objectForInfoDictionaryKey:@"CFBundleName"] ; // CFBundleName may be localized
	if (appName) {
		[window setTitle:appName] ;
	}
	[self setWindow:window] ;
	[window setWindowController:self] ;
	[window setReleasedWhenClosed:YES] ;
	[window center] ;

	// Invoke designated initializer for super, NSWindowController
	self = [super initWithWindow:window] ;

	if (self) {
		[self stealObjectsFromAppleAlerts] ;
		
		// Default values
//		self.rightColumnMinimumWidth = DEFAULT_MIN_TEXT_FIELD_WIDTH ;
		self.rightColumnMaximumWidth = CGFLOAT_MAX ;
		self.allowsShrinking = YES ;
		self.titleMaxChars = 500 ;
		self.smallTextMaxChars = 1500 ;
		self.isEnabled = YES ;
		
		NSPoint windowTopCenter_ = [window frame].origin ;
		windowTopCenter_.x += WINDOW_PROTOTYPE_WIDTH/2 ;
		windowTopCenter_.y += WINDOW_PROTOTYPE_HEIGHT ;  // move from bottom to top
		self.windowTopCenter = windowTopCenter_ ;
        
        [self retainToStatic] ;
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
					 [NSString stringWithFormat:@"%ld", (long)[error code]]] ;
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
            if ([recoveryOptions count] > 3) {
                [self setButton4Title:[recoveryOptions objectAtIndex:2]] ;
            }				
		}
		else {
			// No recovery options
			[self setButton1Title:NSLocalizedString(@"OK", nil)] ;
		}
	}
}

- (void)noteError:(NSError*)error {
	if (![error isOnlyInformational]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:SSYAlertDidProcessErrorNotification
															object:error] ;
	}
}

+ (SSYAlert*)alert {
	SSYAlert* alert ;
	
	if (NSApp != nil) {
		alert = [[self alloc] init] ;
#if !__has_feature(objc_arc)
        [alert autorelease] ;
#endif
    }
	else {
		alert = nil ;
	}

	return alert ;
}

- (void)returnToScriptError:(NSError*)error {
	[[NSScriptCommand currentCommand] setScriptErrorNumber:(int)[error code]] ;
	[[NSScriptCommand currentCommand] setScriptErrorString:[error localizedDescription]] ;
}

- (void)alertError:(NSError*)error
          onWindow:(NSWindow*)window
 completionHandler:(void(^)(NSModalResponse returnCode))completionHandler {
    if (!error) {
        return ;
    }
    
    if ([gSSYAlertErrorHideManager shouldHideError:error]) {
        return ;
    }
    
    if ([[error domain] isEqualToString:NSCocoaErrorDomain] && ([error code] == NSUserCancelledError)) {
        return ;
    }

    [self doLayoutError:error] ;
    [self runModalSheetOnWindow:window
              completionHandler:completionHandler] ;
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
	
	NSInteger alertReturn ;

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
        NSWindow* window = [self window] ;
        if (window) {
            [NSApp runModalForWindow:window] ;
            // Will block here until user clicks a button
            
            alertReturn = [self alertReturn] ;
            NSInteger recoveryResult = [SSYAlert tryRecoveryAttempterForError:error
                                                               recoveryOption:alertReturn
                                                                  contextInfo:nil] ;
            if (recoveryResult != SSYAlertRecoveryNotAttempted) {
                alertReturn = recoveryResult ;
            }
        }
        else {
            alertReturn = SSYAlertRecoveryInternalError ;
            NSLog(@"Internal Error 624-9218 Don't re-use SSYAlert instances!") ;
        }
	}
	
	[self noteError:error] ;
	
	return (SSYAlertRecovery)alertReturn ;
}

+ (SSYAlertRecovery)alertError:(NSError*)error {
	// In BookMacster 1.1.10, I found that Core Data migration, specifically
	// -[Bkmx007-008MigrationPolicy createDestinationInstancesForSourceInstance:::]
	// was spending 99% of its time creating SSYAlerts for nil errors!  Fix…
	if (!error) {
		return SSYAlertRecoveryThereWasNoError ;
	}
	
	SSYAlert* alert = [SSYAlert alert] ;
    return [alert alertError:error] ;
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


+ (NSInteger)runModalDialogTitle:(NSString*)title
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
#if !__has_feature(objc_arc)
	[buttonsArray release] ;
    [buttonsArrayOut autorelease] ;
#endif
    
	return [self runModalDialogTitle:title
							 message:msg
						buttonsArray:buttonsArrayOut] ;
}

+ (NSInteger)runModalDialogTitle:(NSString*)title
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
    if ([buttonsArray count] > 3) {
        [alert setButton4Title:[buttonsArray objectAtIndex:3]] ;
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
    [self stopObservingOtherWindowsToBecomeKey] ;
    
#if !__has_feature(objc_arc)
	[icon release] ;
	[progressBar release] ;
	[titleTextView release] ;
	[smallTextView release] ;
    [smallTextScrollView release] ;
	[helpButton release] ;
	[supportButton release] ;
	[checkbox release] ;
	[button1 release] ;
	[button2 release] ;
	[button3 release] ;
    [button4 release] ;
	[helpAnchorString release] ;
	[errorPresenting release] ;
	[iconInformational release] ;
    [iconWarning release] ;
	[iconCritical release] ;
	[buttonPrototype release] ;
	[wordAlert release] ;
	[documentWindow release] ;
	[otherSubviews release] ;
	[clickTarget release] ;
	[clickObject release] ;
	[m_checkboxInvocation release] ;
	
	[super dealloc] ;
#endif
}

- (BOOL)acceptsFirstResponder {
	return YES ;
}


@end
