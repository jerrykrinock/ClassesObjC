#import "SSYShortcutBackEnd.h"
#import "SRRecorderControl.h"
#import "NSObject+SuperUtils.h"
#import "SSYShortcutActuator.h"

@implementation SSYShortcutBackEnd

@synthesize selectorName = m_selectorName ;
@synthesize ignoreThisAppValidation = m_ignoreThisAppValidation ;

- (void)dealloc {
	[m_selectorName release] ;
	
	[super dealloc] ;
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