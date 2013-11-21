#import "SSYLazyView.h"
#import "SSYAlert.h"

NSString* SSYLazyViewErrorDomain = @"SSYLazyViewErrorDomain" ;


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


NSString* SSYLazyViewWillLoadPayloadNotification = @"SSYLazyViewWillLoadPayloadNotification" ;
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:SSYLazyViewWillLoadPayloadNotification
                                                        object:[self window]
                                                      userInfo:nil] ;

    NSString* nibName = [[self class] lazyNibName] ;
    NSBundle* bundle = [NSBundle mainBundle] ;
    NSInteger errorCode = 0 ;
    NSString* errorDesc = nil ;
    BOOL ok ;

    NSArray* topLevelObjects = nil ;
    BOOL isMacOSX10_8orLater = [bundle respondsToSelector:@selector(loadNibNamed:owner:topLevelObjects:)] ;

    if (isMacOSX10_8orLater) {
#pragma deploymate push "ignored-api-availability" // Skip it until next "pop"
        ok = [bundle loadNibNamed:nibName
                            owner:owner
                  topLevelObjects:&topLevelObjects] ;
#pragma deploymate pop
        if (ok) {
            // See details of doc for -loadNibNamed:owner:topLevelObjects:,
            // https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/LoadingResources/CocoaNibs/CocoaNibs.html#//apple_ref/doc/uid/10000051i-CH4-SW6
            [self setTopLevelObjects:topLevelObjects] ;
        }
        else {
            errorCode = SSY_LAZY_VIEW_ERROR_CODE_COULD_NOT_LOAD_NIB ;
            errorDesc = [NSString stringWithFormat:
                         @"Could not load %@.nib",
                         nibName] ;
        }
    }
    else {
        NSString* nibFile = [bundle pathForResource:nibName
                                             ofType:@"nib"] ;
        if (nibFile) {
            NSMutableArray* mutableTopLevelObjects = [[NSMutableArray alloc] init] ;
            NSDictionary* externalNameTable = [NSDictionary dictionaryWithObjectsAndKeys:
                                               mutableTopLevelObjects, NSNibTopLevelObjects,
                                               owner, NSNibOwner,
                                               nil] ;
            ok = [NSBundle loadNibFile:nibFile
                     externalNameTable:externalNameTable
                              withZone:nil] ;
            if (ok) {
                topLevelObjects = [NSArray arrayWithArray:mutableTopLevelObjects] ;
            }
            else {
                errorCode = SSY_LAZY_VIEW_ERROR_CODE_LEGACY_COULD_NOT_LOAD_NIB ;
                errorDesc = [NSString stringWithFormat:
                             @"Could not load %@",
                             nibFile] ;
            }
            
            [mutableTopLevelObjects release] ;
        }
        else {
            ok = NO ;
            errorCode = SSY_LAZY_VIEW_ERROR_CODE_LEGACY_COULD_NOT_FIND_NIB ;
            errorDesc = [NSString stringWithFormat:
                         @"Could not load %@.nib",
                         nibName] ;
        }
    }

   NSView* payloadView = nil ;
    if (ok) {
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
        for (NSObject* object in topLevelObjects) {
            if ([object isKindOfClass:[NSView class]]) {
                payloadView = (NSView*)object ;
                break ;
            }
        }
    }
    
    if (!payloadView) {
        ok = NO ;
        errorCode = SSY_LAZY_VIEW_ERROR_CODE_NO_PAYLOAD ;
        errorDesc = [NSString stringWithFormat:
                     @"No payload in %@.nib",
                     nibName] ;
    }
    
    if (ok) {
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
        
        // So we don't do this again…
        [self setIsPayloaded:YES] ;
        
        /*
         We must setIsPayloaded:YES before posting
         SSYLazyViewDidLoadPayloadNotification.  Otherwise,
         -[BkmxDocWinCon tabDidPayloadNote:] is invoked
         which invokes -[BkmxDocWinCon resizeWindowAndConstrainSizeForActiveTabViewItem]
         which invokes -[BkmxDocWinCon resizeWindowForTabViewItem:size:]
         That last method will find [tabViewItem isViewPayloaded] == NO and
         thus not resize the window
         */
        [[NSNotificationCenter defaultCenter] postNotificationName:SSYLazyViewDidLoadPayloadNotification
                                                            object:[self window]
                                                          userInfo:nil] ;
    }
    else {
        NSString* suggestion = @"Reinstall this app." ;
        NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  errorDesc, NSLocalizedDescriptionKey,
                                  suggestion, NSLocalizedRecoverySuggestionErrorKey,
                                  nil] ;
        NSError* error = [NSError errorWithDomain:SSYLazyViewErrorDomain
                                             code:errorCode
                                         userInfo:userInfo] ;
        [SSYAlert alertError:error] ;
    }
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
