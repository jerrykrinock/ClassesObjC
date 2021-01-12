#import "SSYReplacePredicateEditorRowTemplate.h"

NSString* SSYReplacePredicateCheckboxWillGoAwayNotification = @"SSYReplacePredicateCheckboxWillGoAwayNotification" ;

@interface SSYReplacePredicateCheckbox ()

@property (assign) CGFloat lastSuperWidth ;
@property (copy) NSString* attributeKey ;

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
    
    /* Here is another kludge to work around weird behavior of
     NSPredicateEditor.
     
     We are only really interested when a checkbox is going away for good.
     For whatever reason, dealloc does not seem to happen (until much later?),
     and indeed this method is, I think, the generally-accepted correct place
     to do such housekeeping.  However, it seems that, when user changes the
     middle (operator) popup in a row, the checkbox (self here) is momentarily
     removed from the superview NSRuleEditorViewSliceRow and then, in the same
     run loop cycle, moved back into it.  So merely checking for a nil superview
     here will detect false removals.  Instead, we must enqueue a notification
     lazily, and then re-check for nil superview in the notification observer
     method -[StarkPredicateEditor checkViewnessOfCheckboxNote:] */
    NSNotification* note = [NSNotification notificationWithName:SSYReplacePredicateCheckboxWillGoAwayNotification
                                                         object:self] ;
    [[NSNotificationQueue defaultQueue] enqueueNotification:note
                                               postingStyle:NSPostWhenIdle
                                               coalesceMask:(NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender)
                                                   forModes:nil] ;
#if TRY_TO_MAKE_WIDTH_TRACK_SUPERVIEW
    
    if (self.superview) {
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
    [self setNeedsDisplay] ;
}
#endif

/*!
 @details  This method is a kludge.  I tried to do it the proper way, which is
 to look at the -representedObject of the menu items.  Unfortunately, that is
 an undocumented NSDictionary.  Then I tried to add tags of value equal to the
 to NSPredicateOperatorType value, in -[StarkPredicateEditor templates].  That
 didn't work because the popup menu in the view is a
 NSRuleEditorPopupButton which is apparently copied by Cocoa from the
 NSPopUpButton seen in the -templates method, but when Cocoa copies it, it
 apparently does not copy the tag because the tags in these copies are all 0.
 So, finally I settled on this kludge which is to compare the, eek, menu titles.
 It is reliable because I defined localizedRegexMenuItemTitle and use it to both
 make the menu and, then in here, to do the comparison and, or course, it would
 be a programming error if two menu items had the same title :)   But it's still
 a code-smelly way to identify a menu item. */
- (BOOL)isRegex {
    NSPopUpButton* operatorPopup = nil ;
    for (NSView* sibling in self.superview.subviews) {
        if ([sibling isKindOfClass:[NSPopUpButton class]]) {
            if (sibling.frame.origin.x >= operatorPopup.frame.origin.x) {
                operatorPopup = (NSPopUpButton*)sibling ;
            }
        }
    }
    
    NSString* selectedTitle = operatorPopup.selectedItem.title ;
    BOOL isRegex = ([selectedTitle isEqualToString:[SSYReplacePredicateEditorRowTemplate localizedRegexMenuItemTitle]]) ;

    return isRegex ;
}

@end


@implementation SSYReplacePredicateEditorRowTemplate

/* Superclass NSPredicateEditorRowTemplate must conform to NSCopying because,
 as the name implies, this is a *template*.  For some reason, Cocoa makes a copy
 whenever it needs another one, and then of course, I guess, it makes a view
 (NSView) from that. */
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
        [button setButtonType:NSButtonTypeSwitch] ;
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

+ (NSString*)localizedRegexMenuItemTitle {
    return NSLocalizedString(@"matches regular expression", nil) ;
}

@end
