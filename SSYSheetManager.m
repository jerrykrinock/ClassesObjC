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
	NSNumber* windowNumberObject = [NSNumber numberWithInt:windowNumber] ;
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
	NSNumber* windowNumberObject = [NSNumber numberWithInt:windowNumber] ;
	NSMutableArray* queue = [[self queues] objectForKey:windowNumberObject] ;
	if ([queue count] > 0) {
		NSInvocation* invocation = [queue objectAtIndex:0] ;

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
		[queue removeObjectAtIndex:0] ;
	}
}

- (NSMutableArray*)queueForWindow:(NSWindow*)window {
	NSInteger windowNumber = [window windowNumber] ;
	NSNumber* windowNumberObject = [NSNumber numberWithInt:windowNumber] ;
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
	   modalDelegate:(id)modalDelegate
	  didEndSelector:(SEL)didEndSelector
		 contextInfo:(void*)contextInfo {
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

 @end