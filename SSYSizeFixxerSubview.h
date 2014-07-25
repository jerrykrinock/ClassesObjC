#import <Cocoa/Cocoa.h>


/*!
 @brief    A subview which is used to mark the fixed size, including
 whitespace margins, of variable-sized view.

 @details  In Interface Builder, set this view as hidden and also
 in the Layout, Send to Back.  In code, recognize this view by its
 unique class.
*/
@interface SSYSizeFixxerSubview : NSView {
}

/*
 @brief    Searches a given array of subviews and extracts (see details), if
 any, the size of any SSYSizeFixxerSubview found within it, and returns it,
 or if no such SSYSizeFixxerSubview is found, returns a given default size.
 
 @details  If any of the elements of the given subviews is an
 SSYSizeFixxerSubview, returns the size of the first one.  Otherwise, if the
 given subviews contains only one element, which responds to -suviews, searches
 its subviews and returns the size of the first one.  The latter condition is
 to support configurations where a view may be the only view embedded in
 another view, as will occur with, for example, BkmxLazyView.

 @param    defaultSize  This is typically used as a debugging aid, or for
 defensive programming.
 */
+ (NSSize)fixedSizeAmongSubviews:(NSArray*)subviews
                     defaultSize:(NSSize)defaultSize ;
@end
