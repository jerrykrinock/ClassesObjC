#if 0
 To log messages when the instance is the Status Bar as opposed to the Dupes Summary,
 /*DB-----?Line*/ if ([self bottom] < 40) {NSLog(@"whatever = %@", whatever) ; }
#endif

#import "SSYProgressView.h"
#if USE_SSYPROGRESSINDICATOR
#import "SSYProgressIndicator.h"
#endif
#import "NS(Attributed)String+Geometrics.h"
#import "NSView+Layout.h"
#import "NSString+LocalizeSSY.h"
#import "NSInvocation+Quick.h"
#import "NSArray+Stringing.h"

NSString* const constKeyStaticConfigInfo = @"staticConfigInfo" ;
NSString* const constKeyPlainText = @"plainText" ;
NSString* const constKeyHyperText = @"hyperText" ;
NSString* const constKeyTarget = @"target" ;
NSString* const constKeyActionValue = @"actionValue" ;
			  
float const SSYProgressPriorityLowest = 0.0;
float const SSYProgressPriorityLow = 250.0;
float const SSYProgressPriorityRegular = 500.0;

#if 0
/* I can't figure out why the left edge of the progress indicator's rect is
 sometimes, in Yosemite, a thin black line.  I know it is part of the
 NSProgressIndicator, because if I set the 'hidden' attribute of _progBar to
 YES, the thin black line disappears (along with the progress indicator).
 The following code, which attempts to thin black line with a thicker red line,
 makes a thick red line only when the thin black line is not there.   To use
 this code, in -rejuvenateProgressBar, instantiate one of these instead
 of an NSProgressIndicator: */
@interface SSYPatchedProgressIndicator : NSProgressIndicator
@end
@implementation SSYPatchedProgressIndicator
- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect] ;
    [[NSGraphicsContext currentContext] saveGraphicsState] ;
    [[NSColor redColor] set] ;
    NSRect patchRect = [self frame] ;
    patchRect.size.width = 3.0 ;
    [NSBezierPath fillRect: patchRect] ;
    [[NSGraphicsContext currentContext] restoreGraphicsState] ;
}
@end
#endif

@interface SSYRolloverButton : NSButton
@end

@implementation SSYRolloverButton

// The following do not work unless you -addTrackingRect
//- (void)mouseEntered:(NSEvent *)event {
//	if ([self isEnabled]) {
//	}
//	
//	[super mouseEntered:event] ;
//}
//
//- (void)mouseExited:(NSEvent *)event {
//	if ([self isEnabled]) {
//	}
//
//	[super mouseExited:event] ;
//}

- (void)resetCursorRects {
	NSRect wholeThing = NSMakeRect(0,0, [self width], [self height]) ;
	
	[self addCursorRect:wholeThing
				 cursor:[NSCursor pointingHandCursor]] ;
}


@end

NSString* constKeyCompletionVerb = @"verb" ;
NSString* constKeyCompletionResult = @"rslt" ;
NSString* constKeyCompletionShowtime = @"shtm" ;

@interface SSYProgressView () 

@property (copy) NSDate* completionsLastStartedShowing ;
@property (assign) float progressPriority;
@property (assign) double progressValue ;
// Don't retain this because it will be retained as a subview
@property (assign) PROGRESSINDICATORCLASS* spinner ;

@end


@implementation SSYProgressView

@synthesize completionsLastStartedShowing ;
@synthesize progressValue ;
@synthesize spinner = m_spinner ;

- (NSTimeInterval)nextProgressUpdate {
	NSTimeInterval answer ;
	@synchronized(self) {
		answer = nextProgressUpdate ;
	}
	
	return answer ;
}

- (void)setNextProgressUpdate:(NSTimeInterval)nextProgressUpdate_ {
	@synchronized(self) {
		nextProgressUpdate = nextProgressUpdate_ ;
	}
}


+ (void)initialize {
	[self exposeBinding:constKeyStaticConfigInfo] ;
}

- (NSMutableArray*)completions {
	if (!completions) {
		completions = [[NSMutableArray alloc] init] ;
	}
	
	return completions ;
}

- (NSArray*)activeCompletions {
	NSMutableArray* activeCompletions = [NSMutableArray array] ;
	for (NSDictionary* completion in [self completions]) {
		NSString* verb = [completion objectForKey:constKeyCompletionVerb] ;
		NSString* result = [completion objectForKey:constKeyCompletionResult] ;
		NSString* resultsString = @"" ;
		if (result) {
			resultsString = [NSString stringWithFormat:
							 @" (%@)",
							 result] ;
		}
		
		NSString* completionString = [verb stringByAppendingString:resultsString] ;
		if (completionString) {
			[activeCompletions addObject:completionString] ;
		}
	}
	
	return activeCompletions ;
}

- (void)setFontSize:(CGFloat)fontSize {
    _fontSize = fontSize;
}

- (CGFloat)fontSize {
    if (_fontSize > 0.0) {
        return _fontSize;
    }

    CGFloat frameHeight = [self frame].size.height ;
	CGFloat fontSize ;
#if 0
#warning SSYProgressView computing font size the correct, ridiculous way
	// Although the following is the *correct* way to determine
	// font size, I don't use it because:
	// * The iterative computation is obviously stupid
	// * The fontSize that you get is ridiculously small, although
	// I suppose there may be some non-Latin glyphs that actually 
	// do require this much height, I've never seen any.  If there
	// are, someone should redesign these fonts!  Examples:
	//    frameHeight      fontSize
	//        14               6
	//        18               8
	CGFloat requiredSize ;
	CGFloat fontSize = 24.0 ; // or whatever the largest possible size might be
	do {
		requiredSize = [[NSFont systemFontOfSize:fontSize] boundingRectForFont].size.height ;
		fontSize -= 1.0 ;
	} while (requiredSize > frameHeight) ;
#else
	// The following formula are reverse-engineered to give
	// the following results which *look good* in practice,
	// with the current Lucide Grande system font.
	//    frameHeight      fontSize
	//        14              11
	//        16              11
	//        18              12
	if (frameHeight > 15.0) {
		fontSize = floor(0.7 * frameHeight) ;
	}
	else {
		fontSize = floor(0.8 * frameHeight) ;
	}
#endif
	return fontSize ;
}

- (NSTextField*)textField {
	if (!_textField) {
		_textField = [[NSTextField alloc] initWithFrame:NSMakeRect(0,0,0, [self frame].size.height)] ;
		[[_textField cell] setLineBreakMode:NSLineBreakByTruncatingMiddle] ;
		[_textField setBordered:NO] ;
		[_textField setEditable:NO] ;
		[_textField setDrawsBackground:NO] ;
		[_textField setFont:[NSFont systemFontOfSize:[self fontSize]]] ;
		// A newly-created NSTextField has string value "Field".
		[_textField setStringValue:@""] ;
		[self addSubview:_textField] ;
	}
	
	return _textField ;
}

- (void)rejuvenateProgressBar {
    NSRect frame ;
	if (_progBar != nil) {
		frame = [_progBar frame] ;
		[_progBar removeFromSuperviewWithoutNeedingDisplay] ;
	}
	else {
		frame = NSMakeRect(0,1.0,100,[self frame].size.height - 3.0) ;
		// The y=1.0, h-=3.0 makes it line up with the text nicer.
	}
    _progBar = [[PROGRESSINDICATORCLASS alloc] initWithFrame:frame] ;
	[self addSubview:_progBar] ;
	[_progBar release] ;
	[_progBar setStyle:BARSTYLE] ;
	[_progBar setUsesThreadedAnimation:YES] ; // unreliable pre-Leopard
	[_progBar setDisplayedWhenStopped:NO] ;
}

- (PROGRESSINDICATORCLASS*)progBar {
	if (_progBar == nil) {
		[self rejuvenateProgressBar] ;
	}
	
	return _progBar ;
}

/*!
 @brief    If one does not already exist, creates a cancel button of width 0.0
 */
- (SSYRolloverButton*)hyperButton {
	if (!_hyperButton) {
		_hyperButton = [[SSYRolloverButton alloc] initWithFrame:NSMakeRect(0,0,0,[self frame].size.height)] ;
		[_hyperButton setBordered:NO] ;
		[_hyperButton setAlignment:NSTextAlignmentCenter] ;
		[self addSubview:_hyperButton] ;
	}
	
	return _hyperButton ;
}


/*!
 @brief    If one does not already exist, creates a cancel button of width 0.0
*/
- (SSYRolloverButton*)cancelButton {
	if (!_cancelButton) {
		CGFloat length = [self frame].size.height ;
		_cancelButton = [[SSYRolloverButton alloc] initWithFrame:NSMakeRect([self frame].size.width - length, 0, 0, length)] ;
		[_cancelButton setImage:[NSImage imageNamed:@"stop14"]] ;
		[_cancelButton setBordered:NO] ;
		[_cancelButton setToolTip:[NSString localize:@"cancel"]] ;
		[self addSubview:_cancelButton] ;
	}
	
	return _cancelButton ;
}

- (void)showCancelButton {
	[[self cancelButton] setWidth:([self frame].size.height)] ;
}	

- (void)hideCancelButton {
	[[self cancelButton] setWidth:0.0] ;
}	

- (CGFloat)textWidth {
	return [[self textField] frame].size.width ;
}

- (CGFloat)hyperWidth {
	return [[self hyperButton] frame].size.width ;
}

- (CGFloat)progWidth {
	return [[self progBar] frame].size.width ;
}

- (CGFloat)cancelWidth {
	return [[self cancelButton] frame].size.width ;
}

/*!
 @brief    Resizes all currently-existing subviews to fit the receiver's
 current overall width

 @param    textOnly  If YES, the progress bar will not be resized.
 Any resizing required will be accomplished be resizing the text field.
 If NO, the text field will be resized to fit its current string
 value, and the progress bar width will absorb or give as required.
*/
- (void)sizeToFitTextOnly:(BOOL)textOnly {
	NSInvocation* invocation = [NSInvocation invocationWithTarget:self
														 selector:@selector(unsafeSizeToFitTextOnly:)
												  retainArguments:YES
												argumentAddresses:&textOnly] ;
	[invocation invokeOnMainThreadWaitUntilDone:YES] ;
}

- (void)unsafeAlignSubviews {
	// [self textField]  // This one never moves
	[[self hyperButton] setLeftEdge:[[self textField] rightEdge]] ;
	[[self progBar] setLeftEdge:[[self hyperButton] rightEdge]] ;
	[[self cancelButton] setLeftEdge:[[self progBar] rightEdge]] ;
}	

- (void)unsafeSizeToFitTextOnly:(BOOL)textOnly {
	CGFloat newTotalWidth = [self frame].size.width ;
	
	CGFloat currentTextAndBarWidth = [self textWidth] + [self progWidth] ;
	CGFloat currentHyperAndCancelWidth = [self hyperWidth] + [self cancelWidth] ;
	CGFloat currentTotalWidth = currentTextAndBarWidth + currentHyperAndCancelWidth ;

	CGFloat delta = newTotalWidth - currentTotalWidth ;
	
	// The hyperWidth and cancelWidth cannot be adjusted.
	// The remainder, textAndBarWidth, will be split between textField and progBar	
	CGFloat requiredTextWidth = [[[self textField] stringValue] widthForHeight:FLT_MAX
																		  font:[[self textField] font]] ;
	CGFloat textExcessWidth = [self textWidth] - requiredTextWidth ;
	
	CGFloat deltaText = 0.0 ;
	CGFloat deltaProg = 0.0 ;
	CGFloat extraDelta = delta + textExcessWidth ;
	if (textOnly) {
		deltaText = delta ;
	}
	else if (delta > 0) {
		// text and/or prog width must increase
		if (textExcessWidth >= 0.0) {
			// Add all of the available delta to the progress bar
			deltaProg = delta ;
		}
		else {
			if (extraDelta > 0.0) {
				// There is enough delta to show all of the text
				// Increase the text field up to the requirement and
				// then give the remainder to the progBar
				deltaText = -textExcessWidth ;
				deltaProg = extraDelta ;  // By solving delta=deltaText+deltaProg
			}
			else {
				// There is not enough delta to show all of the text
				// Give the text field all that we have.
				deltaText = delta ;
			}
		}
	}
	else {
		// text and/or prog width must be squeezed
		if (textExcessWidth < 0.0) {
			// The text field is already insufficient.
			// Squeeze all of the negative delta from the progress bar
			deltaProg = delta ;
		}
		else {
			if (extraDelta <= 0.0) {
				// There is not enough in the text field to absorb all
				// of the required delta squeeze.  Squeeze the text
				// until it is about to be truncated and then squeeze
				// the remainder out of the progBar.
				deltaText = -textExcessWidth ;
				deltaProg = extraDelta ;  // By solving delta=deltaText+deltaProg
			}
			else {
				// There is enough in the text field to absorb all
				// of the required delta squeeze.
				deltaText = delta ;
			}
		}

		// See if the above squeezed the progress bar down too narrow,
		// less than 0 if it is hidden or 50.0 if not hidden.
		// If so, give it back to the limit and take the difference out
		// of the text field instead.
		CGFloat proposedProgBarWidth = [self progWidth] + deltaProg ;
		CGFloat progBarMinWidth = [[self progBar] isHidden] ? 0.0 : 50.0 ;
		if (proposedProgBarWidth < progBarMinWidth) {
			deltaProg = progBarMinWidth - [self progWidth] ;
			deltaText = delta - deltaProg ;  // By solving delta=deltaText+deltaProg
		}
		
	}
		
	// Set widths of adjustable subviews
	[[self textField] deltaW:deltaText] ;
	[[self progBar] deltaW:deltaProg] ;
		
	[self unsafeAlignSubviews] ;
	
	BOOL textIsTruncated = [[self textField] width] < requiredTextWidth ;
	if (textIsTruncated) {
		NSString* tip = [NSString stringWithFormat:
						 @"%@\n%@",
						 [NSString localize:@"completed"],
						 [[self activeCompletions] componentsJoinedByString:@"\n"]] ;
		
		[[self textField] setToolTip:tip] ;
	}
	else {
		[[self textField] setToolTip:nil] ;
	}
	
    self.needsDisplay = YES;
}

- (void)unsafeSetHasCancelButtonWithTarget:(id)target
									action:(SEL)action {
	BOOL needsButton = (target != nil) && (action != nil) ;
	
	if (needsButton) {
		[self showCancelButton] ;
	}
	else if (!needsButton) {
		[self hideCancelButton] ;
	}
	
	if (needsButton) {
		[[self cancelButton] setTarget:target] ;
		[[self cancelButton] setAction:action] ;
	}
	
	[self sizeToFitTextOnly:NO] ;
}

- (void)setHasCancelButtonWithTarget:(id)target
							  action:(SEL)action {
	[NSInvocation invokeOnMainThreadTarget:self
								  selector:@selector(unsafeSetHasCancelButtonWithTarget:action:)
						   retainArguments:YES
							 waitUntilDone:YES
						 argumentAddresses:&target, &action] ;
}

- (void)setProgressBarWidth:(CGFloat)barWidth {
	NSInvocation* invocation = [NSInvocation invocationWithTarget:[self progBar]
														 selector:@selector(setWidth:)
												  retainArguments:YES
												argumentAddresses:&barWidth] ;
	[invocation invokeOnMainThreadWaitUntilDone:YES] ;
	[self sizeToFitTextOnly:YES] ;
}

// Cocoa invokes this when the window is resized.  This implementation
// is needed to scale the subviews (text and progress bar) appropriately.
- (void)setFrame:(NSRect)frame {
	// We're only concerned with width.  Height is not resizable.
/*
	CGFloat oldWidth = [self frame].size.width ;
	CGFloat oldTextPlusBarWidth = [self textBarWidth] ;
	CGFloat oldTextWidth = [[self textField] frame].size.width ;
	CGFloat oldBarWidth = oldTextPlusBarWidth - oldTextWidth ;
*/
	[super setFrame:frame] ;
	[self sizeToFitTextOnly:NO] ;
}

- (void)setTextWidthForText {
	NSTextField* textField = [self textField] ;
	
	// Make textToDisplay by appending ellipsis to verbToDisplay
	NSString* text = [textField stringValue] ;
	CGFloat requiredWidth = [text widthForHeight:FLT_MAX
										  font:[textField font]] ;
	[textField setWidth:requiredWidth] ;
	[self sizeToFitTextOnly:NO] ;
}

#define COMPLETION_SHOW_TIME 10.0

- (void)updateCompletionsPause:(BOOL)pause {
	NSDate* start = [self completionsLastStartedShowing] ;
	if (pause) {
		[self setCompletionsLastStartedShowing:nil] ;
	}
	
	NSTimeInterval deltaTime = 0.0 ;
	if (start) {
		deltaTime = -[start timeIntervalSinceNow] ;
	}
	
	NSMutableArray* updatedCompletions = [NSMutableArray array] ;
	for (NSDictionary* completion in [self completions]) {
		NSNumber* timeNumber = [completion objectForKey:constKeyCompletionShowtime] ;
		NSTimeInterval time = 0.0 ;
		if (timeNumber) {
			time = [timeNumber doubleValue] + deltaTime ;
		}
		if (time < COMPLETION_SHOW_TIME) {
			NSDictionary* updatedCompletion = [NSDictionary dictionaryWithObjectsAndKeys:
											   [completion objectForKey:constKeyCompletionVerb], constKeyCompletionVerb,
											   [NSNumber numberWithDouble:time], constKeyCompletionShowtime,
											   // Note that we put the result last, since it may be nil
											   [completion objectForKey:constKeyCompletionResult], constKeyCompletionResult,
											   nil] ;
			[updatedCompletions addObject:updatedCompletion] ;
		}
	}
	
	[[self completions] removeAllObjects] ;
	[[self completions] addObjectsFromArray:updatedCompletions] ;	
}

// Invoke this method to "pause" the timers on each of the completions
// when the progressView is temporarily taken over to display some non-completion
// text, progress bar or whatever.
- (void)updateCompletionsPause {
	BOOL yes = YES ;
	[NSInvocation invokeOnMainThreadTarget:self
								  selector:@selector(updateCompletionsPause:)
						   retainArguments:YES
							 waitUntilDone:YES
						 argumentAddresses:&yes] ;
}

- (void)unsafeSetVerb:(NSString*)newVerb
			   resize:(BOOL)resize {
	NSTextField* textField = [self textField] ;
    [textField setStringValue:newVerb] ;
	[[textField cell] setLineBreakMode:NSLineBreakByTruncatingMiddle] ;

	if (resize) {
		[self setTextWidthForText] ;
	}

	// Yes, the following *is* sometimes necessary to update, for example,
	// when "Deleting BOOKMARK_NAME at del.icio.us"
	[textField display] ;
	
	[self updateCompletionsPause] ;
}

- (void)setVerb:(NSString*)newVerb
		 resize:(BOOL)resize {
	NSInvocation* invocation = [NSInvocation invocationWithTarget:self
														 selector:@selector(unsafeSetVerb:resize:)
												  retainArguments:YES
												argumentAddresses:&newVerb, &resize] ;
	[invocation invokeOnMainThreadWaitUntilDone:YES] ;
}

- (void)setStringValue:(NSString*)string {
	// Another way to get the same effect would be to
	// set the width of the text field to cover the
	// entire width, and then I wouldn't have to 
	// -clearAll, but that would require a little
	// more code to do thread-safely.
	[self clearAll] ;
	[self setVerb:string
		   resize:YES] ;
}


- (void)unsafeHideProgressBar {
	PROGRESSINDICATORCLASS* bar = [self progBar] ;
	[bar stopAnimation:self] ;
	[bar setHidden:YES] ;
    self.progressPriority = SSYProgressPriorityLowest;
}

- (void)unsafeStartSpinning {
	if ([self spinner] != nil) {
		return ;
	}

	// Displace the text field
	CGFloat height = [self frame].size.height ;
	NSRect textFrame = [[self textField] frame] ;
	NSRect spinnerFrame = textFrame ;
	textFrame.origin.x += height ;
	[self unsafeAlignSubviews] ;
	[[self textField] setFrame:textFrame] ;
	[[self textField] display] ;

	// Insert the spinner
	spinnerFrame.size.width = height ;
	PROGRESSINDICATORCLASS* spinner = [[PROGRESSINDICATORCLASS alloc] initWithFrame:spinnerFrame] ;
	// The following is to eliminate this warning from appearing in system console:
	// "A regular control size progress indicator … with the frame size for small control size detected.  Please use -setControlSize: to explicitly specify NSControlSizeSmall"
	// I'm not sure if this is the correct threshold, but it worked for my application.
	// Also, apparently, there should be a threshold for NSControlSizeMini, but I haven't run into that yet. 
	if (height < 17.0) {
		[spinner setControlSize:NSControlSizeSmall] ;
	}
	[self addSubview:spinner] ;
	[spinner release] ;
	[self setSpinner:spinner] ;
	[spinner setStyle:CIRCLESTYLE] ;
	[spinner startAnimation:self] ;
	[spinner display] ;
}

- (void)unsafeStopSpinning {
	if ([self spinner] == nil) {
		return ;
	}

	// Remove the spinner
	[[self spinner] removeFromSuperviewWithoutNeedingDisplay] ;
	[self setSpinner:nil] ;

	// Re-place the text field
	CGFloat height = [self frame].size.height ;
	NSRect textFrame = [[self textField] frame] ;
	textFrame.origin.x -= height ;
	[[self textField] setFrame:textFrame] ;
	[[self textField] display] ;
}

- (void)unsafeRemoveAll {
	[self unsafeStopSpinning] ;
	[[self textField] setStringValue:@""] ;
	[[self hyperButton] setWidth:0.0] ;
	[self hideCancelButton] ;
	[self unsafeHideProgressBar] ;

	[self sizeToFitTextOnly:NO] ;
}

- (void)unsafeSetIndeterminate:(BOOL)indeterminate
			 withLocalizedVerb:(NSString*)localizedVerb
                      priority:(float)priority {
	[self unsafeRemoveAll] ;
	
	NSTextField* textField = [self textField] ;
	[[textField cell] setLineBreakMode:NSLineBreakByTruncatingMiddle] ;
	
	// Make textToDisplay by appending ellipsis to verbToDisplay
	NSString* text = [NSString stringWithFormat:
                      @"%@%C",
                      localizedVerb,
                      (unsigned short)0x2026] ;
	[textField setStringValue:text] ;
	
	[self setTextWidthForText] ;
    // For NSProgressIndicator Bug
    // Maybe this will be unnecessary with SSYProgressIndicator?
	[self rejuvenateProgressBar] ;
	PROGRESSINDICATORCLASS* progBar = [self progBar] ; // The new one, that is
	[progBar setIndeterminate:indeterminate] ;
    /* If CA_ASSERT_MAIN_THREAD_TRANSACTIONS is set to 1 in environment,
     the following line raises assertion from "CoreAnimation" saying
     "an implicit transaction wasn't created on a main thread." */
	[progBar startAnimation:self] ;
	[progBar setHidden:NO] ;
    self.progressPriority = priority;
	[self display] ;
}

- (SSYProgressView*)setIndeterminate:(BOOL)indeterminate
                   withLocalizedVerb:(NSString*)localizedVerb
                            priority:(float)priority {
    SSYProgressView* returnResult;
    if (priority >= self.progressPriority) {
        [NSInvocation invokeOnMainThreadTarget:self
                                      selector:@selector(unsafeSetIndeterminate:withLocalizedVerb:priority:)
                               retainArguments:YES
                                 waitUntilDone:YES
                             argumentAddresses:&indeterminate, &localizedVerb, &priority] ;
        [self updateCompletionsPause] ;
        returnResult = self;
    }
    else {
        returnResult = nil;
    }

    return returnResult;
}

- (SSYProgressView*)setIndeterminate:(BOOL)indeterminate
                 withLocalizableVerb:(NSString*)localizableVerb
                            priority:(float)priority {
	return [self setIndeterminate:indeterminate
                withLocalizedVerb:[NSString localize:localizableVerb]
                         priority:priority] ;
}

- (void)unsafeSetText:(NSString*)text
			hyperText:(NSString*)hyperText
			   target:(id)target
			   action:(SEL)action {
	if (text == nil) {
		text = @"" ;
	}

	NSTextField* textField = [self textField] ;
	[[textField cell] setLineBreakMode:NSLineBreakByTruncatingMiddle] ;
	[textField setStringValue:text] ;
    NSPoint origin = textField.frame.origin;
    NSSize size;
    size.height = textField.frame.size.height;
    [textField sizeToFit];
    size.width = textField.frame.size.width;
    textField.frame = NSMakeRect(origin.x, origin.y, size.width, size.height);

	if (hyperText == nil) {
		hyperText = @"" ;
	}
	SSYRolloverButton* hyperButton = [self hyperButton] ;
	if ([hyperText length] > 0) {		
		[hyperButton setTarget:target] ;
		[hyperButton setAction:action] ;
		NSFont* font = [NSFont systemFontOfSize:11.0] ;
		NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:
									font, NSFontAttributeName,
									[NSColor controlTextColor], NSForegroundColorAttributeName,
									[NSNumber numberWithInteger:NSUnderlineStyleSingle], NSUnderlineStyleAttributeName,
									nil] ;				
		NSAttributedString* title = [[NSAttributedString alloc] initWithString:hyperText
																	attributes:attributes] ;
		[hyperButton setAttributedTitle:title];
        NSPoint origin = hyperButton.frame.origin;
        NSSize size;
        size.height = hyperButton.frame.size.height;
        [hyperButton sizeToFit];
		size.width = hyperButton.frame.size.width;
        [title release] ;
        hyperButton.frame = NSMakeRect(origin.x, origin.y, size.width, size.height);
	}
	else {
        [hyperButton setWidth:0.0] ;
	}

	[self unsafeHideProgressBar] ;

	[self hideCancelButton] ;
		
	[self sizeToFitTextOnly:NO] ;
}

- (NSString*)unsafeText {
	NSString* text = [[self textField] stringValue] ;
	return  text ;
}

- (NSString*)unsafeHyperText {
    NSString* hyperText = [[self hyperButton] title] ;
    return  hyperText ;
}

- (void)unsafeShowCompletionVerb:(NSString*)verb
						  result:(NSString*)result
                        priority:(float)priority {
    NSDictionary* newCompletion = [NSDictionary dictionaryWithObjectsAndKeys:
								   [NSNumber numberWithDouble:0.0], constKeyCompletionShowtime,
								   verb, constKeyCompletionVerb,
								   result, constKeyCompletionResult,
								   nil] ;

    // Remove any prior completions of same verb and same result
    NSArray* completionsCopy = [[self completions] copy] ;
    NSInteger i = [completionsCopy count] - 1 ;
    for (NSDictionary* completion in [completionsCopy reverseObjectEnumerator]) {
        if ([[completion objectForKey:constKeyCompletionVerb] isEqualToString:verb]) {
            if ([[completion objectForKey:constKeyCompletionResult] isEqualToString:result]) {
                [[self completions] removeObjectAtIndex:i] ;
            }
        }
        i-- ;
    }
    [completionsCopy release] ;

	[[self completions] addObject:newCompletion] ;

    if ((priority >= self.progressPriority) || !verb) {
        if (verb) {
            self.progressPriority = priority;
        }

        [self updateCompletionsPause:NO] ;

        NSArray* activeCompletions = [self activeCompletions] ;

        // Combine the verb+result strings into one string
        NSString* whatDone = [activeCompletions listValuesForKey:nil
                                                     conjunction:nil
                                                      truncateTo:0] ;
        if ([whatDone length] > 0) {
            self.progressPriority = priority;

            // Prepend "Completed: "
            NSString* msg = [NSString stringWithFormat:
                             @"%@ %@",
                             [NSString localize:@"completed"],
                             whatDone] ;

            // Finally, set it into the view!
            [self unsafeSetText:msg
                      hyperText:nil
                         target:nil
                         action:NULL] ;

            // The last, most recent completions are the most important, so we…
            [[[self textField] cell] setLineBreakMode:NSLineBreakByTruncatingHead] ;
            // and this must be done *after* -unsafeSetText::: because that
            // method set the truncation mode to Middle.

            // Restart the clock
            [self setCompletionsLastStartedShowing:[NSDate date]] ;
        } else {
            [self unsafeStopSpinning] ;
            [[self progBar] setHidden:YES] ;
            self.progressPriority = SSYProgressPriorityLowest;
            [[self textField] setStringValue:@""] ;
            [[self hyperButton] setWidth:0.0] ;
            [self hideCancelButton] ;
            
            [self sizeToFitTextOnly:NO] ;
        }
    }
}

- (SSYProgressView*)showCompletionVerb:(NSString*)verb
                                result:(NSString*)result
                              priority:(float)priority {
    [NSInvocation invokeOnMainThreadTarget:self
                                  selector:@selector(unsafeShowCompletionVerb:result:priority:)
                           retainArguments:YES
                             waitUntilDone:YES
                         argumentAddresses:&verb, &result, &priority] ;

    /* A little kludgey here; I am predicting how the above asynchronous method
     will behave: */
    return (priority >= self.progressPriority) ? self : nil;
}
	
- (void)setText:(NSString*)text
	  hyperText:(NSString*)hyperText
		 target:(id)target
		 action:(SEL)action {
	[NSInvocation invokeOnMainThreadTarget:self
								  selector:@selector(unsafeSetText:hyperText:target:action:)
						   retainArguments:YES
							 waitUntilDone:YES
						 argumentAddresses:&text, &hyperText, &target, &action] ;
	[self updateCompletionsPause] ;
}

- (NSString*)text {
	NSInvocation* invocation = [NSInvocation invokeOnMainThreadTarget:self
															 selector:@selector(unsafeText)
													  retainArguments:NO
														waitUntilDone:YES
													argumentAddresses:NULL] ;
	[invocation invoke] ;
	NSString* text = nil ;
	[invocation getReturnValue:&text] ;
	
	return text ;
}

- (NSString*)hyperText {
    NSInvocation* invocation = [NSInvocation invokeOnMainThreadTarget:self
                                                             selector:@selector(unsafeHyperText)
                                                      retainArguments:NO
                                                        waitUntilDone:YES
                                                    argumentAddresses:NULL] ;
    [invocation invoke] ;
    NSString* hyperText = nil ;
    [invocation getReturnValue:&hyperText] ;
    
    return hyperText ;
}

// staticConfigInfo is actually a "write-only" binding, but if I don't
// provide a getter, the system will bitch about no KVC compliance and
// abort loading of the window this view is in.
- (NSDictionary*)staticConfigInfo {
	return nil ;
}

- (void)setStaticConfigInfo:(NSDictionary*)info {
	NSString* plainText = [info objectForKey:constKeyPlainText] ;
	NSString* hyperText = [info objectForKey:constKeyHyperText] ;
	id target = [info objectForKey:constKeyTarget] ;
	SEL action = [[info objectForKey:constKeyActionValue] pointerValue] ;
	
	[self setText:plainText
		hyperText:hyperText
		   target:target
		   action:action] ;
}	

- (void)startSpinning {
	// Even though we're going to repeat this in -unsafeStartSpinning
	// to support internal invocations, we do it here for efficiency,
	// since checking spinner for nil will be much faster than a
	// -performSelectorOnMainThread:::
	if ([self spinner] != nil) {
		return ;
	}

	[self performSelectorOnMainThread:@selector(unsafeStartSpinning)
						   withObject:nil
						waitUntilDone:YES] ;
}

- (void)stopSpinning {
	// Even though we're going to repeat this in -unsafeStopSpinning
	// to support internal invocations, we do it here for efficiency,
	// since checking spinner for nil will be much faster than a
	// -performSelectorOnMainThread:::
	if ([self spinner] == nil) {
		return ;
	}

	[self performSelectorOnMainThread:@selector(unsafeStopSpinning)
						   withObject:nil
						waitUntilDone:YES] ;
}


- (void)unsafeClearAll {
	[self unsafeRemoveAll] ;
	[self display] ;
}

- (void)clearAll {
	// Since this one does not have a non-object argument, I can
	// use the following simpler method instead of an invocation.
	[self performSelectorOnMainThread:@selector(unsafeClearAll)
						   withObject:nil
						waitUntilDone:YES] ;
	[self updateCompletionsPause] ;
	[self setNextProgressUpdate:0.0] ;
}

- (void)unsafeSetMaxValue:(double)value {
	// For NSProgressIndicator Bug
	[self rejuvenateProgressBar] ;

	PROGRESSINDICATORCLASS* progBar = [self progBar] ;
	
	[progBar setIndeterminate:NO] ;
	[progBar setMaxValue:value] ;
	[progBar setHidden:NO] ;
}

- (double)unsafeMaxValue {
	double maxValue = _progBar ? [_progBar maxValue] : 0.0 ; 
	return maxValue ;
}

- (double)maxValue {
	NSInvocation* invoc = [NSInvocation invokeOnMainThreadTarget:self
														selector:@selector(unsafeMaxValue)
												 retainArguments:YES
												   waitUntilDone:YES
											   argumentAddresses:NULL] ;
	[invoc invoke] ;
	double maxValue ;
	[invoc getReturnValue:&maxValue] ;
	
	return maxValue ;
}

- (void)setMaxValue:(double)value {
	[self setNextProgressUpdate:0.0] ;
	[NSInvocation invokeOnMainThreadTarget:self
								  selector:@selector(unsafeSetMaxValue:)
						   retainArguments:YES
							 waitUntilDone:YES
						 argumentAddresses:&value] ;
}

- (void)unsafeSetIndeterminate:(BOOL)yn {
	[[self progBar] setDisplayedWhenStopped:YES] ;
	[[self progBar] startAnimation:self] ;
	[[self progBar] setIndeterminate:yn] ;
}

- (void)setIndeterminate:(BOOL)yn {
	[NSInvocation invokeOnMainThreadTarget:self
								  selector:@selector(unsafeSetIndeterminate:)
						   retainArguments:YES
							 waitUntilDone:YES
						 argumentAddresses:&yn] ;
}

#define PROGRESS_UPDATE_PERIOD 0.1

- (void)unsafeSetDoubleValue:(double)value {
		[[self progBar] setDoubleValue:value] ;
		[[self progBar] display] ;
}

- (void)setDoubleValue:(double)value {
	[self setProgressValue:value] ;
	NSTimeInterval secondsNow = [NSDate timeIntervalSinceReferenceDate] ;
	if (secondsNow > [self nextProgressUpdate]) {
		[self setNextProgressUpdate:(secondsNow + PROGRESS_UPDATE_PERIOD)] ;
		[NSInvocation invokeOnMainThreadTarget:self
								  selector:@selector(unsafeSetDoubleValue:)
						   retainArguments:YES
							 waitUntilDone:YES
						 argumentAddresses:&value] ;
	}
}

- (void)incrementDoubleValueBy:(double)delta {
	double newProgressValue = [self progressValue] + delta ;
	[self setDoubleValue:newProgressValue] ;
}	

- (void)incrementAndRunDoubleValueBy:(double)delta  {
    double newProgressValue = [self progressValue] + delta ;
    [self setProgressValue:newProgressValue] ;
    NSTimeInterval secondsNow = [NSDate timeIntervalSinceReferenceDate] ;
    if (secondsNow > [self nextProgressUpdate]) {
        [self setNextProgressUpdate:(secondsNow + PROGRESS_UPDATE_PERIOD)] ;
        [NSInvocation invokeOnMainThreadTarget:self
                                  selector:@selector(unsafeSetDoubleValue:)
                           retainArguments:YES
                             waitUntilDone:YES
                         argumentAddresses:&newProgressValue] ;
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate date]];
    }
}

- (void)incrementDoubleValueByObject:(NSNumber*)value {
	[self incrementDoubleValueBy:[value doubleValue]] ;
}	

- (SSYProgressView*)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame] ;
	
	return self ;
}

- (void)dealloc {
	[_textField release] ;
	[_hyperButton release] ;
	[_cancelButton release] ;
	[completions release] ;
	[completionsLastStartedShowing release] ;
	
	[super dealloc] ;
}




@end
