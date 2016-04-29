#import "SSYReplacePredicateEditorRowTemplate.h"

NSString* SSYReplacePredicateCheckboxWillGoAwayNotification = @"SSYReplacePredicateCheckboxWillGoAwayNotification" ;

@implementation SSYReplacePredicateCheckbox

#if !__has_feature(objc_arc)
- (void)dealloc {
    [_attributeKey release] ;
    [super dealloc] ;
}
#endif

- (void)viewDidMoveToSuperview {
    if (self.superview == nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SSYReplacePredicateCheckboxWillGoAwayNotification
                                                            object:self] ;
    }
}

@end

@implementation SSYReplacePredicateEditorRowTemplate

/* Superclass NSPredicateEditorRowTemplate must conform to NSCopying because,
 as the name implies, this is a *template*.  Cocoa makes a copy whenever
 it needs another one. */
- (SSYReplacePredicateEditorRowTemplate*)copyWithZone:(NSZone*)zone {
    SSYReplacePredicateEditorRowTemplate* copy = [super copyWithZone:zone] ;
    copy.replacer = self.replacer ;
    copy.attributeKey = self.attributeKey ;
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
