#import "SSYDragTableView.h"
#import "NSInvocation+Quick.h"
#import "SSYArrayController.h"


@implementation SSYDragTableView

- (NSDragOperation)        draggingSession:(NSDraggingSession *)session
     sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
    NSDragOperation answer ;
    switch(context) {
        case NSDraggingContextOutsideApplication:
            answer = NSDragOperationCopy ;
            break;
            
        case NSDraggingContextWithinApplication:
        default:
            answer = (NSDragOperationCopy | NSDragOperationMove) ;
            break;
    }
    
    return answer ;
}

- (void)keyDown:(NSEvent*)event {
	NSString *s = [event charactersIgnoringModifiers] ;
	NSUInteger modifierFlags = [event modifierFlags] ;
	BOOL cmdKeyDown = ((modifierFlags & NSCommandKeyMask) != 0) ;
	unichar keyChar = 0 ;
	BOOL didHandle = NO ;
	if ([s length] == 1) {
		keyChar = [s characterAtIndex:0] ;
		if (keyChar == NSDeleteCharacter) {
			SEL selectionGetter = @selector(selectedObjects) ;
			SEL remover = @selector(removeObjects:) ;
			if (
				[[self delegate] respondsToSelector:selectionGetter]
				&&
				[[self delegate] respondsToSelector:remover]
				) {
				NSArray* selectedObjects = [[self delegate] performSelector:selectionGetter] ;
				[[self delegate] performSelector:remover
									  withObject:selectedObjects] ;
				didHandle = YES ;
			}
		}
		else if (cmdKeyDown) {
			if (
				(keyChar == NSUpArrowFunctionKey)
				||
				(keyChar == NSDownArrowFunctionKey)
				) {
				SEL mover = @selector(moveSelectionIndexBy:) ;
				if ([[self delegate] respondsToSelector:mover]) {			
					didHandle = YES ;
					NSIndexSet* selectedRowIndexes = [self selectedRowIndexes] ;
					if ([selectedRowIndexes count] > 0) {
						NSInteger moveBy = 0 ;
						if (
							(keyChar == NSUpArrowFunctionKey)
							&&
							([selectedRowIndexes firstIndex] > 0)
							) {
							moveBy = -1 ;
						}
						else if (
								 (keyChar == NSDownArrowFunctionKey)
								 &&
								 ([selectedRowIndexes lastIndex] < ([self numberOfRows] - 1))
								 ) {
							moveBy = +1 ;
						}
						else {
							NSBeep() ;
						}
						
						if (moveBy != 0) {
							// Use an invocation instead of performSelector:: due to the
							// non-object argument.
							NSInvocation* invocation = [NSInvocation invocationWithTarget:[self delegate]
																				 selector:mover
																		  retainArguments:YES
																		argumentAddresses:&moveBy] ;
							[invocation invoke] ;
						}
					}
					else {
						NSBeep() ;
					}
				}
			}
		}
	}
	
	if (!didHandle) {
		[super keyDown:event] ;
	}
}

/*  Was using this for debugging
- (void)viewDidMoveToWindow {
	[super viewDidMoveToWindow] ;
	
	// This redraws after the view is redisplayed quickly,
	// such as after switching tabs
	[self performSelector:@selector(display)
			   withObject:nil
			   afterDelay:0.1] ;
	
	// This redraws after the view is displayed slowly,
	// such as when the window initially opens
	[self performSelector:@selector(display)
			   withObject:nil
			   afterDelay:1.0] ;
}	
*/

@end