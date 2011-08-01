#import "SSYLabelledTextField.h"
#import "NSView+Layout.h"
#import "SSYAlert.h"

#pragma mark * Const Keys for En/Decoding Instance Variables
NSString* const constKeyKeyField = @"KeyField" ;
NSString* const constKeyValueField = @"ValueField" ;
NSString* const constKeyValidationSelector = @"ValidationSelector" ;
NSString* const constKeyValidationObject = @"ValidationObject" ;
NSString* const constKeyWindowController = @"WindowController" ;
NSString* const constKeyErrorMessage = @"ErrorMessage" ;


@interface NSWindowController (Disableable) 

- (void)setEnabled:(BOOL)enabled ;
- (void)setWhyDisabled:(NSString*)why ;

@end

@implementation SSYLabelledTextField

@synthesize keyField ;
@synthesize valueField ;
@synthesize validationSelector ;
@synthesize validationObject ;
@synthesize windowController ;
@synthesize errorMessage ;

- (void)setStringValue:(NSString*)stringValue {
	[[self valueField] setStringValue:stringValue] ;
}

- (NSString*)stringValue {
	return [[self valueField] stringValue] ;
}

- (void)validate {
	SEL validationSelector_ = [self validationSelector] ;
	if (validationSelector_ != NULL) {
		BOOL ok = NO ;
		ok = [[[self stringValue] performSelector:validationSelector
									   withObject:[self validationObject]] boolValue] ;
		
		
		NSWindowController* windowController_ = [[self window] windowController] ;
		if (!windowController_) {
			windowController_ = windowController ;
		}
		if ([windowController_ respondsToSelector:@selector(setEnabled:)]) {
			[windowController_ setEnabled:ok] ;
		}
		else if ([windowController_ respondsToSelector:@selector(setIsEnabled:)]) {
			[(id)windowController_ setIsEnabled:ok] ;
		}
		
		if ([windowController_ respondsToSelector:@selector(setWhyDisabled:)]) {
			NSString* why = ok ? nil : [self errorMessage] ;
			[windowController_ setWhyDisabled:why] ;
		}
	}
}

#define CONTROL_VERTICAL_SPACING 14.0

- (id)initAsSecure:(BOOL)secure
validationSelector:(SEL)validationSelector_
  validationObject:(id)validationObject_
  windowController:(NSWindowController*)windowController_
	  displayedKey:(NSString*)displayedKey
	displayedValue:(NSString*)displayedValue
		  editable:(BOOL)editable_
	  errorMessage:(NSString*)errorMessage_ {
	self = [super initWithFrame:NSZeroRect];
	if (self != nil) {
		NSTextField* textField ;
		
		float y ;
		
		// Create and add the value field
		Class fieldClass = secure ? [NSSecureTextField class] : [NSTextField class] ;
		textField = [[fieldClass alloc] initWithFrame:NSMakeRect(0, 0, 100, [SSYAlert smallTextHeight] + 4.0)] ;
		[textField setFont:[SSYAlert smallTextFont]] ;
		[textField setBordered:NO] ;
		[textField setEditable:YES] ;
		[textField setDrawsBackground:YES] ;
		[textField setLeftEdge:0.0] ;
		[textField setBottom:0.0] ;
		[textField setDelegate:self] ; // for -controlTextDidChange
		[self setValueField:textField] ;
		[self addSubview:textField] ;
		y = [textField height] ;
		[textField release] ;
		
		// Create and add the key field
		textField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 100, [SSYAlert smallTextHeight])] ;
		[textField setFont:[SSYAlert smallTextFont]] ;
		[textField setBordered:NO] ;
		[textField setEditable:NO] ;
		[textField setDrawsBackground:NO] ;
		y += CONTROL_VERTICAL_SPACING/2 ;  // Divide by two so key field is close to value field
		[textField setLeftEdge:0.0] ;
		[textField setBottom:y] ;
		[self setKeyField:textField] ;
		[self addSubview:textField] ;
		y += [textField height] ;
		[textField release] ;
		
		// Start out with self and subviews all at same width,
		// then set to track future changes to self's width
		[self setWidth:[textField width]] ;
		[[self keyField] setAutoresizingMask:NSViewWidthSizable] ;
		[[self valueField] setAutoresizingMask:NSViewWidthSizable] ;
		
		// This looks weird.  I suppose it makes sense, if there is only
		// one field in the keyboard loop at this level??
		[[self valueField] setNextKeyView:[self valueField]] ;
		
		[self setHeight:y] ;
		
		[self setValidationSelector:validationSelector_] ;
		[self setValidationObject:validationObject_] ;
		[self setWindowController:windowController_] ;
		if (displayedKey) {
			[[self keyField] setStringValue:displayedKey] ;
		}
		if (displayedValue) {
			[[self valueField] setStringValue:displayedValue] ;
		}
		[[self valueField] setEditable:editable_] ;
		[self setErrorMessage:errorMessage_] ;
		
		// The following is needed in the usual case where, upon initialization,
		// the initial value of @"" is invalid.&nbsp; We need to send validation
		// messages (actually invalidation messages) to the window controller.
		[self validate] ;
	}
	return self;
}

+ (SSYLabelledTextField*)labelledTextFieldSecure:(BOOL)secure
							  validationSelector:(SEL)validationSelector
								validationObject:(id)validationObject
								windowController:(id)windowController
									displayedKey:(NSString*)displayedKey
								  displayedValue:(NSString*)displayedValue
										editable:(BOOL)editable
									errorMessage:(NSString*)errorMessage {
	SSYLabelledTextField* instance = [[SSYLabelledTextField alloc] initAsSecure:secure
															 validationSelector:validationSelector
															   validationObject:validationObject
															   windowController:windowController
																   displayedKey:displayedKey
																 displayedValue:displayedValue																	   editable:editable
																   errorMessage:errorMessage] ;
	return [instance autorelease] ;
}

- (void) dealloc {
	[keyField release] ;
	[valueField release] ;
	[validationObject release] ;
	[windowController release] ;
	[errorMessage release] ;
	
	[super dealloc];
}

- (NSString*)description {
	NSArray* keys = [NSArray arrayWithObjects:
					 @"keyField",
					 @"valueField",
					 @"validationObject",
					 @"windowController",
					 @"errorMessage",
					 nil] ;
	NSDictionary* dictionary = [self dictionaryWithValuesForKeys:keys] ;
	NSMutableDictionary* dic = [NSMutableDictionary dictionaryWithDictionary:dictionary] ;
	[dic setValue:NSStringFromSelector([self validationSelector])
		   forKey:@"validationSelector"] ;
	return [dic description] ;
}

- (void)sizeHeightToFitAllowShrinking:(BOOL)allowShrinking {
	[[self keyField] sizeHeightToFitAllowShrinking:allowShrinking] ;
	[self setHeight:
	 [[self valueField] height] 
	 + CONTROL_VERTICAL_SPACING
	 + [[self keyField] height]] ;
}

- (BOOL)acceptsFirstResponder {
	return [[self valueField] acceptsFirstResponder] ;
}

- (void)setNextKeyView:(NSView*)view {
	[[self valueField] setNextKeyView:view] ;
}

/*- (NSView*)nextKeyView {
 NSView* view = [[self editableField] nextKeyView] ;
 return view ;
 }
 
 - (NSView*)previousKeyView {
 NSView* view = [super previousKeyView] ;
 if (!view) {
 view = [[self editableField] previousKeyView] ;
 }
 return view ;
 }
 */
- (BOOL)becomeFirstResponder {
	BOOL x = [[self window] makeFirstResponder:[self valueField]] ;
	return x ;
}

- (NSString*)title { // for debugging
	return [[self keyField] stringValue] ;
}

// Delegate methods
- (void)controlTextDidChange:(NSNotification *)notification {
	[self validate] ;
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
    
	[coder encodeObject:keyField forKey:constKeyKeyField] ;
    [coder encodeObject:valueField forKey:constKeyValueField] ;
    [coder encodeObject:NSStringFromSelector(validationSelector) forKey:constKeyValidationSelector] ;
    [coder encodeObject:validationObject forKey:constKeyValidationObject] ;
	[coder encodeObject:windowController forKey:constKeyWindowController] ;
    [coder encodeObject:errorMessage forKey:constKeyErrorMessage] ;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder] ;
	
	keyField = [[coder decodeObjectForKey:constKeyKeyField] retain] ;
	valueField = [[coder decodeObjectForKey:constKeyValueField] retain] ;
    validationSelector = NSSelectorFromString([coder decodeObjectForKey:constKeyValidationSelector]) ;
	validationObject = [[coder decodeObjectForKey:constKeyValidationObject] retain] ;
	windowController = [[coder decodeObjectForKey:constKeyWindowController] retain] ;
	errorMessage = [[coder decodeObjectForKey:constKeyErrorMessage] retain] ;
	
	return self ;
}


@end