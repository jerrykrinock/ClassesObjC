#import <Cocoa/Cocoa.h>

// Usually you don't like to import headers into headers, but in this case we want
// anyone importing this header to have access to the SSYPathObserverChangeFlags
#import "SSYPathObserver.h"

@interface SSYPathWaiter : NSObject {
	BOOL m_succeeded ;
}

/*!
 @brief    Blocks until a given path in the filesystem is changed
 in a given way.
 
 @details  "Deleted in the Unix sense" means that the vnode
 has been removed.  A file which has been trashed has not been
 deleted in the Unix sense.
 
 @param    watchFlags  An xor of one or more of the 
 SSYPathObserverChangeFlags defined in SSYPathObserverChangeFlags.h,
 which specify the type(s) of changes to be considered

 @result   YES if the path does not exist already, or if it was deleted
 before the timeout expired.
 */
- (BOOL)blockUntilWatchFlags:(uint32_t)watchFlags
						path:(NSString*)path
					 timeout:(NSTimeInterval)timeout ;

@end
