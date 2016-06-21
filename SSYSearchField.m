#import "SSYSearchField.h"

NSString* const SSYSearchFieldDidCancelNotification = @"SSYSearchFieldDidCancelNotification" ;

@interface SSYSearchField ()

@property (assign) id cancelButtonTarget ;
@property (assign) SEL cancelButtonAction ;

@end


@implementation SSYSearchField

@synthesize cancelButtonTarget = m_cancelButtonTarget ;
@synthesize cancelButtonAction = m_cancelButtonAction ;

- (void)awakeFromNib {
	NSSearchFieldCell* cell = [self cell] ;
	NSButtonCell* cancelButtonCell = [cell cancelButtonCell] ;
	
	// Get the target and action of the cancelButtonCell
	[self setCancelButtonTarget:[cancelButtonCell target]] ;
	[self setCancelButtonAction:[cancelButtonCell action]] ;
	
	// Tell the cancelButtonCell to send message to us instead
	// of its original target and action
	[cancelButtonCell setTarget:self] ;
	[cancelButtonCell setAction:@selector(cancelAction:)] ;
}

- (IBAction)cancelAction:(id)sender {
	// Post our notification
	[[NSNotificationCenter defaultCenter] postNotificationName:SSYSearchFieldDidCancelNotification
														object:self] ;
	
	// Invoke the original target|action of the cancelButtonCell
	[[self cancelButtonTarget] performSelector:[self cancelButtonAction]
									withObject:sender] ;
}

- (void)appendToRecentSearches:(NSString*)newString {
    if ([newString length] > 0) {
        NSMutableArray* recentSearches = [[self recentSearches] mutableCopy] ;

        // In case newString is a re-do of an earlier search,
        [recentSearches removeObject:newString] ;
        // Now add newString at the top
        [recentSearches insertObject:newString
                             atIndex:0] ;

        if (![[self recentSearches] isEqualToArray:recentSearches]) {
            [self setRecentSearches:recentSearches] ;
            /* I have four times seen a crash here, most recently while developing
             BkmkMgrs ver 2.0 in macOS 10.1.2, when the above method attempts
             to post a notification.  Could not reproduce after that.  Crash
             occurs when framework method attempts to post a notification.
             But I could not identify the notification because Xcode gives
             me the "couldn't materialize struct" crap when I ask for values
             in registers $rdi $rdx $rsi.  I looked through my code, Apple
             documentation and have no idea what notification would be posted.
             
             Quincey Morris says that this notification is not KVO because
             KVO does not use NSNotificationCenter.  He suspects a threading
             bug because of the objc_msgSend_corrupt_cache_error().

             #0	0x00007fff979e3172 in strlen ()
             #1	0x00007fff97a3cf99 in strdup ()
             #2	0x00007fff9bb886be in objc_class::nameForLogging() ()
             #3	0x00007fff9bb8628c in cache_t::bad_cache(objc_object*, objc_selector*, objc_class*) ()
             #4	0x00007fff9bb861cd in objc_msgSend_corrupt_cache_error ()
             #5	0x00007fff95134275 in safeARCWeaklyStore ()
             #6	0x00007fff951341c7 in -[NSMenuItem setTarget:] ()
             #7	0x00007fff952e6e3a in -[NSMenuItem copyWithZone:] ()
             #8	0x00007fff95228bcd in -[NSSearchFieldCell(NSSearchFieldCell_Local) _updateSearchMenu] ()
             #9	0x00007fff99857cbc in __CFNOTIFICATIONCENTER_IS_CALLING_OUT_TO_AN_OBSERVER__ ()
             #10	0x00007fff997491b4 in _CFXNotificationPost ()
             #11	0x00007fff91564ea1 in -[NSNotificationCenter postNotificationName:object:userInfo:] ()
             #12	0x000000010023e4da in -[SSYSearchField appendToRecentSearches:] at /Users/jk/Documents/Programming/ClassesObjC/SSYSearchField.m:53
             #13	0x00000001002feea0 in -[CntntViewController search:] at /Users/jk/Documents/Programming/Projects/BkmkMgrs/CntntViewController.m:351
             #14	0x0000000100110b24 in -[BkmxDocWinCon search:] at /Users/jk/Documents/Programming/Projects/BkmkMgrs/BkmxDocWinCon.m:2907
             #15	0x000000010023b2cd in -[SSYToolbarButton doDaClick:] at /Users/jk/Documents/Programming/ClassesObjC/SSYToolbarButton.m:115

             
             
             On 2014 Nov 07, at 16:02, Greg Parker <gparker@apple.com> wrote:
             
             You may have better luck tracing it from the other side. Run to that line in appendToRecentSearches:, set a breakpoint on -[NSNotificationCenter postNotificationName:object:userInfo:], and step over your line. At those breakpoints you should be able to see the notification parameters in the parameter registers, assuming the notification is sent every time that line runs.
             
             Great idea, Greg.  It worked.
             
             It told me that that setting recent searches in this menu posts 122 notifications, 120 of which are due to building the search field’s popup menu.
             
             • 40 NSMenuDidAddItemNotification, one for each item in the search field’s popup menu
             • 20 NSMenuDidChangeItemNotification, which are mixed in with the above, for items that changed.
             • 1 NSUserDefaultsDidChangeNotification.
             • 1 NSAutosavedRecentsChangedNotification
             • 40 NSMenuDidAddItemNotification, same as before.
             • 20 NSMenuDidChangeItemNotification, same as before
             
             However, nowhere in *my* code do I directly create an observer of any of those four notification names.  So I’m still head-scratching.
             
             If anyone has any idea what disappearing objects in AppKit might be observing these notifications, let us know.
             
             */
        }
        
        [recentSearches release] ;
    }
}

@end
