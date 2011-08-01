#import "SSYTempWindowController.h"


@implementation SSYTempWindowController

+ (NSString*)nibName {
	NSLog(@"Internal Error 235-0832") ;
	return nil ;
}


- (void)goAway {
	[[NSNotificationCenter defaultCenter] removeObserver:self] ;
	[[self window] setWindowController:nil] ;
	[self release] ;
}


- (id)init {
	self = [super initWithWindowNibName:[[self class] nibName]] ;
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(goAway)
													 name:NSWindowWillCloseNotification
												   object:[self window]] ;
	}
	
	return self ;
}

+ (id)showWindow {
	SSYTempWindowController* instance = nil ;

	// See if a window with a window controller of this class already exists
	for (NSWindow* window in [NSApp windows]) {
		NSWindowController* candidate = [window windowController] ;
		if ([candidate isMemberOfClass:[self class]]) {
			instance = (SSYTempWindowController*)candidate ;
		}
	}
	
	if (!instance) {
		instance = [[self alloc] init] ;
	}
	
	[instance showWindow:self] ;
	
	return instance ;
}

@end