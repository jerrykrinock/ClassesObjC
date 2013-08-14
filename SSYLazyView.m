#import "SSYLazyView.h"
#import "SSYExtrospectiveViewController.h"

@implementation NSTabViewItem (SSYLazyPayload)

- (BOOL)isViewPayloaded {
    NSView* view = [self view] ;
    BOOL answer = YES ;
    if ([view respondsToSelector:@selector(isPayloaded)]) {
        if (![(SSYLazyView*)view isPayloaded]) {
            answer = NO ;
        }
    }
    
    return answer ;
}


@end


NSString* SSYLazyViewDidLoadPayloadNotification = @"SSYLazyViewDidLoadPayloadNotification" ;

@interface SSYLazyView ()

@property (retain) NSArray* topLevelObjects ;

@end

@implementation SSYLazyView

@synthesize isPayloaded = m_isPayloaded ;
@synthesize topLevelObjects = m_topLevelObjects ;

#if 0
- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame] ;
    if (self) {
        // Initialization code here.
    }
    
    return self ;
}
#endif

+ (Class)lazyViewControllerClass {
    return [NSViewController class] ;
}

+ (NSString*)lazyNibName {
    return @"Internal Error 939-7834" ;
}

- (void)loadWithOwner:(id)owner {
    // Only do this once
    if ([self isPayloaded]) {
		return ;
	}
	
    NSString* nibName = [[self class] lazyNibName] ;
    NSBundle* bundle = [NSBundle mainBundle] ;

    NSArray* topLevelObjects ;
    
    if ([bundle respondsToSelector:@selector(loadNibNamed:owner:topLevelObjects:)]) {
        // Mac OS X 10.8 or later
       [bundle loadNibNamed:nibName
                       owner:owner
             topLevelObjects:&topLevelObjects] ;

        // See details of doc for -loadNibNamed:owner:topLevelObjects:,
        // https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/LoadingResources/CocoaNibs/CocoaNibs.html#//apple_ref/doc/uid/10000051i-CH4-SW6
        [self setTopLevelObjects:topLevelObjects] ;
    }
    else {
        [NSBundle loadNibNamed:nibName
                         owner:owner] ;
    }

    // Remove any placeholder subviews.
    // In BookMacster et al,  there are two such placeholders…
    // (0) An SSYSizeFixxerSubview.
    // (1) A text field with a string that says "Loading <Something>…"
    NSInteger nSubviews = [[self subviews] count] ;
    for (NSInteger i=(nSubviews-1); i>=0; i--) {
        NSView* subview = [[self subviews] objectAtIndex:i] ;
        [subview removeFromSuperviewWithoutNeedingDisplay] ;
    }
    
    // Ferret out the new top-level view
    NSView* payloadView = nil ;
    for (NSObject* object in topLevelObjects) {
        if ([object isKindOfClass:[NSView class]]) {
            payloadView = (NSView*)object ;
            break ;
        }
    }
    if (!payloadView) {
        NSLog(@"Internal Error 210-0209  No view in %@", nibName) ;
    }
    
    // Resize the incoming new view to match the current size of
    // the placeholder view
    NSRect frame = NSMakeRect(
                              [payloadView frame].origin.x,
                              [payloadView frame].origin.y,
                              [self frame].size.width,
                              [self frame].size.height
                              ) ;
    [payloadView setFrame:frame] ;

    // Place the incoming new view.
    [self addSubview:payloadView] ;
    [self display] ;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SSYLazyViewDidLoadPayloadNotification
                                                        object:[self window]
                                                      userInfo:nil] ;
    
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
    
    // So we don't do this again…
    [self setIsPayloaded:YES] ;
}

- (void)viewDidMoveToWindow {
	[super viewDidMoveToWindow] ;
    [self loadWithOwner:[[self window] windowController]] ;
}

- (void)dealloc {
    [m_topLevelObjects release] ;
    
    [super dealloc] ;
}

@end
