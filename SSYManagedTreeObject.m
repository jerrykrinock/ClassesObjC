#import "SSYManagedTreeObject.h"
#import "NSSet+SimpleMutations.h"
#import "NSSet+Indexing.h"
#import "NSObject+DoNil.h"

NSString* const constKeyChildren = @"children" ;
NSString* const constKeyParent = @"parent" ;
/*
 See note on DropboxFalseStart below
 // NodeId was going to be needed because, when adding a new bookmark
 // from one .bkmxDoc to another on a different Mac, they may have
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

- (void)forgetCachedChildrenOrdered {
    // Children may be changed
    [m_cachedChildrenOrdered release] ;
    m_cachedChildrenOrdered = nil ;
}

- (void)deeplyForgetCachedChildrenOrdered {
    [self forgetCachedChildrenOrdered] ;
    
    // Call this method recursively to perform selector on each of this
    // object's children's...children
    // Notice that we invoke *children* not *childrenOrdered* since the latter is
    // cached, and presumably the cache is invalid, because we are being
    // invoked to wipe it.
    NSSet* children = [self children] ;
    for (SSYManagedTreeObject* child in children) {
        [child deeplyForgetCachedChildrenOrdered] ;
    }
}

- (void)didTurnIntoFault {
	/* cocoa-dev@lists.apple.com
     
	 On 20090812 20:41, Jerry Krinock said:
	 
	 Now I understand that if nilling an instance variable after releasing
	 it is done in -dealloc, it is papering over other memory management
	 problems and is therefore bad programming practice.  But I believe
	 that this practice is OK in -didTurnIntoFault because, particularly
	 when Undo is involved, -didTurnIntoFault may be invoked more than once
	 on an object.  Therefore nilling after releasing in -didTurnIntoFault
	 is recommended.
	 
	 On 20090812 22:06, Sean McBride said
	 
	 I made that discovery a few months back too, and I agree with your
	 reasoning and conclusions.  I also asked an Apple guy at WWDC and he
	 concurred too.
	 */
	
    [self forgetCachedChildrenOrdered] ;
	
	[super didTurnIntoFault] ;
}

- (void)handleWillSetNewChildren:(NSSet*)newValue {
	[self postWillSetNewValue:newValue
					   forKey:constKeyChildren] ;
    
    [self forgetCachedChildrenOrdered] ;
}

/* Testing indicates that this method can be invoked, and children can by
 mutated, without invoking -setChildren: or any other setter.  In other words,
 this method seems to be an independent value-changer.  Therefore, the following
 override is necessary.  It was added in BookMacster 1.12.7. */
- (NSMutableSet*)mutableSetValueForKey:(NSString *)key {
    if ([key isEqualToString:constKeyChildren]) {
        [self forgetCachedChildrenOrdered];
    }
    
    return [super mutableSetValueForKey:key] ;
}


- (void)setChildren:(NSSet *)value
{    
	[self handleWillSetNewChildren:value] ;
	
    [self willChangeValueForKey:constKeyChildren];
    [self setPrimitiveChildren:[NSMutableSet setWithSet:value]];
    [self didChangeValueForKey:constKeyChildren];
}

- (void)addChildrenObject:(SSYManagedTreeObject *)value 
{    
	[self handleWillSetNewChildren:[[self children] setByAddingObject:value]] ;
	
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    
    [self willChangeValueForKey:constKeyChildren withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveChildren] addObject:value];
    [self didChangeValueForKey:constKeyChildren withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    
    [changedObjects release];
}

- (void)removeChildrenObject:(SSYManagedTreeObject *)value 
{
	[self handleWillSetNewChildren:[[self children] setByRemovingObject:value]] ;
	
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    
    [self willChangeValueForKey:constKeyChildren withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveChildren] removeObject:value];
    [self didChangeValueForKey:constKeyChildren withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    
    [changedObjects release];
}

- (void)addChildren:(NSSet *)value 
{    
	[self handleWillSetNewChildren:[[self children] setByAddingObjectsFromSet:value]] ;
	
    [self willChangeValueForKey:constKeyChildren withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveChildren] unionSet:value];
    [self didChangeValueForKey:constKeyChildren withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeChildren:(NSSet *)value 
{
	[self handleWillSetNewChildren:[[self children] setByRemovingObjectsFromSet:value]] ;
	
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

- (NSInteger)indexValue {
	return [[self index] integerValue] ;
}

- (void)setIndexValue:(NSInteger)index {
	[self setIndex:[NSNumber numberWithInteger:index]] ;
}

- (NSArray*)childrenOrdered {
    /* Prior to BookMacster 1.12.7, this implementation was only one line,
    return [[self children] arraySortedByKeyPath:constKeyIndex] ;
     The m_cachedChildrenOrdered ivar was added to improve performance in
     BookMacster 1.12.7, particularly when invoked by
     -[StarkContainersHierarchicalMenu menu:updateItem:atIndex:shouldCancel:]
     to update the the Doxtus menu in the Dock menu or status menulet, when
     an open document contained a folder with thousands of children.  Note that,
     even if the preference "Show Status in Menu Bar" was switched off, the
     Dock menu would still be active, and the system would pre-populate this
     menu typically 10 seconds after the application was launched and such a
     document was opened.  This would cause inexplicable beachballing for
     tens of seconds. */

    if (!m_cachedChildrenOrdered) {
        m_cachedChildrenOrdered = [[[self children] arraySortedByKeyPath:constKeyIndex] retain] ;
    }
    
    // arrayWithArray was added in BookMacster 1.12.8 to fix crashes which
    // were occuring in various methods when m_cachedChildrenOrdered was
    // changed.  I also removed -arrayWithArray in several methods where the
    // return of this method is used, and crashes were noted, because it is
    // no longer necessary now that this method is returning a copy.  In other
    // words, I removed the ad-hoc fixes and replaced them with the
    // following global, root-cause fix.
    return [NSArray arrayWithArray:m_cachedChildrenOrdered] ;
}


/* Performance of this method is not good; it takes too long when invoked by
 [Stark mergeFoldersWithInfo:].  I tried to make it better by using
 -[Stark sortedChildren] instead of iterating through -[Stark children].
 But that made it about 8x slower. */
- (SSYManagedTreeObject*)childAtIndex:(NSInteger)index {
    SSYManagedTreeObject* iteratedChild = nil ;
    for (SSYManagedTreeObject* aChild in [self children]) {
		if ([aChild indexValue] == index) {
			iteratedChild = aChild ;
			break ;
		}
	}
    
    return iteratedChild ;
}

- (NSInteger)numberOfChildren {
	NSInteger count = [[self children] count] ;

	return count ;
}

// This is required to trigger -[BkmxDoc objectWillChangeNote:]
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