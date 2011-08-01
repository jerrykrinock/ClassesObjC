#import "SSYLazyNotificationCenter.h"
#import "NSDictionary+KeyPaths.h"

// This is a singleton, but not a "true singletons", because
// I didn't bother to override
//    +allocWithZone:
//    -copyWithZone: 
//    -retain
//    -retainCount
//    -release
//    -autorelease
static SSYLazyNotificationCenter* defaultCenter = nil ;

NSString* const constSSYLazyNotificationCenterObserver = @"obsrvr" ;
NSString* const constSSYLazyNotificationSelectorName = @"selName" ;


@implementation SSYLazyNotificationCenter

+ (SSYLazyNotificationCenter*)defaultCenter {
    @synchronized(self) {
        if (!defaultCenter) {
            defaultCenter = [[self alloc] init] ; 
        }
    }
	
	// No autorelease.  This sticks around forever.
    return defaultCenter ;
}

/*
 observations is dictionary of arrays of dictionaries, as shown here:
 observations
 *   noteName1 (array)
 *      observation11 (dictionary) :(
 *          observer=observer11,
 *			selectorName=selectorName11
 *        )
 *      observation12 (dictionary) :(
 *          observer=observer12,
 *			selectorName=selectorName12
 *        )
 *   noteName2 (array)
 *      observation21 (dictionary) :(
 *          observer=observer21,
 *			selectorName=selectorName21
 *        )
 *      observation22 (dictionary) :(
 *          observer=observer22,
 *			selectorName=selectorName22
 *        )
 */

- (NSMutableDictionary*)observations {
	if (!m_observations) {
		m_observations = [[NSMutableDictionary alloc] init] ;
	}
	
	return m_observations ;
}

- (NSMutableDictionary*)fireTimers {
	if (!m_fireTimers) {
		m_fireTimers = [[NSMutableDictionary alloc] init] ;
	}
	
	return m_fireTimers ;
}

- (void)dealloc {
	[m_observations release] ;
	[m_fireTimers release] ;
	
	[super dealloc] ;
}


- (void)addObserver:(id)observer
		   selector:(SEL)selector
			   name:(NSString*)name {
	NSDictionary* observation = [NSDictionary dictionaryWithObjectsAndKeys:
								 observer, constSSYLazyNotificationCenterObserver,
								 NSStringFromSelector(selector), constSSYLazyNotificationSelectorName,
								 nil] ;
	[[self observations] addUniqueObject:observation
							 toArrayAtKey:name] ;
}

- (void)enqueueNotification:(NSNotification*)note
					  delay:(NSTimeInterval)delay {
	NSTimer* existingTimer = [[self fireTimers] objectForKey:[note name]] ;
	if (existingTimer) {
		// Modify the new timer to have the same fire date as the existing timer.
		delay = [[existingTimer fireDate] timeIntervalSinceNow] ;
		delay = MAX(delay, FLT_MIN) ;
		[existingTimer invalidate] ;
	}
	NSTimer* timer = [NSTimer scheduledTimerWithTimeInterval:delay
													  target:self
													selector:@selector(fire:)
													userInfo:note
													 repeats:NO] ;
	// Note that the following will replace the existing timer, if any.
	[[self fireTimers] setObject:timer
						  forKey:[note name]] ;
}

- (void)fire:(NSTimer*)timer {
	NSNotification* note = [timer userInfo] ;
	NSString* noteName = [note name] ;
	[[self fireTimers] removeObjectForKey:noteName] ;
	NSArray* observations = [[self observations] objectForKey:noteName] ;
	for (NSDictionary* observation in observations) {
		id observer = [observation objectForKey:constSSYLazyNotificationCenterObserver] ;
		SEL selector = NSSelectorFromString([observation objectForKey:constSSYLazyNotificationSelectorName]) ;
		[observer performSelector:selector
					   withObject:note] ;
	}
}

- (void)removeObserver:(id)observer {
	NSMutableDictionary* newObservations = [[NSMutableDictionary alloc] initWithCapacity:[[self observations] count]] ;
	for (NSString* name in [self observations]) {
		NSArray* array = [[self observations] objectForKey:name] ;
		NSMutableArray* workingArray = [array mutableCopy] ;
		for (NSDictionary* observation in array) {
			id aObserver = [observation objectForKey:constSSYLazyNotificationCenterObserver] ;
			if (aObserver == observer) {
				[workingArray removeObject:observation] ;
			}
		}
		NSArray* newArray = [workingArray copy] ;
		[workingArray release] ;
		[newObservations setObject:newArray
						forKey:name] ;
		[newArray release] ;
	}
	
	[[self observations] removeAllObjects] ;
	[[self observations] addEntriesFromDictionary:newObservations] ;
	[newObservations release] ;
}

@end