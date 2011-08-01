#import "SSYToolbar.h"
#import "MAKVONotificationCenter.h"
#import "BkmxGlobals.h"

NSString* const constBindingToolbarDisplayStyle = @"displayStyle" ;
static BOOL static_alreadyEntered = NO ;

// Superclass (NSToolbar) properties
static NSString* const constKeyDisplayMode = @"displayMode" ;
static NSString* const constKeySizeMode = @"sizeMode" ;

@implementation SSYToolbar

+ (void)initialize {
	if (self == [SSYToolbar class]) {
		[self exposeBinding:constBindingToolbarDisplayStyle] ;
	}
}

- (void)setDisplayStyle:(SSYToolbarDisplayStyle)displayStyle {
	NSToolbarDisplayMode displayMode = (displayStyle != SSYToolbarDisplayStyleTextOnly) ? NSToolbarDisplayModeIconAndLabel : NSToolbarDisplayModeLabelOnly ;
	[self setDisplayMode:displayMode] ;
	NSToolbarSizeMode sizeMode = (displayStyle == SSYToolbarDisplayStyleTextAndSmallIcons) ? NSToolbarSizeModeSmall : NSToolbarSizeModeRegular ;
	[self setSizeMode:sizeMode] ;
}

- (SSYToolbarDisplayStyle)displayStyle {
	if ([self displayMode] == NSToolbarDisplayModeLabelOnly) {
		return SSYToolbarDisplayStyleTextOnly ;
	}
	return ([self sizeMode] == NSToolbarSizeModeSmall) ? SSYToolbarDisplayStyleTextAndSmallIcons : SSYToolbarDisplayStyleTextAndRegularIcons ;
}


#if 0
//This is not needed?
+ (NSSet*)keyPathsForValuesAffectingDisplayStyle {
	return [NSSet setWithObjects:
			constKeyDisplayMode,
			constKeySizeMode,
			nil] ;
}
#endif

/*
 The following override is a kludge is to fix a very strange bug:
 Open two documents.
 Set Prefs > Appearance > Toolbar Icons to None.
 Turn breakpoints on.
 Click "Quick Search" in one of the docs.
 Icons will appear in BOTH documents.
 Debugger told me that, somehow, -[super setDisplayMode:] in the
 first document was invoking -[super setDisplayMode:] in the second
 document.  Unbelieveable, but the proof is that using the
 static variable static_alreadyEntered to lock out re-entry
 fixed the problem.   This seems to have nothing to do with the
 binding, because I tried implementing -[SSYToolbar bind:::] myself
 in here, and only implemented one observer in the forward 
 direction, but this did not solve the problem.  Very mysterious.
 Try it if you don't believe it.
 Fixed in BookMacster 0.9.10.
 */
- (void)setDisplayMode:(NSToolbarDisplayMode)displayMode {
	if (!static_alreadyEntered) {
		static_alreadyEntered = YES ;
		[super setDisplayMode:displayMode] ;
		static_alreadyEntered = NO ;
	}
}

// The following two methods

- (void)shutDown {
	m_isShutDown = YES ;
}

- (void)validateVisibleItems {
	if (!m_isShutDown) {
		[super validateVisibleItems] ;
	}
}

@end