#import "SSYTabView.h"

NSString* const SSYTabViewDidChangeItemNotification = @"SSYTabViewDidChangeItemNotification" ;
static NSString* SSYTabViewObservedKeyPath = @"selectedTabIndex" ;

@implementation SSYTabView

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

- (void)awakeFromNib {
	// Set the initial state
	NSTabViewItem* selectedTabViewItem = [self selectedTabViewItem] ;
	// We have required that corresponding tab view items and toolbar items
	// have the same identifiers.  So we can do this:
	NSString* identifier = [selectedTabViewItem identifier] ;
	[toolbar setSelectedItemIdentifier:identifier] ;
}

// Needed for propagating changes from toolbar to tab view
- (IBAction)changeTabViewItem:(NSToolbarItem*)sender {
	NSString* identifier = [sender itemIdentifier] ;
	// We have required that corresponding tab view items and toolbar items
	// have the same identifiers.  So we can do this:
	[self selectTabViewItemWithIdentifier:identifier] ;
}

@end