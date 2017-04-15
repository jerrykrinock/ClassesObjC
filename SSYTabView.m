#import "SSYTabView.h"

NSString* const SSYTabViewDidChangeItemNotification = @"SSYTabViewDidChangeItemNotification" ;
static NSString* SSYTabViewObservedKeyPath = @"selectedTabIndex" ;

@implementation SSYTabView

#if 0
#warning Logging SSYTabView Memory Managment
#define LOG_SSYTABVIEW_MEMORY_MANAGEMENT 1
#else
#endif

#if LOG_SSYTABVIEW_MEMORY_MANAGEMENT
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder] ;
	NSString* line = [NSString stringWithFormat:@"%p initted %03ld %@", self, (long)[self retainCount], SSYDebugCaller()] ;
    printf("%s\n", [line UTF8String]) ;
    
    return self ;
}

- (id)retain {
	id x = [super retain] ;
	NSString* line = [NSString stringWithFormat:@"retain  %03ld %@", (long)[self retainCount], SSYDebugCaller()] ;
    printf("%s\n", [line UTF8String]) ;
	return x ;
}

- (id)autorelease {
	NSString* line = [NSString stringWithFormat:@"autorelease %@", SSYDebugCaller()] ;
    printf("%s\n", [line UTF8String]) ;
	id x = [super autorelease] ;
	return x ;
}

- (oneway void)release {
	NSInteger rc = [self retainCount] ;
	NSString* line = [NSString stringWithFormat:@"release %03ld %@", (long)rc-1, SSYDebugCaller()] ;
    printf("%s\n", [line UTF8String]) ;
#if 0
    if (rc == 1) {
        [self retain] ;
        [self autorelease] ;
    }
#endif
    
	[super release] ;
	return ;
}

- (void)dealloc {
	NSInteger rc = [self retainCount] ;
	NSString* line = [NSString stringWithFormat:@"deallocc %03ld %p %@", (long)rc-1, self, SSYDebugCaller()] ;
    printf("%s\n", [line UTF8String]) ;

    [super dealloc] ;
}
#endif

+ (void)initialize {
	if (self == [SSYTabView class] ) {
		[self exposeBinding:SSYTabViewObservedKeyPath] ;
	}
}

// This is the only support that is needed for the segmented control
- (NSInteger)selectedTabIndex {
	NSInteger selectedTabIndex ;
	@synchronized(self) {
		selectedTabIndex = m_selectedTabIndex ; ;
	}
	return selectedTabIndex ;
}

- (void)setSelectedTabIndex:(NSInteger)selectedTabIndex {
	@synchronized(self) {
		m_selectedTabIndex = selectedTabIndex ;

		if (selectedTabIndex == [[self tabViewItems] indexOfObject:[self selectedTabViewItem]]) {
			return ;
		}
		
		NSString* identifier = [[self tabViewItemAtIndex:selectedTabIndex] identifier] ;
		[toolbar setSelectedItemIdentifier:identifier] ;

		// Now, we need to set the selected tab in super.  There are three
		// methods that we could choose to do this:
		//   selectTabViewItem:
		//   selectTabViewItemAtIndex:
		//   selectTabViewItemWithIdentifier:
		// Presumably, one of these methods is the "designated/base" method
		// which is invoked by the other two in super's implementation, and
		// this is the one we want to invoke.  Invoking either of the other 
		// two will cause an infinite loop when the designated/base method
		// is invoked, because that message will come back to one of our
		// overrides (see below) since it will not be sent to super in
		// Apple's implementation.  As it turns out, the correct answer,
		// the only one which does not cause an infinite loop, is
		// selectTabViewItem.  However, since Apple is free to change the
		// implementation, we instead use the method which is most
		// straightforward, and avoid the infinite loop by setting
		// m_lockOutInfiniteLoop momentarily, and check it in our
		// overrides below.
		m_lockOutInfiniteLoop = YES ;
		[super selectTabViewItemAtIndex:selectedTabIndex] ;
        
		// When the above message invokes any of the methods we have
		// overridden below, they'll route to super too.
		m_lockOutInfiniteLoop = NO ;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:SSYTabViewDidChangeItemNotification
															object:self] ;
	}
}

- (void)selectTabViewItem:(NSTabViewItem *)tabViewItem {
	if (m_lockOutInfiniteLoop) {
		[super selectTabViewItem:tabViewItem] ;
	}
	else {
		NSInteger index = [[self tabViewItems] indexOfObject:tabViewItem] ;
		if (index != NSNotFound) {
			[self setSelectedTabIndex:index] ;
		}
	}
}

- (void)selectTabViewItemAtIndex:(NSInteger)index {
	if (m_lockOutInfiniteLoop) {
		[super selectTabViewItemAtIndex:index] ;
	}
	else {
		[self setSelectedTabIndex:index] ;
	}
}

- (void)selectTabViewItemWithIdentifier:(id)identifier {
	if (m_lockOutInfiniteLoop) {
		[super selectTabViewItemWithIdentifier:identifier] ;
	}
	else {
		NSInteger index = [[[self tabViewItems] valueForKey:@"identifier"] indexOfObject:identifier] ;
		if (index != NSNotFound) {
			[self setSelectedTabIndex:index] ;
		}
	}
}

// Needed for propagating changes from toolbar to tab view
- (IBAction)changeTabViewItem:(NSToolbarItem*)sender {
	NSString* identifier = [sender itemIdentifier] ;
	// We have required that corresponding tab view items and toolbar items
	// have the same identifiers.  So we can do this:
	[self selectTabViewItemWithIdentifier:identifier] ;
}

- (void)awakeFromNib {
    // Set the initial state
	NSTabViewItem* selectedTabViewItem = [self selectedTabViewItem] ;
	// We have required that corresponding tab view items and toolbar items
	// have the same identifiers.  So we can do this:
	NSString* identifier = [selectedTabViewItem identifier] ;

    [toolbar setSelectedItemIdentifier:identifier] ;
}

@end
