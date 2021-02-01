#import "SSYWrappingCheckbox.h"
#import "NSView+Layout.h"
#import "SSYAlert.h"
#import "NS(Attributed)String+Geometrics.h"

static NSString* const constKeyTextField = @"TextField" ;
static NSString* const constKeyCheckbox = @"Checkbox" ;
static NSString* const constKeyMaxWidth = @"MaxWidth" ;

@implementation SSYPassMouseEventsToSiblingTextField

- (NSView*)sibling {
    NSArray* siblings = [[self superview] subviews];
    for (NSView* sibling in siblings) {
        if (sibling != self) {
            return sibling;
        }
    }
    
    return nil;
}

- (NSEvent*)eventTranslated:(NSEvent*)event
                  toSibling:(NSView*)sibling{
    NSPoint offset = NSMakePoint(NSMinX(self.superview.frame), NSMinY(self.superview.frame));
    return [NSEvent mouseEventWithType:event.type
                              location:NSMakePoint(offset.x + NSMidX(sibling.frame), offset.y + NSMidY(sibling.frame))
                         modifierFlags:event.modifierFlags
                             timestamp:event.timestamp
                          windowNumber:event.windowNumber
                               context:nil
                           eventNumber:event.eventNumber
                            clickCount:event.clickCount
                              pressure:event.pressure];
}

- (void)mouseDown:(NSEvent *)event {
    [[self sibling] mouseDown:[self eventTranslated:event
                                          toSibling:[self sibling]]];
}

- (void)mouseUp:(NSEvent *)event {
    [[self sibling] mouseUp:[self eventTranslated:event
                                        toSibling:[self sibling]]];
}

@end

@interface SSYWrappingCheckbox ()

@end

@implementation SSYWrappingCheckbox

@synthesize textField = m_textField ;
@synthesize checkbox = m_checkbox ;

- (CGFloat)maxWidth {
	CGFloat maxWidth ;
	@synchronized(self) {
		maxWidth = m_maxWidth ; ;
	}
	return maxWidth ;
}

- (void)setMaxWidth:(CGFloat)maxWidth {
	@synchronized(self) {
		m_maxWidth = maxWidth ;
	}

	[self sizeToFit] ;
}

- (void)setState:(NSControlStateValue)state {
	[[self checkbox] setState:state] ;
}

- (NSControlStateValue)state {
	return [[self checkbox] state] ;
}

- (void)sizeHeightToFitAllowShrinking:(BOOL)allowShrinking {
	[[self textField] sizeHeightToFitAllowShrinking:allowShrinking] ;
	[self setHeight:[[self textField] height]] ;
}

// You could change these if you wanted a different size checkbox
CGFloat static const constCheckboxWidth = 18.0 ;
CGFloat static const constCheckboxHeight = 18.0 ;
// It is possible that I should define only one of the following
// constants, and use the negative for the other one.
CGFloat static const kCenteringTweakForCheckbox = +2.0 ;
CGFloat static const kCenteringTweakForTextField = -2.0 ;

CGFloat static const constCheckboxToTextMargin = 3.0 ;
CGFloat static const constTextMarginX = 0.0 ;
CGFloat static const constTextMarginY = 5.0 ;

- (void)sizeToFit {
	SSYPassMouseEventsToSiblingTextField* textField = [self textField] ;
	NSString* title = [textField stringValue] ;
	CGFloat maxWidth = [self maxWidth] ;
	
	CGFloat textMaxWidth = maxWidth - constCheckboxWidth - constCheckboxToTextMargin - constTextMarginX  ;
	NSFont* font = [SSYAlert smallTextFont] ;
	NSSize textSize = [title sizeForWidth:textMaxWidth
								   height:CGFLOAT_MAX
									 font:font] ;
	NSSize textFieldSize ;
	textFieldSize.width = textSize.width + constTextMarginX ;
	textFieldSize.height = textSize.height + constTextMarginY ;
	CGFloat checkboxY ;
	CGFloat textFieldY ;
	if (textSize.height > constCheckboxHeight + 2 * kCenteringTweakForCheckbox) {
		// Text field's bottom will be at self's bottom
		textFieldY = 0.0 ;
		checkboxY = (textFieldSize.height - constCheckboxHeight)/2 + kCenteringTweakForCheckbox ;
	}
	else {
		// Checkbox's bottom will be at self's bottom
		checkboxY = 0.0 ;
		textFieldY = (constCheckboxHeight - textFieldSize.height)/2 + kCenteringTweakForTextField ;
	}
	
	NSButton* checkbox = [self checkbox] ;
	
	[checkbox setBottom:checkboxY] ;
	NSRect textFieldFrame = NSMakeRect(
									   constCheckboxWidth + constCheckboxToTextMargin,
									   textFieldY,
									   textFieldSize.width,
									   textFieldSize.height) ;
	[textField setFrame:textFieldFrame] ;
	
	[self setAutoresizingMask:NSViewWidthSizable] ;
	
	// Start out with self and subviews all at same width,
	// then set to track future changes to self's width
	
	[textField setAutoresizingMask:NSViewNotSizable] ;
	
	CGFloat overallWidth = NSMaxX(textFieldFrame) ;
	CGFloat overallHeight = MAX(NSMaxY(textFieldFrame), [checkbox top]) ;
	[self setSize:NSMakeSize(overallWidth, overallHeight)] ;
	
	[[self textField] setAutoresizingMask:NSViewWidthSizable] ;
}


- (id)initWithTitle:(NSString*)title
		   maxWidth:(CGFloat)maxWidth {
	self = [super initWithFrame:NSZeroRect] ;
	if (self != nil) {
		// Create checkbox
		// The checkbox's origin.y may change later, but we want to set the other
		// three parms which will be constant.
		NSRect checkboxFrame = NSMakeRect(0.0, 0.0, constCheckboxWidth, constCheckboxHeight) ;
		NSButton* checkbox = [[NSButton alloc] initWithFrame:checkboxFrame] ;
		[checkbox setTitle:@""] ;
		[checkbox setButtonType:NSButtonTypeSwitch] ;
		[checkbox setAutoresizingMask:NSViewNotSizable] ;
		[self addSubview:checkbox] ;
		[checkbox release] ;
		[self setCheckbox:checkbox] ; // weak
		
		// Create text field
		// We just set its frame to the zero rect for now, because the only one
		// of the four parms we know for sure at this time is the position.x.
		SSYPassMouseEventsToSiblingTextField* textField = [[SSYPassMouseEventsToSiblingTextField alloc] initWithFrame:NSZeroRect] ;
		[textField setBordered:NO] ;
		[textField setDrawsBackground:NO] ;
		NSFont* font = [SSYAlert smallTextFont] ;
		[textField setFont:font] ;
		[[textField cell] setWraps:YES] ;
		[textField setEditable:NO] ;
		[self addSubview:textField] ;
		[textField release] ;
		[self setTextField:textField] ; // weak
		
		// Set parameters
		[textField setStringValue:title] ;
		[self setMaxWidth:maxWidth] ;
		[self sizeToFit] ;
	}

	return self ;
}

- (BOOL)becomeFirstResponder {
	BOOL x = [[self window] makeFirstResponder:[self checkbox]] ;
	return x ;
}

- (void)setNextKeyView:(NSView*)view {
	[[self checkbox] setNextKeyView:view] ;
}

+ (SSYWrappingCheckbox*)wrappingCheckboxWithTitle:(NSString*)title
										 maxWidth:(CGFloat)width {
	SSYWrappingCheckbox* instance = [[SSYWrappingCheckbox alloc] initWithTitle:title
																	  maxWidth:width] ;
	return [instance autorelease] ;
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
    
	[coder encodeObject:m_textField forKey:constKeyTextField] ;
    [coder encodeObject:m_checkbox forKey:constKeyCheckbox] ;
	[coder encodeDouble:m_maxWidth forKey:constKeyMaxWidth] ;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder] ;
	
	m_textField = [[coder decodeObjectForKey:constKeyTextField] retain] ;
	m_checkbox = [[coder decodeObjectForKey:constKeyCheckbox] retain] ;
    m_maxWidth = [coder decodeDoubleForKey:constKeyMaxWidth] ;
				  
	// Should be unnecessary since -sizeToFit is always invoked when
	// setting title or maximum width?
	// [self sizeToFit] ;
	
	return self ;
}

@end
