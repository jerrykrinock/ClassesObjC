//  NSFancyPanel.m
//  FancyAbout

//  Copyright (c) 2003 Apple Computer, Inc. All rights reserved.
//	See legal notice at end of file.

#import "NSFancyPanel.h"


@interface NSObject (DelegateMethods)
- (BOOL) handlesKeyDown: (NSEvent *) keyDown
    inWindow: (NSWindow *) window;
- (BOOL) handlesMouseDown: (NSEvent *) mouseDown
    inWindow: (NSWindow *) window;
@end


@implementation NSFancyPanel

//	PUBLIC INSTANCE METHODS -- OVERRIDES FROM NSWindow

//	NSWindow will refuse to become the main window unless it has a title bar.
//	Overriding lets us become the main window anyway.
- (BOOL) canBecomeMainWindow
{
    return YES;
}

//	Much like above method.
- (BOOL) canBecomeKeyWindow
{
    return YES;
}

//	Ask our delegate if it wants to handle keystroke or mouse events before we route them.
- (void) sendEvent:(NSEvent *) theEvent
{
    //	Offer key-down events to the delegats
    if ([theEvent type] == NSKeyDown)
        if ([[self delegate] respondsToSelector: @selector(handlesKeyDown:inWindow:)])
            if ([(id)[self delegate] handlesKeyDown: theEvent  inWindow: self])
                return;

    //	Offer mouse-down events (lefty or righty) to the delegate
    if ( ([theEvent type] == NSLeftMouseDown) || ([theEvent type] == NSRightMouseDown) )
        if ([[self delegate] respondsToSelector: @selector(handlesMouseDown:inWindow:)])
            if ([(id)[self delegate] handlesMouseDown: theEvent  inWindow: self])
                return;

    //	Delegate wasn’t interested, so do the usual routing.
    [super sendEvent: theEvent];
}

@end

