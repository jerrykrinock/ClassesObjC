#import "SSYFileThumbnailView.h"
#import "Browser.h"
#import <QuickLook/QLThumbnailImage.h>

@implementation SSYFileThumbnailView

- (Browser*)browser {
    Browser* browser = (Browser*)[[self window] windowController] ;
    // As window is closing, browser will be nil.
    if (browser) {
        if (![browser respondsToSelector:@selector(selectedFileoid)]) {
            NSLog(@"Internal Error 649-9283 %@", browser) ;
            browser = nil ;
        }
    }
    
    return browser ;
}

- (Fileoid*)fileoid {
    return [[self browser] selectedFileoid] ;
}


- (void)awakeFromNib {
    NSArrayController* fileoidController = [[self browser] fileoidController] ;
    [fileoidController addObserver:self
                        forKeyPath:@"selectedObjects"
                           options:0
                           context:NULL] ;
}

- (void)dealloc {
	[[[self browser] fileoidController] removeObserver:self
                                            forKeyPath:@"selectedObjects"] ;
    
	[super dealloc] ;
}

- (void)drawImage:(NSImage*)imageIn {
    CGImageRef imageRef = (CGImageRef)imageIn ;
    NSImage* image = nil ;
    NSRect rect ;
    rect.origin.x = 0 ;
    rect.origin.y = 0 ;
    rect.size.width = [self frame].size.width ;
    rect.size.height = [self frame].size.height ;
    
    if (imageRef) {            
        // The following kludge is because the QuickLook API (above) returns a
        // CGImageRef.
        // Maybe I could hand this off directly to an IKImageView ???
        
        CGRect cgRect ;
        cgRect.origin.x = 0 ;
        cgRect.origin.y = 0 ;
        cgRect.size.width = [self frame].size.width ;
        cgRect.size.height = [self frame].size.height ;
        
        image = [[NSImage alloc] initWithSize:rect.size] ;
        [image lockFocus] ;
        CGContextDrawImage([[NSGraphicsContext currentContext] graphicsPort],
                           cgRect,
                           imageRef) ;
        [image unlockFocus] ;
    }
    else {
        // QuickLook thumbnail is not available for this file.
        // Use its icon instead.
        image = [[[NSWorkspace sharedWorkspace] iconForFile:[[self fileoid] path]] retain] ;
        [image setSize:rect.size] ; 
    }
    
    [self setImage:image] ;
    [image release] ;
}

- (void)updateImage {
    Fileoid* fileoid = [self fileoid] ;
    if (fileoid) {
        NSString* path = [fileoid path] ;
        NSURL* url = [NSURL fileURLWithPath:path] ;
        NSRect frame = [self frame] ;
        
        CGRect cgRect ;
        cgRect.origin.x = 0 ;
        cgRect.origin.y = 0 ;
        cgRect.size.width = frame.size.width ;
        cgRect.size.height = frame.size.height ;
        
        dispatch_queue_t aQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) ;
        dispatch_async(aQueue, ^{
            // Before inserting the following dispatch_async, above, when this
            // function ran a complaint would log in console from function
            // QLError() stating that a thumbnail was being computed on the main
            // thread and this could cause a nonresponsive user interface.
            // Oddly, this would only happen with the preview pane (QLPreviewPane)
            // was visible.
            CGImageRef imageRef = QLThumbnailImageCreate(NULL,
                                                         (CFURLRef)url,
                                                         cgRect.size,
                                                         NULL) ;
            
            [(id)imageRef autorelease] ;
            
            // Must always update UI on main thread, so I'm told…
            [self performSelectorOnMainThread:@selector(drawImage:)
                                   withObject:(id)imageRef
                                waitUntilDone:NO] ;
        } ) ;
    }
    else {
        [self setImage:nil] ;
    }    
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    [self updateImage] ;
}


- (void)drawRect:(NSRect)dirtyRect {
    [self updateImage] ;
    
    [super drawRect:dirtyRect] ;
}

@end
