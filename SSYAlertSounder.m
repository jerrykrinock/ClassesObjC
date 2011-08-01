#import "SSYAlertSounder.h"
#import <AudioToolbox/AudioServices.h>

static SSYAlertSounder* static_sharedSounder = nil ;

@interface SSYAlertSounder ()

@end

@implementation SSYAlertSounder

- (id)init {
	self = [super init] ;
	if (self) {
		m_soundIds = [[NSMutableDictionary alloc] init] ;
	}
	
	return self ;
}

- (void)dealloc {
	for (NSNumber* soundId in [m_soundIds allValues]) {
		AudioServicesDisposeSystemSoundID([soundId longValue]) ;
	}
	
	[m_soundIds release] ;
	
	[super dealloc] ;
}

- (NSMutableDictionary*)soundIds {
	return m_soundIds ;
}


+ (SSYAlertSounder*)sharedSounder {
	@synchronized(self) {
        if (!static_sharedSounder) {
            static_sharedSounder = [[self alloc] init] ;
        }
    }
	
	// No autorelease.  This sticks around forever.
    return static_sharedSounder ;
}

- (void)playAlertSoundNamed:(NSString*)name {
	SystemSoundID soundId = [[[self soundIds] objectForKey:name] longValue] ;
	// Used -longValue because SystemSoundID is a UInt32
	
	if (!soundId) {
		NSString* path = [[NSBundle mainBundle] pathForResource:name
														 ofType:@"aiff"] ;
		if (!path) {
			path = @"/System/Library/Sounds" ;
			path = [path stringByAppendingPathComponent:[name stringByAppendingPathExtension:@"aiff"]] ;
		}
		CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:path] ;
		
		if (url) {
			OSStatus err ;
			err = AudioServicesCreateSystemSoundID(url, &soundId) ;
			
			if (err) {
				soundId = 0 ;
			}
			else {
				[[self soundIds] setObject:[NSNumber numberWithLong:soundId]
									  forKey:name] ;
			}
		}
		
		else {
			NSBeep() ;
		}
	}

	if (soundId) {
		AudioServicesPlayAlertSound(soundId) ;
	}
}

@end