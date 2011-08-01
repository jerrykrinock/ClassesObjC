// Somewhat adapted from Buzz Andersen's Cocoalicious class, SFHFRatingCell

#import <Cocoa/Cocoa.h>

@interface SSRadioButtonCell : NSActionCell <NSCopying, NSCoding> {
    NSImage* _selectedImage ;
    NSImage* _deselectedImage ;
	NSMutableArray* _widths ;
	
    NSRect _currentFrameInControlView ;
	int _numberOfButtons ;
}

- (void)setSelectedImage:(NSImage*)newImage ;
- (void)setDeselectedImage:(NSImage*)newImage ;
- (NSImage*)selectedImage ;
- (NSImage*)deselectedImage ;

- (NSNumber *) calculateSelectionForPoint: (NSPoint) point inView: (NSView *) controlView;

- (void)setNumberOfButtons:(int)x ;
- (int)numberOfButtons ;
- (NSMutableArray*)widths ;
- (int)numberOfButtons ;
- (void)triggerKVO ;

- (void)setWidth:(float)width forSegment:(int)segment ;

@end
