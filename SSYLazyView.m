#import "SSYLazyView.h"
#import "SSYExtrospectiveViewController.h"

@implementation SSYLazyView

@synthesize viewController = m_viewController ;
@synthesize isLoaded = m_isLoaded ;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame] ;
    if (self) {
        /*SSYDBL*/ NSLog(@"%@ did init", self) ;
        // Initialization code here.
    }
    
    return self ;
}

+ (Class)lazyViewControllerClass {
    return [NSViewController class] ;
}

+ (NSString*)lazyNibName {
    return @"Internal Error 939-7834" ;
}

- (void)loadInWindow:(NSWindow*)window {
   if ([self isLoaded]) {
		return ;
	}
	
    NSString* nibName = [[self class] lazyNibName] ;
    Class viewControllerClass = [[self class] lazyViewControllerClass] ;
    SSYExtrospectiveViewController* viewCon = [(SSYExtrospectiveViewController*)[viewControllerClass alloc] initWithNibName:nibName
                                                                                                                            bundle:nil] ;
    [self setViewController:viewCon] ;
    [viewCon setWindow:window] ; // experimental
    [viewCon release] ;
    [viewCon loadView] ;
    
    // Remove any placeholder subviews.  In BookMacster,  there are two…
    // (0) An SSYSizeFixxerSubview.
    // (1) A text field with a string that says "Loading <Something>…"
    NSInteger nSubviews = [[self subviews] count] ;
    for (NSInteger i=(nSubviews-1); i>=0; i--) {
        NSView* subview = [[self subviews] objectAtIndex:i] ;
        [subview removeFromSuperviewWithoutNeedingDisplay] ;
    }
    
    // Resize the incoming new view
    NSView* newView = [viewCon view] ;
    NSRect frame = NSMakeRect(
                              [newView frame].origin.x,
                              [newView frame].origin.y,
                              [self frame].size.width,
                              [self frame].size.height
                              ) ;
    [newView setFrame:frame] ;

    // Place the incoming new view.
    [self addSubview:newView] ;
    [self display] ;
    
#if 0
    /*
     I considered actually swapping in [viewCon view] in place of the
     receiver, and allowing the receiver to be released and deallocced.
     But that is too messy because not only does the tab view item need
     to get a new view, but the outlet to this Lazy View, needed for other
     purposes, from the window controller, would need to be rewired.
     Before realizing that this was approach was the more problematic,
     I solved the first problem, but not the second, by doing this…
     */
    if (parentTabViewItem) {
        // parentTabViewItem is an outlet.  (More mess)
        [parentTabViewItem setView:[viewCon view]] ;
    }
    else {
        NSView* superview = [self superview] ;
        [superview addSubview:[viewCon view]] ;
    }
#endif
    
    [self setIsLoaded:YES] ;
}

- (void)viewDidMoveToWindow {
    /*SSYDBL*/ NSLog(@"%@ did move to window", self) ;
	[super viewDidMoveToWindow] ;

#if 11
#define LAZY_LOAD_DELAY 0.0
#endif
    [self performSelector:@selector(loadInWindow:)
               withObject:[self window]
               afterDelay:LAZY_LOAD_DELAY] ;
}

- (void)dealloc {
    /*SSYDBL*/ NSLog(@"%@ is dealloccing", self) ;
    [m_viewController release] ;
    
    [super dealloc] ;
}

@end
