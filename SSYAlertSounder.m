#import "SSYAlertSounder.h"
#import <AudioToolbox/AudioServices.h>
#import "NSBundle+MainApp.h"
#import "SSY_ARC_OR_NO_ARC.h"


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
        AudioServicesDisposeSystemSoundID((unsigned int)[soundId longValue]) ;
    }
    
#if NO_ARC
    [m_soundIds release] ;
    
    [super dealloc] ;
#endif
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

- (SystemSoundID)soundIdForPath:(NSString*)path
                     rememberAs:(NSString*)name {
    SystemSoundID soundId = 0 ;
    
    if (path) {
        CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path] ;
        if (url) {
            OSStatus err ;
            err = AudioServicesCreateSystemSoundID(url, &soundId) ;
            
            if (err) {
                // This will happen if file was not found.
                soundId = 0 ;
            }
            else {
                [[self soundIds] setObject:[NSNumber numberWithLong:soundId]
                                    forKey:name] ;
            }
        }
    }
    
    return soundId ;
}

- (NSArray*)availableSoundsSorted {
    NSString* const type = @"aiff" ;
    NSMutableArray* paths = [[NSMutableArray alloc] init] ;
    NSString* path ;
    NSArray* morePaths ;
    
    morePaths = [[NSBundle mainAppBundle] pathsForResourcesOfType:type
                                                      inDirectory:nil] ;
    [paths addObjectsFromArray:morePaths] ;
    
    path = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Sounds"] ;
    morePaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path
                                                                    error:NULL] ;
    [paths addObjectsFromArray:morePaths] ;
    
    path = @"/System/Library/Sounds" ;
    morePaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path
                                                                    error:NULL] ;
    [paths addObjectsFromArray:morePaths] ;
    
    NSMutableArray* names = [[NSMutableArray alloc] init] ;
    for (NSString* path in paths) {
        NSString* name = [[path lastPathComponent] stringByDeletingPathExtension] ;
        if ([[path pathExtension] isEqualToString:type]) {
            [names addObject:name] ;
        }
    }
    
    [names sortUsingComparator:^NSComparisonResult(NSString* s1, NSString* s2) {
        return [s1 localizedCaseInsensitiveCompare:s2] ;
    }] ;
    
    NSArray* answer = [names copy] ;
    
#if NO_ARC
    [paths release] ;
    [names release] ;
    [answer autorelease] ;
#endif
    
    return answer ;
}


- (void)playAlertSoundNamed:(NSString*)name {
    if (!name) {
        return ;
    }
    
    // First, see if we've got this sound cached
    SystemSoundID soundId = (SystemSoundID)[[[self soundIds] objectForKey:name] longValue] ;
    // Used -longValue because SystemSoundID is a UInt32
    
    NSString* path ;
    
    // If not found, look in the current application's bundle
    if (!soundId) {
        path = [[NSBundle mainAppBundle] pathForResource:name
                                                  ofType:@"aiff"] ;
        
        soundId = [self soundIdForPath:path
                            rememberAs:name] ;
        // If not found, look in current user's library
        if (!soundId) {
            path = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Sounds"] ;
            path = [path stringByAppendingPathComponent:[name stringByAppendingPathExtension:@"aiff"]] ;
            
            soundId = [self soundIdForPath:path
                                rememberAs:name] ;
            
            // If not found, look in system's library
            if (!soundId) {
                path = @"/System/Library/Sounds" ;
                path = [path stringByAppendingPathComponent:[name stringByAppendingPathExtension:@"aiff"]] ;
                
                soundId = [self soundIdForPath:path
                                    rememberAs:name] ;
            }		
        }		
    }
    
    if (soundId) {
        AudioServicesPlayAlertSound(soundId) ;
    }
    else {
        NSBeep() ;
    }
}

@end