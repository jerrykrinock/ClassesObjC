#import <Cocoa/Cocoa.h>


@interface SSYPathWaiter : NSObject {
	BOOL m_succeeded ;
}

/*!
 @brief    Blocks until a given path is deleted in the Unix
 sense.
 
 @details  "Deleted in the Unix sense" means that the vnode
 has been removed.  A file which has been trashed has not been
 deleted in the Unix sense.

 @result   YES if the path does not exist already, or if it was deleted
 before the timeout expired.
 */
- (BOOL)blockUntilDeletedPath:(NSString*)path
					  timeout:(NSTimeInterval)timeout ;

@end
