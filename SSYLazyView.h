#import <Cocoa/Cocoa.h>

@class SSYExtrospectiveViewController ;

/*
 @details  
 
 In the Xcode xib editor, you may have one or more initial placeholder subviews
 in your Lazy View.  For example, you may place a text field with large
 font size that says "Loading Stuff…".  All of these placeholder subviews
 will be removed when the new view is placed in.
 */
@interface SSYLazyView : NSView {
    SSYExtrospectiveViewController* m_viewController ;
    BOOL m_isLoaded ;
}

@property (retain) SSYExtrospectiveViewController* viewController ;
@property (assign) BOOL isLoaded ;

/*
 @brief    Returns the view controller class which will be instantiated
 when the receiver loads.
 
 @details  The default implementation returns NSViewController.  Subclasses
 override this method to return the desired subclass of NSViewController.
 */
+ (Class)lazyViewControllerClass ;

/*
 @brief    Returns the name of the nib. without the .nib extension, which will
 be loaded and become the one and only subview of the receiver when it loads.
 
 @details  The default implementation returns @"Internal Error 939-7834".
 Subclasses should override this method.
 */
+ (NSString*)lazyNibName ;

/*
 @brief    Creates the receiver's view controller and loads the receiver's
 view, or if these things have not already been done, no op.
 */
- (void)loadInWindow:(NSWindow*)window ;

@end
