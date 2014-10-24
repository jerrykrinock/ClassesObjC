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

- (void)appendToRecentSearches:(NSString*)newString {
    if ([newString length] > 0) {
        NSMutableArray* recentSearches = [[self recentSearches] mutableCopy] ;

        // In case newString is a re-do of an earlier search,
        [recentSearches removeObject:newString] ;
        // Now add newString at the top
        [recentSearches insertObject:newString
                             atIndex:0] ;

        if (![[self recentSearches] isEqualToArray:recentSearches]) {
            [self setRecentSearches:recentSearches] ;
            /* I have twice seen a crash here, when the above method attempts
             to post a notification.  Could not reproduce after that.  Crash
             occurs when framework method attempts to post a notification.
             But I could not identify the notification because Xcode gives
             me the "couldn't materialize struct" crap when I ask for values
             in registers $rdi $rdx $rsi.  I looked through my code, Apple
             documentation and have no idea what notification would be posted.
             */
        }
        
        [recentSearches release] ;
    }
}

@end
