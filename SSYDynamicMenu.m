#import "SSYDynamicMenu.h"
#import "NSMenu+Populating.h"
#import "NSMenu+Ancestry.h"
#import "SSYRuntimeUtilities.h"


@implementation SSYDynamicMenu

@synthesize target = m_target ;
@synthesize selector = m_selector ;
@synthesize targetInfo = m_targetInfo ;
@synthesize representedObjects = m_representedObjects ;
@synthesize selectedRepresentedObject = m_selectedRepresentedObject ;

@synthesize owningPopUpButton = m_owningPopUpButton ;

- (id)initWithTitle:(NSString*)title {
	self = [super initWithTitle:title] ;
	[self setDelegate:self] ;
	return self ;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder] ;
	[self setDelegate:self] ;
	return self ;
}

- (void)dealloc {
	[m_target release] ;
	[m_targetInfo release] ;
	[m_representedObjects release] ;
	[m_selectedRepresentedObject release] ;
	
	[super dealloc] ;
}

- (id)initWithTarget:(id)target
			selector:(SEL)selector
		  targetInfo:(id)targetInfo {
	self = [super init] ;
	
	if(self) {
		[self setTarget:target] ;
		[self setSelector:selector] ;
		[self setTargetInfo:targetInfo] ;
	}
	
	return self ;
}

- (IBAction)hierarchicalMenuAction:(id)sender  {
	SEL selector = [self selector] ;
	NSInteger numberOfArguments = [SSYRuntimeUtilities numberOfArgumentsInSelector:selector] ;
	switch (numberOfArguments) {
		case 1:
			[[self target] performSelector:selector
							withObject:[sender representedObject]] ;
			break ;
		case 2:
			[[self target] performSelector:selector
								withObject:[self targetInfo]
								withObject:[sender representedObject]] ;
			break ;
		default:
			NSLog(@"Internal Error 657-0183") ;
	}
}

- (void)reload {
	[[self delegate] menuNeedsUpdate:self] ;
}

@end