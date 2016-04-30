#import "SSYReplacePredicateEditorRowTemplate.h"

NSString* SSYReplacePredicateCheckboxWillGoAwayNotification = @"SSYReplacePredicateCheckboxWillGoAwayNotification" ;

@interface SSYReplacePredicateCheckbox ()

@property (assign) CGFloat lastSuperWidth ;

@end

@implementation SSYReplacePredicateCheckbox

#if !__has_feature(objc_arc)
- (void)dealloc {
    [_attributeKey release] ;
    [super dealloc] ;
}
#endif

/* 
 #define this to 0 because it does not work, nor does the autoresizing
 mask on the editable text field work, even though, according to debugging,
 • the text field's autoresizing mask is NSWidthSizable
 • the text field's immediate superview is resizing as expected
 • does not work even if I don't add my checkbox
 */
#define TRY_TO_MAKE_WIDTH_TRACK_SUPERVIEW 0

- (void)viewDidMoveToSuperview {
    [super viewDidMoveToSuperview] ;
    if (self.superview == nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SSYReplacePredicateCheckboxWillGoAwayNotification
                                                            object:self] ;
    }
#if TRY_TO_MAKE_WIDTH_TRACK_SUPERVIEW
    else {
        [self.superview addObserver:self
                         forKeyPath:@"frame"
                            options:0
                            context:NULL] ;
    }
#endif
}

#if TRY_TO_MAKE_WIDTH_TRACK_SUPERVIEW
- (void)viewWillMoveToSuperview:(NSView*)newSuperview {
    [super viewWillMoveToSuperview:newSuperview] ;
    [self.superview removeObserver:self
                        forKeyPath:@"frame"] ;
}

- (void)observeValueForKeyPath:(NSString*)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context {
    [self trackSuperview] ;
}

- (void)trackSuperview {
    CGFloat deltaWidth = self.superview.frame.size.width - self.lastSuperWidth ;
    self.lastSuperWidth = self.superview.frame.size.width ;
    NSRect newFrame = self.frame ;
    newFrame.origin.x += deltaWidth ;
    self.frame = newFrame ;
    /*SSYDBL*/ NSLog(@"new frame = %@", NSStringFromRect(newFrame)) ;
    [self setNeedsDisplay] ;
}
#endif

@end

@implementation SSYReplacePredicateEditorRowTemplate

/* Superclass NSPredicateEditorRowTemplate must conform to NSCopying because,
 as the name implies, this is a *template*.  Cocoa makes a copy whenever
 it needs another one. */
- (SSYReplacePredicateEditorRowTemplate*)copyWithZone:(NSZone*)zone {
    SSYReplacePredicateEditorRowTemplate* copy = [super copyWithZone:zone] ;
    copy.replacer = self.replacer ;
    copy.attributeKey = self.attributeKey ;
    /*SSYDBL*/ NSLog(@"Made copy: %@ with ak=%@", copy, copy.attributeKey ) ;
    return copy ;
}

#if !__has_feature(objc_arc)
- (void)dealloc {
    [_attributeKey release] ;
    [super dealloc] ;
}
#endif

- (NSArray*)templateViews {
    NSArray <NSView*> * superTemplateViews = [super templateViews] ;
    NSArray* answer ;
    NSView* thirdControl = [superTemplateViews lastObject] ;
    if (
        [thirdControl isKindOfClass:[NSTextField class]]  // Normal case
        ||
        [thirdControl isKindOfClass:[NSTextView class]] // Defensive programming
        ) {
        /* This is a row whose right-hand expression is user-editable text, to
         which the "Replace" function and checkbox is applicable. */
        NSMutableArray* views = [superTemplateViews mutableCopy] ;
        SSYReplacePredicateCheckbox* button = [[SSYReplacePredicateCheckbox alloc] initWithFrame:NSMakeRect(0.0, 2.0, 68.0, 18.0)] ;
        button.predicateEditorRowTemplate = self ;
        button.attributeKey = self.attributeKey ;
        [button setButtonType:NSSwitchButton] ;
        [button setTitle:NSLocalizedString(@"Replace", @"Title of a checkbox, associated with 'Find', which user activates to indication that the associated finding should be replaced with some other text or data")] ;
        [button setTarget:self.replacer] ;
        [button setFont:[NSFont systemFontOfSize:11.0]] ;
        [button setAction:@selector(userClickedReplaceCheckboxForRowTemplateButton:)];
        [views addObject:button] ;
        NSArray* copy = [views copy] ;
#if !__has_feature(objc_arc)
        [views release] ;
        [copy autorelease] ;
#endif
        answer = copy ;
    }
    else {
        /* This is some other kind of row.  Leave as is from super. */
        answer = superTemplateViews ;
    }

    return answer ;
}

+ (NSString*)anyEditableStringValueInView:(NSView*)view {
    NSString* answer = nil ;
    if ([view respondsToSelector:@selector(stringValue)]) {
        if ([view respondsToSelector:@selector(isEditable)]) {
            if ([(NSTextField*)view isEditable]) {
                answer = ((NSTextField*)view).stringValue ;
            }
        }
    }
    
    return answer ;
}

@end
