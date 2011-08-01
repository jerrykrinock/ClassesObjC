/*
 Copyright (c) 2006, Andrew Bowman.  All rights reserved.
 
 Redistribution and use in source and binary forms, with or without 
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this 
 list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, 
 this list of conditions and the following disclaimer in the documentation 
 and/or other materials provided with the distribution.
 * Neither the name of Inverse Falcon nor the names of its contributors may be 
 used to endorse or promote products derived from this software without 
 specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON 
 ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "IFVerticallyExpandingTextField.h"

// Private helper class for associating NSViews with autoresizingMasks
@interface IFViewMaskPair : NSObject 
{   
	NSView *view;
	unsigned int savedAutoresizingMask;
}

- (id) initWithView: (NSView *)aView;
- (void) restoreAutoresizingMask;

@end


@implementation IFViewMaskPair 

- (id) initWithView: (NSView *)aView {
	self = [super init];
	view = aView;
	savedAutoresizingMask = [view autoresizingMask];
	
	return self;
}

- (void) restoreAutoresizingMask {
	[view setAutoresizingMask: savedAutoresizingMask];
}

@end



@interface IFVerticallyExpandingTextField (PRIVATE)

- (void) autosizeHeight: (NSTextView *)fieldEditor;
- (void) autosizeSuperviewOfView: (NSView *)originView withGrowth: (float)growth;

- (void) alterAutoresizeMasksForViews: (NSArray *)sibViews 
                      surroundingView: (NSView *)originView;
- (void) restoreAutoresizeMasks;

@end


@implementation IFVerticallyExpandingTextField

- (void) awakeFromNib {
	superviewsExpandOnGrowth = YES;
	viewMaskPairs = [[NSMutableArray alloc] init];
	
	if ([self autoresizingMask] & NSViewHeightSizable) {
		[self setAutoresizingMask: [self autoresizingMask] & ~NSViewHeightSizable];
		
		NSLog(@"Warning: IFVerticallyExpandingTextField: Vertical autosizing option "
			  "in Interface Builder interferes with this class's functionality and has "
			  "been temporarily disabled.  Turn off this option for all "
			  "IFVerticallyExpandingTextFields in Interface Builder to prevent this warning.");
	}
}

- (void) setSuperviewsExpandOnGrowth: (BOOL)shouldExpand {
	superviewsExpandOnGrowth = shouldExpand;
}

- (BOOL) superviewsExpandOnGrowth {
	return superviewsExpandOnGrowth;
}

- (void) forceAutosize {
	
	// Entry point for vertical expansion.  Call this method if you need to manually
	// force an autosize.  Most of the time this is done for you in response to the 
	// textDidChange and viewDidEndLiveResize callbacks.
	//
	// Note that if we're forced to steal the field editor and first responder status,
	// quirky behavior can occur if we just throw first responder back to whoever 
	// had it last (especially with several expanding text fields), so we resign 
	// first responder.
	
	BOOL stolenEditor = NO;
	NSWindow *myWindow = [self window];
	NSTextView *fieldEditor = (NSTextView*)[myWindow fieldEditor: YES forObject: self];
	
	if ([fieldEditor delegate] != self) {
		stolenEditor = YES;
		
		[myWindow endEditingFor: nil];
		[myWindow makeFirstResponder: self];
		
		// Set cursor to end, breaking the selection
		[fieldEditor setSelectedRange: NSMakeRange([[self stringValue] length], 0)];
	}
	
	[self autosizeHeight: fieldEditor];
	
	if (stolenEditor) {   
		// Odd things can occur when messing with the first responder when using 
		// several IFVerticallyExpandingTextFields.  Best not to mess with it, for now.
		
		[myWindow makeFirstResponder: nil];
	}
}


/* Private methods */

- (void) autosizeHeight: (NSTextView *)fieldEditor {
	NSRect newFrame = [self frame];
	float oldHeight = newFrame.size.height;
	float newHeight;
	float fieldGrowth;
	
	if ([self isHidden])
		newHeight = 0;
	else
		newHeight = [[fieldEditor layoutManager] usedRectForTextContainer:
			[fieldEditor textContainer]].size.height + IFVerticalPadding;
	
	fieldGrowth = newHeight - oldHeight;   
	
	if (fieldGrowth != 0) {
		
		// We're expanding or contracting. First adjust our frame, 
		// then see about superviews.
		
		newFrame.size = NSMakeSize(newFrame.size.width, newHeight);
		
		if ([self autoresizingMask] & NSViewMinYMargin)
			newFrame.origin.y -= fieldGrowth;
		
		[self setFrame: newFrame];
		
		if (superviewsExpandOnGrowth) {
			[self autosizeSuperviewOfView: self withGrowth: fieldGrowth];
		}
		
		// If superviews are set not to expand on growth, it's best to call display
		// on the window in reponse to this notification to prevent artifacts.
		[[NSNotificationCenter defaultCenter] postNotificationName: @"IFTextFieldDidExpandNotification"
															object: self
														  userInfo: 
			[NSDictionary dictionaryWithObject: [NSNumber numberWithFloat: fieldGrowth]
										forKey: @"IFTextFieldNotificationFieldGrowthItem"]];
	}
}



- (void) autosizeSuperviewOfView: (NSView *)originView withGrowth: (float)growth {
	
	// Recursively autosize superviews until we get to a window or scroll view
	
	NSView *currentView = [originView superview];  // current view we are working in
	
	[self alterAutoresizeMasksForViews: [currentView subviews] surroundingView: originView];
	
	if (currentView == [[originView window] contentView]) {
		// First base case, stop recursion when we've reached window's content view
		
		NSWindow *myWindow = [originView window];
		NSRect windowFrame = [myWindow frame];
		
		windowFrame.size.height += growth;
		windowFrame.origin.y -= growth;
		
		// Using animate: YES causes some brief drawing artifacts and makes multiple
		// troublesome viewDidEndLiveResize calls.  Stick with NO for now.
		[myWindow setFrame: windowFrame display: [myWindow isVisible] animate: NO];
		
		[self restoreAutoresizeMasks];
	}
	else if ([currentView isKindOfClass: [NSScrollView class]]) {
		// Second base case, stop at scrollviews.
		// Trying to get scrollviews' content to expand.
		// Scrollview blocks do appear, but with no arrows or scrolling controls
		// Some help here would be appreciated
		
		NSScrollView *scrollView = (NSScrollView *) currentView;
		NSRect contentFrame = [[scrollView contentView] frame];
		
		contentFrame.size.height += growth;
		contentFrame.origin.y -= growth;
		
		[[scrollView contentView] setFrame: contentFrame];
		[scrollView tile];
		
		[self restoreAutoresizeMasks];
		
	}
	else {
		// Recursive case, modify our current frame then step up to its superview
		
		NSRect currentFrame = [currentView frame];
		currentFrame.size.height += growth;
		currentFrame.origin.y -= growth;
		
		[currentView setFrame: currentFrame];
		
		[self autosizeSuperviewOfView: currentView withGrowth: growth];
	}
	
}


- (void) alterAutoresizeMasksForViews: (NSArray *)siblingViews 
					  surroundingView: (NSView *)originView {
	
	// We need to alter the autoresizing masks of surrounding views so they don't 
	// mess up the originView's vertical expansion or contraction.
	//
	// This method uses BSD-licensed code from the Disclosable View application 
	// copyright (c) 2002, Kurt Revis of Snoize (www.snoize.com) 
	
	NSEnumerator *enumerator = [siblingViews objectEnumerator];
	NSView *sibView;
	unsigned int mask;
	
	while (sibView = [enumerator nextObject]) {
		if (sibView != originView) {
			
			// save autoresizingMask for restoration later
			[viewMaskPairs addObject: 
				[[[IFViewMaskPair alloc] initWithView: sibView] autorelease]];
			
			mask = [sibView autoresizingMask];
			
			if (NSMaxY([sibView frame]) <= NSMaxY([originView frame])) {
				// This subview is below us. Make it stick to the bottom of the window.
				// It should not change height.
				mask &= ~NSViewHeightSizable;
				mask |= NSViewMaxYMargin;
				mask &= ~NSViewMinYMargin;
			} 
			else {
				// This subview is above us. Make it stick to the top of the window.
				// It should not change height.
				mask &= ~NSViewHeightSizable;
				mask &= ~NSViewMaxYMargin;
				mask |= NSViewMinYMargin;
			}
			
			[sibView setAutoresizingMask: mask];
		}
	}
}

- (void) restoreAutoresizeMasks {
	IFViewMaskPair *pair;
	
	while ([viewMaskPairs count]) {
		pair = [viewMaskPairs lastObject];
		[pair restoreAutoresizingMask];
		[viewMaskPairs removeLastObject];
	}
}


/* Overridden methods */

- (void) textDidChange: (NSNotification *)note {
	[self forceAutosize];
}

- (void) viewDidEndLiveResize {
	[self forceAutosize];
}

- (void) setStringValue: (NSString *)aString {
	NSTextView *myEditor = (NSTextView*)[self currentEditor];
	
	if (myEditor)
		[myEditor setString: aString];
	else
		[super setStringValue: aString];
	
	// If we don't delay, autosizing won't display correctly
	[NSThread sleepUntilDate: [NSDate dateWithTimeIntervalSinceNow: .05]];
	[self forceAutosize];
}

- (void) setHidden: (BOOL)flag {
	if ([self isHidden] != flag) {
		[super setHidden: flag];
		[self forceAutosize];
	}
}

- (void) dealloc {
	[viewMaskPairs release];
	[super dealloc];
}

@end