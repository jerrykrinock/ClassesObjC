#import <Cocoa/Cocoa.h>

@class SRRecorderControl ;

/*!
 @brief    This class implements the delegate of SRRecorderControl,
 and works with SSYShortcutActuator to control global (cross-application)
 keyboard shortcuts.  Typically, you instantiate it as a custom object in a
 nib which contains an SRRecorderControl.
*/
@interface SSYShortcutBackEnd : NSObject {
	NSString* m_selectorName ;
	BOOL m_ignoreThisAppValidation ;
	IBOutlet SRRecorderControl* recorderControl ;
}

@property (copy) NSString* selectorName ;
@property (assign) BOOL ignoreThisAppValidation ;

- (void)awakeWithSelectorName:(NSString*)selectorName ;

@end
