@interface SSYPrefsWindowController : NSWindowController
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= 1060) 
	<NSToolbarDelegate>
#endif
{
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
 string for the given key.

 @details  Do not return nil.  If the given key cannot be localized, 
 return the key itself.
 
 The strings which will be passed to this method are:
 • The 'label' of any tab in the nib file, for which this method
 should return the localized title of the tab.
 • The string @"windowTitlePrefs", for which this method should return
 the title of the Preferences window
*/
-(NSString*)localizeString:(NSString*)key ;

/*!
 @brief    Subclasses should over-ride this to provide tooltips for
 a given toolbar item identifier.
 
 @details  The default implementation returns nil.
 */
-(NSString*)toolTipForIdentifier:(NSString*)identifier ;

- (BOOL)revealTabViewIdentifier:(NSString*)identifier ;

@end
