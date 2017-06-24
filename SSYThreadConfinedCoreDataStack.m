#import "SSYThreadConfinedCoreDataStack.h"
#import "NSBundle+MainApp.h"
#import "BSManagedDocument.h"

@implementation SSYThreadConfinedCoreDataStack

@synthesize managedObjectContext = m_managedObjectContext ;
@synthesize managedObjectModel = m_managedObjectModel;
@synthesize persistentStoreCoordinator = m_persistentStoreCoordinator;
@synthesize storeUrl = m_storeUrl ;

- (void)dealloc {
    [m_managedObjectContext release] ;
    [m_persistentStoreCoordinator release] ;
    [m_managedObjectModel release] ;
    [m_storeUrl release] ;
    
    [super dealloc] ;
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (!m_managedObjectModel) {
        NSArray* bundles = [NSArray arrayWithObject:[NSBundle mainAppBundle]] ;
        m_managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:bundles] ;
        [m_managedObjectModel retain] ;
    }

    return m_managedObjectModel ;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (!m_persistentStoreCoordinator) {
        NSError* error = nil;
        
        // Create the coordinator and store
        m_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]] ;
    
        NSURL* url = [self storeUrl];
        NSString* path = [url path];
        BOOL isDirectory;
        [[NSFileManager defaultManager] fileExistsAtPath:path
                                             isDirectory:&isDirectory];
        if (isDirectory) {
            /* It's a file package. */
            path = [path stringByAppendingPathComponent:[BSManagedDocument storeContentName]];
            path = [path stringByAppendingPathComponent:[BSManagedDocument persistentStoreName]];
            url = [NSURL fileURLWithPath:path];
        }


        error = nil ;
        if (![m_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                       configuration:nil
                                                                 URL:url
                                                             options:nil
                                                               error:&error]) {
            NSLog(@"Internal Error 285-0013 %@ %@", error, [error userInfo]) ;
        }
    }
    
    return m_persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
    if (!m_managedObjectContext) {
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        if (coordinator) {
            m_managedObjectContext = [[NSManagedObjectContext alloc] init] ;
            [m_managedObjectContext setPersistentStoreCoordinator:coordinator] ;
            [m_managedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy] ;
        }
        else {
            // Fail
            NSLog(@"Internal Error 292-4473 %@", [self storeUrl]) ;
        }
    }
    
    return m_managedObjectContext ;
}

- (id)initWithStoreUrl:(NSURL*)url {
    if (url) {
        self = [super init] ;
        if (self) {
            [self setStoreUrl:url] ;
        }
    }
    else {
        [self release] ;
        self = nil ;
    }

    return self ;
}

@end
