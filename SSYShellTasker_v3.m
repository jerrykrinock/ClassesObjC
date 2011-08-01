#import "SSYShellTasker.h"
#import "NSError+SSYAdds.h"
#import "SSYThreadPauser.h"

NSInteger const SSYShellTaskerErrorFailedLaunch = 90551 ;
NSInteger const SSYShellTaskerErrorTimedOut= 90552  ;


#define TASK_IS_NOT_DONE 0
#define TASK_IS_DONE 1


@interface SSYShellTasker ()

@property (retain) NSTask* task ;
@property (retain) NSConditionLock* lock ;

@end


@implementation SSYShellTasker

@synthesize task = m_task ;
@synthesize lock = m_lock ;

- (void)dealloc {
	[m_task release] ;
	[m_lock release] ;
	
	[super dealloc] ;
}

+ (NSInteger)doShellTaskCommand:(NSString*)command
					  arguments:(NSArray*)arguments
					inDirectory:(NSString*)inDirectory
					  stdinData:(NSData*)stdinData
				   stdoutData_p:(NSData**)stdoutData_p
				   stderrData_p:(NSData**)stderrData_p
						timeout:(NSTimeInterval)timeout 
						error_p:(NSError**)error_p {
 /*DB?Line*/ NSLog(@">>>>>> timeout:%0.2f %@ %@", timeout, command, [arguments componentsJoinedByString:@" "]) ;
   // Each of the three NSFileHandles we are going to create requires creation of an NSPipe,
	// which according to documentation -fileHandleForReading is released "automatically"
	// when the NSPipe is released.  Actually, I find that it is autoreleased when the
	// current autorelease pool is released, which is a little different.
	// To conserve system resources, therefore, we use a local pool here.
	// For more info, 
	//	  http://www.cocoabuilder.com/archive/message/cocoa/2002/11/30/51122
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init] ;
	
    NSInteger result = 0 ;
    NSPipe* pipeStdin = nil ;
    NSPipe* pipeStdout = nil ;
    NSPipe* pipeStderr = nil ;
    NSFileHandle* fileStdin = nil ;
    NSFileHandle* fileStdout = nil ;
    NSFileHandle* fileStderr = nil ;
	
	NSTask* task = [[NSTask alloc] init] ;
	SSYShellTasker* tasker = [[SSYShellTasker alloc] init] ;
	[tasker setTask:task] ;
	[task release] ;
	
	[task setLaunchPath:command] ;
	
    if (inDirectory) {
        [task setCurrentDirectoryPath: inDirectory] ;
	}
	
    if (arguments != nil) {
    	[task setArguments: arguments] ;
	}
	
    if (stdinData) {
    	pipeStdin = [[NSPipe alloc] init] ;
	    fileStdin = [pipeStdin fileHandleForWriting] ;
	    [task setStandardInput:pipeStdin] ;
    }
	
	if (stdoutData_p) {
	    pipeStdout = [[NSPipe alloc] init] ;
	    fileStdout = [pipeStdout fileHandleForReading] ;
	    [task setStandardOutput:pipeStdout ] ;
	}
	
	if (stderrData_p) {
		pipeStderr = [[NSPipe alloc] init] ;
	    fileStderr = [pipeStderr fileHandleForReading] ;
	    [task setStandardError:pipeStderr ] ;
	}
	
	[NSThread detachNewThreadSelector:@selector(waitOnTask)
							 toTarget:tasker
						   withObject:nil] ;
	
	@try {
		[task launch] ;
		
		if ([task isRunning]) {
			// Note: The following won't execute if no stdinData, since fileStdin will be nil
			[fileStdin writeData:stdinData] ;  
			[fileStdin closeFile] ;
		}
		
		NSConditionLock* lock = [[NSConditionLock alloc] initWithCondition:TASK_IS_NOT_DONE] ;
		[tasker setLock:lock] ;
		[lock release] ;
		
		// Will block here until task is done, or timeout
		BOOL taskCompleted = [lock lockWhenCondition:TASK_IS_DONE
										  beforeDate:[NSDate dateWithTimeIntervalSinceNow:timeout]] ;
		/*DB?Line*/ NSLog(@"3045: Locked lock with condition TASK IS DONE") ;
		
		if (taskCompleted) {
			// Task completed on time
			/*DB?Line*/ NSLog(@"3149: Completed on time") ;
			
			result = [task terminationStatus] ;
		
			NSData* data ;
			if (stdoutData_p) {
				data = [fileStdout readDataToEndOfFile] ;
				*stdoutData_p = data ;
			}
			if (stderrData_p) {
				data = [fileStderr readDataToEndOfFile] ;
				*stderrData_p = data ;
			}
		}
		else {
			// Timed out
			pid_t pid = [task processIdentifier] ;
			/*DB?Line*/ NSLog(@"3649: Timed out.  Killing pid %d", pid) ;
			
			// Kill the external task
			kill(pid, SIGKILL) ;
			

			result = SSYShellTaskerErrorTimedOut ;
			
			/*DB?Line*/ NSLog(@"3821: Will create timeout error") ;
			if (error_p) {
				*error_p = [NSError errorWithDomain:@"SSYShellTasker"
											   code:SSYShellTaskerErrorTimedOut
										   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
													 @"SSYShellTasker: Task timed out (and was killed)", NSLocalizedDescriptionKey,
													 [NSNumber numberWithDouble:timeout], @"exceeded seconds",
													 command, @"command",
													 nil]] ;
				if (arguments) {
					*error_p = [*error_p errorByAddingUserInfoObject:arguments
															  forKey:@"arguments"] ;
				}
				if (stdinData) {
					*error_p = [*error_p errorByAddingUserInfoObject:stdinData
															  forKey:@"stdin data"] ;
				}
			}
			/*DB?Line*/ NSLog(@"4559: Did create timeout error") ;
		}
	}	
	@catch (NSException* exception) {
		if (error_p) {
			*error_p = [NSError errorWithDomain:@"SSYShellTasker"
										   code:SSYShellTaskerErrorFailedLaunch
									   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
												 @"SSYShellTasker: Task raised exception attempting to launch", NSLocalizedDescriptionKey,
												 nil]] ;
			*error_p = [*error_p errorByAddingUnderlyingException:exception] ;
		}
			
		result = SSYShellTaskerErrorFailedLaunch ;
	}
	@finally {
	}
	
	[pipeStdin release] ;
	[pipeStdout release] ;
	[pipeStderr release] ;
	[pool release] ;
/*DB?Line*/ NSLog(@"5261 <<<<<<<< COMPLETED") ;

	return result ;
}

- (void)waitOnTask {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init] ;
	NSRunLoop* runLoop = [NSRunLoop currentRunLoop] ;
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(taskDone:)
												 name:NSTaskDidTerminateNotification
											   object:nil] ;
	/*DB?Line*/ NSLog(@"5391: Running run loop") ;
	[runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode] ;

	while (YES) {
		BOOL taskIsDone = [[self lock] condition] == TASK_IS_DONE ;
		/*DB?Line*/ NSLog(@"5661: taskIsDone = %d", taskIsDone) ;
		if (taskIsDone) {
			/*DB?Line*/ NSLog(@"5743: Exitting run loop because task is done") ;
			break ;
		}
		
		BOOL hasInputSources = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
														beforeDate:[NSDate distantFuture]] ;
		/*DB?Line*/ NSLog(@"5961: hasInputSources = %d", hasInputSources) ;
		if (!hasInputSources) {
			/*DB?Line*/ NSLog(@"5992: Exitting run loop because no input sources") ;
			break ;
		}
	}
	
//	while (([[self lock] condition] == TASK_IS_NOT_DONE) && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
//																					 beforeDate:[NSDate distantFuture]]) {
//		;
//	}

	/*DB?Line*/ NSLog(@"5476: Run loop has exitted with lock condition %d", [[self lock] condition] ) ;
	[[NSNotificationCenter defaultCenter] removeObserver:self] ;
	[pool release] ;
}		
		
- (void)taskDone:(NSNotification*)note {
/*DB?Line*/ NSLog(@"5703 Task completed on time") ;
	[[self lock] lock] ;
	[[self lock] unlockWithCondition:TASK_IS_DONE] ;
/*DB?Line*/ NSLog(@"5803 Set to TASK_IS_DONE and unlocked") ;
}

@end

/* MORE TEST CODE for SSYShellTasker */

/*
 #import "SSYShellTasker.h"
 
 
 @interface Foo : NSObject {}
 @end
 
 @implementation Foo
 
 + (void)goShellStuff {
 NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init] ;
 
 NSError* error = nil ;
 NSString* command ;
 NSArray* arguments = nil ;
 NSString* directory = nil ;
 NSData* stdoutData = nil ;
 
 command = @"/usr/bin/open" ;
 arguments = [NSArray arrayWithObject:@"/Users/jk/Documents/Programming/Builds/Debug/BookMacster.app"] ;
 
 command = @"/bin/ls" ;
 arguments = nil ;
 directory = @"/Users" ;
 
 NSInteger result = [SSYShellTasker doShellTaskCommand:command
 arguments:arguments
 inDirectory:directory
 stdinData:nil
 stdoutData_p:&stdoutData
 stderrData_p:NULL
 timeout:5.0
 error_p:&error] ;
 
 NSLog(@"task result = %d", result) ;
 NSString* stdoutString = [[NSString alloc] initWithData:stdoutData
 encoding:NSUTF8StringEncoding] ;
 NSLog(@"stdout:\n%@", stdoutString) ;
 [stdoutString release] ;
 NSLog(@"task error = %@", error) ;
 
 [pool release] ;
 }	
 
 @end
 
 
 int main(int argc, const char *argv[]) {
 NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init] ;
 
 NSLog(@"----- Doing From Main Thread -----") ;
 [Foo goShellStuff] ;
 
 NSLog(@"----- Doing From Secondary Thread -----") ;
 [NSThread detachNewThreadSelector:@selector(goShellStuff)
 toTarget:[Foo class]
 withObject:nil] ;
 
 [[NSRunLoop currentRunLoop] run] ;
 
 NSLog(@"This never executes.") ;
 [pool release] ; // Needed to suppress compiler warning
 
 return 0 ;
 }

*/