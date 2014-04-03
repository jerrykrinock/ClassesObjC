#import "SSYPrefsWindowController.h"

@interface SSYPrefsWindowController ()

-(void) mapTabsToToolbar ;

@end


@implementation SSYPrefsWindowController

+ (NSSet*)standardToolbarIdentifiers {
	return [NSSet setWithObjects:
			NSToolbarSeparatorItemIdentifier,
			NSToolbarSpaceItemIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier,
			NSToolbarCustomizeToolbarItemIdentifier,
			nil] ;
}

-(id)init
{
	if ((self = [super initWithWindowNibName:@"PrefsWindow"])) {
		itemsList = [[NSMutableDictionary alloc] init];
		baseWindowName = [@"" retain];
		autosaveName = [@"PrefsWindow" retain];
	}
	
	return self;
}


-(void)	dealloc
{
	[itemsList release];
	[baseWindowName release];
	[autosaveName release];
	
	[super dealloc] ;
}


-(void)	awakeFromNib {
	NSString*		key;
	NSInteger		index = 0;
	NSString*		wndTitle = nil;
	
	[[self window] setTitle:[self localizeString:@"windowTitlePrefs"]] ;

	// Generate a string containing the window's title so we can display the original window title plus the selected pane:
	wndTitle = [[ibOutlet_tabView window] title];
	if( [wndTitle length] > 0 ) {
		[baseWindowName release];
		baseWindowName = [[NSString stringWithFormat: @"%@ : ", wndTitle] retain];
	}
	
	[[self window] setFrameAutosaveName:@"PrefsWindow"] ; 
	
	// Select the preferences page the user last had selected when this window was opened:
	key = [NSString stringWithFormat: @"%@.prefspanel.recentTab", @"PrefsWindow"];
	index = [[NSUserDefaults standardUserDefaults] integerForKey:key];
	[ibOutlet_tabView selectTabViewItemAtIndex:index];
	
	// Actually hook up our toolbar and the tabs:
	[self mapTabsToToolbar];
}


/* -----------------------------------------------------------------------------
	mapTabsToToolbar:
		Create a toolbar based on our tab control.
		
		Tab title		-   Name for toolbar item.
		Tab identifier  -	Image file name and toolbar item identifier.
   -------------------------------------------------------------------------- */

-(void) mapTabsToToolbar {
    // Create a new toolbar instance, and attach it to our document window 
    NSToolbar		*toolbar =[[ibOutlet_tabView window] toolbar];
	NSInteger		itemCount = 0,
					x = 0;
	
	if( toolbar == nil )   // No toolbar yet? Create one!
		toolbar = [[[NSToolbar alloc] initWithIdentifier: [NSString stringWithFormat: @"%@.prefspanel.toolbar", autosaveName]] autorelease];
	
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];
	
	// Set up item list based on Tab View:
	itemCount = [ibOutlet_tabView numberOfTabViewItems];
	
	[itemsList removeAllObjects];	// In case we already had a toolbar.
	
	BOOL didFindFirstRealItem = NO ;
	for( x = 0; x < itemCount; x++ ) {
		NSTabViewItem*		theItem = [ibOutlet_tabView tabViewItemAtIndex:x];
		NSString*			theIdentifier = [theItem identifier];
        NSString*			theLabel = [self localizeString:[theItem label]] ;
		[itemsList setObject:theLabel forKey:theIdentifier];
		
		// Select the first tab view item which is a "real" item
		if (!didFindFirstRealItem) {
			if (YES
				// Flexible Space and Separator are not "real" items
				&& ![theIdentifier isEqualToString:NSToolbarFlexibleSpaceItemIdentifier]
				&& ![theIdentifier isEqualToString:NSToolbarSeparatorItemIdentifier]
				) {
				[ibOutlet_tabView selectTabViewItem:theItem] ;
				didFindFirstRealItem = YES ;
			}
		}

	}
    
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window 
    [[ibOutlet_tabView window] setToolbar: toolbar];
	
	// Set up window title:
	NSString* label = [[ibOutlet_tabView selectedTabViewItem] label] ;
	if (label) {
		[[ibOutlet_tabView window] setTitle: [baseWindowName stringByAppendingString: [self localizeString:label]]];
	}
	
	NSString* identifier = [[ibOutlet_tabView selectedTabViewItem] identifier] ;
	if( [toolbar respondsToSelector: @selector(setSelectedItemIdentifier:)] ) {
		[toolbar setSelectedItemIdentifier: identifier];
	}
}


/* -----------------------------------------------------------------------------
	orderFrontPrefsPanel:
		IBAction to assign to "Preferences..." menu item.
   -------------------------------------------------------------------------- */

-(IBAction)		orderFrontPrefsPanel: (id)sender
{
	[[ibOutlet_tabView window] makeKeyAndOrderFront:sender];
}


/* -----------------------------------------------------------------------------
	setAutosaveName:
		Name used for saving state of prefs window.
   -------------------------------------------------------------------------- */

-(void)			setAutosaveName: (NSString*)name
{
	[name retain];
	[autosaveName release];
	autosaveName = name;
}


-(NSString*)	autosaveName
{
	return autosaveName;
}


/* -----------------------------------------------------------------------------
toolTipForLabel:
Subclasses should over-ride this to provide tooltips for each toobar item
-------------------------------------------------------------------------- */

-(NSString*)toolTipForIdentifier:(NSString*)identifier
{
	return nil ;
}

/* -----------------------------------------------------------------------------
	NSToolbar Delegate method:

	toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:
		Create an item with the proper image and name based on our list
		of tabs for the specified identifier.
   -------------------------------------------------------------------------- */

-(NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem   *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
	NSString* itemLabel = [itemsList objectForKey:itemIdent] ;

	/* if([[SSYPrefsWindowController standardToolbarIdentifiers] member:itemIdent] != nil) {
	 // This is a standard toolbar item which Cocoa will configure
	 }
	 else  */
	if([[SSYPrefsWindowController standardToolbarIdentifiers] member:itemIdent] != nil) {
			// This is a standard toolbar item which Cocoa will configure
		}
	else if	(itemLabel != nil) {
		// Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel: itemLabel];
		[toolbarItem setPaletteLabel: itemLabel];
		[toolbarItem setTag:[ibOutlet_tabView indexOfTabViewItemWithIdentifier:itemIdent]];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		[toolbarItem setToolTip: [self toolTipForIdentifier:itemIdent]];
		[toolbarItem setImage: [NSImage imageNamed:itemIdent]];
		
		// Tell the item what message to send when it is clicked 
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(changePanes:)]; }
	else
	{
		// itemIdent refered to a toolbar item that is not provide or supported by us or cocoa 
		// Returning nil will inform the toolbar this kind of item is not supported 
		toolbarItem = nil;
    }
	
    return toolbarItem;
}

/* -----------------------------------------------------------------------------
	toolbarSelectableItemIdentifiers:
		Make sure all our custom items can be selected. NSToolbar will
		automagically select the appropriate item when it is clicked.
   -------------------------------------------------------------------------- */

-(NSArray*) toolbarSelectableItemIdentifiers: (NSToolbar*)toolbar
{
	return [itemsList allKeys];
}


/* -----------------------------------------------------------------------------
	changePanes:
		Action for our custom toolbar items that causes the window title to
		reflect the current pane and the proper pane to be shown in response to
		a click.
   -------------------------------------------------------------------------- */

- (void)selectTabViewItemWithTag:(NSInteger)tag
                           label:(NSString*)label {
    [ibOutlet_tabView selectTabViewItemAtIndex:tag] ;
	[[ibOutlet_tabView window] setTitle: [baseWindowName stringByAppendingString:label]];
	
	NSString* key = [NSString stringWithFormat: @"%@.prefspanel.recentpage", autosaveName];
	[[NSUserDefaults standardUserDefaults] setInteger:tag forKey:key];
}

- (IBAction)	changePanes: (id)sender
{
    [self selectTabViewItemWithTag:[sender tag]
                             label:[sender label]] ;
}

/* -----------------------------------------------------------------------------
	toolbarDefaultItemIdentifiers:
		Return the identifiers for all toolbar items that will be shown by
		default.
		This is simply a list of all tab view items in order.
   -------------------------------------------------------------------------- */

-(NSArray*) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
	NSInteger			itemCount = [ibOutlet_tabView numberOfTabViewItems],
						x;
	//NSTabViewItem*		theItem = [ibOutlet_tabView tabViewItemAtIndex:0];
	//NSMutableArray*	defaultItems = [NSMutableArray arrayWithObjects: [theItem identifier], NSToolbarSeparatorItemIdentifier, nil];
	NSMutableArray*	defaultItems = [NSMutableArray array];
	
	for( x = 0; x < itemCount; x++ )
	{
		NSTabViewItem* theItem = [ibOutlet_tabView tabViewItemAtIndex:x];
		[defaultItems addObject: [theItem identifier]];
	}
	
	return defaultItems;
}

- (BOOL)revealTabViewIdentifier:(NSString*)identifier {
    BOOL didDo = NO ;
    NSInteger i = 0 ;
    for (NSTabViewItem* item in [ibOutlet_tabView tabViewItems]) {
        // item i=0 is the flexible space item
        if ([[item identifier] isEqualToString:identifier]) {
            NSToolbar *toolbar =[[ibOutlet_tabView window] toolbar] ;
            [toolbar setSelectedItemIdentifier:identifier] ;
            NSToolbarItem* toolbarItem = nil ;
            if (i < [[toolbar items] count]) {
                toolbarItem = [[toolbar items] objectAtIndex:i] ;
            }
            NSString* label = [toolbarItem label] ;
            if (label) {
                [self selectTabViewItemWithTag:i
                                         label:label] ;
                didDo = YES ;
            }
            else {
                NSLog(@"Internal Error 624-0202 %@", [item identifier]) ;
            }
            break ;
        }
        i++ ;
    }
    
    return didDo ;
}


/* -----------------------------------------------------------------------------
	toolbarAllowedItemIdentifiers:
		Return the identifiers for all toolbar items that *can* be put in this
		toolbar. We allow a couple more items (flexible space, separator lines
		etc.) in addition to our custom items.
   -------------------------------------------------------------------------- */

-(NSArray*) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
    NSMutableArray*		allowedItems = [[[itemsList allKeys] mutableCopy] autorelease];
	
	[allowedItems addObjectsFromArray:[[SSYPrefsWindowController standardToolbarIdentifiers] allObjects]];
	
	return allowedItems;
}

- (NSString*)localizeString:(NSString*)key {
	return key ;
}


@end