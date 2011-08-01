#import "SSYDragDestinationTextView.h"
#import "NSObject+SuperUtils.h"
#import "NSView+FocusRing.h"
#import "SSYDragDestinationTextViewDelegate.h"


@implementation SSYDragDestinationTextView : NSTextView


- (void)awakeFromNib {
	[self patchPreLeopardFocusRingDrawingForScrolling] ;
	
	// Safely invoke super
	[self safelySendSuperSelector:_cmd
						arguments:nil] ;
}

- (void)setTabToNextKeyView:(BOOL)yn {
	_tabToNextKeyView = yn ;
}

/*- (void)keyDown:(NSEvent*)event {
	NSString *s = [event charactersIgnoringModifiers] ;
	unichar keyChar = 0 ;
	if ([s length] == 1) {
		keyChar = [s characterAtIndex:0] ;

		// Our superclass NSTextView accepts tabs and backtabs as text.
		// If we want _tabToNextKeyView, we re-implement the NSView behavior
		// of selecting the next or previous key view
		if ((keyChar == NSTabCharacter)&& _tabToNextKeyView) {
			[[self window] selectNextKeyView:self] ;
		}
		else if ((keyChar == NSBackTabCharacter) && _tabToNextKeyView) {
			[[self window] selectPreviousKeyView:self] ;
		}
		else {
			// Handle using super's (i.e. NSTextView) -interpretKeyEvents:,
			// which will typewrite the key-downed character
			NSArray* events = [NSArray arrayWithObject:event] ;
			[self interpretKeyEvents:events] ;
		}
	}
}
*/

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	NSDragOperation answer = NSDragOperationNone ;
	NSPasteboard* pasteboard = [sender draggingPasteboard] ;
	NSString *anAcceptableType = [pasteboard availableTypeFromArray:[self registeredDraggedTypes]];	
	
	if (anAcceptableType != nil) {
		// Don't be hidden!!!...
		[NSApp activateIgnoringOtherApps:YES] ;
		[[self window] makeKeyAndOrderFront:self] ;
		
		answer = NSDragOperationCopy ; // Accept data as a copy operation
		
		_isInDrag = YES ;
		[self selectAll:self] ;
		[self setNeedsDisplay:YES] ;
	}
	
	return answer ;
}

// Called whenever a drag exits our drop zone
- (void)draggingExited:(id <NSDraggingInfo>)sender {
	_isInDrag = NO ;
	[self setSelectedRange:NSMakeRange(0,0)] ;
	[self setNeedsDisplay:YES] ;
}

// Method to determine if we can accept the drop
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
	BOOL answer = NO ;
	
	// Panther does not respond to -registeredDraggedTypes.
	// We simply do not support dragging in Panther.
	if ([self respondsToSelector:@selector(registeredDraggedTypes)]) {
		NSPasteboard* pasteboard = [sender draggingPasteboard] ;
		NSString* anAcceptableType = [pasteboard availableTypeFromArray:[self registeredDraggedTypes]] ;
		if (anAcceptableType != nil) {
			_isInDrag = NO ;
			[self setSelectedRange:NSMakeRange(0,0)] ;
			[self setNeedsDisplay:YES] ;
			answer = YES ;
		}
	}
	
	return answer ;
} 

// Forward the drop to the delegate, or else, its window's delegate
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    BOOL answer ;
	if ([self respondsToSelector:@selector(delegate)]) {
		answer = [(id <SSYDragDestinationTextViewDelegate>)[self delegate] performDragOperation:sender
										   destination:self] ;
	}
	else if ([[[self window] delegate] respondsToSelector:@selector(performDragOperation:destination:)]) {
		answer = [(id <SSYDragDestinationTextViewDelegate>)[[self window] delegate] performDragOperation:sender
				  destination:self] ;
	}
	
	return answer ;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
}

- (void)drawRect:(NSRect)rect {
	[super drawRect:rect] ;
	if (_isInDrag) {
		[self drawFocusRing] ;
	}
}

@end

/*

	  
	  NSPasteboard *pb = [sender draggingPasteboard];
 NSString *value;
 NSString *type;
 type = [pb availableTypeFromArray:[NSArray arrayWithObject:NSStringPboardType]];
 if (type) {
 value = [pb stringForType:NSStringPboardType];
 id target = [self myDropTarget];
 SEL action = [self myDropAction];
 [target performSelector:action withObject:value];
 return YES;
 }
 return NO;
 }
  
 
 - (BOOL)performDragOperation:(id <NSDraggingInfo>)info {
	NSPasteboard* pasteboard = [info draggingPasteboard] ;
	
	NSArray* acceptableTypes ;
	if ([self respondsToSelector:@selector(orderedRegisteredDraggedTypes)]) {
		acceptableTypes = [self orderedRegisteredDraggedTypes] ;
	}
	else {
		acceptableTypes = [self registeredDraggedTypes] ;
	}
	NSString *bestType = [pasteboard availableTypeFromArray:acceptableTypes] ;	
	
	id object = nil ;
	
	if ([bestType isEqualToString:@"MV Super-secret message transfer pasteboard type"]) {
		NSLog(@"Tried drag of Apple Mail message: not supported yet.") ;
		//		// Three reasons why this code is commented out:
		//		// 1.  Import takes 30 seconds or more.
		//		// 2.  Import comes in html, as shown below.  Must filter to plain text somehow:
		//		// this:</DIV><DIV><BR></DIV><DIV>Licensee Name:</DIV><DIV>bH New Sale =
		//		// 150953</DIV><DIV><BR></DIV><DIV>Serial =
		//		// Number:</DIV><DIV>CbN34wJoOVX7Jgva</DIV><DIV><BR></DIV><DIV>Bookmarksman =		
		//		// Neither of problems 1 or 2 are fixed by uncommenting "theLock" in
		//		// CIPAppleScriptHelper.m
		//		// 3.  According to Apple Documentation, should not use [self class] in the
		//		// next line but should use [MyApp class] instead.  But MyApp is not
		//		// declared anywhere.  Maybe this could be fixed by using -classNamed:@"MyApp".
		//		// But who do you send that instance message to?
		//		NSBundle *bundle = [NSBundle bundleForClass:[self class]];
		//		NSLog(@"Hullo!  bundlePath = %@", [bundle bundlePath]) ;
		//		NSString *resourcePath = [bundle pathForResource: @"MailHelper"
		//												  ofType: @"applescript"];
		//		
		//		NSLog(@"Hullo!  resourcePath = %@", resourcePath) ;
		//		NSLog(@"Hullo!  1 Getting result from helper") ;
		//		NSAppleEventDescriptor *result =
		//			[[CIPAppleScriptHelper sharedHelper] callInResource: resourcePath
		//														 script: @"getSelectedMailCount"] ;
		//		
		//		NSLog(@"Hullo!  1 result = %@", result) ;
		//		NSMutableString* textFromMessages = [[NSMutableString alloc] init] ;
		//		
		//		if(result) {
		//			int k;
		//			NSString *mailMessage;
		//			
		//			NSLog(@"Hullo!  2 Getting result from helper") ;
		//			result = [[CIPAppleScriptHelper sharedHelper] callInResource: resourcePath
		//																  script: @"getSelectedMailBodies"];
		//			NSLog(@"Hullo!  2 result = %@", result) ;
		//			int numberOfItems = [result numberOfItems];
		//			NSLog(@"Hullo!  numberOfItems = %i", numberOfItems) ;
		//			for(k=1; k <= numberOfItems; k++) {
		//				mailMessage = [[result descriptorAtIndex: k] stringValue] ;
		//				NSLog(@"Hullo!  mailMessage = %@", mailMessage) ;
		//				[textFromMessages appendString:mailMessage] ;
		//			}		
		//		}
		//		
		//		if ([textFromMessages length] > 0) {
		//			object = [textFromMessages copy] ;
		//		}
		//		
		//		[textFromMessages release] ;
		
	}
	
	if (!object) {
		object = [pasteboard propertyListForType:bestType] ;
		if (!object) {
			object = [pasteboard stringForType:bestType] ;
			if (!object) {
				object = [pasteboard dataForType:bestType] ;
			}
		}
	}
	
	if (object) {
		[[self target] performSelector:@selector(swallowDraggedObject:) withObject:object] ;
		return YES ;
	}
	
	return NO ;
}
*/


