#import <Cocoa/Cocoa.h>

/*
 I was going to factor much of BkmxDocTabViewController into this,
 and also factor an BkmxLazyView out of SSYLazyView, but
 then decided not to, because it would just be for reuse vanity that
 no one would ever re-use.
 */
#if 0

@interface SSYDocTabViewController : NSViewController {
    NSWindowController* m_windowController ;
    BOOL m_awakened ;
}

@property (assign) NSWindowController* windowController ;
@property (assign) BOOL awakened ;

- (id)initWithNibName:(NSString*)nibNameOrNil
     windowController:(NSWindowController*)windowController
               bundle:(NSBundle*)nibBundleOrNil ;

- (NSDocument*)document ;

- (void)tearDown ;

@end

#endif