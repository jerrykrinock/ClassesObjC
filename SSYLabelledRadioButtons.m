#import "SSYLabelledRadioButtons.h"
#import "NSView+Layout.h"
#import "SSYAlert.h"
#import "NS(Attributed)String+Geometrics.h"
#import "SSYClickActionTextField.h"
#import "NSArray+SSYMutations.h"
#import "NSArray+SafeGetters.h"

static NSString* const constKeyWidth = @"Width" ;

@interface SSYLabelledRadioButtons ()

@property NSInteger preselectedIndex ;
@property (retain) NSArray* choices ;

@end

@implementation SSYLabelledRadioButtons

@synthesize preselectedIndex ;
@synthesize choices = m_choices ;

- (NSMatrix*)matrix {
	// How this works is explained in comments in the implementation
	// of -initWithLabel:choices:width:
	// However, when displayed in an SSYAlert, sometimes this
	// this gets invoked when popping an autorelease pool,
	// when there are no subviews.  So, I use -firstObjectSafely.
	return [[self subviews] firstObjectSafely] ;
}

- (NSTextField*)labelField {
	// How this works is explained in comments in the implementation
	// of -initWithLabel:choices:width:
	NSTextField* field = [[self subviews] lastObject] ;
	if ([field isKindOfClass:[SSYClickActionTextField class]]) {
		field = nil ;
	}
	
	return field ;
}

- (NSArray*)cellularFields {
	// How this works is explained in comments in the implementation
	// of -initWithLabel:choices:width:
	NSInteger labelFieldOffset = ([self labelField] != nil) ? -1 : 0 ;
	NSRange range = NSMakeRange(1, [[self subviews] count] - 1 +labelFieldOffset) ;
	return [[self subviews] subarrayWithRange:range] ;
}

// This is to work around a problem/bug in NSMatrix.
- (void)drawRect:(NSRect)rect {
	if (firstDrawing) {
		[[self matrix] selectCell:[[self matrix] cellAtRow:[self preselectedIndex]
													column:0]] ;
		firstDrawing = NO ;
	}
	
	[super drawRect:rect] ;
	
	// Regarding the workaround, you can do it after.  This works too:
	// [[self matrix] selectCell:...] ;
}

- (void)setSelectedIndex:(NSInteger)index {
	[self setPreselectedIndex:index] ;
}

- (NSInteger)selectedIndex {
	return [[self matrix] selectedRow] ;
}

// *** Accessors based on @property attributes: assign

@synthesize width = m_width ;

- (CGFloat)width {
	CGFloat width ;
	@synchronized(self) {
		width = m_width ; ;
	}
	return width ;
}

- (void)setWidth:(CGFloat)width {
	@synchronized(self) {
		m_width = width ;
	}

	[self sizeToFit] ;
}

#define CONTROL_VERTICAL_SPACING 14.0

- (void)sizeHeightToFitAllowShrinking:(BOOL)allowShrinking {
	[[self labelField] sizeHeightToFitAllowShrinking:allowShrinking] ;
	[self setHeight:
	 [[self matrix] height] 
	 + CONTROL_VERTICAL_SPACING
	 + [[self labelField] height]] ;
}

CGFloat static const constButtonWidth = 20.0 ;
CGFloat static const constIntercellHeight = 2.0 ;
CGFloat static const constHeightMarginPerCell = 6.0 ;
CGFloat static const constTextCenteringTweak = -0.0 ;

- (void)sizeToFit {
	CGFloat textWidth = [self width] - constButtonWidth ;
	CGFloat tallestCellHeight = 0.0 ;
	CGFloat widestCellWidth = 0.0 ;
	NSFont* font = [SSYAlert smallTextFont] ;
	NSMutableArray* textHeights = [NSMutableArray array] ;
	NSArray* cellularFields = [self cellularFields] ;
	// First iteration through choices, to find the heights
	NSInteger i = 0 ;
	NSMatrix* matrix = [self matrix] ;
	for (SSYClickActionTextField* textField in cellularFields) {
		NSString* title = [textField stringValue] ;
		NSSize size = [title sizeForWidth:textWidth
								   height:CGFLOAT_MAX
									 font:font] ;
		size.height += constHeightMarginPerCell ;
		[textHeights addObject:[NSNumber numberWithDouble:size.height]] ;
		tallestCellHeight = MAX(tallestCellHeight, size.height) ;
		widestCellWidth = MAX(widestCellWidth, size.width) ;
		i++ ;
	}
	[matrix setCellSize:NSMakeSize(constButtonWidth, tallestCellHeight)] ;
	[matrix sizeToCells] ;
	
	i = 0 ;
	CGFloat halfSpacing = (tallestCellHeight + constIntercellHeight) / 2.0 ;
	// Second iteration through the choices, to create and place the
	// text field for each button cell
	// We start with the top button and work down.
	CGFloat y = [matrix frame].size.height ;
	for (SSYClickActionTextField* cellularField in cellularFields) {
		CGFloat textHeight = [[textHeights objectAtIndex:i] doubleValue] ;
		CGFloat halfTextHeight = textHeight / 2.0 ;
		y -= halfSpacing ;
		y -= halfTextHeight ;
		y += constTextCenteringTweak ;
		NSRect frame = NSMakeRect(constButtonWidth, y, textWidth, textHeight) ;
		[cellularField setFrame:frame] ;
		// To make sure that the size does not change when we set the width of self, below
		[cellularField setAutoresizingMask:NSViewNotSizable] ;
		y -= constTextCenteringTweak ;
		y += halfTextHeight ;
		y -= halfSpacing ;
		i++ ;
	}

	y = [matrix frame].size.height ;

	NSTextField* labelField = [self labelField] ;
	if (labelField) {
		CGFloat width = constButtonWidth + widestCellWidth ;
		NSRect frame = NSMakeRect(0, 0, width, [SSYAlert smallTextHeight]) ;
		// To make sure that the size does not change when we set the width of self, below
		[labelField setAutoresizingMask:NSViewNotSizable] ;
		[labelField setFrame:frame] ;
		// Set spacing between label and matrix to two lines:
		y += [[SSYAlert smallTextFont] pointSize] ;
		[labelField setLeftEdge:0.0] ;
		[labelField setBottom:y] ;
		y += [labelField height] ;
	}
	
	// First, set self's width, then set sub text views to track future
	// changes to self's width
		CGFloat width = (constButtonWidth + textWidth) ;
		[super setWidth:width] ;

	[[self labelField] setAutoresizingMask:NSViewWidthSizable] ;
	for (SSYClickActionTextField* cellularField in [self cellularFields]) {
		[cellularField setAutoresizingMask:NSViewWidthSizable] ;
	}
	
	[self setHeight:y] ;
}

/*
 To make up and down arrow keys work to change selection
 */
- (void)keyDown:(NSEvent*)event {
	NSString *s = [event charactersIgnoringModifiers] ;
	unichar keyChar = 0 ;
	BOOL didHandle = NO ;
	if ([s length] == 1) {
		keyChar = [s characterAtIndex:0] ;
		if (
			(keyChar == NSUpArrowFunctionKey)
			||
			(keyChar == NSDownArrowFunctionKey)
			) {
			[[self matrix] keyDown:event] ;
			didHandle = YES ;
		}
	}
	
	if (!didHandle) {
		[super keyDown:event] ;
	}
}

- (id)initWithLabel:(NSString*)label
			choices:(NSArray*)choices
		      width:(CGFloat)width {
	self = [super initWithFrame:NSZeroRect] ;
	if (self != nil) {		
		// Note the order in which we add subviews.
		// The matrix is added first.
		// The cellular text field(s) are added next.
		// If used, the label text field is added last.
		// We assume this order when accessing the subviews later.
		
		NSButtonCell* cell = [[NSButtonCell alloc] initTextCell:NSLocalizedString(@"proto", nil)] ;
		[cell setButtonType:NSButtonTypeRadio] ;
		[cell setTitle:@""] ;
		NSMatrix* matrix  = [[NSMatrix alloc] initWithFrame:NSZeroRect
													   mode:NSRadioModeMatrix
												  prototype:cell
											   numberOfRows:[choices count]
											numberOfColumns:1] ;
		[cell release] ; // Memory leak fixed in BookMacster 1.11
		[matrix setLeftEdge:0.0] ;
		[matrix setBottom:0.0] ;
		[matrix setIntercellSpacing:NSMakeSize(0.0, constIntercellHeight)] ;
		[self addSubview:matrix] ;
		[matrix release] ;
		
		NSFont* font = [SSYAlert smallTextFont] ;

		NSInteger i = 0 ;
		// We start with the top button and work down.
		for (NSString* title in choices) {
			SSYClickActionTextField* textField = [[SSYClickActionTextField alloc] initWithFrame:NSZeroRect] ;
			[textField setBordered:NO] ;
			[textField setDrawsBackground:NO] ;
			[textField setEditable:NO] ;
			[textField setFont:font] ;
			[textField setStringValue:title] ;
			// It actually wrapped without the following, but I put it in anyhow.
			[[textField cell] setWraps:YES] ;
			// Set target and action so that a click on the text field
			// will act the same as a click on the adjacent
			// matrix cell, "just like a real NSMatrix cell".
			[textField setTarget:[matrix cellAtRow:i
											column:0]] ;
			[textField setAction:@selector(performClick:)] ;
			[self addSubview:textField] ;
            [textField release] ;
			i++ ;
		}

		if (label) {
			NSTextField* labelField = [[NSTextField alloc] initWithFrame:NSZeroRect] ;
			[labelField setFont:font] ;
			[labelField setBordered:NO] ;
			[labelField setEditable:NO] ;
			[labelField setDrawsBackground:NO] ;
			[labelField setStringValue:label] ;
			[self addSubview:labelField] ;
			[labelField release] ;
		}
		
		// Just in case this is not the default:
		[matrix setAutoresizingMask:NSViewNotSizable] ;
		
		[self setWidth:width] ;
		[self sizeToFit] ;
		
		firstDrawing = YES ;
		
		[self setChoices:choices] ;
	}

	return self ;
}

- (void)dealloc {
	[m_choices release] ;
	
	[super dealloc] ;
}

- (void)setNextKeyView:(NSView*)view {
	[[self matrix] setNextKeyView:view] ;
}

+ (SSYLabelledRadioButtons*)radioButtonsWithLabel:(NSString*)label
										  choices:(NSArray*)choices
										    width:(CGFloat)width {
	SSYLabelledRadioButtons* instance = [[SSYLabelledRadioButtons alloc] initWithLabel:label
																			   choices:choices
																			  width:width] ;
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
    
	[coder encodeDouble:m_width forKey:constKeyWidth] ;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder] ;
	
	m_width = [coder decodeDoubleForKey:constKeyWidth] ;
    
	return self ;
}

@end
