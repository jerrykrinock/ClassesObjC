#import "SSYSizeFixxerSubview.h"


@implementation SSYSizeFixxerSubview


+ (BOOL)shallowlyGetFixedSize_p:(NSSize *)size_p
                    defaultSize:(NSSize)defaultSize
                   fromSubviews:(NSArray *)subviews {
	// Set a large default fixed size for defensive programming
    *size_p = defaultSize ;
	
	// Set to the size of the Size Fixxer Subview
	BOOL didFindSSYSizeFixxerSubview = NO ;
	for (NSView* subview in subviews) {
		if ([subview isKindOfClass:[SSYSizeFixxerSubview class]]) {
			*size_p = [subview frame].size ;
			didFindSSYSizeFixxerSubview = YES ;
			break ;
		}
	}
    
    return didFindSSYSizeFixxerSubview ;
}

+ (NSSize)fixedSizeAmongSubviews:(NSArray *)subviews
                     defaultSize:(NSSize)defaultSize {
    NSSize size;
    BOOL didFindSSYSizeFixxerSubview = [self shallowlyGetFixedSize_p:&size
                                                         defaultSize:defaultSize
                                                        fromSubviews:subviews] ;
	
	if (!didFindSSYSizeFixxerSubview) {
		if ([subviews count] == 1) {
            // The subview is a thin wrapper around another view.
            NSView* innerView = [subviews objectAtIndex:0] ;
            NSArray* innerSubviews = [innerView subviews] ;
            didFindSSYSizeFixxerSubview = [self shallowlyGetFixedSize_p:&size
                                                            defaultSize:defaultSize
                                                           fromSubviews:innerSubviews] ;
        }
	}
    
	if (!didFindSSYSizeFixxerSubview) {
		// This will occur for the two spacers, NSToolbarFlexibleSpaceItem
	}
    
    return size ;
}

@end
