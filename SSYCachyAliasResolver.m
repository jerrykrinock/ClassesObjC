#import "SSYCachyAliasResolver.h"
#import "NSData+FileAlias.h"

static SSYCachyAliasResolver* sharedResolver = nil ;


@interface SSYCachyAliasResolver ()

@property (retain, readonly) NSMutableDictionary* cache ;

@end


@implementation SSYCachyAliasResolver

- (void)dealloc {
	[m_cache release] ;
	
	[super dealloc] ;
}

- (NSMutableDictionary*)cache {
	NSMutableDictionary* cache ;
	@synchronized(self) {
		if (!m_cache) {
			m_cache = [[NSMutableDictionary alloc] init] ;
		}

		cache = [[m_cache retain] autorelease] ;
	}
	
	return cache ;
}

+ (SSYCachyAliasResolver*)sharedResolver {
	@synchronized(self) {
        if (!sharedResolver) {
            sharedResolver = [[self alloc] init] ;
        }
    }
	
	// No autorelease.  This sticks around forever.
    return sharedResolver ;
}

- (NSString*)pathFromAlias:(NSData*)alias
				  useCache:(BOOL)useCache
				   timeout:(NSTimeInterval)timeout
				  lifetime:(NSTimeInterval)lifetime
				   error_p:(NSError**)error_p {
	if (!alias) {
		return nil ;
	}
	
	id path = nil ;
	NSNumber* key = nil ;
	BOOL alreadyInCache = NO ;
	// First, try to get from cache if allowed
	if (useCache) {
		NSUInteger hash = [alias hash] ;
		key = [NSNumber numberWithInteger:hash] ; 
		path = [[self cache] objectForKey:key] ;
		alreadyInCache = (path != nil) ;
	}
	
	// If not found in cache, try to resolve alias
	if (!path) {
		path = [alias pathFromAliasRecordWithTimeout:timeout
											 error_p:error_p] ;
	}
	
	// If nothing in cache and could not resolve alias, set to a Null
	if (!path) {
		path = [NSNull null] ;
	}

	// Cache the result
	if (!alreadyInCache && (lifetime > 0.0)) {
		if (!key) {
			NSUInteger hash = [alias hash] ;
			key = [NSNumber numberWithInteger:hash] ; 
		}
		
		[[self cache] setObject:path
						 forKey:key] ;

		[NSTimer scheduledTimerWithTimeInterval:lifetime
										 target:self
									   selector:@selector(clearCachedPath:)
									   userInfo:key
										repeats:NO] ;
	}
	
	if ([path isKindOfClass:[NSNull class]]) {
		path = nil ;
	}
	
	return path ;
}

- (void)clearCachedPath:(NSTimer*)timer {
	NSNumber* key = [timer userInfo] ;
	[[self cache] removeObjectForKey:key] ;
}

@end