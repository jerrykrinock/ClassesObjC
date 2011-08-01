//
//  MAKVONotificationCenter.m
//  MAKVONotificationCenter
//
//  Created by Michael Ash on 10/15/08.
//

#import "MAKVONotificationCenter.h"

#import <libkern/OSAtomic.h>
#import <objc/message.h>


@interface MAKVObservation : NSObject
{
	id			_observer;
	SEL			_selector;
	id			_userInfo;
	
	id			_target;
	NSString*	_keyPath;
}

- (id)initWithObserver:(id)observer object:(id)target keyPath:(NSString *)keyPath selector:(SEL)selector userInfo: (id)userInfo options: (NSKeyValueObservingOptions)options;
- (void)deregister;

@end

@implementation MAKVObservation

static char MAKVONotificationMagicContext;

- (id)initWithObserver:(id)observer object:(id)target keyPath:(NSString *)keyPath selector:(SEL)selector userInfo: (id)userInfo options: (NSKeyValueObservingOptions)options
{
	if((self = [self init]))
	{
		_observer = observer;
		_selector = selector;
		_userInfo = [userInfo retain];
		
		_target = target;
		_keyPath = [keyPath retain];
		
		[target addObserver:self
				 forKeyPath:keyPath
					options:options
					context:&MAKVONotificationMagicContext];
	}
	return self;
}

- (id)observer {
	return _observer;
}

- (id)target {
	return _target;
}

- (NSString*)keyPath {
	return _keyPath;
}

- (SEL)selector {
	return _selector;
}

- (void)dealloc
{
	[_userInfo release];
	[_keyPath release];
	[super dealloc];
}

- (NSString*)description {
	return [NSString stringWithFormat:
			@"<%@ %p ivars:\n   keyPath: %@\n   observer: %@ %p\n   selector: %@\n   target: %@ %p\n   userInfo: %@",
			[self class],
			self,
			_keyPath,
			[_observer class],
			_observer,
			NSStringFromSelector(_selector),
			[_target class],
			_target,
			_userInfo] ;
}
	

#pragma mark -

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(context == &MAKVONotificationMagicContext)
	{
		// we only ever sign up for one notification per object, so if we got here
		// then we *know* that the key path and object are what we want
		((void (*)(id, SEL, NSString *, id, NSDictionary *, id))objc_msgSend)(_observer, _selector, keyPath, object, change, _userInfo);
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)deregister
{
	[_target removeObserver:self forKeyPath:_keyPath];
}

@end


@implementation MAKVONotificationCenter

+ (id)defaultCenter
{
	static MAKVONotificationCenter *center = nil;
	if(!center)
	{
		// Do a bit of clever atomic setting to make this thread safe.
		// If two threads try to set simultaneously, one will fail
		// and the other will set things up so that the failing thread
		// gets the shared center...
		
		MAKVONotificationCenter *newCenter = [[self alloc] init];
		// objc_atomicCompareAndSwapGlobalBarrier() is not documented.  We
		// assume it behaves as OSAtomicCompareAndSwapPtrBarrier(), with the
		// same signature.  The first argument, 'predicate', is interpreted
		// to the the "pre-existing" value or '__oldValue' of
		// OSAtomicCompareAndSwapPtrBarrier().
		// In our usage, either method supposedly compares center to nil,
		//    if center is nil, sets center to newCenter and returns true
		//       Note that this whole code block is if(!center).
		//       This is thus the normal behavior when no thread race occurs
		//    if center is not nil, does nothing and returns false
		//       This will happen if another thread snuck in and set it.
		// Mike's original line, does not work with garbage collection.
		//   if(!OSAtomicCompareAndSwapPtrBarrier(nil, newCenter, (void *)&center)) {
		// See Brian Webster's first comment in http://www.mikeash.com/?page=pyblog/key-value-observing-done-right.html
		// Patched line:
		if(!objc_atomicCompareAndSwapGlobalBarrier(nil, newCenter, &center)) {
			// Thread race has occurred and we lost
			// center has previously been set to newCenter by another thread
			[newCenter release];
		}
	}
	return center;
}

- (id)init
{
	if((self = [super init]))
	{
		observations = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[observations release];
	[super dealloc];
}

#pragma mark -

- (id)_dictionaryKeyForObserver:(id)observer object:(id)target keyPath:(NSString *)keyPath selector:(SEL)selector
{
	return [NSString stringWithFormat:@"%p:%p:%@:%p", observer, target, keyPath, selector];
}

- (id)_dictionaryKeyForObservation:(MAKVObservation*)observation
{
	return [self _dictionaryKeyForObserver:[observation observer] object:[observation target] keyPath:[observation keyPath] selector:[observation selector]];
}

- (id)addObserver:(id)observer object:(id)target keyPath:(NSString *)keyPath selector:(SEL)selector userInfo: (id)userInfo options: (NSKeyValueObservingOptions)options
{
	MAKVObservation *observation = nil;
	id key = [self _dictionaryKeyForObserver:observer object:target keyPath:keyPath selector:selector];
	@synchronized(self)
	{
		id oldObservation = [observations objectForKey:key];
		if (!oldObservation) {
			observation = [[MAKVObservation alloc] initWithObserver:observer object:target keyPath:keyPath selector:selector userInfo:userInfo options:options];
			[observations setObject:observation forKey:key];
		}
	}
	return [observation autorelease];
}

- (void)removeObservation:(id)observation
{
	@synchronized(self)
	{
		[observation retain];
		[observations removeObjectForKey:[self _dictionaryKeyForObservation:observation]];
	}
	[(MAKVObservation*)observation deregister];
	[observation release];
}

- (void)removeObserver:(id)observer {
	{
		NSString* prefix = [NSString stringWithFormat:@"%p:", observer] ;
		NSMutableArray* keysToRemove = [[NSMutableArray alloc] init] ;
		@synchronized(self)
		{
			// I guess we're still supporting Mac OS X 10.4?...
			// Geez, I forgot how to do this...
			NSEnumerator* e = [observations keyEnumerator];
			NSString* key ;
			while ((key = [e nextObject])) {
				if ([key hasPrefix:prefix]) {
					[keysToRemove addObject:key];
				}
			}
			
			e = [keysToRemove objectEnumerator] ;
			while ((key = [e nextObject])) {
				MAKVObservation* observation = [observations objectForKey:key];
				[observation retain];
				[observations removeObjectForKey:[self _dictionaryKeyForObservation:observation]];
				[observation deregister];
				[observation release];
			}
		}
		[keysToRemove release] ;
	}
}

- (void)removeObserver:(id)observer object:(id)target keyPath:(NSString *)keyPath selector:(SEL)selector
{
	id key = [self _dictionaryKeyForObserver:observer object:target keyPath:keyPath selector:selector];
	@synchronized(self)
	{
		MAKVObservation *observation = [observations objectForKey:key];
		[self removeObservation:observation];
	}
}


@end

@implementation NSObject (MAKVONotification)

- (id)addObserver:(id)observer forKeyPath:(NSString *)keyPath selector:(SEL)selector userInfo:(id)userInfo options:(NSKeyValueObservingOptions)options
{
	return [[MAKVONotificationCenter defaultCenter] addObserver:observer object:self keyPath:keyPath selector:selector userInfo:userInfo options:options];
}

- (void)removeObserver:(id)observer keyPath:(NSString *)keyPath selector:(SEL)selector
{
	[[MAKVONotificationCenter defaultCenter] removeObserver:observer object:self keyPath:keyPath selector:selector];
}

@end