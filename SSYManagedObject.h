#import <Cocoa/Cocoa.h>

// Public Notifications
extern NSString* const constNoteWillUpdateObject ;
extern NSString* const SSYManagedObjectWillFaultNotification ;

// Keys inside Notification UserInfo Dictionaries
extern NSString* const constKeySSYChangedKey ;
extern NSString* const constKeyNewValue ;


// From the fatally flawed "Class Observer" concept
//extern NSString* const constKeyObserver ;
//extern NSString* const constKeyObserverOptions ;
//extern NSString* const constKeyObserverContext ;

/*!
 @brief    Some stuff Apple left out.

 @details  It looks like this could be a category instead of a subclass.
 
 From Ben Trumbull on cocoa-dev
 
 http://www.cocoabuilder.com/archive/cocoa/194906-coredata-huge-memory-usage-is-this-right.html?q=refreshObject+%22retain+cycle%22#195186 
 
 We recommend an import use its own MOC, and simply set the undo
 manager on the MOC to nil.  Easier, better, less filling.
 
 The staleness interval has nothing to do with imports.  It affects
 the, well, staleness of cached data for faulting.
 
 It's insufficient to drain the autorelease pool every 1000
 iterations.  You need to actually save the MOC, then drain the pool.
 Until you save, the MOC needs to retain all the pending changes you've
 made to the inserted objects.  Losing changes just because somebody
 popped an autorelease pool would be bad.  This is documented in
 several places, including the programming guide and -
 setRetainsRegisteredObject:
 
 There is an additional issue that complicates matters greatly under
 the retain/release (not GC) memory model.  Managed objects with
 relationships nearly always create unreclaimable retain cycles.
 
 Example:
 
 Department <->> People
 
 Department has a relationship to many people, and each person has an
 inverse relationship to the department.  Since these objects retain
 each other, the retain game is over.  This is a fundamental limitation
 to retain counting.
 
 To help alleviate this, Core Data allows you to turn a managed object
 back into a fault.  You can turn a specific object back into a fault
 with -refreshObject:mergeChanges:NO (which shouldn't be called on a
 managed object with unsaved changes pending).  Or you can use the
 sledge hammer, and just -reset the whole context.  A big but not quite
 that big hammer would be to call -registeredObjects on the MOC you
 just saved, and then for (NSManagedObject* mo in registeredObjects)
 { [moc refreshObject:mo mergeChanges:NO] }  This is a bit like reset,
 but you can still re-use the managed objects themselves in the future.
 
 As for why can't Core Data break the retain cycles for the objects you
 no longer want (i.e. like -reset, but not everything), how would we
 know ?  We can't tell the difference between your UI/array controller/
 whatever retaining an object, and an inverse relationship retaining
 the object.  It's trivial enough for you to grab the -
 registeredObjects set, make a mutable copy, remove the objects you
 want to preserve, and refresh the rest.  And if you can't tell the
 difference between the objects you want to preserve and those you want
 to nuke, how could we ?
 
 If you have concrete ideas for an API that would make this easier,
 please file an enhancement request at bugreport.apple.com
 
 The only meaningful difference between -reset and -release on the MOC
 is whether or not you ever need to use that MOC object again.  And,
 now under GC, -reset is more immediate.
 
 It may occur to some to ask why turning the object back into a fault
 helps.  Faults represent futures for unrealized/unmaterialized pieces
 of a graph of connected objects.  They don't retain anything as they
 have no data, just an identity.  A managed object that's in use has
 data, and retains that data much in the same way any Cocoa object's
 standard setter methods might work.  The active pieces of the graph
 are wired down, and the periphery are faults.  Like a cloud.  If you
 turn enough of the center pieces of the cloud back into faults, you'll
 have multiple distinct clouds instead (which is usually better)
 
 MOC are not particularly expensive to create, so if you cache your
 PSC, you can use different MOCs for different working sets or distinct
 operations.
 
 I can import millions of records in a stable 3MB of memory without
 calling -reset.
 
 - Ben
*/
@interface SSYManagedObject : NSManagedObject {

}

+ (NSString*)entityNameForClass:(Class)class ;

+ (NSEntityDescription*)entityDescription ;

/*!
 @brief    Should be overridden by subclasses

 @details  Default implementation returns nil
 @result   A uniqueAttributeKey which will be used to validate inserts
*/
- (NSString*)uniqueAttributeKey ;

/*!
 @brief    Returns the owner of the receiver's managed object context, as registered with
 the SSYMOCManager singleton, or an object of kind NSPersistentDocument which
 owns the receiver's managed object context

 @details  See +[SSYMOCManager ownerOfManagedObjectContext:] for exact search algorithm
 and definition of "owner".  If the owner must be of a specific type or
 conform to a certain formal protocol, you can re-declare and override this
 method in subclasses.  The implementation simply returns super's owner.
 @result   The owner of the receiver
*/
- (id)owner ;

/*!
 @brief    Returns whether or not a retained managed object is
 available to receive messages

 @details  Credit for the idea of checking the objectID goes to
 David Riggle <riggle@mac.com>.  See cocoa-dev@lists.apple.com for
 20111021, subject line: Re: Core Data: Determine if managed object is deleted
*/
- (BOOL)isAvailable ;


/*!
 @brief    Returns the absolute string of the URI representation of the
 object's objectID, optionally graduating the objectID to be permanent
 first, or nil if a permanent URI was requested but an error occured
 when obtaining it

 @details  If permanent URI is graduated, this method also updates the file modification
 date of a given document, as required by Details in the documentation of 
 -[NSManagedObjectContext obtainPermanentIDsForObjects:error:].  If an
 error occurs when attempting to graduate the URI, this method logs the
 error.
 @param    makePermanent  If YES, and if the receiver's objectID is
 temporary, will try to graduate it to a permanent ID before returning
 the absolute string of its URI representation, and return nil if a
 permanent objectID cannot be obtained.
 @param    document  Document whose file modification date may need to be
 updated.  If the receiver is not the context of an NSPersistentDocument,
 pass nil.
*/
- (NSString*)objectUriMakePermanent:(BOOL)makePermanent
						   document:(NSPersistentDocument*)document ;

/*!
 @brief    Replaces the objects in the to-many relationship for a given
 key with a new set of objects, the elements of a given array, and sets
 the 'index' value of each object equal to its position in the array.

 @details  All changes are made using KVO-compliant methods, in
 particular -mutableSetValueForKey.
 
 If, for example, the receiver has a to-many relationship to a set foos,
 of objects that have an 'index' property, and you need to implement a
 KVC-compliant array property foosOrdered, this method can be used in
 the implementation setFoosOrdered:.&nbsp; Actually, it does everything
 so that your implementation simply invokes this method.&nbsp; Tip:
 Your getter's implementation is one line also:
 [[self foos] arraySortedByKeyPath:'index'] ;
 
 @param    array  An array of objects that each conform to the
 SSYIndexee protocol (i.e., have an 'index' property)
 @param    setKey  The receiver's key to a to-many relationship, which
 ordinarily is used to access the set of objects in the relationship.
*/
- (void)setIndexedSetWithArray:(NSArray*)array
					 forSetKey:(NSString*)setKey ;

/*!
 @brief    Posts a constNoteWillUpdateObject notification.

 @details  This is a workaround for Apple Bug 6624874, using Solution 2.
 
 Solution 2.  Use Custom Setters.  For each key/value in each object that
 is to be observed, implement a custom setter, and in each such custom setter
 post a (regular, as in NSNotificationCenter) notification of the value change.
 This is not too bad with attributes, because there is only one setter per
 attribute.  But for to-many relations you need to override the four
 (or is it five) set mutator methods in order to cover all the possible
 ways in which the relationship may be changed.&nbsp; 
 What if more mutator methods are added in some future version of Mac OS?
 This requires much code and seems quite fragile.
 
 In your custom setter, you should invoke this method <i>before</i>
 actually changing the value (with willChangeValueForKey:, setPrimitiveXXXX:,
 didChangeValueForKey:).&nbsp;  This is so that the observer method
 receiving the notification can still send [object key] and get the
 <i>old</i> value, for comparison with the new value that you pass as a
 parameter here.
 
 See header file for custom accessor templates.
 
 @param    value  The new value to which key will be changed.
*/
- (void)postWillSetNewValue:(id)value
					 forKey:(NSString*)key ;

- (void)breakRetainCycles ;

- (NSUInteger)countOfNonNilValues ;


/*!
 @brief    A hash representing all relevant current property values of
 the receiver

 @details  The default implementation considers all attribute values to
 be relevant, and excludes all relationships.  Subclasses may override
 to exclude some attributes, or include some relationships, as desired. 
 
 I don't use this implementation in BookMacster any more.  Instead, I have
 tweaked implementations in two subclasses.
 */
- (uint32_t)valuesHash ;

/*!
 @brief    Useful for debugging
 */
- (void)logChangesForAllManagedObjectsInSameContext ;

@end

#if 0
/******* ACCESSOR TEMPLATES *******/

NSString* constKeyBozo = @"bozo" ;

@interface Whatever (CoreDataGeneratedAccessors)

- (void)setPrimitiveBozo:(Bype)value ;


@end

******* Setter for a To-Many Property *************************
******* Replace 'Bozo' (5) and 'Bype' (1) *********************

- (void)setBozo:(Bype)newValue  {
	[self postWillSetNewValue:newValue
					   forKey:constKeyBozo] ;
	[self willChangeValueForKey:constKeyBozo] ;
    [self setPrimitiveBozo:newValue] ;
    [self didChangeValueForKey:constKeyBozo] ;
}

******* Setters for a To-Many Property ************************
******* Replace 'Bozos' (27), 'bozos' (4) and 'Bype' (2) ******

- (void)postWillSetNewBozos:(NSSet*)newValue {
	[self postWillSetNewValue:newValue
					   forKey:constKeyBozos] ;
}

- (void)setBozos:(NSSet*)value {    
	[self postWillSetNewBozos:value] ;
	
    [self willChangeValueForKey:constKeyBozos];
    [self setPrimitiveBozos:[NSMutableSet setWithSet:value]];
    [self didChangeValueForKey:constKeyBozos];
}

- (void)addBozosObject:(Bype*)value {    
	[self postWillSetNewBozos:[[self bozos] setByAddingObject:value]] ;
	
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    
    [self willChangeValueForKey:constKeyBozos withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveBozos] addObject:value];
    [self didChangeValueForKey:constKeyBozos withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    
    [changedObjects release];
}

- (void)removeBozosObject:(Bype*)value {
	[self postWillSetNewBozos:[[self bozos] setByRemovingObject:value]] ;
	
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    
    [self willChangeValueForKey:constKeyBozos withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveBozos] removeObject:value];
    [self didChangeValueForKey:constKeyBozos withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    
    [changedObjects release];
}

- (void)addBozos:(NSSet*)value {    
	[self postWillSetNewBozos:[[self bozos] setByAddingObjectsFromSet:value]] ;
	
    [self willChangeValueForKey:constKeyBozos withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveBozos] unionSet:value];
    [self didChangeValueForKey:constKeyBozos withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeBozos:(NSSet *)value {
	[self postWillSetNewBozos:[[self bozos] setByRemovingObjectsFromSet:value]] ;
	
    [self willChangeValueForKey:constKeyBozos withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveBozos] minusSet:value];
    [self didChangeValueForKey:constKeyBozos withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}

/******* GREP REPLACEMENT PATTERNS FOR BBEDIT *******/

// Search Pattern:
// Replace a list of types and attributes that looks like this:
Type1 AttributeName1 attributeName1
Type2 AttributeName2 attributeName2
etc.

// Replacement pattern to make string constants:
NSString* constKeyBozo = @"\3" ;

// Replacement pattern to make primitive accessors for to-one:
- (\1)primitive\2 ;\r- (void)setPrimitive\2:(\1)value ;\r

// Replacement pattern to make primitive accessors for to-many:
- (NSMutableSet*)primitive\2 ;\r- (void)setPrimitive\2:(NSMutableSet*)value ;\r

// Replacement pattern to make to-one setter:
- (void)set\2:(\1)value {\r\t[self postWillSetNewValue:value\r\t\t\t\t\t   forKey:constKey\2] ;\r    [self willChangeValueForKey:constKey\2] ;\r    [self setPrimitive\2:value];\r    [self didChangeValueForKey:constKey\2] ;\r}\r\r

// Replacement pattern to make to-many setters:
//   (Note that this pattern has two & which are escaped to \&

- (void)postWillSetNew\2:(NSSet*)newValue {
	[self postWillSetNewValue:newValue
					   forKey:constKey\2] ;
}

- (void)set\2:(NSSet*)value {    
	[self postWillSetNew\2:value] ;
	
    [self willChangeValueForKey:constKey\2];
    [self setPrimitive\2:[NSMutableSet setWithSet:value]];
    [self didChangeValueForKey:constKey\2];
}

- (void)add\2Object:(\1)value {    
	[self postWillSetNew\2:[[self \3] setByAddingObject:value]] ;
	
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:\&value count:1];
    
    [self willChangeValueForKey:constKey\2 withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitive\2] addObject:value];
    [self didChangeValueForKey:constKey\2 withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    
    [changedObjects release];
}

- (void)remove\2Object:(\1)value {
	[self postWillSetNew\2:[[self \3] setByRemovingObject:value]] ;
	
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:\&value count:1];
    
    [self willChangeValueForKey:constKey\2 withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitive\2] removeObject:value];
    [self didChangeValueForKey:constKey\2 withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    
    [changedObjects release];
}

- (void)add\2:(NSSet*)value {    
	[self postWillSetNew\2:[[self \3] setByAddingObjectsFromSet:value]] ;
	
    [self willChangeValueForKey:constKey\2 withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitive\2] unionSet:value];
    [self didChangeValueForKey:constKey\2 withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)remove\2:(NSSet *)value {
	[self postWillSetNew\2:[[self \3] setByRemovingObjectsFromSet:value]] ;
	
    [self willChangeValueForKey:constKey\2 withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitive\2] minusSet:value];
    [self didChangeValueForKey:constKey\2 withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}

#endif
