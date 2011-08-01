@interface SSQueuedSpeechSynthesizer : NSObject {

	NSSpeechSynthesizer* _synth ;
	NSMutableArray* _queue ;
}

+ (SSQueuedSpeechSynthesizer*)createSharedSpeaker ;
// must be invoked before any of the other methods work.

+ (SSQueuedSpeechSynthesizer*)sharedSpeaker ;
// only returns the sharedSpeaker if +createSharedSpeaker has been called first.
// Will return nil otherwise

- (void)speak:(NSString*)s1 then:(NSString*)s2 then:(NSString*)s3 ;

@end
