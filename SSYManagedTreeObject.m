#import "SSYManagedTreeObject.h"
#import "NSSet+SimpleMutations.h"
#import "NSArray+SortDescriptorsHelp.h"
#import "NSKeyedUnarchiver+CatchExceptions.h"
#import "NSError+SSYAdds.h"
#import "NSSet+Indexing.h"
#import "NSManagedObject+Attributes.h"
#import "NSObject+DoNil.h"

NSString* const constKeyChildren = @"children" ;
NSString* const constKeyIndex = @"index" ;
NSString* const constKeyParent = @"parent" ;
/*
 See note on DropboxFalseStart below
 // NodeId was going to be needed because, when adding a new bookmark
 // from one .bkmslf to another on a different Mac, they may have
 // different Core Data objectID, since Core Data does not allow objectID
 // to be set and insists on composing objectID on its own.  So I was
 // going to identify parent <-> child relationships, and possible other
 // stuff, using my own nodeId instead of the Core Data objectID.
 NSString* const constKeyNodeId = @"nodeId" ;

NSString* const SSYManagedObjectAttributesKey = @"at" ;
NSString* const SSYManagedObjectChildrenNodeIdsKey = @"ci" ;
NSString* const SSYManagedObjectParentNodeIdKey = @"pi" ;
*/

@interface SSYManagedTreeObject (CoreDataGeneratedPrimitiveAccessors)

/*
 These accessors are dynamically generated at runtime by Core Data.  They 
 must be declared in a category with no implementation. If declared in, for
 example, the subclass @interface, or in an anonymous category ("()"),
 you get compiler warnings that their implementations
 are missing.
 http://www.cocoabuilder.com/archive/message/cocoa/2008/8/10/215317
 */

- (NSMutableSet*)primitiveChildren;
- (void)setPrimitiveChildren:(NSMutableSet*)value;
- (void)addChildrenObject:(SSYManagedTreeObject *)value ;
- (void)removeChildrenObject:(SSYManagedTreeObject *)value ;
- (void)addChildren:(NSSet *)value ;
- (void)removeChildren:(NSSet *)value ;

- (void)setPrimitiveIndex:(NSNumber*)value ;

- (void)setPrimitiveParent:(SSYManagedTreeObject*)value ;

@end

@interface SSYManagedTreeObject ()

@property (retain) NSData* nodeId ;

@end

@implementation SSYManagedTreeObject

@dynamic children ;
@dynamic index ;
@dynamic parent ;
@dynamic nodeId ;

- (void)postWillSetNewChildren:(NSSet*)newValue {
	[self postWillSetNewValue:newValue
					   forKey:constKeyChildren] ;
}

- (void)setChildren:(NSSet *)value 
{    
	[self postWillSetNewChildren:value] ;
	
    [self willChangeValueForKey:constKeyChildren];
    [self setPrimitiveChildren:[NSMutableSet setWithSet:value]];
    [self didChangeValueForKey:constKeyChildren];
}

- (void)addChildrenObject:(SSYManagedTreeObject *)value 
{    
	[self postWillSetNewChildren:[[self children] setByAddingObject:value]] ;
	
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    
    [self willChangeValueForKey:constKeyChildren withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveChildren] addObject:value];
    [self didChangeValueForKey:constKeyChildren withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    
    [changedObjects release];
}

- (void)removeChildrenObject:(SSYManagedTreeObject *)value 
{
	[self postWillSetNewChildren:[[self children] setByRemovingObject:value]] ;
	
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    
    [self willChangeValueForKey:constKeyChildren withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveChildren] removeObject:value];
    [self didChangeValueForKey:constKeyChildren withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    
    [changedObjects release];
}

- (void)addChildren:(NSSet *)value 
{    
	[self postWillSetNewChildren:[[self children] setByAddingObjectsFromSet:value]] ;
	
    [self willChangeValueForKey:constKeyChildren withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveChildren] unionSet:value];
    [self didChangeValueForKey:constKeyChildren withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeChildren:(NSSet *)value 
{
	[self postWillSetNewChildren:[[self children] setByRemovingObjectsFromSet:value]] ;
	
    [self willChangeValueForKey:constKeyChildren withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveChildren] minusSet:value];
    [self didChangeValueForKey:constKeyChildren withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}

- (void)removeAllChildren {
	[self removeChildren:[self children]] ;
}

- (void)setIndex:(NSNumber*)newValue  {
	// In order to avoid registering undo and unnecessarily dirtying the dot,
	// we only do the overwrite if there was a substantive change.
	// (Note that current or new value can be nil.)
	if ([NSObject isEqualHandlesNilObject1:[self index]
									object2:newValue]) {
		return ;
	}

	[self postWillSetNewValue:newValue
					   forKey:constKeyIndex] ;
	[self willChangeValueForKey:constKeyIndex] ;
    [self setPrimitiveIndex:newValue] ;
    [self didChangeValueForKey:constKeyIndex] ;
}

- (int)indexValue {
	return [[self index] intValue] ;
}

- (void)setIndexValue:(NSInteger)index {
	[self setIndex:[NSNumber numberWithInt:index]] ;
}

- (NSArray*)childrenOrdered {
    return [[self children] arraySortedByKeyPath:constKeyIndex] ;
}

- (SSYManagedTreeObject*)childAtIndex:(int)index {
	SSYManagedTreeObject* child = nil ;
	for (SSYManagedTreeObject* aChild in [self children]) {
		if ([aChild indexValue] == index) {
			child = aChild ;
			break ;
		}
	}
	
	return child ;
}

- (int)numberOfChildren {
	return [[self children] count] ;
}

// This is required to trigger -[Bkmslf objectWillChangeNote:]
- (void)setParent:(SSYManagedTreeObject*)newValue  {
	[self postWillSetNewValue:newValue
					   forKey:constKeyParent] ;
	[self willChangeValueForKey:constKeyParent] ;
    [self setPrimitiveParent:newValue] ;
    [self didChangeValueForKey:constKeyParent] ;
	
}

/*
 DropboxFalseStart
 I was going to use this before I learned that Dropbox is smart enough to do
 partial syncs of files.  Now, it's not needed.
 
 - (NSData*)dataRepresentation {
	NSDictionary* attributes = [self attributesDictionaryWithNulls:YES] ;
	NSSet* childrenNodeIds = [[self children] valueForKey:constKeyNodeId] ;
	NSData* parentNodeId = [[self parent] nodeId] ;
	
	NSDictionary* representation = [NSDictionary dictionaryWithObjectsAndKeys:
									attributes, SSYManagedObjectAttributesKey,
									childrenNodeIds, SSYManagedObjectChildrenNodeIdsKey,
									parentNodeId, SSYManagedObjectParentNodeIdKey,
									nil] ;
	
	return [NSKeyedArchiver archivedDataWithRootObject:representation] ;
}

- (BOOL)extractFromDataRepresentation:(NSData*)dataRepresentation
						 attributes_p:(NSDictionary**)attributes_p
					   parentNodeId_p:(SSYManagedTreeObject**)parentNodeId_p
					childrenNodeIds_p:(NSSet**)childrenNodeIds_p
							  error_p:(NSError**)error_p {
	NSError* error = nil ;
	NSDictionary* dic = [NSKeyedUnarchiver unarchiveObjectSafelyWithData:dataRepresentation
																error_p:&error] ;
	if (!dic) {
		if (error_p) {
			*error_p = SSYMakeError(65108, @"Could not unarchive object") ;
			*error_p = [*error_p errorByAddingUnderlyingError:error] ;
		}
		
		return NO ;
	}
	
	if (attributes_p) {
		*attributes_p = [dic objectForKey:SSYManagedObjectAttributesKey] ;
	}
	
	if (childrenNodeIds_p) {
		*childrenNodeIds_p = [dic objectForKey:SSYManagedObjectChildrenNodeIdsKey] ;
	}	
	
	if (parentNodeId_p) {
		*parentNodeId_p = [dic objectForKey:SSYManagedObjectParentNodeIdKey] ;
	}
	
	return YES ;
}
*/

@end