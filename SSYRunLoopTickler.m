#import "SSYRunLoopTickler.h"
#import "SSY_ARC_OR_NO_ARC.h"

@implementation SSYRunLoopTickler

+ (void)tickle {
	NSPort* sendPort = [NSMachPort port] ;
	[[NSRunLoop currentRunLoop] addPort:sendPort
								forMode:NSDefaultRunLoopMode] ;	
	NSPort* receivePort = [NSMachPort port] ;
	NSPortMessage* message = [[NSPortMessage alloc] initWithSendPort:sendPort
														 receivePort:receivePort
														  components:nil] ;
	BOOL sentOk = [message sendBeforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]] ;
	if (!sentOk) {
		// Should actually return an NSError, but I don't think
		// this will ever happen in real life, so I'm just going
		// to log it.
		NSLog(@"%s failed to send its message.", __PRETTY_FUNCTION__) ;
	}
	
#if NO_ARC
	[message release] ;
#endif
    
	// If I remove the port now, the desired "tickle" causing a
	// blocked -[NSRunLoop runMode:beforeDate:] to return will
	// not occur.  But if I do so with a delay of 0.0, it works.
	[self performSelector:@selector(removePort:)
			   withObject:sendPort
			   afterDelay:0.0] ;
}

/*!
 Just a debugging note:  If the +tickle message is sent from a
 secondary thread which exits, the delayed performance of this
 method will not occur, but that is OK because when its thread
 ends the port will be "removed" anyhow.
 */
+ (void)removePort:(NSPort*)port {
	[[NSRunLoop currentRunLoop] removePort:port
								   forMode:NSDefaultRunLoopMode] ;
}

@end