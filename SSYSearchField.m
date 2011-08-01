#import "SSYSearchField.h"

NSString* const SSYSearchFieldDidCancelNotification = @"SSYSearchFieldDidCancelNotification" ;

@interface SSYSearchField ()

@property (assign) id cancelButtonTarget ;
@property (assign) SEL cancelButtonAction ;

@end


@implementation SSYSearchField

@synthesize cancelButtonTarget = m_cancelButtonTarget ;
@synthesize cancelButtonAction = m_cancelButtonAction ;

- (void)awakeFromNib {
	NSSearchFieldCell* cell = [self cell] ;
	NSButtonCell* cancelButtonCell = [cell cancelButtonCell] ;
	
	// Get the target and action of the cancelButtonCell
	[self setCancelButtonTarget:[cancelButtonCell target]] ;
	[self setCancelButtonAction:[cancelButtonCell action]] ;
	
	// Tell the cancelButtonCell to send message to us instead
	// of its original target and action
	[cancelButtonCell setTarget:self] ;
	[cancelButtonCell setAction:@selector(cancelAction:)] ;
}

- (IBAction)cancelAction:(id)sender {
	// Post our notification
	[[NSNotificationCenter defaultCenter] postNotificationName:SSYSearchFieldDidCancelNotification
														object:self] ;
	
	// Invoke the original target|action of the cancelButtonCell
	[[self cancelButtonTarget] performSelector:[self cancelButtonAction]
									withObject:sender] ;
}

@end
