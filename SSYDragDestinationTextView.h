#import <Cocoa/Cocoa.h>

/*
 This class implements most of the NSDraggingDestination protocol,
 making it a little easier to make any NSTextView a dragging destination.
 
 Things which must be done elsewhere:
 
 - Somewhere, 
		- send me -unregisterDraggedTypes, followed by 
		    -registerForDraggedTypes: to the dragging destination NSView.
        - If scrolling is desired, send configureScrollingHorzontal:vertical
    Suggestions: Do these in a window controller's -awakeFromNib

 -	Dragging destination NSView must have a delegate, or be in a window with a delegate,
    which implements the SSYDragDestinationTextViewDelegate protcol.


 */

@interface SSYDragDestinationTextView : NSTextView {
	BOOL _isInDrag ;
	BOOL _tabToNextKeyView ;
}


/*!
 @brief    Sets the ivar _tabToNextKeyView

 @details  By default, NSTextView accepts hitting the tab key as a text character.
 Setting this to YES tells it to tab to the next key view, like an NSTextField does.
 @param    YES  to tab to the next key view, NO for the default NSTextView behavior.
*/
- (void)setTabToNextKeyView:(BOOL)yn ;

@end


