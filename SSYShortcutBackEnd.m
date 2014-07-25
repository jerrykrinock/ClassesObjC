#import "SSYShortcutBackEnd.h"
#import "SRRecorderControl.h"
#import "NSObject+SuperUtils.h"
#import "SSYShortcutActuator.h"

@implementation SSYShortcutBackEnd

@synthesize selectorName = m_selectorName ;

- (void)dealloc {
	[m_selectorName release] ;
	
	[super dealloc] ;
}

- (BOOL)ignoreThisAppValidation {
    return m_ignoreThisAppValidation ;
}

- (void)setIgnoreThisAppValidation:(BOOL)yn {
    m_ignoreThisAppValidation = yn ;
    [recorderControl setIgnoreThisAppValidation:yn] ;
}

- (void)awakeWithSelectorName:(NSString*)selectorName {
	[self setSelectorName:selectorName] ;
	KeyCombo keyCombo = [[SSYShortcutActuator sharedActuator] keyComboForSelectorName:selectorName] ;
	[recorderControl setKeyCombo:keyCombo] ;
}

- (BOOL)shortcutRecorder:(SRRecorderControl*)aRecorder
			   isKeyCode:(NSInteger)keyCode
		   andFlagsTaken:(NSUInteger)flags
				  reason:(NSString**)aReason {
	return NO ;
}

- (void)shortcutRecorder:(SRRecorderControl*)aRecorder
	   keyComboDidChange:(KeyCombo)keyCombo {
	[[SSYShortcutActuator sharedActuator] setKeyCode:keyCombo.code
									   modifierFlags:keyCombo.flags
										selectorName:[self selectorName]] ;
}


@end