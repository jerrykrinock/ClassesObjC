#import <Foundation/Foundation.h>

/* This class is a "transformer" which can be used for creating a tree of
NSMutableDictionaries from a prototype tree of NSMutableDictionaries, where
the two trees have different formats; that is, different keys and sub-keys.
*/



@interface SSYTreeTransformer : NSObject
{
	SEL _reformatter;
	SEL _childrenInExtractor ;
	SEL _newParentMover ;
	id _contextObject ;
}

+ (SSYTreeTransformer*)treeTransformerWithReformatter:(SEL)reformatter
								 childrenInExtractor:(SEL)childrenInExtractor
									  newParentMover:(SEL)newParentMover
									   contextObject:(id)contextObject ;
/*
 reformatter must be an selector which, when sent to an instance of the
 input class, returns an instance of the output class, autoreleased,
 representing the a shallow copy of the receiver in the output class,
 or nil if the receiver cannot be transformed due to missing keys or
 other corruption.  If the receiver has children, the returned
 object should have no children, but shall accept children when
 newParentMover is executed with the return object as parameter.
 reformatter may optionally accept one argument.  There are thus two
 alternative prototypes:
	(id)reformat ;
	(id)reformatWithContext: ;

 childrenInExtractor must be a selector which, when sent to an object
 of the input class, will return an autoreleased NSArray of the
 receiver's children, or nil if no children.  Prototype:
 (NSArray*)children ;
 
 newParentMover must be selector which, when sent to an object of the
 output class, with a parameter equal to another object of the output
 class, will append the receiver to the children of the other object.
 Prototype:
 (void)moveToNewParent:(NSMutableDictionary*)newParent ;
 
 contextObject is an object that will be passed as an argument to the
 reformatter.  If reformatter does not have an argument, contextObject
 must be nil.  If reformatter does have an argument, contextObject must
 not be nil.
 */

+ (SSYTreeTransformer*)treeTransformerWithReformatter:(SEL)reformatter
								 childrenInExtractor:(SEL)childrenInExtractor
									  newParentMover:(SEL)newParentMover ;
/*
Same as previous method, specialized to the case of no reformatter argument */

- (id)deepTransformedCopyOf:(id)nodeIn ;
/* returns a copy which the invoking method must release */

@end
