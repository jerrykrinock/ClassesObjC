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
            /* I have seen a crash here 4 times.  The first crash was recorded
             on 2014-10-24.  It may have been earlier.  The most recent
             was on 2015-01-10.  Crash occurs when the above method attempts
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
             
             
             * * * * * 
             
             Also, I have a crash from a user, may be related??
             
             Process:               BookMacster [14837]
             Path:                  /Applications/BookMacster.app/Contents/MacOS/BookMacster
             Identifier:            com.sheepsystems.BookMacster
             Version:               1.22.31 (1.22.31)
             Code Type:             X86-64 (Native)
             Parent Process:        ??? [1]
             Responsible:           BookMacster [14837]
             User ID:               501
             
             Date/Time:             2015-02-07 19:36:14.435 +0100
             OS Version:            Mac OS X 10.10.2 (14C109)
             Report Version:        11
             Anonymous UUID:        A3240FD9-18BB-B01E-B37D-3C1F535A2A84
             
             Sleep/Wake UUID:       B821B138-8603-4161-8866-7B4DD3F2103E
             
             Time Awake Since Boot: 260000 seconds
             Time Since Wake:       240 seconds
             
             Crashed Thread:        0  Dispatch queue: com.apple.main-thread
             
             Exception Type:        EXC_BAD_ACCESS (SIGSEGV)
             Exception Codes:       KERN_INVALID_ADDRESS at 0x0000000000000018
             
             VM Regions Near 0x18:
             -->
             __TEXT                 0000000100000000-0000000100006000 [   24K] r-x/rwx SM=COW  /Applications/BookMacster.app/Contents/MacOS/BookMacster
             
             Application Specific Information:
             objc_msgSend() selector name: methodForSelector:
             Performing @selector(search:) from sender BkmxSearchField 0x6080001c4470
             
             Thread 0 Crashed:: Dispatch queue: com.apple.main-thread
             0   libobjc.A.dylib               	0x00007fff8a5ef0dd objc_msgSend + 29
             1   com.apple.AppKit              	0x00007fff92d677d2 -[NSMenuItem setTarget:] + 55
             2   com.apple.AppKit              	0x00007fff92f1a92c -[NSMenuItem copyWithZone:] + 224
             3   com.apple.AppKit              	0x00007fff92e5c73d -[NSSearchFieldCell(NSSearchFieldCell_Local) _updateSearchMenu] + 968
             4   com.apple.CoreFoundation      	0x00007fff871f2cdc __CFNOTIFICATIONCENTER_IS_CALLING_OUT_TO_AN_OBSERVER__ + 12
             5   com.apple.CoreFoundation      	0x00007fff870e4244 _CFXNotificationPost + 3140
             6   com.apple.Foundation          	0x00007fff88f55c31 -[NSNotificationCenter postNotificationName:object:userInfo:] + 66
             7   com.sheepsystems.Bkmxwork     	0x000000010013e6a1 0x10000b000 + 1259169
             8   com.sheepsystems.Bkmxwork     	0x00000001001a8f72 0x10000b000 + 1695602
             9   libsystem_trace.dylib         	0x00007fff8a5dfcd7 _os_activity_initiate + 75
             10  com.apple.AppKit              	0x00007fff92f4db71 -[NSApplication sendAction:to:from:] + 452
             11  com.apple.AppKit              	0x00007fff92f4d970 -[NSControl sendAction:to:] + 86
             12  com.apple.AppKit              	0x00007fff9312386c __26-[NSCell _sendActionFrom:]_block_invoke + 131
             13  libsystem_trace.dylib         	0x00007fff8a5dfcd7 _os_activity_initiate + 75
             14  com.apple.AppKit              	0x00007fff92f96509 -[NSCell _sendActionFrom:] + 144
             15  com.apple.AppKit              	0x00007fff9334e47f __64-[NSSearchFieldCell(NSSearchFieldCell_Local) _sendPartialString]_block_invoke + 63
             16  libsystem_trace.dylib         	0x00007fff8a5dfcd7 _os_activity_initiate + 75
             17  com.apple.AppKit              	0x00007fff9334e437 -[NSSearchFieldCell(NSSearchFieldCell_Local) _sendPartialString] + 186
             18  com.apple.Foundation          	0x00007fff88fb9db3 __NSFireTimer + 95
             19  com.apple.CoreFoundation      	0x00007fff87189b64 __CFRUNLOOP_IS_CALLING_OUT_TO_A_TIMER_CALLBACK_FUNCTION__ + 20
             20  com.apple.CoreFoundation      	0x00007fff871897f3 __CFRunLoopDoTimer + 1059
             21  com.apple.CoreFoundation      	0x00007fff871fcdbd __CFRunLoopDoTimers + 301
             22  com.apple.CoreFoundation      	0x00007fff87146288 __CFRunLoopRun + 2024
             23  com.apple.CoreFoundation      	0x00007fff87145858 CFRunLoopRunSpecific + 296
             24  com.apple.HIToolbox           	0x00007fff8c57baef RunCurrentEventLoopInMode + 235
             25  com.apple.HIToolbox           	0x00007fff8c57b86a ReceiveNextEventCommon + 431
             26  com.apple.HIToolbox           	0x00007fff8c57b6ab _BlockUntilNextEventMatchingListInModeWithFilter + 71
             27  com.apple.AppKit              	0x00007fff92d7ef81 _DPSNextEvent + 964
             28  com.apple.AppKit              	0x00007fff92d7e730 -[NSApplication nextEventMatchingMask:untilDate:inMode:dequeue:] + 194
             29  com.apple.AppKit              	0x00007fff92d72593 -[NSApplication run] + 594
             30  com.apple.AppKit              	0x00007fff92d5da14 NSApplicationMain + 1832
             31  com.sheepsystems.BookMacster  	0x0000000100001ad4 0x100000000 + 6868
             32  com.sheepsystems.BookMacster  	0x00000001000019e0 0x100000000 + 6624
             
            Thread 0 crashed with X86 Thread State (64-bit):
             rax: 0x0000000000000001  rbx: 0x00007fff936feac0  rcx: 0x00007fff92d68653  rdx: 0x00007fff936feac0
             rdi: 0x000000010c429ed0  rsi: 0x00007fff936fc86a  rbp: 0x00007fff5fbfc8f0  rsp: 0x00007fff5fbfc8b8
             r8: 0x0000000000000000   r9: 0x0000000000000016  r10: 0x00007fff936fc86a  r11: 0x0000000000000000
             r12: 0x000000010c429ed0  r13: 0x00007fff8a5ef0c0  r14: 0x00006080014ae380  r15: 0x0000000000000000
             rip: 0x00007fff8a5ef0dd  rfl: 0x0000000000010246  cr2: 0x0000000000000018
             
             Logical CPU:     2
             Error Code:      0x00000004
             Trap Number:     14
             
             
             Binary Images:
             0x100000000 -        0x100005fff +com.sheepsystems.BookMacster (1.22.31 - 1.22.31) <53EFC72B-E3BF-318F-80FE-D22007CCAB08> /Applications/BookMacster.app/Contents/MacOS/BookMacster
             0x10000b000 -        0x1002f3fff +com.sheepsystems.Bkmxwork (0.0 - 0.0) <CCADE138-FB5F-352D-B0A8-040C720A9F5E> /Applications/BookMacster.app/Contents/Frameworks/Bkmxwork.framework/Versions/A/Bkmxwork
             0x1003b7000 -        0x1003bcfff +com.sheepsystems.SSYLocalize (1.0) <2378D29F-FE90-3384-820C-669498AE894C> /Applications/BookMacster.app/Contents/Frameworks/SSYLocalize.framework/Versions/A/SSYLocalize
             0x1003c3000 -        0x1003e1fff +org.andymatuschak.Sparkle (1.5 Beta [git] - 1248ccd) <A0479542-E9B7-3541-B88B-51DB18875775> /Applications/BookMacster.app/Contents/Frameworks/Bkmxwork.framework/Versions/A/Frameworks/Sparkle.framework/Versions/A/Sparkle
             */
        }
        
        [recentSearches release] ;
    }
}

@end
