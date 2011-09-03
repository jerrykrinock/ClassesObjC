#import "SSYDictionaryDebugger.h"

#ifdef SSY_DEBUGGING_MUTABLE_DICTIONARY_INCLUDED

@implementation SSYDebuggingMutableDictionary

- (id) init
{
	self = [super init];
	if (self != nil) {
		dic = [[NSMutableDictionary alloc] init] ;
		
	}
#if SSY_DEBUGGING_MUTABLE_DICTIONARY_LOG_MEMORY_MANAGEMENT
	NSLog(@"info %p has been initted", self) ;
#endif
	return self;
}

- (NSString*)description {
	return [dic description] ;
}

- (id)forwardingTargetForSelector:(SEL)sel {
	return dic ;
}

- (void)setValue:(id)value
 forUndefinedKey:key {
	[dic setValue:value
		   forKey:key] ;;
}

- (void)dealloc {
#if SSY_DEBUGGING_MUTABLE_DICTIONARY_LOG_MEMORY_MANAGEMENT
	NSLog(@"info %p is being deallocced", self) ;
#endif
	[dic release] ;
	
	[super dealloc] ;
}

#if SSY_DEBUGGING_MUTABLE_DICTIONARY_LOG_MEMORY_MANAGEMENT

- (id)retain {
	id x = [super retain] ;
	NSLog(@"info %p retained to %d by %@", self, [self retainCount], SSYDebugCaller()) ;
	return x ;
}

- (id)autorelease {
	id x = [super autorelease] ;
	NSLog(@"info %p autoreleased by %@", self, SSYDebugCaller()) ;
	return x ;
}

- (oneway void)release {
	NSInteger rc = [self retainCount] ;
	[super release] ;
	NSLog(@"info %p released fr %d by %@", self, rc, SSYDebugCaller()) ;
}

#endif


#if SSY_DEBUGGING_MUTABLE_DICTIONARY_LOG_CONTENTS_CHANGED

- (void)setValue:(id)value forKey:(NSString *)key {
	NSLog(@"12686-01 %s", __PRETTY_FUNCTION__) ;
	
	NSLog(@"     key=%@", key) ;
	NSLog(@"     value=%@", value) ;
	if (!value) {
		NSLog(@"An object is being removed!") ;
	}
	[dic setValue:value forKey:key] ;
}

- (void)removeObjectForKey:(id)aKey{
	NSLog(@"12686-02  %s", __PRETTY_FUNCTION__) ;
	NSLog(@"An object is being removed!") ;
	NSLog(@"     key=%@", aKey) ;
	[dic removeObjectForKey:aKey] ;
}

- (void)removeAllObjects{
	NSLog(@"12686-03 %s", __PRETTY_FUNCTION__) ;
	NSLog(@"An object is being removed!") ;
	[dic removeAllObjects] ;
}
- (void)setObject:(id)anObject forKey:(id)aKey{
	NSLog(@"12686-04 %s", __PRETTY_FUNCTION__) ;
	NSLog(@"     key=%@", aKey) ;
	NSLog(@"     value=%@", anObject) ;
	[dic setObject:anObject forKey:aKey] ;
}

#endif


@end

#endif