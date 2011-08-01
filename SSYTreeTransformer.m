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
														   newParentMover:(SEL)newParentMover
															contextObject:contextObject] ;
	return [x autorelease] ;
}

+ (SSYTreeTransformer*)treeTransformerWithReformatter:(SEL)reformatter
								 childrenInExtractor:(SEL)childrenInExtractor
									  newParentMover:(SEL)newParentMover {
	SSYTreeTransformer* x = [[SSYTreeTransformer alloc] initWithReformatter:reformatter
													  childrenInExtractor:childrenInExtractor
														   newParentMover:(SEL)newParentMover
															contextObject:nil] ;
	return [x autorelease] ;
}

- (id)deepTransformedCopyOf:(id)nodeIn {
	id nodeOut ;
	id contextObject = [self contextObject] ;
	
	nodeOut = [nodeIn performSelector:_reformatter
						   withObject:contextObject] ;
	// reformatter returns nodeOut as an autoreleased object
	// nodeOut is now the new parent.
	
	NSArray* childrenIn ;

	if ((childrenIn = [nodeIn performSelector:_childrenInExtractor])) {
		for (id childIn in childrenIn) {
			// Get next child out with recursion
			id nextChildOut ;
			if ((nextChildOut = [self deepTransformedCopyOf:childIn]))  // may be nil!
			{
				[nextChildOut performSelector:_newParentMover withObject:nodeOut] ;
				// Since the above will add nextChildOut to nodeOut's Children array, I can now release it. (I hope!!!)
				[nextChildOut release] ;
			}
		}
	}

	return [nodeOut retain] ; 
	// Since this method must return a "copy", but nodeOut was autoreleased, I retain it before returning
}

@end