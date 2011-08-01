#import <Cocoa/Cocoa.h>

@protocol SSYMenuMaker

/*!
 @brief    Returns an NSMenu which will pop up below a
 button when the button sending the message
 is clicked.
 
 @details  The menu will be created by the object you
 connect to the menuMaker outlet.
 
 SSYMenuButton can create a popup menu but is not able to set the
 selected item.  To do that would require
 -[NSMenu popUpMenuPositioningItem:atLocation:inView:], which was added
 in Mac OS 10.6, "for popping up a menu as if it were a popup button".
 There is a depracated Carbon method, PopUpMenuSelect().
 See the NSMenu.h header for more information.
 
 */
- (NSMenu*)menuForButton:(NSButton*)button ;

@end


@interface SSYMenuButton : NSButton {
	
	IBOutlet NSObject <SSYMenuMaker> * menuMaker ;
	
}

@end
