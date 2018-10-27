#import "SSYToolbarButton.h"
#import "NSImage+Transform.h"
#import "NSImage+SSYDarkMode.h"

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

        // The following is to support some other object binding to the
        // 'value' binding of a SSYToolbarButton.  We splice ourself in
        // to observe the action.
        [super setTarget:self] ;
        [super setAction:@selector(doDaClick:)] ;

        // In BookMacster, we use the conventional target/action and not
        // the binding.
	}
	
	return self ;
}

@synthesize onImage = m_onImage ;
@synthesize offImage = m_offImage ;
@synthesize disImage = m_disImage ;
@synthesize backgroundImage = m_backgroundImage;
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

	if (self.view) {
        /* Change the image for a view-based button */
        [self.view setNeedsDisplay:YES];
    } else {
        /* Change the image for a image-based button */
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
        NSImage* darkerImage = [image darkenedImage] ;
        [self setImage:darkerImage] ;
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
    [m_backgroundImage release];
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


@implementation SSYToolbarButtonView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    NSImage* image = nil;
    NSString* toolTip = nil;
    switch (self.toolbarItem.value) {
        case NSOnState:
            image = [self.toolbarItem onImage];
            toolTip = [self.toolbarItem onToolTip];
            break ;
        case NSOffState:
            image = [self.toolbarItem offImage];
            toolTip = [self.toolbarItem offToolTip];
            break ;
        case NSMixedState:
            image = self.toolbarItem.disImage;
            toolTip = self.toolbarItem.disToolTip;
            break ;
    }

    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    [image drawInRect:NSMakeRect(
                                 0.0,
                                 0.0,
                                 [image size].width,
                                 [image size].height)
             fromRect:NSZeroRect
            operation:NSCompositeSourceOver
             fraction:1.0];

    [self.toolbarItem.backgroundImage drawInRect:NSMakeRect(
                                                            0.0,
                                                            0.0,
                                                            self.toolbarItem.backgroundImage.size.width,
                                                            self.toolbarItem.backgroundImage.size.height)
                                        fromRect:NSZeroRect
                                       operation:NSCompositeSourceOver
                                        fraction:1.0];

    if (toolTip) {
        [self setToolTip:toolTip] ;
    }
}

- (void)mouseDown:(NSEvent*)event {
    [self.toolbarItem doDaClick:self];
}

@end
