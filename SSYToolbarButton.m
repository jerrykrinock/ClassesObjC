#import "SSYToolbarButton.h"

static NSString* const constKeyValue = @"value" ;
static NSString* const constKeyToolTip = @"toolTip" ;

@interface SSYToolbarButton ()

// To avoid retain cycles, it is conventional to not retain
// targets.  (In this case, I tested [super setTarget:aTarg]
// and it does not increase the retain count of aTarg.)
@property (assign) id externalTarget ;
@property (assign) SEL externalAction ;

@end

@implementation SSYToolbarButton

+ (void)initialize {
	if (self == [SSYToolbarButton class] ) {
		[self exposeBinding:constKeyValue] ;
		[self exposeBinding:constKeyToolTip] ;
	}
}

@synthesize onImage = m_onImage ;
@synthesize offImage = m_offImage ;
@synthesize externalTarget = m_externalTarget ;
@synthesize externalAction = m_externalAction ; 

- (void)awakeFromNib {
	// The following is to support some other object binding to the
	// 'value' binding of a SSYToolbarButton.  We splice ourself in
	// to observe the action.
	[super setTarget:self] ;
	[super setAction:@selector(doDaClick:)] ;

	// In BookMacster, we use the conventional target/action and not
	// the binding.  So we could actually dispense with the
	// externalTarget and externalAction thing.  The reason we use
	// conventional is because there are possibly multiple "Show Inspector"
	// SSYToolbarButtons (one in each Bookmarkshelf) but only one
	// observer ('inspectorNowShowing' in BkmxAppDel), and an
	// observer can only be bound to one bound-to object at a time.
}

- (void)setTarget:(id)target {
	[self setExternalTarget:target] ;
}

- (void)setAction:(SEL)action {
	[self setExternalAction:action] ;
}

- (NSInteger)value {
	return m_value ;
}

- (void)setValue:(NSInteger)value {
	if (
		[self image] // This is not the first setting
		&&
		(value == m_value) 
		) {
		return ; 
	}
	
	m_value = value ;
	
	NSImage* image = (value == NSOnState) ? [self onImage] : [self offImage] ;
	[self setImage:image] ;
}	

- (IBAction)doDaClick:(id)sender {
	[self setValue:([self value] == NSOnState) ? NSOffState : NSOnState] ;
	[[self externalTarget] performSelector:[self externalAction]
								withObject:self] ;
}

- (void)dealloc {
	[m_onImage release] ;
	[m_offImage release] ;
	
	[super dealloc] ;
}

@end