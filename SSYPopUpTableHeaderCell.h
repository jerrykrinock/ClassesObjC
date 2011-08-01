#import <Cocoa/Cocoa.h>


/*!
 @brief    A table header cell that is a popup menu!

 @details  This class is based on Keith Blount's original work
 http://www.cocoabuilder.com/archive/message/cocoa/2005/4/16/133285
 or http://lists.apple.com/archives/cocoa-dev/2005/Apr/msg01223.html
 but I've made emough improvements to it that I decided it deserves
 to have my own SSY prefix.
 
 The instance variable realSelf is to work around in case a bug occurs:
 
 I have a subclass of NSPopUpButtonCell which I use in place of an NSTableHeaderCell,
 providing a popup menu so that the user can choose what attribute is displayed in the column.
 This subclass retains an instance variable, which I call a templateHeaderCell.  This instance
 variable is a NSTableHeaderCell which it uses to draw the empty table header when needed.
 
 Two of my table columns, in their -awakeFromNib, create one of these cells, and set them as
 their headerCell.  From NSLog in my subclass' -init, I see that these are the only two
 instances of my subclass which are ever created.
 
 However, when clicking on the table column which causes redrawing, my subclass' -drawWithFrame:inView:
 is invoked by a third instance, one with a different 'self' value, of my subclass.  But it's
 worse -- the address of its -templateHeaderCell instance variable is the same as that in one of
 the two ^real^ instances.  So, it's like an identity theft.  The thief has the instance variables
 of the real object.
 
 Apparently, whatever created the thief did not retain it, because it is soon deallocced, causing
 its instance variables to be deallocced, and things kind of go downhill from there when the ^real^
 instance comes back later and tries to access them :(
 
 In order to work around this, during -init, I set another instance variable named 'realSelf':
	[self setRealSelf:self] ;
 And then during -drawWithFrame:inView: and -dealloc, test before doing anything with:
     if (self != [self realSelf])
 If this occurs I log an error and return.
 
 This only happens if a column is resized without resizing other columns to compensate.  I have
 seen another column created in this case and suspect the other column is the one that created
 the thief.
*/
@interface SSYPopUpTableHeaderCell : NSPopUpButtonCell {	
	// A bug catcher.  See long explanation in class documentation details
	SSYPopUpTableHeaderCell* realSelf ;
	
	CGFloat lostWidth ;
}

/*!
 @brief    The width on the right side of the column header which
 is not available for menu text because it is used by the popup arrows
 and whitespace to the right of the arrows.
*/
@property (readonly) CGFloat lostWidth ;

@end
