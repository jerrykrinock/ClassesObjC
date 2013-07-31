#import <Cocoa/Cocoa.h>

@class SSYNibAwareViewController ;

@interface SSYLazyView : NSView {
    Class m_viewControllerClass ;
    SSYNibAwareViewController* m_viewController ;
    BOOL m_isLoaded ;
}

@property (assign) Class viewControllerClass ;
@property (retain) SSYNibAwareViewController* viewController ;
@property (assign) BOOL isLoaded ;

@end
