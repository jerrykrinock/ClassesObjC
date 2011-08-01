@interface SSYPrefsWindowController : NSWindowController {
	IBOutlet NSTabView*		ibOutlet_tabView ;	///< The tabless tab-view that we're a switcher for.
	NSMutableDictionary*	itemsList ;			///< Auto-generated from tab view's items.
	NSString*				baseWindowName ;	///< Auto-fetched at awakeFromNib time. We append a colon and the name of the current page to the actual window title.
	NSString*				autosaveName ;		///< Identifier used for saving toolbar state and current selected page of prefs window.
}


+ (NSSet*)standardToolbarIdentifiers ;

-(void)			setAutosaveName: (NSString*)name;
-(NSString*)	autosaveName;

// Action for hooking up this object and the menu item:
-(IBAction)		orderFrontPrefsPanel: (id)sender;


/*!
 @brief    Subclasses should override this method to provide a localized
 label for the given label.

 @details  The default implementation simply capitalizes the given label.
 @param    label  The unlocalized label for the tab view item, typically
 assigned in a nib file.
*/
-(NSString*)localizeLabel:(NSString*)label ;


/*!
 @brief    Subclasses should over-ride this to provide tooltips for
 a given toolbar item identifier.
 
 @details  The default implementation returns nil.
 */
-(NSString*)toolTipForIdentifier:(NSString*)identifier ;


@end
