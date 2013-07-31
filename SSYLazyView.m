#import "SSYLazyView.h"
#import "SSYNibAwareViewController.h"

@implementation SSYLazyView

@synthesize viewControllerClass = m_viewControllerClass ;
@synthesize viewController = m_viewController ;
@synthesize isLoaded = m_isLoaded ;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame] ;
    if (self) {
        // Initialization code here.
    }
    
    return self ;
}

- (void)viewDidMoveToWindow {
    /*SSYDBL*/ NSLog(@">> %s", __PRETTY_FUNCTION__) ;
	[super viewDidMoveToWindow] ;
	
	if ([self isLoaded]) {
		return ;
	}
	
    NSString* nibName = [[self viewControllerClass] nibName] ;
    /*SSYDBL*/ NSLog(@"Will load nib %@", nibName) ;
    SSYNibAwareViewController* viewCon = [(SSYNibAwareViewController*)[[self viewControllerClass] alloc] initWithNibName:nibName
                                                                                                bundle:nil] ;
    [self setViewController:viewCon] ;
    [viewCon release] ;
    
    [self addSubview:[viewCon view]] ;
    
    [self setIsLoaded:YES] ;
}

- (void)dealloc {
    [m_viewController release] ;
    
    [super dealloc] ;
}

@end
