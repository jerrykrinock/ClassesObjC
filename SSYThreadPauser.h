#import <Cocoa/Cocoa.h>


@interface SSYThreadPauser : NSObject {
}

/*!
 @brief    Runs a job on another thread and blocks the current
 thread until the method is complete, or until a timeout, whichever
 happens first.
 
 @details  If timeout occurs, the workerThread will be sent
 a -cancel message, so that if your worker periodically sends -isCancelled
 to its current thread, it can abort the work in order to stop wasting
 cpu cycles.&nbsp;  See -[NSThread isCancelled] documentation.
 @param    worker  The target which will perform the job.
 @param    selector  The selector of the job to be run.  This
 method need not create nor drain an autorelease pool if garbage collection
 is not being used, because SSYThreadPauser takes care of that.
 @param    object  A parameter which will be passed to selector
 @param    workerThread  The thread on which the job will be performed.
 If you pass nil, a temporary thread will be created.
 @param    timeout  The timeout before the job is aborted.  For no
 timeout, pass FLT_MAX.  (Search tags: floatmax float_max maxfloat max_float)
 @result   YES if the job completed, NO if it timed out.
 */
+ (BOOL)blockUntilWorker:(id)worker
				selector:(SEL)selector	
				  object:(id)object
				  thread:(NSThread*)workerThread
				 timeout:(NSTimeInterval)timeout ;

@end



#ifdef TEST_CODE_FOR_SSY_THREAD_PAUSER

@interface WorkerDemo : NSObject {}

- (void)doWorkForTimeInterval:(NSNumber*)interval ;

@end


@implementation WorkerDemo

#define CANCEL_GRANULARITY 10

- (void)doWorkForTimeInterval:(NSNumber*)interval {
	NSLog(@"2308: Beginning work") ;
	
	NSTimeInterval timeChunk = [interval doubleValue]/CANCEL_GRANULARITY ;
	NSInteger i ;
	for (i=0; i<CANCEL_GRANULARITY; i++) {
		usleep(1e6 * timeChunk) ;
		if ([[NSThread currentThread] isCancelled]) {
			NSLog(@"2492 Cancelling work") ;
			break ;
		}
	}
	
	NSLog(@"2557: Ending work") ;
}

@end

int main (int argc, const char * argv[]) {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init] ;
	
	WorkerDemo* workerDemo = [[WorkerDemo alloc] init] ;
	NSTimeInterval duration ;
	NSTimeInterval timeout ;
	BOOL ok ;	
	
	NSLog(@"Starting Test #1") ;
	duration = 1.0 ;
	timeout = 2.0 ;
	ok = [SSYThreadPauser blockUntilWorker:workerDemo
								  selector:@selector(doWorkForTimeInterval:)
									object:[NSNumber numberWithDouble:duration]
									thread:nil  // SSYThreadPauser will create a thread
								   timeout:timeout] ;
	NSLog(@"Job duration=%0.0f  timeout=%0.0f  succeeded=%ld",
		  duration,
		  timeout,
		  (long)ok) ;
	
	
	NSLog(@"Starting Test #2") ;
	duration = 3.0 ;
	timeout = 2.0 ;
	ok = [SSYThreadPauser blockUntilWorker:workerDemo
								  selector:@selector(doWorkForTimeInterval:)
									object:[NSNumber numberWithDouble:duration]
									thread:nil  // SSYThreadPauser will create a thread
								   timeout:timeout] ;
	NSLog(@"Job duration=%0.0f  timeout=%0.0f  succeeded=%ld",
		  duration,
		  timeout,
		  (long)ok) ;
	
	// Wait to allow the other threads to complete before we exit,
	// so we don't miss any crashes, errors or warnings.
	usleep(3000000) ;
	
	[pool release] ;
}

#endif