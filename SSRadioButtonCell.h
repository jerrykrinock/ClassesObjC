// Somewhat adapted from Buzz Andersen's Cocoalicious class, SFHFRatingCell

#import <Cocoa/Cocoa.h>

@interface SSRadioButtonCell : NSActionCell <NSCopying, NSCoding> {
    NSImage* _selectedImage ;
    NSImage* _deselectedImage ;
	NSMutableArray* _widths ;
	
    NSRect _currentFrameInControlView ;
	NSInteger _numberOfButtons ;
}

- (void)setSelectedImage:(NSImage*)newImage ;
- (void)setDeselectedImage:(NSImage*)newImage ;
- (NSImage*)selectedImage ;
- (NSImage*)deselectedImage ;

- (NSNumber *) calculateSelectionForPoint: (NSPoint) point inView: (NSView *) controlView;

- (void)setNumberOfButtons:(NSInteger)x ;
- (NSInteger)numberOfButtons ;
- (NSMutableArray*)widths ;
- (NSInteger)numberOfButtons ;
- (void)triggerKVO ;

- (void)setWidth:(CGFloat)width forSegment:(NSInteger)segment ;

@end
