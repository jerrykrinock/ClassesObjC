#import <Cocoa/Cocoa.h>

// Based largely on FileDropView by Seth Willits, 2005
// This still has some pretty kludgey code in it (probably mine - JK)

@interface SSYFileDropView : NSControl {
	BOOL highlight ;
	NSString* m_filePath ;

	IBOutlet NSButton* image ;
		// In IB, the above is a borderless NSButton.  I tried to use a NSView
		// here but then this sub-view was outside the drop zone for the
		// FIleDropView, and thus FileDropView had a "hole" where the file could
		// not be dropped.  According to Glenn Andreas:
		// NSImageView already has support for drag & drop built in, which is  
		// what you're seeing (since when dropping, AppKit finds the "deepest"  
		// view under the mouse that deals with the drop)
	IBOutlet NSTextField* label ;
}

@property (copy) NSString* path ;

- (NSString*)objectValue ;
- (void)setObjectValue:(NSString*)objectValue ;

@end