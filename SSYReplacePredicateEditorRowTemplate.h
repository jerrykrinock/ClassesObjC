#import <Cocoa/Cocoa.h>

@class SSYReplacePredicateEditorRowTemplate ;

/*!
 @brief    Notification which is posted whenever a checkbox is going to be
 removed from the superview and deallocced
 
 @details  Because of the way NSPredicateEditor constructs rows from templates,
 rows are quite "disposable" and this removal and dealloc may happen when,
 for example, the attribute type (left popup) of a row is changed.  If the
 checkbox is in the active "Replace" row, that is, if its state is ON, a
 someone will need this notification to hide or disable the "Replace" controls.
 
 Use of this notification is a kludge.  A better way would be to make the
 related NSPredicateEditor observe the 'superview' property of the checkbox.
 However, when I simply implemented -observeValueForKeyPath:::: in
 MyPredicateEditor, with an empty implementation, when the view loaded, in
 -[MyPredicateEditor viewDidMoveToWindow], the line of code where it
 adds a row using the IBAction method, [self addRow:self], would raise
 an exception saying that it was trying to add a row at index 1 which was
 out of bounds since the number of rows is currently 0.  I think maybe this is
 a weird bug in NSPredicateEditor.  I started to try and reproduce it in a
 demo project but it was taking too long to get the stupid predicate editor
 to display anything at all. */
extern NSString* SSYReplacePredicateCheckboxWillGoAwayNotification ;

@protocol SSYReplacePredicateEditorRowTemplateReplacer

- (IBAction)userClickedReplaceCheckboxForRowTemplateButton:(NSPredicateEditorRowTemplate*)rowTemplate ;

@end

@interface SSYReplacePredicateCheckbox : NSButton

@property (assign) SSYReplacePredicateEditorRowTemplate* predicateEditorRowTemplate ;
@property (readonly) NSString* attributeKey ;
@property (readonly) BOOL isRegex ;

@end

/*!
@details  Thank you to this blog post:
 http://www.knowstack.com/nspredicateeditor-sample-code/
 */
@interface SSYReplacePredicateEditorRowTemplate : NSPredicateEditorRowTemplate

@property (assign) NSObject <SSYReplacePredicateEditorRowTemplateReplacer> * replacer ;
@property (copy) NSString* attributeKey ;

+ (NSString*)anyEditableStringValueInView:(NSView*)view ;
+ (NSString*)localizedRegexMenuItemTitle ;

@end
