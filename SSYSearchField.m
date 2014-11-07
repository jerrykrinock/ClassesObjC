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
            /* I have thrice seen a crash here, most recently while developing
             BkmkMgrs ver 1.22.23 in OS X 10.0, when the above method attempts
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
             */
        }
        
        [recentSearches release] ;
    }
}

@end
