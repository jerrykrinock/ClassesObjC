#import "SSYLaunchdBasics.h"

#if MAC_OS_X_VERSION_MAX_ALLOWED < 1070
#define NO_ARC 1
#else
#if __has_feature(objc_arc)
#define NO_ARC 0
#else
#define NO_ARC 1
#endif
#endif


@implementation SSYLaunchdBasics

+ (NSString*)homeLaunchAgentsPath {
	return [[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"LaunchAgents"] ;
}


+ (NSSet*)installedLaunchdAgentLabelsWithPrefix:(NSString*)prefix {
	NSError* error = nil ;
	NSArray* allAgentNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self homeLaunchAgentsPath]
																				 error:&error] ;
	if (!allAgentNames) {
		if (
			([error code] != NSFileReadNoSuchFileError)
			||
			(![[error domain] isEqualToString:NSCocoaErrorDomain])
			) {
				NSLog(@"Internal Error 257-8032 %@", error) ;
		}
	}

	NSMutableSet* targetAgentNames = [[NSMutableSet alloc] init] ;
	if (prefix) {
		for (NSString* agentName in allAgentNames) {
			if ([agentName hasPrefix:prefix]) {
				[targetAgentNames addObject:[agentName stringByDeletingPathExtension]] ;
			}
		}
	}
	
	NSSet* answer = [targetAgentNames copy] ;
#if NO_ARC
	[targetAgentNames release] ;
	[answer autorelease] ;
#endif

    return answer ;
}

+ (NSDictionary*)installedLaunchdAgentsWithPrefix:(NSString*)prefix {
	NSSet* allAgentNames = [self installedLaunchdAgentLabelsWithPrefix:prefix] ;
	NSString* directory = [self homeLaunchAgentsPath] ;
	NSMutableDictionary* agents = [[NSMutableDictionary alloc] init] ;
	for (NSString* agentName in allAgentNames) {
		NSString* filename = [agentName stringByAppendingPathExtension:@"plist"] ;
		NSString* path = [directory stringByAppendingPathComponent:filename] ;
		NSDictionary* agentDic = [NSDictionary dictionaryWithContentsOfFile:path] ;
		// Use defensive programming when reading from files!
		if ([agentDic isKindOfClass:[NSDictionary class]]) {
			[agents setObject:agentDic
					   forKey:agentName] ;
		}
	}
	
	NSDictionary* answer = [agents copy] ;
#if NO_ARC
	[agents release] ;
	[answer autorelease] ;
#endif

    return answer ;
}

@end
