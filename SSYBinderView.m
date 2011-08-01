#import "SSYBinderView.h"

/*!
 @brief    A class which encapsulates a Cocoa Binding, remembering
 its parameters even when it is not currently bound.
*/
@interface SSYBinding : NSObject {
	NSView* m_boundObject ;
	NSString* m_bindingName ;
	id m_boundToObject ;
	NSString* m_keyPath ;
	NSDictionary* m_options ;
}

@property (retain) NSView* boundObject ;
@property (copy) NSString* bindingName ;
@property (retain) id boundToObject ;
@property (copy) NSString* keyPath ;
@property (retain) NSDictionary* options ;

- (void)bind ;
- (void)unbind ;

@end

@implementation SSYBinding

@synthesize boundObject = m_boundObject ;
@synthesize bindingName = m_bindingName ;
@synthesize boundToObject = m_boundToObject ;
@synthesize keyPath = m_keyPath ;
@synthesize options = m_options ;

- (void)dealloc {
	[m_boundObject release] ;
	[m_bindingName release] ;
	[m_boundToObject release] ;
	[m_keyPath release] ;
	[m_options release] ;

	[super dealloc] ;
}

- (void)bind {
	[[self boundObject] bind:[self bindingName]
					toObject:[self boundToObject]
				 withKeyPath:[self keyPath]
					 options:[self options]] ;
}

- (void)unbind {
	[[self boundObject] unbind:[self bindingName]] ;
}

@end

@interface SSYBinderView ()

@property BOOL isBound ;

@end


@implementation SSYBinderView

@synthesize isBound = m_isBound ;

- (void)dealloc {
	[m_bindings release] ;
	
	[super dealloc] ;
}

- (NSMutableSet*)bindings {
	if (!m_bindings) {
		m_bindings = [[NSMutableSet alloc] init] ;
	}
	
	return m_bindings ;
}

- (void)viewWillMoveToWindow:(NSWindow*)window {
	SEL selector = NULL ;
	
	if (window && ![self isBound]) {
		selector = @selector(bind) ;
		[self setIsBound:YES] ;
	}
	else if (!window && [self isBound]) {
		selector = @selector(unbind) ;
		[self setIsBound:NO] ;
	}
	
	if (selector) {
		for (SSYBinding* binding in [self bindings]) {
			[binding performSelector:selector] ;
		}
	}
	
	[super viewWillMoveToWindow:window] ;
}

- (void)bindSubview:(NSView*)subview
		bindingName:(NSString*)bindingName
		   toObject:(id)object
		withKeyPath:(NSString*)keyPath
			options:(NSDictionary*)options {
	if (!subview || !bindingName || !object || !keyPath) {
		return ;
	}
	
	SSYBinding* binding = [[SSYBinding alloc] init] ;
	[binding setBoundObject:subview] ;
	[binding setBindingName:bindingName] ;
	[binding setBoundToObject:object] ;
	[binding setKeyPath:keyPath] ;
	[binding setOptions:options] ; 

	[[self bindings] addObject:binding] ;
	[binding release] ;
	
	if ([self isBound]) {
		[binding bind] ;
	}
}

/* todo
 - (void)unbindSubview:(NSView*)subview
		  bindingName:(NSString*)bindingName {
 // Either I'm going to have to iterate through [self bindings] to
 // look for the specified binding and remove it, or else
 // change [self bindings] to be a dictionary instead of a set.
 // The dictionary could be keyed by some composite string
 // giving the subview's pointer plus the bindingName.
}
*/

@end