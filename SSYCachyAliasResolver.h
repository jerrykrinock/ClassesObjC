#import <Cocoa/Cocoa.h>


/*!
 @brief    Provides a singleton which caches aliases it resolves
 for re-use, up to a given lifetime.
 
 @details  A wrapper around a wrapper around a tool which invokes
 the notoriously slow and blocking FSResolveAlias() function.
*/
@interface SSYCachyAliasResolver : NSObject {
	NSMutableDictionary* m_cache ;
}

+ (SSYCachyAliasResolver*)sharedResolver ;

/*!
 @brief    Resolves an alias to a path, blocking only up to a given
 timeout, caching the path for future invocations up to a given
 lifetime if desired, and if desired for performance reasons, will
 cache the result for later and/or return a cached result if available.

 @details  This method requires that an executable FileAliasWorker
 be available in the application's main bundle.
 @param    alias  The alias data to be resolved
 @param    useCache  YES if you will accept a cached result, which
 can be returned instantly.
 @param    timeout  In case useCache is NO, or if a cached result
 is not availble, the timeout for which this method will block
 @param    lifetime  The time interval for which the result, if
 resolved from scratch, will be cached for future invocations of
 this method
 @param    error_p  Pointer which will, upon return, if an error
 occurred and said pointer is not NULL, point to an NSError
 describing said error.
 @result   The resolved path, or nil if the path could not be
 resolved.
*/
- (NSString*)pathFromAlias:(NSData*)alias
				  useCache:(BOOL)useCache
				   timeout:(NSTimeInterval)timeout
				  lifetime:(NSTimeInterval)lifetime
				   error_p:(NSError**)error_p ;

@end