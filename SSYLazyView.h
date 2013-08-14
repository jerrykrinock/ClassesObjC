#import <Cocoa/Cocoa.h>

/*
 @brief    Notification which is posted when the payload view loads.
 
 @details  The notification object is the window in which the SSYLazyView object
 resides.  Note that the
 loading of the payload, and hence the posting of this notification, occurs no
 more than once during the lifetime of an SSYLazyView object.
 */
extern NSString* SSYLazyViewDidLoadPayloadNotification;

/*
 @brief    A companion to SSYLazyView; provides a method by which a tab view
 item whose view is an instance of SSYLazyView can look down and see if their
 view has been payloaded
 */
@interface NSTabViewItem (SSYLazyPayload)

/*
 @brief    If the receiver's view is an instance of SSYLazyView, returns 
 that view's response to -isPayloaded; otherwise, returns YES
 */
- (BOOL)isViewPayloaded ;

@end

/*
 @brief    View which, upon being moved to a window for the first time, or
 upon demand (-loadWithOwner:), removes all of its original subviews
 ("placeholders") and adds a in their place a single "payload" view which it
 loads from a designated nib
 
 @details  When the receiver loads its nib as a result of being moved to a
 window, the window controller of the window to which it was moved is assigned
 as the file's owner of the nib.
 
 In the Xcode xib editor, you may have one or more initial placeholder subviews
 in your Lazy View.  For example, you may place a text field with large
 font size that says "Loading Stuff…".  All of these placeholder subviews
 will be removed when the new view is placed in.
 */
@interface SSYLazyView : NSView {
    BOOL m_isPayloaded ;
    
    // Needed in Mac OS X 10.8 or later…
    NSArray* m_topLevelObjects ;
}

@property (assign) BOOL isPayloaded ;

/*
 @brief    Returns the name of the nib, without the .nib extension, which will
 be loaded and whose top-level view object become the one and only subview of
 the receiver when the payload view loads.
 
 @details  The default implementation returns @"Internal Error 939-7834".
 You must subclass this class and override this method.
 */
+ (NSString*)lazyNibName ;

/*
 @brief    Creates the receiver's view controller and loads the receiver's
 view, or if these things have not already been done, no op
 
 @details  This method is used to "manually" load the payload, before the
 receiver is moved to a window.
 
 @param    owner  The object which to assign as the File's Owner when the 
 nib is loaded.
 */
- (void)loadWithOwner:(id)owner ;

@end
