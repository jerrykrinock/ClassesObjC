#import "SSYLabelledPopUp.h"
#import "NSView+Layout.h"
#import "NSPopUpButton+Populating.h"
#import "SSYAlert.h"

NSString* const constKeyLabelField = @"LabelField" ;
NSString* const constKeyPopUpButton = @"PopUpButton" ;


@implementation SSYLabelledPopUp

@synthesize labelField ;
@synthesize popUpButton ;

//- (void)setDisplayedKey:(NSString*)label {
//	[[self labelField] setStringValue:label] ;
//}

- (void)setChoices:(NSArray*)choices {
	[[self popUpButton] populateTitles:choices
								target:self
								action:@selector(doNothing:)] ;
}

- (IBAction)doNothing:(id)sender {
	// Even if button does nothing, must still have
	// a dummy target and action to be enabled.
}

- (int)selectedIndex {
	return [[self popUpButton] selectedTag] ;
}

#define CONTROL_VERTICAL_SPACING 14.0

- (void)sizeHeightToFitAllowShrinking:(BOOL)allowShrinking {
	[[self labelField] sizeHeightToFitAllowShrinking:allowShrinking] ;
	[self setHeight:
	 [[self popUpButton] height] 
	 + CONTROL_VERTICAL_SPACING
	 + [[self labelField] height]] ;
}

- (id)initWithLabel:(NSString*)label {
	self = [super initWithFrame:NSZeroRect] ;
	if (self != nil) {
		
		float y ;
		
		NSPopUpButton* button ;
		button = [[NSPopUpButton alloc] initWithFrame:NSZeroRect
											pullsDown:NO] ;
		[button setHeight:22] ;  // for NSPopUpButton with control size = small.
		// Note: Setting the above to > 22 causes no change in actual size
		[button setLeftEdge:0.0] ;
		[button setBottom:0.0] ;
		[self setPopUpButton:button] ;
		[self addSubview:button] ;
		y = [button height] ;
		[button release] ;
		
		NSTextField* textField ;
		textField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 100, [SSYAlert smallTextHeight])] ;
		[textField setFont:[SSYAlert smallTextFont]] ;
		[textField setBordered:NO] ;
		[textField setEditable:NO] ;
		[textField setDrawsBackground:NO] ;
		[textField setStringValue:label] ;
		y += 0 ; // No vertical spacing between label and popup
		[textField setLeftEdge:0.0] ;
		[textField setBottom:y] ;
		[self setLabelField:textField] ;
		[self addSubview:textField] ;
		y += [textField height] ;
		[textField release] ;
		
		[self setAutoresizingMask:NSViewWidthSizable] ;
		
		// Start out with self and subviews all at same width,
		// then set to track future changes to self's width
		[self setWidth:[textField width]] ;
		[[self labelField] setAutoresizingMask:NSViewWidthSizable] ;
		[[self popUpButton] setAutoresizingMask:NSViewWidthSizable] ;
		
		[self setHeight:y] ;
		
		// This looks weird.  I suppose it makes sense, if there is only
		// one field in the keyboard loop at this level??
		[button setNextKeyView:button] ;
		
	}
	return self;
}

- (BOOL)becomeFirstResponder {
	BOOL x = [[self window] makeFirstResponder:[self popUpButton]] ;
	return x ;
}

- (void)setNextKeyView:(NSView*)view {
	[[self popUpButton] setNextKeyView:view] ;
}

+ (SSYLabelledPopUp*)popUpControlWithLabel:(NSString*)label {
	SSYLabelledPopUp* instance = [[SSYLabelledPopUp alloc] initWithLabel:label] ;
	return [instance autorelease] ;
}


- (void) dealloc {
	[labelField release] ;
	[popUpButton release] ;
	
	[super dealloc];
}

- (BOOL)acceptsFirstResponder {
	return YES ;
}

#pragma mark * NSCoding Protocol Conformance

// See http://developer.apple.com/documentation/Cocoa/Conceptual/Archiving/Tasks/codingobjects.html

// Although NSResponder::NSControl subclasses can sometimes get away with not implementing these
// two methods, not so if the control is used in SSYAlert, because SSYAlert will encode it when
// adding to its configurations stack.

// @encode(type_spec) is a compiler directive that returns a character string that encodes 
//    the type structure of type_spec.  It can be used as the first argument of can be used as
//    the first argument of encodeValueOfObjCType:at: 

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder] ;
    
	[coder encodeObject:labelField forKey:constKeyLabelField] ;
    [coder encodeObject:popUpButton forKey:constKeyPopUpButton] ;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder] ;
	
	labelField = [[coder decodeObjectForKey:constKeyLabelField] retain] ;
	popUpButton = [[coder decodeObjectForKey:constKeyPopUpButton] retain] ;
    
	return self ;
}

@end