#import "SSYTreeTransformer.h"

@implementation SSYTreeTransformer

- (id)contextObject {
    return [[_contextObject retain] autorelease];
}

- (void)setContextObject:(id)value {
    if (_contextObject != value) {
        [_contextObject release];
        _contextObject = [value retain];
    }
}

- (id)initWithReformatter:(SEL)reformatter
	  childrenInExtractor:(SEL)childrenInExtractor
		   newParentMover:(SEL)newParentMover
			contextObject:(id)contextObject
{
    if((self=[super init]))
    {
		_reformatter = reformatter ;
		_childrenInExtractor = childrenInExtractor ;
    	_newParentMover = newParentMover ;
		[self setContextObject:contextObject] ;
    }
    return self;
}

- (void) dealloc {
	[_contextObject release] ;
	
	[super dealloc] ;
}


+ (SSYTreeTransformer*)treeTransformerWithReformatter:(SEL)reformatter
								 childrenInExtractor:(SEL)childrenInExtractor
									  newParentMover:(SEL)newParentMover
									   contextObject:(id)contextObject {
	SSYTreeTransformer* x = [[SSYTreeTransformer alloc] initWithReformatter:reformatter
													  childrenInExtractor:childrenInExtractor
#if MAC_OS_X_VERSION_MAX_ALLOWED > 1070
                                                             newParentMover:newParentMover
#else
                                                             newParentMover:(SEL)newParentMover
#endif
                                                              contextObject:contextObject] ;
	return [x autorelease] ;
}

+ (SSYTreeTransformer*)treeTransformerWithReformatter:(SEL)reformatter
								 childrenInExtractor:(SEL)childrenInExtractor
									  newParentMover:(SEL)newParentMover {
	SSYTreeTransformer* x = [[SSYTreeTransformer alloc] initWithReformatter:reformatter
													  childrenInExtractor:childrenInExtractor
#if MAC_OS_X_VERSION_MAX_ALLOWED > 1070
                                                             newParentMover:newParentMover
#else
                                                             newParentMover:(SEL)newParentMover
#endif															
                                                              contextObject:nil] ;
	return [x autorelease] ;
}

- (id)copyDeepTransformOf:(id)nodeIn {
	id nodeOut ;
	id contextObject = [self contextObject] ;
	
	nodeOut = [nodeIn performSelector:_reformatter
						   withObject:contextObject] ;
	// reformatter returns nodeOut as an autoreleased object
	// nodeOut is now the new parent.
	
	NSArray* childrenIn ;

    if ([nodeIn respondsToSelector:_childrenInExtractor]) {  // Defensive programming
        if ((childrenIn = [nodeIn performSelector:_childrenInExtractor])) {
            for (id childIn in childrenIn) {
                // Get next child out with recursion
                id nextChildOut = [self copyDeepTransformOf:childIn] ;
                // nextChildOut may be nil, in particular for Safari, because of iCloud, deleted
                // starks are not deleted before the actual export.  To delete them, we
                // temporarily set the stark's 'isDeletedThisIxport' flag bit, in
                // -[ExtoreSafari extoreRootsForExport], which causes
                // extoreItemForSafari:, or reformatter, and thus this method, to return nil.
                // I noted once that there are other cause(s) in BookMacster which can make
                // nextChildOut be nil at this point, but did not document them.
                if (nextChildOut) {
                    [nextChildOut performSelector:_newParentMover withObject:nodeOut] ;
                    // Since the above will add nextChildOut to nodeOut's Children array, I can now release it.
                    [nextChildOut release] ;
                }
            }
        }
    }

	return [nodeOut retain] ; 
	// Since this method must return a "copy", but nodeOut was autoreleased, I retain it before returning
}

@end