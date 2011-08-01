#import <Cocoa/Cocoa.h>

/*!
 @brief    Notification posted when an SSYHintArrow closes and
 thus no longer appears on the screen

 @details  You may use this to re-enable showing of subsequent
 Help Arrows.  The notification object is Hint Arrow which
 disappeared.  There is no userInfo dictionary.
*/
extern NSString* const SSYHintArrowDidCloseNotification ;

/*!
 @brief    Produces a fat Help Arrow with a blue gradient and
 white border, with some animation, similar to the one you
 get in a Cocoa app when you click Help, search for a menu item
 and select the result.

 @details  The fat blue arrow is an attached window.
 
 It is instantiated as a singleton.  (Certainly one would not want more
 than one of these buggers displayed at once!)
 
 Apple's fat blue menu-item pointer makes a little circle continuously.
 I think that's kind of confusing, and since Marcus Zarra's animation
 code (acknowledged below) shakes the arrow back and forth, I gave it
 parameters to point at the target point three times and then stop.
 I like this much better than the little circles.
 
 There are four ways to remove the SSYHintArrow's arrow from the
 screen.  The most common way is that the user clicks somewhere in the
 host window, and you send +removeIfEvent: from within your override of
 the host window's -sendEvent method.  The second way is if the user
 decides to click on the SSYHintArrow itself, it is programmed in this
 same way.  The third way is to send +remove.  The final way is to use
 the built-in fail safe, which is that if for some reason the window is
 closed while SSYHintArrow is attached to it, SSYHintArrow will
 detect the closure and remove itself.
 
 In all four cases, SSYHintArrow cleans up after itself; you
 don't need to release or close anything.
 
 REQUIREMENTS
 
 You'll need to link /System/Library/Frameworks/QuartzCore.framework
 into any project including this class.
 
 Requires SDK Mac OS 10.5 or later.

 ACKNOWLEDGEMENTS
 
 The idea to use an attached window, and most of the heavy lifting code,
 was copied and modified from the MAAttachedWindow:
 http://mattgemmell.com/2007/10/03/maattachedwindow-nswindow-subclass
 written by Matt Gemmell, http://mattgemmell.com 
 
 Code for using Core Animation to animate the window was copied and
 modified from the Core Animation Tutorial: Window Shake Effect:
 http://www.cimgf.com/2008/02/27/core-animation-tutorial-window-shake-effect/
 written by Marcus Zarra, http://www.zarrastudios.com/ZDS/Home/Home.html
  
 And thanks to Jonathan Muggins for directing me to both of the above.
 http://www.mugginsoft.com
*/
@interface SSYHintArrow : NSWindow {
    NSColor* m_borderColor ;
    float m_borderWidth ;
    float m_viewMargin ;
    float m_arrowHeight ;
    float m_cornerRadius ;
    NSSize m_size ;
	
    @private
	NSGradient* m_gradient ;
    __weak NSView* m_view ;
    __weak NSWindow* m_window ;
    NSPoint m_point ;
    float m_distance ;
    NSRect m_viewFrame ;
    BOOL m_isResizingLockout ;
}

/*
 @brief    Creates and attaches a Hint Arrow at a given
 point in a given window

 @param    point  The point, in the coordinate system of the 
 given window, at which the arrowhead (the left end) of the
 arrow will be placed.
 @param    window  The window to which the Help Arrow should
 be attached.
*/
+ (void)showHelpArrowAtPoint:(NSPoint)point
					inWindow:(NSWindow*)window ;

/*
 @brief    Creates and attaches a Help Arrow pointing from
 the right, at the right edge of a given view, halfway
 between the bottom and the top.
 
 @param    view  The view whose edge on whith the Hint Arrow
 should be attached.  SSYHintArrow is attached to the
 window containing the given view.
 */
+ (void)showHelpArrowRightOfView:(NSView*)view ;

/*!
 @brief    Removes and destroys a Help Arrow created by
 showHelpArrowAtPoint:inWindow:, if a given event is a mouseDown
 (left, right, or other) or keyDown event.
 
 @details   @details   @details  Usually, you'll want to remove
 the arrow whenever the user clicks any mouse button or any key.
 There is no Cocoa method to get exactly that.  To get this
 behavior, you must override -sendEvent: in a subclass of the
 host window, and within it send this message, like this
 
 #import "SSYHintArrow.h"
 
 @implementation MyWindow
 
 - (void)sendEvent:(NSEvent *)event {
     // your other code here, if any
     [SSYHintArrow removeIfEvent:event] ;
     // your more other code here, if any
     [super sendEvent:event] ;
 }
 
 @end
 
 @details  This is but one of ways to remove +SSYHintArrow's
 arrow from the screen.  But it is the most commonly used.
 */
+ (void)removeIfEvent:(NSEvent*)event ;

/*!
 @brief    Removes and destroys a Help Arrow created by
 showHelpArrowAtPoint:inWindow:
 
 @details  This is but one of ways to remove +SSYHintArrow's
 arrow from the screen.
 */
+ (void)remove ;

@end

