#import <Foundation/Foundation.h>

@interface SSYThreadConfinedCoreDataStack : NSObject {
    NSManagedObjectContext* m_managedObjectContext ;
    NSPersistentStoreCoordinator* m_persistentStoreCoordinator ;
    NSManagedObjectModel* m_managedObjectModel ;
    NSURL* m_storeUrl ;
}

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext ;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel ;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator ;
@property (strong, nonatomic) NSURL *storeUrl ;

- (id)initWithStoreUrl:(NSURL*)url ;

@end
