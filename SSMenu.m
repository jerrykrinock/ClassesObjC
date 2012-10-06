#import "SSMenu.h"

@implementation SSMenu

- (NSMenuItem *)owningMenuItem {
    return [[owningMenuItem retain] autorelease];
}

- (void)setOwningMenuItem:(NSMenuItem *)value {
    if (owningMenuItem != value) {
        [owningMenuItem release];
        owningMenuItem = [value retain];
    }
}


- (void)removeSubmenusFromAllItems {
	/* http://www.cocoabuilder.com/archive/message/cocoa/2007/2/22/179184
	
	Update 20070827.  Apple has fixed this bug in Leopard.  This method
	is only needed to support Tiger and Panther.
	
	Must remove submenu when dealloccing NSMenuItem?
	FROM : Jerry Krinock
	DATE : Thu Feb 22 04:03:17 2007
	
	I had subclassed NSMenu to make hierarchical contextual menus attached to
	cells in NSOutlineViews, following [1].  While troubleshooting some
	occasional crashes a few weeks ago, I saw reports indicating messages
	possibly sent to contextual menus/items that had disappeared a long time
	ago.  [Such as:  HIToolbox PopulateMenu()]  To study this, in my NSMenu
	subclass I placed NSLog statements in the -init and -dealloc methods.
	
	RESULT: As a hierarchical contextual menu was displayed and traversed, in
	the log I saw subclassed NSMenu objects being initted as they appeared.
	After the mouse was released and the menu disappeared, I saw that the
	top-level objects were deallocced, but the deeper objects were never
	deallocced, even after the parent outline, window and document were closed
	and deallocced.
	
	SOLUTION: I added code to send -setSubmenu:nil to each item of my NSMenus as
	they are being deallocced [2].  Now, all the nested NSMenus are always
	deallocced when the menu disappears.  Further, this also solves the problem
	of "Crazy Instead of Lazy", so now I don't need thebeLazy workarounds any
	more:
	
	http://www.cocoabuilder.com/archive/message/cocoa/2006/7/20/168013
	
	CONCLUSION: I think this indicates a leak in Apple's implementation of
	NSMenuItem; possibly that they retain the _submenu as an instance variable,
	but don't  set it to nil during -dealloc.  Either that, or they've got a
	retain cycle.  Methods -[NSMenuItem menu] and -[NSMenu supermenu], which
	refer to what I'd call their "parents" and "grandparents" respectively, have
	always worried me a little. */
	
	NSInteger lastIndex = [[self itemArray] count] - 1 ;
	NSInteger i ;
	for (i=lastIndex; i>=0; i--) {
		NSMenuItem* item = [self itemAtIndex:i] ;
		[item setSubmenu:nil] ;
	}
}

- (id)initWithOwningMenuItem:(id)owningMenuItem_ {
	self = [super initWithTitle:@"notYet"];
	if (self != nil) {
		[self setOwningMenuItem:owningMenuItem_] ;
	}
	return self;
}

- (void) dealloc {
	// To work around bug in Tiger (not needed in Leopard):
	[self removeSubmenusFromAllItems] ;

	[self setDelegate:nil] ;
	
	[super dealloc];
}

- (id)retain {
	return [super retain] ;
}

- (void)release {
	[super release] ;
}

@end