#import "SSYToolbarButton.h"
#import "NSImage+Transform.h"

static NSString* const constKeyValue = @"value" ;
static NSString* const constKeyToolTip = @"toolTip" ;


@interface SSYToolbarButton ()

// To avoid retain cycles, it is conventional to not retain
// targets.  (In this case, I tested [super setTarget:aTarg]
// and it does not increase the retain count of aTarg.)
@property (assign) id externalTarget ;
@property (assign) SEL externalAction ;
@property (retain) NSImage* originalImage ;
@property (assign) NSTimer* flashTimer ;  // NSTimer retains itself, so 'assign'

@end

@implementation SSYToolbarButton

+ (void)initialize {
	if (self == [SSYToolbarButton class] ) {
		[self exposeBinding:constKeyValue] ;
		[self exposeBinding:constKeyToolTip] ;
	}
}


- (id)initWithItemIdentifier:(NSString*)identifier {
	self = [super initWithItemIdentifier:identifier] ;
	if (self) {
		// Make sure that setValue: does not take its early return the 
		// first time it is invoked…
		[self setValue:NSNotFound] ;
	}
	
	return self ;
}

@synthesize onImage = m_onImage ;
@synthesize offImage = m_offImage ;
@synthesize disImage = m_disImage ;
@synthesize originalImage = m_originalImage ;
@synthesize onLabel = m_onLabel ;
@synthesize offLabel = m_offLabel ;
@synthesize disLabel = m_disLabel ;
@synthesize onToolTip = m_onToolTip ;
@synthesize offToolTip = m_offToolTip ;
@synthesize disToolTip = m_disToolTip ;
@synthesize externalTarget = m_externalTarget ;
@synthesize externalAction = m_externalAction ;
@synthesize flashDuration = m_flashDuration ;

- (void)awakeFromNib {
	// The following is to support some other object binding to the
	// 'value' binding of a SSYToolbarButton.  We splice ourself in
	// to observe the action.
	[super setTarget:self] ;
	[super setAction:@selector(doDaClick:)] ;
	
	// In BookMacster, we use the conventional target/action and not
	// the binding.
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
	if (value == m_value) {
		return ; 
	}
	
	m_value = value ;
	
	NSImage* image = nil ;
	NSString* label = nil ;
	NSString* toolTip = nil ;
	switch (value) {
		case NSOnState:
			image = [self onImage] ;
			label = [self onLabel] ;
			toolTip = [self onToolTip] ;
			break ;
		case NSOffState:
			image = [self offImage] ;
			label = [self offLabel] ;
			toolTip = [self offToolTip] ;
			break ;
		case NSMixedState:
			image = [self disImage] ;
			label = [self disLabel] ;
			toolTip = [self disToolTip] ;
			break ;
	}

	if (image) {
		[self setImage:image] ;
	}
	
	if (label) {
		[self setLabel:label] ;
	}
	
	if (toolTip) {
		[self setToolTip:toolTip] ;
	}
}

- (void)restoreOriginalImage:(NSTimer*)timer {
    [self setImage:[self originalImage]] ;
    [self setOriginalImage:nil] ;
}

- (IBAction)doDaClick:(id)sender {
    if ([self flashDuration] > 0.0) {
        NSImage* image = [self image] ;
        [self setOriginalImage:image] ;
        NSImage* darkerImage = [image copy] ;
        [darkerImage darken] ;
        [self setImage:darkerImage] ;
        [darkerImage release] ;
        NSTimer* timer = [NSTimer scheduledTimerWithTimeInterval:[self flashDuration]
                                                          target:self
                                                        selector:@selector(restoreOriginalImage:)
                                                        userInfo:nil
                                                         repeats:NO] ;
        // Stash the timer so that we can invalidate it during -dealloc, in case
        // we are deallocced (window closes, for example) before the timer
        // fires.  Otherwise there would be a crash.
        [self setFlashTimer:timer] ;
    }
    
	//[self setValue:([self value] == NSOnState) ? NSOffState : NSOnState] ;
	[[self externalTarget] performSelector:[self externalAction]
								withObject:self] ;
}

- (void)dealloc {
    [m_flashTimer invalidate] ;
    
	[m_onImage release] ;
	[m_offImage release] ;
	[m_disImage release] ;
    [m_originalImage release] ;
	[m_onLabel release] ;
	[m_offLabel release] ;
	[m_disLabel release] ;
	[m_onToolTip release] ;
	[m_offToolTip release] ;
	[m_disToolTip release] ;
	
	[super dealloc] ;
}

@end