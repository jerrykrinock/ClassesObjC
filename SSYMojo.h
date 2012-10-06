#import <Cocoa/Cocoa.h>
#import "SSYErrorHandler.h"


/*!
 @brief    A class for putting and fetching -- "managing" --  managed objects of
 a particular entity in a particular managed object context.

 @details   I wanted to make this a subclass of NSManagedObjectContext.  However,
 the documentation for NSManagedObjectContext says that "you are highly
 discouraged from subclassing" it.  So, what I did instead was to make this class
 be a wrapper around an managed object context which is an instance variable.
 I also implemented message forwarding of unknown messages to the moc instance variable.
 I'm not sure whether that message forwarding is necessary or not.
 */
@interface SSYMojo : NSObject {
	NSManagedObjectContext* m_managedObjectContext ;
	NSString* entityName ;
}

/*!
 @brief    ￼The built-in managed object context which the receiver will use.
 */
@property (retain) NSManagedObjectContext* managedObjectContext ;

/*!
 @brief    The name of the entity of the managed objects which the 
 receiver is expected to manage.
*/
@property (copy) NSString* entityName ;

/*!
 @brief    Designated Initializer for Mojo instances  ￼
 
 @details  managedObjectContext and entityName are required.  If either is nil, this
 method will return nil.
 @param    managedObjectContext  The managed object context into which objects
 will be managed.
 @param    entityName  The name of the entity of the objects which
 will be managed.
 */
- (id)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext_
						entityName:(NSString*)entityName_ ;


/*!
 @brief    Returns all objects in the receiver's managed object context
 satisfying given predicates, if any, compounded OR or AND.
 @param    subpredicates  The array of subpredicates to be compounded
 @param    type  Either NSAndPredicateType or NSOrPredicateType
 @param    error_p  Pointer to an NSError* object.  Upon return, if an
 error occurred in the underlying fetch request, and if this pointer is
 not NULL, it will point to an NSError object representing the problem.
 @result   An array of results, or an empty array if no results are found,
 or nil if an error occurs
 */
- (NSArray*)objectsWithSubpredicates:(NSArray*)subpredicates
								type:(NSCompoundPredicateType)type
							 error_p:(NSError**)error_p ;

/*!
 @brief    Gets all of the objects in the receiver's managed object context
 satisfying a given predicate, if any.
 
 @details  Pass predicate = nil to get all objects of the receiver's entity.
 @param    predicate  The predicate required of results, or nil.
 @param    error_p  Pointer to an NSError* object.  Upon return, if an
 error occurred in the underlying fetch request, and if this pointer is
 not NULL, it will point to an NSError object representing the problem.
 @result   An array of results, or an empty array if no results are found,
 or nil if an error occurs
 */
- (NSArray*)objectsWithPredicate:(NSPredicate*)predicate
						 error_p:(NSError**)error_p ;

/*!
 @brief    Same as -objectsWithPredicate, but only returns the first item found
 
 @details  Returns nil if no results are found
 */
- (NSManagedObject*)objectWithPredicate:(NSPredicate*)predicate
								error_p:(NSError**)error_p ;

/*!
 @brief    Returns all objects satisfying a predicate created "directly in code"
 @result   An array of results, or an empty array if no results are found,
 or nil if an error occurs
 */
- (NSArray*)objectsWithDirectPredicateLeftExpression:(NSExpression*)lhs
									 rightExpression:(NSExpression*)rhs
										operatorType:(NSPredicateOperatorType)operatorType
											 error_p:(NSError**)error_p ;

/*!
 @brief    Returns the first object satisfying a predicate created "directly in code"
 */
- (NSManagedObject*)objectWithDirectPredicateLeftExpression:(NSExpression*)lhs
											rightExpression:(NSExpression*)rhs
											   operatorType:(NSPredicateOperatorType)operatorType
													error_p:(NSError**)error_p ;

/*!
 @brief    Returns all objects of the receiver's entity in the receiver's
 managed object context.
 @result   An array of results, or an empty array if no results are found,
 or nil if an error occurs
 */
- (NSArray*)allObjectsError_p:(NSError**)error_p ;

/*!
 @brief    Returns all objects of the receiver's entity in the receiver's
 managed object context, displaying the error in an SSYAlert if any occurs.
 @result   An array of results, or an empty array if no results are found,
 or nil if an error occurs
 */
- (NSArray*)allObjects ;

/*!
 @brief    Inserts a new object with the receiver's entityName into the
 receiver's managed object context
 @result   The newly-inserted object
 */
- (NSManagedObject*)freshObject ;

/*!
 @brief    Returns the object from the receiver's managed object context
 that has a given object identifier.
*/
- (NSManagedObject*)objectWithID:(NSManagedObjectID*)objectID ;

/*!
 @brief    Inserts an object from the receiver's managed object context
 */
- (void)insertObject:(NSManagedObject*)object ;

/*!
 @brief    Deletes an object from the receiver's managed object context
*/
- (void)deleteObject:(NSManagedObject*)object ;

/*!
 @brief    Deletes all objects of the receiver's entity from the receiver's
 managed object context
 */
- (BOOL)deleteAllObjectsError_p:(NSError**)error_p ;

/*!
 @brief    Saves the receiver's managed object context
 
 @details  A wrapper around -[NSManagedObjectContext save:].
 Parameters and result are same.
 */
- (BOOL)save:(NSError**)error_p ;

/*!
 @brief    If the receiver's managed object context is backed by a 
 persistent store, deletes the store's file

 @details  If the receiver's managed object context is backed
 by more than one persistent store, deltes the file of the first
 store.
 @param    error_p  If the store could not be deleted, and if
 error_p is not NULL, *error_p is set to an error explaining the
 problem.
 @result   The URL of the store that was deleted, or nil if there
 was no persistent store or if the target store's file could not
 be deleted.
*/
- (NSURL*)deleteFileError_p:(NSError**)error_p ;

@end