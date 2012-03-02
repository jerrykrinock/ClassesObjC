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

- (void)awakeFromNib {
	// Safely invoke super
	[self safelySendSuperSelector:_cmd
						arguments:nil] ;
	
	// Do this with a delay, in case we get -awakeFromNib before the
	// window containing the SRRecorderControl.  In that case, assuming
	// that -setIgnoreThisAppValidation is set in the window controller's
	// -awakeFromNib, our -ignoreThisAppValidation has not been set yet.
	[self performSelector:@selector(propagateIgnoreThisAppValidation)
			   withObject:nil
			   afterDelay:0.0] ;
}

- (void)propagateIgnoreThisAppValidation {
	[recorderControl setIgnoreThisValidation:[self ignoreThisAppValidation]] ;
}

- (void)awakeWithSelectorName:(NSString*)selectorName
	  ignoreThisAppValidation:(BOOL)ignoreThisAppValidation {
	[self setSelectorName:selectorName] ;
	[self setIgnoreThisAppValidation:ignoreThisAppValidation] ;
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