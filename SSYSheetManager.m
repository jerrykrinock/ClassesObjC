#import "SSYSheetManager.h"
#import "NSInvocation+Quick.h"


static SSYSheetManager* sharedSheetManager = nil ;


@implementation SSYSheetManager

- (NSMutableDictionary*)queues {
	if (!queues) {
		queues = [[NSMutableDictionary alloc] init] ;
	}
	
	return queues ;
}

- (NSCountedSet*)retainedHelpers {
	if (!m_retainedHelpers) {
		m_retainedHelpers = [[NSCountedSet alloc] init] ;
	}
	
	return m_retainedHelpers ;
}

- (void)dealloc {
    [queues release] ;
    [m_retainedHelpers release] ;
    
    [super dealloc] ;
}

- (NSWindow*)sheetInInvocation:(NSInvocation*)invocation {
	NSWindow* sheet = nil ;
	[invocation getArgument:&sheet
					atIndex:2] ;
	// index 2 because 0 and 1 are target and selector
	if (NSEqualRects([sheet frame], NSZeroRect)) {
		sheet = nil ;
	}
	
	return sheet ;
}


#if 0
- (NSString*)descriptionOfQueues {
	NSMutableString* answer = [[NSMutableString alloc] init] ;
	for (NSNumber* windowNumber in [self queues]) {
		[answer appendFormat:@"For window %@:\n", windowNumber] ;
		NSArray* queue = [[self queues] objectForKey:windowNumber] ;
		NSInteger i = 0 ;
		for (NSInvocation* invocation in queue) { 
			NSWindow* sheet = [self sheetInInvocation:invocation] ;
			NSString* string = @"No text found" ;
			for (NSView* subview in [[sheet contentView] subviews]) {
				if ([subview respondsToSelector:@selector(string)]) {
					string = [(NSText*)subview string] ;
				}
				else if ([subview respondsToSelector:@selector(objectValue)]) {
					id objectValue = [(NSTextField*)subview objectValue] ;
					if ([objectValue isKindOfClass:[NSString class]]) {
						if ([objectValue length] > [string length]) {
							string = (NSString*)objectValue ;
						}
					}
				}
			}
			
			if (sheet) {
				[answer appendFormat:@"   sheet %ld will display text: %@\n",
				 (long)i,
				 string] ;
			}
			else {
				[answer appendFormat:@"   sheet %ld has zero frame, will be skipped\n",
				(long)i] ;
			}
			
			i++ ;
		}
	}
	
	NSString* copy = [[answer copy] autorelease] ;
	[answer release] ;
	
	return copy ;
}
#endif
+ (SSYSheetManager*)sharedSheetManager {
	@synchronized(self) {
        if (!sharedSheetManager) {
            sharedSheetManager = [[self alloc] init] ; 
        }
    }
	
	// No autorelease.  This singleton sticks around forever.
    return sharedSheetManager ;
}

- (void)windowWillClose:(NSNotification*)note {
	NSWindow* window = [note object] ;
	NSInteger windowNumber = [window windowNumber] ;
	NSNumber* windowNumberObject = [NSNumber numberWithInteger:windowNumber] ;
	[[self queues] removeObjectForKey:windowNumberObject] ;
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSWindowWillCloseNotification
												  object:window] ;
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSWindowDidEndSheetNotification
												  object:window] ;
}

- (void)windowDidEndSheet:(NSNotification*)note {
	NSWindow* window = [note object] ;
	NSInteger windowNumber = [window windowNumber] ;
	NSNumber* windowNumberObject = [NSNumber numberWithInteger:windowNumber] ;
	NSMutableArray* queue = [[self queues] objectForKey:windowNumberObject] ;
	if ([queue count] > 0) {
		NSWindow* sheet = nil ;
		NSInvocation* invocation = nil ;
		while ((sheet == nil) && ([queue count] > 0)) {
			invocation = [[[queue objectAtIndex:0] retain] autorelease] ;
            // The -retain, -autorelease is so that invocation doesn't get
            // deallocced when we remove it from queue, 2 lines below…
			sheet = [self sheetInInvocation:invocation] ;
			[queue removeObjectAtIndex:0] ;
		}

		if (!sheet) {
			// The queue does not have any sheets of nonzero size.
			return ;
		}
		
		// When I first tested this method, the following line began the sheet:
		//    [invocation invoke]
		// But in subsequent testing I found that it did not.  So I thought
		// that, even though this method is triggered by an NSWindowDidEndSheetNotification,
		// maybe there was still some vestige of the sheet hanging around that
		// inhibited another sheet from beginning.  So, I changed it to
		// perform after a delay of 0.0 and that fixed the problem....
		
		[invocation performSelector:@selector(invoke)
						 withObject:nil
						 afterDelay:0.0] ;
	}
}

- (NSMutableArray*)queueForWindow:(NSWindow*)window {
	NSInteger windowNumber = [window windowNumber] ;
	NSNumber* windowNumberObject = [NSNumber numberWithInteger:windowNumber] ;
	NSMutableArray* queue = [[self queues] objectForKey:windowNumberObject] ;
	if (!queue) {
		queue = [NSMutableArray arrayWithCapacity:4] ;
		// Note: An app which wants to queue more than 4 sheets
		// on a single window is probably in deep doodoo anyhow.
		[[self queues] setObject:queue
									forKey:windowNumberObject] ;
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(windowWillClose:)
													 name:NSWindowWillCloseNotification
												   object:window] ;
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(windowDidEndSheet:)
													 name:NSWindowDidEndSheetNotification
												   object:window] ;
		[[self queues] setObject:queue
									forKey:windowNumberObject] ;
	}
	
	return queue ;
}

+ (void)enqueueSheet:(NSWindow*)sheet
	  modalForWindow:(NSWindow*)documentWindow
        retainHelper:(id)helper
	   modalDelegate:(id)modalDelegate
	  didEndSelector:(SEL)didEndSelector
		 contextInfo:(void*)contextInfo {
	if (NSEqualRects([sheet frame], NSZeroRect)) {
		return ;
	}
    
    if (helper) {
        [[[self sharedSheetManager] retainedHelpers] addObject:helper] ;
    }
	
	if ([documentWindow attachedSheet] == nil) {
		// No sheet currently on window.  Begin immediately.
		[NSApp beginSheet:sheet
		   modalForWindow:documentWindow
			modalDelegate:modalDelegate
		   didEndSelector:didEndSelector
			  contextInfo:contextInfo] ;
	}
	else {
		// Wrap as an invocation and add to queue
		NSInvocation* invocation = [NSInvocation invocationWithTarget:NSApp
															 selector:@selector(beginSheet:modalForWindow:modalDelegate:didEndSelector:contextInfo:)
													  retainArguments:YES
													argumentAddresses:&sheet, &documentWindow, &modalDelegate, &didEndSelector, &contextInfo] ;
		SSYSheetManager* sharedSheetManager = [self sharedSheetManager] ;
		NSMutableArray* queue = [sharedSheetManager queueForWindow:documentWindow] ;
		[queue addObject:invocation] ;
	}
}

+ (void)releaseHelper:(id)helper {
    [[[self sharedSheetManager] retainedHelpers] removeObject:helper] ;
}

+ (void)autoreleaseHelper:(id)helper {
    [helper retain] ;
    [[[self sharedSheetManager] retainedHelpers] removeObject:helper] ;
    [helper autorelease] ;
}


 @end