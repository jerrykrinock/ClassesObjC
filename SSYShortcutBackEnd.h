#import <Cocoa/Cocoa.h>

@class SRRecorderControl ;

/*!
 @brief    This class implements the delegate of SRRecorderControl,
 and works with SSYShortcutActuator to control global (cross-application)
 keyboard shortcuts.
*/
@interface SSYShortcutBackEnd : NSObject {
	NSString* m_selectorName ;
	BOOL m_ignoreThisAppValidation ;
	IBOutlet SRRecorderControl* recorderControl ;
}

@property (copy) NSString* selectorName ;
@property (assign) BOOL ignoreThisAppValidation ;

- (void)awakeWithSelectorName:(NSString*)selectorName
	  ignoreThisAppValidation:(BOOL)ignoreThisAppValidation ;

@end
