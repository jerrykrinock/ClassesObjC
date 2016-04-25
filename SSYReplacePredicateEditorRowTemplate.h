#import <Cocoa/Cocoa.h>

@class SSYReplacePredicateEditorRowTemplate ;

@protocol SSYReplacePredicateEditorRowTemplateReplacer

- (IBAction)userClickedReplaceCheckboxForRowTemplateButton:(NSPredicateEditorRowTemplate*)rowTemplate ;

@end

@interface SSYReplacePredicateCheckbox : NSButton

@property (assign) SSYReplacePredicateEditorRowTemplate* predicateEditorRowTemplate ;
@property (copy) NSString* attributeKey ;

@end

/*!
@details  Thank you to this blog post:
 http://www.knowstack.com/nspredicateeditor-sample-code/
 */
@interface SSYReplacePredicateEditorRowTemplate : NSPredicateEditorRowTemplate

@property (assign) NSObject <SSYReplacePredicateEditorRowTemplateReplacer> * replacer ;
@property (copy) NSString* attributeKey ;

+ (NSString*)anyEditableStringValueInView:(NSView*)view ;

@end
