#import "SSYLazyView.h"
#import "SSYExtrospectiveViewController.h"

@implementation SSYLazyView

@synthesize viewController = m_viewController ;
@synthesize isLoaded = m_isLoaded ;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame] ;
    if (self) {
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

- (void)load {
#if 11
#warning Not loading any tabs
    return ;
#endif
    if ([self isLoaded]) {
		return ;
	}
	
    NSString* nibName = [[self class] lazyNibName] ;
    Class viewControllerClass = [[self class] lazyViewControllerClass] ;
    SSYExtrospectiveViewController* viewCon = [(SSYExtrospectiveViewController*)[viewControllerClass alloc] initWithNibName:nibName
                                                                                                                            bundle:nil] ;
    /*SSYDBL*/ NSLog(@"%@ will load nib %@ and instantiate %@", [self className], nibName, [viewCon className]) ;
    [self setViewController:viewCon] ;
    [viewCon setWindow:[self window]] ; // experimental
//    /*SSYDBL*/ NSLog(@"7651 %@ has view %@ in window %@", viewCon, [viewCon view], [viewCon window]) ;
    [viewCon release] ;
    [viewCon loadView] ;
    
    [self addSubview:[viewCon view]] ;
    
    [self setIsLoaded:YES] ;
}

- (void)viewDidMoveToWindow {
	[super viewDidMoveToWindow] ;

#if 11
#define LAZY_LOAD_DELAY 1.0
#endif
    [self performSelector:@selector(load)
               withObject:nil
               afterDelay:LAZY_LOAD_DELAY] ;
}

- (void)dealloc {
    [m_viewController release] ;
    
    [super dealloc] ;
}

@end
