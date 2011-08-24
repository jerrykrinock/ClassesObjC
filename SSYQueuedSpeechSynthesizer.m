#import "SSYQueuedSpeechSynthesizer.h"

// This is a "true singleton" per Cocoa document "Creating A Singleton Instance", except
// that the single is not created if needed by +sharedSpeaker but must be explicitly created
// by sending +createSharedSpeaker.  If +sharedSpeaker is invoked before +createSharedSppeaker
// is run once, it returns nil.

static SSYQueuedSpeechSynthesizer *sharedSpeaker = nil ;

@implementation SSYQueuedSpeechSynthesizer

- (void)setSynth:(NSSpeechSynthesizer*)synth {
	[synth retain] ;
	[_synth release] ;
	_synth = synth ;
}

- (NSSpeechSynthesizer*)synth {
	return _synth;
}

- (void)setQueue:(NSMutableArray*)queue {
	[queue retain] ;
	[_queue release] ;
	_queue = queue ;
}

- (NSMutableArray*)queue {
	return _queue ;
}

- (id)init {
	if ((self = [super init])) {
		NSSpeechSynthesizer* synth = [[NSSpeechSynthesizer alloc] init] ;
		[self setSynth:synth] ;
		[synth release] ;
		[[self synth] setDelegate:self];
		
		NSMutableArray* queue = [[NSMutableArray alloc] init] ;
		[self setQueue:queue] ;
		[queue release] ;
	}	

	return self ;
}

+ (SSYQueuedSpeechSynthesizer*)createSharedSpeaker
{
	if (sharedSpeaker == nil) {
		sharedSpeaker = [[self alloc] init];
	}
	
    return sharedSpeaker;
}

+ (SSYQueuedSpeechSynthesizer*)sharedSpeaker
{
    return sharedSpeaker;
}

+ (id)allocWithZone:(NSZone *)zone
{
	if (sharedSpeaker == nil) {
		sharedSpeaker = [super allocWithZone:zone];
	}

    return sharedSpeaker;
}

- (id)retain
{
    return self;
}

- (unsigned)retainCount
{
    return UINT_MAX;  //denotes an object that cannot be released
}

- (void)release
{
    //do nothing
}
- (id)autorelease
{
    return self;
}
- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (void)speak:(NSString*)s1
		 then:(NSString*)s2
		 then:(NSString*)s3 {
	NSMutableString* whole = [[NSMutableString alloc] init] ;
	if (s1) {
		[whole appendString:s1] ;
	}
	if (s2) {
		[whole appendString:@" "] ;
		[whole appendString:s2] ;
	}
	if (s3) {
		[whole appendString:@" "] ;
		[whole appendString:s3] ;
	}

	if ([[self synth] isSpeaking] || ([[self queue] count] > 0)) {
		[[self queue] addObject:whole] ;
	}
	else {
		[[self synth] startSpeakingString:whole] ;
	}
	
	[whole release] ;
}

- (void)startSpeakingAndDeleteFromQueue {
	[[self synth] startSpeakingString:[[self queue] objectAtIndex:0]] ;
	[[self queue] removeObjectAtIndex:0] ;
}

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)finishedSpeaking {
	NSMutableArray* queue = [self queue] ;
	if ([queue count] > 0) {
		[self performSelector:@selector(startSpeakingAndDeleteFromQueue) withObject:nil afterDelay:1.0] ;
	}
}

@end
