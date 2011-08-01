#import "SSYDictionaryDebugger.h"


@implementation SSYDebuggingMutableDictionary

- (id) init
{
	self = [super init];
	if (self != nil) {
		dic = [[NSMutableDictionary alloc] init] ;
		
	}
	return self;
}



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

- (NSString*)description {
	return [dic description] ;
}

- (id)forwardingTargetForSelector:(SEL)sel {
	return dic ;
}

- (void)dealloc {
	[dic release];

	[super dealloc];
}

@end
