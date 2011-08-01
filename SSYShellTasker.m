#import "SSYShellTasker.h"
#import "NSError+SSYAdds.h"
#import "SSYThreadPauser.h"
#import "SSYRunLoopTickler.h"

NSInteger const SSYShellTaskerErrorFailedLaunch = 90551 ;
NSInteger const SSYShellTaskerErrorTimedOut= 90552  ;

NSString* const constKeySSYShellTaskerCommand = @"command" ;
NSString* const constKeySSYShellTaskerArguments = @"arguments" ;
NSString* const constKeySSYShellTaskerInDirectory = @"inDirectory" ;
NSString* const constKeySSYShellTaskerStdinData = @"stdinData" ;
NSString* const constKeySSYShellTaskerStdoutData = @"stdoutData" ;
NSString* const constKeySSYShellTaskerStderrData = @"stderrData" ;
NSString* const constKeySSYShellTaskerTimeout = @"timeout" ;
NSString* const constKeySSYShellTaskerResult = @"result" ;
NSString* const constKeySSYShellTaskerNSError = @"error" ;
NSString* const constKeySSYShellTaskerWants = @"wants" ;

// Since stdout and stderr might be huge, for efficiency, we
// only provide them if the invoker wants them.
#define SSYShellTaskerWantsStdout 0x1
#define SSYShellTaskerWantsStderr 0x2
// The task "result" are always provided, since they are small

@implementation SSYShellTasker

- (void)taskDone:(NSNotification*)note {
	// This is definitely needed in Mac OS 10.6:
	[SSYRunLoopTickler tickle] ;
}

- (void)doWithInfo:(NSMutableDictionary*)info {
    // Each of the three NSFileHandles we are going to create requires creation of an NSPipe,
	// which according to documentation -fileHandleForReading is released "automatically"
	// when the NSPipe is released.  Actually, I find that it is autoreleased when the
	// current autorelease pool is released, which is a little different.
	// To conserve system resources, therefore, we use a local pool here.
	// For more info, 
	//	  http://www.cocoabuilder.com/archive/message/cocoa/2002/11/30/51122
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init] ;

	NSString* command = [info objectForKey:constKeySSYShellTaskerCommand] ;
	NSArray* arguments = [info objectForKey:constKeySSYShellTaskerArguments] ;
	NSString* inDirectory = [info objectForKey:constKeySSYShellTaskerInDirectory] ;
	NSData* stdinData =  [info objectForKey:constKeySSYShellTaskerStdinData] ;
	NSTimeInterval timeout = [[info objectForKey:constKeySSYShellTaskerTimeout] floatValue] ;
	NSInteger wants = [[info objectForKey:constKeySSYShellTaskerWants] intValue] ;
	
	NSError* error = nil ;
	
    NSInteger taskResult = 0 ;
    NSTask* task;
    NSPipe* pipeStdin = nil ;
    NSPipe* pipeStdout = nil ;
    NSPipe* pipeStderr = nil ;
    NSFileHandle* fileStdin = nil ;
    NSFileHandle* fileStdout = nil ;
    NSFileHandle* fileStderr = nil ;
	
    task = [[NSTask alloc] init] ;
	
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
	
	if ((wants & SSYShellTaskerWantsStdout) > 0) {
	    pipeStdout = [[NSPipe alloc] init] ;
	    fileStdout = [pipeStdout fileHandleForReading] ;
	    [task setStandardOutput:pipeStdout ] ;
	}
	
	if ((wants & SSYShellTaskerWantsStderr) > 0) {
		pipeStderr = [[NSPipe alloc] init] ;
	    fileStderr = [pipeStderr fileHandleForReading] ;
	    [task setStandardError:pipeStderr ] ;
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(taskDone:)
												 name:NSTaskDidTerminateNotification
											   object:task] ;
	
	@try {
		[task launch] ;
		if ([task isRunning]) {
			// Note: The following won't execute if no stdinData, since fileStdin will be nil
			[fileStdin writeData:stdinData] ;  
			[fileStdin closeFile] ;
		}
		
		if (timeout > 0.0) {
			NSDate* limitTime = [NSDate dateWithTimeIntervalSinceNow:timeout] ;
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
									 beforeDate:limitTime] ;
			// The above will block and be run to here either due to 
			// the posting of an NSTaskDidTerminateNotification, or the
			// passing of limitTime, whichever occurs first.
			if (![task isRunning]) {
				taskResult = [task terminationStatus] ;

				NSData* data ;
				if ((wants & SSYShellTaskerWantsStdout) > 0) {
					data = [fileStdout readDataToEndOfFile] ;
					if (data) {
						[info setObject:data
								 forKey:constKeySSYShellTaskerStdoutData] ;
					}
				}
				if ((wants & SSYShellTaskerWantsStderr) > 0) {
					data = [fileStderr readDataToEndOfFile] ;
					if (data) {
						[info setObject:data
								 forKey:constKeySSYShellTaskerStderrData] ;
					}
				}			
			}
			else {
				taskResult = SSYShellTaskerErrorTimedOut ;

				// Clean up
				kill([task processIdentifier], SIGKILL) ;
				
				error = [NSError errorWithDomain:@"SSYShellTasker"
											code:SSYShellTaskerErrorTimedOut
										userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
												  @"SSYShellTasker: Task timed out (and was killed)", NSLocalizedDescriptionKey,
												  [NSNumber numberWithDouble:timeout], @"exceeded seconds",
												  command, @"command",
												  nil]] ;
				if (arguments) {
					error = [error errorByAddingUserInfoObject:arguments
														forKey:@"arguments"] ;
				}
				if (stdinData) {
					error = [error errorByAddingUserInfoObject:stdinData
														forKey:@"stdin data"] ;
				}
			}
		}
    }
	
	@catch (NSException* exception) {
		error = [NSError errorWithDomain:@"SSYShellTasker"
									code:SSYShellTaskerErrorFailedLaunch
								userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
										  @"SSYShellTasker: Task raised exception attempting to launch", NSLocalizedDescriptionKey,
										  nil]] ;
		error = [error errorByAddingUnderlyingException:exception] ;
		taskResult = SSYShellTaskerErrorFailedLaunch ;
	}
	@finally {
	}
	
	[info setObject:[NSNumber numberWithInt:taskResult]
			 forKey:constKeySSYShellTaskerResult] ;				

	if (error) {
		[info setObject:error
			 forKey:constKeySSYShellTaskerNSError] ;
	}
	
	[pipeStdin release] ;
	[pipeStdout release] ;
	[pipeStderr release] ;
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSTaskDidTerminateNotification
												  object:task] ;	
    [task release] ;
	
	[pool release] ;
}

+ (NSInteger)doShellTaskCommand:(NSString*)command
					  arguments:(NSArray*)arguments
					inDirectory:(NSString*)inDirectory
					  stdinData:(NSData*)stdinData
				   stdoutData_p:(NSData**)stdoutData_p
				   stderrData_p:(NSData**)stderrData_p
						timeout:(NSTimeInterval)timeout 
						error_p:(NSError**)error_p {
	NSInteger wants = 0 ;
	if (stdoutData_p) {
		wants += SSYShellTaskerWantsStdout ;
	}
	if (stderrData_p) {
		wants += SSYShellTaskerWantsStderr ;
	}
	
	// Initialize dictionary with values that cannot be nil
	NSMutableDictionary* info = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								 command, constKeySSYShellTaskerCommand,
								 [NSNumber numberWithInt:wants], constKeySSYShellTaskerWants,
								 [NSNumber numberWithDouble:timeout], constKeySSYShellTaskerTimeout,
								 nil] ;
	// Now set in values which can be nil
	if (arguments) {
		[info setObject:arguments
				 forKey:constKeySSYShellTaskerArguments] ;
	}
	if (inDirectory) {
		[info setObject:inDirectory
				 forKey:constKeySSYShellTaskerInDirectory] ;
	}
	if (stdinData) {
		[info setObject:stdinData
				 forKey:constKeySSYShellTaskerStdinData] ;
	}
	
	SSYShellTasker* tasker = [[SSYShellTasker alloc] init] ;
	NSInteger result ;
	
	if (timeout == 0.0) {
		[tasker doWithInfo:info] ;
	}
	else {
		[SSYThreadPauser blockUntilWorker:tasker
								 selector:@selector(doWithInfo:)	
								   object:info
								   thread:nil // Run in a new thread
								  timeout:FLT_MAX] ;
		// In the above, we set timeout:FLT_MAX because timeout is in info,
		// and we'll get a more descriptive NSError if doWithInfo: times out
		// than from SSYThreadPauser if we would let SSYThreadPauser time out.
		// Also, doWithInfo: will clean up by killing the task process.
		if (stdoutData_p) {
			*stdoutData_p = [info objectForKey:constKeySSYShellTaskerStdoutData] ;
		}
		if (stderrData_p) {
			*stderrData_p = [info objectForKey:constKeySSYShellTaskerStderrData] ;
		}
		if (error_p) {
			*error_p = [info objectForKey:constKeySSYShellTaskerNSError] ;
		}		
	}
		
	result = [[info objectForKey:constKeySSYShellTaskerResult] intValue] ;

	[tasker release] ;
		
	return result ;
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