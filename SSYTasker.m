#import "SSYTasker.h"
#import <pthread.h>
#import "SSYRunLoopTickler.h"

NSString* constKeySSYTaskerFileHandle = @"fileHandle" ;
NSString* constKeySSYTaskerData = @"data" ;

NSString* SSYTaskerErrorDomain = @"SSYTaskerErrorDomain" ;

NSInteger SSYTaskerMetaErrorCode = 444000 ;

@interface SSYTasker ()

@property (assign) FILE * restrict heartbeatTo ;

@end

@implementation NSFileHandle (CSFileHandleExtensions)

- (NSData*)availableDataError_p:(NSError**)error_p {
    while (YES) {
        @try {
            return [self availableData] ;
        }
        @catch (NSException *exception) {
            if (
                [[exception name] isEqualToString:NSFileHandleOperationException]
                &&
                [[exception reason] isEqualToString:@"*** -[NSConcreteFileHandle availableData]: Interrupted system call"]
                ) {
                // This exception was raised by the NSTask Stealth Bug and should be ignored
            }
            else {
                // This is a real exception which we need to handle
                if (error_p) {
                    NSMutableDictionary* exceptionInfo = [[NSMutableDictionary alloc] init] ;
                    id value ;
                    
                    value = [exception name] ;
                    if (value) {
                        [exceptionInfo setObject:value
                                          forKey:@"Name"] ;
                    }
                    
                    value = [exception reason] ;
                    if (value) {
                        [exceptionInfo setObject:value
                                          forKey:@"Reason"] ;
                    }
                    
                    value = [exception userInfo] ;
                    if (value) {
                        [exceptionInfo setObject:value
                                          forKey:@"User Info"] ;
                    }
                    
                    NSString* errorDesc = @"Error occurred while reading" ;
                    *error_p  = [NSError errorWithDomain:SSYTaskerErrorDomain
                                                    code:SSYTaskerErrorCodeExceptionOccurredWhileReading
                                                userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                          errorDesc, NSLocalizedDescriptionKey,
                                                          [NSDictionary dictionaryWithDictionary:exceptionInfo], @"Underlying Exception",
                                                          nil]] ;
                }
                else {
                    // We cannot handle this exception because caller did not
                    // provide a pointer for returning errors.
                    @throw ;
                }
                
                return nil ;
            }
        }
    }
}

@end



void* writeDataToHandle(NSDictionary*info) {
    NSFileHandle* fileHandle = [info objectForKey:constKeySSYTaskerFileHandle] ;
    NSData* data = [info objectForKey:constKeySSYTaskerData] ;
    [fileHandle writeData:data] ;
    [fileHandle closeFile] ;
    return nil ;
}


@interface SSYTasker ()

@property BOOL isTaskDone ;
@property NSMutableData* stdoutData ;
@property NSMutableData* stderrData ;
@property NSError* error ;

@end

@implementation SSYTasker

@synthesize isTaskDone = m_isTaskDone ;
@synthesize stdoutData = m_stdoutData ;
@synthesize stderrData = m_stderrData ;
@synthesize error = m_error ;
@synthesize delegate = m_delegate ;

- (void)processNote:(NSNotification*)note
           pipeName:(NSString*)pipeName
           intoData:(NSMutableData *)mutableData {
    NSFileHandle* fileHandle = (NSFileHandle*)[note object] ;
    NSError* error = nil ;
    NSData* data = [fileHandle availableDataError_p:&error] ;
    if (error) {
        [self setError:error] ;
    }
    
    if (pipeName) {
        [[self delegate] gotBytesCount:[data length]
                              pipeName:pipeName] ;
    }
    if ([data length] > 0) {
        
        [mutableData appendData:data] ;
        // Tell the fileHandle that we want more data.
        [fileHandle waitForDataInBackgroundAndNotify] ;
    }
    else {
        // According to documentation, it tells us that either stdout or stderr
        // is done.  In my experience, this branch usually does not execute
        // in a typical program run.  But somtimes it does.  We ignore it and
        // wait instead for NSTaskDidTerminateNotification which is reliable.
    }
}

- (void)eatStdoutNote:(NSNotification*)note {
    NSMutableData* mutableData = [self stdoutData] ;
    if (!mutableData) {
        mutableData = [[NSMutableData alloc] init] ;
        [self setStdoutData:mutableData] ;
    }
    
    [self processNote:note
             pipeName:@"stdout"
             intoData:mutableData];
}

- (void)eatStderrNote:(NSNotification*)note {
    NSMutableData* mutableData = [self stderrData] ;
    if (!mutableData) {
        mutableData = [[NSMutableData alloc] init] ;
        [self setStderrData:mutableData] ;
    }
    
    [self processNote:note
             pipeName:@"stderr"
             intoData:mutableData];
}

- (void)taskTerminatedNote:(NSNotification*)note {
    [[NSNotificationCenter defaultCenter] removeObserver:self] ;
    [self setIsTaskDone:YES] ;
}

- (void)kickFromTimer:(NSTimer*)timer {
    FILE * restrict heartbeatTo = [self heartbeatTo] ;
    if (heartbeatTo != NULL) {
        fprintf(heartbeatTo, "H") ;
    }
    [SSYRunLoopTickler tickle] ;
}

- (NSInteger)runCommand:(NSString*)launchPath
              arguments:(NSArray*)arguments
            heartbeatTo:(FILE *restrict)heartbeatTo
              stdinData:(NSData*)stdinData
              workingIn:(NSString*)workingDirectory {
    NSInteger errorCode = 0 ;

    // Reset in case we are invoked more than once in a lifetime.
    [self setIsTaskDone:NO] ;
    [self setStdoutData:nil] ;
    [self setStderrData:nil] ;
    [self setError:nil] ;

    [self setHeartbeatTo:heartbeatTo] ;
    
    // Create task with given parameters
    NSTask *task = [[NSTask alloc] init] ;
	[task setLaunchPath:launchPath] ;
	if (arguments) {
        [task setArguments:arguments] ;
    }
    if (workingDirectory) {
        [task setCurrentDirectoryPath:workingDirectory] ;
    }
    
    NSFileHandle* fileStdin = nil ;
    if (stdinData) {
        NSPipe *pipeStdin = [NSPipe pipe] ;
        fileStdin = [pipeStdin fileHandleForWriting] ;
        [task setStandardInput:pipeStdin] ;
    }
    
    /*
     In order to prevent the stdout and stderr pipes from clogging and stalling
     tasks that return a lot of stdout or stderr, instead of invoking
     -[NSTask waitUntilExit], we create a run loop, observe when data is
     available in either pipe and process it out.  To terminate, we watch for
     NSTaskDidTerminateNotification.
     */
    
    // Prepare to receive stdout
    NSPipe *pipeStdout = [[NSPipe alloc] init] ;
	NSFileHandle *fileStdout = [pipeStdout fileHandleForReading] ;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(eatStdoutNote:)
                                                 name:NSFileHandleDataAvailableNotification
                                               object:fileStdout] ;
	[task setStandardOutput:pipeStdout] ;
    [fileStdout waitForDataInBackgroundAndNotify] ;
    
	// Prepare to receive stderr
    NSPipe *pipeStderr = [[NSPipe alloc] init] ;
	NSFileHandle *fileStderr = [pipeStderr fileHandleForReading];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(eatStderrNote:)
                                                 name:NSFileHandleDataAvailableNotification
                                               object:fileStderr] ;
	[task setStandardError:pipeStderr] ;
    [fileStderr waitForDataInBackgroundAndNotify] ;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(taskTerminatedNote:)
                                                 name:NSTaskDidTerminateNotification
                                               object:task] ;
    
    [task launch] ;
    
    if (stdinData) {
        // Torsten Curdt says that we need to write to stdin in a separate
        // thread, in case it is more than 64 KB.  I don't know if that is
        // still true, but we use his code here, updated for ARC, with
        // improved error handling.
        pthread_t thread = nil ;
        
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                              fileStdin, constKeySSYTaskerFileHandle,
                              stdinData, constKeySSYTaskerData,
                              nil] ;
        
        int err ;
        
        err = pthread_create(
                             &thread,
                             nil,
                             (void *(*)(void *))writeDataToHandle,
                             (__bridge void *)info) ;
        if (err != 0) {
            errorCode = SSYTaskerErrorCodeCouldNotCreateThreadForStdin ;
        }
        
        if (errorCode == 0) {
            err = pthread_detach(thread) ;
            if (err != 0) {
                errorCode = SSYTaskerErrorCodeCouldNotDetachThreadForStdin ;
            }
        }
        
        
    }
    
    int exitStatus = -1 ;
    if (errorCode == 0) {
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop] ;
        NSTimer* timer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                          target:self
                                                        selector:@selector(kickFromTimer:)
                                                        userInfo:nil
                                                         repeats:YES] ;
        do {
            @autoreleasepool {
                BOOL keepRunning = [runLoop runMode:NSDefaultRunLoopMode
                                         beforeDate:[NSDate distantFuture]] ;
                if (!keepRunning) {
                    [self setIsTaskDone:YES] ;
                }
                // That's all. Actual work is done by notification handlers.
                // Just run the loop again, to wait for next notification or done.
            }
        } while ([self isTaskDone] == NO) ;
        
        [timer invalidate] ;
        
        exitStatus = [task terminationStatus] ;
        
        [[NSNotificationCenter defaultCenter] removeObserver:self] ;
    }
    
    if ((errorCode != 0) && ([self error] == nil)) {
        NSError* error = [NSError errorWithDomain:SSYTaskerErrorDomain
                                             code:errorCode
                                         userInfo:nil] ;
        [self setError:error] ;
    }
    
    NSInteger result = [self error] ? SSYTaskerMetaErrorCode : exitStatus ;
    
    return result ;
}

- (NSData*)stdoutFromLastRun {
    return [[self stdoutData] copy] ;
}

- (NSData*)stderrFromLastRun {
    return [[self stderrData] copy] ;
}

- (NSError*)errorFromLastRun {
    NSError* error = [self error] ;
    if (!error) {
        if (errno) {
            NSString* desc = [NSString stringWithFormat:
                              @"Command returned Unix errno %d",
                              errno] ;
            error = [NSError errorWithDomain:SSYTaskerErrorDomain
                                        code:SSYTaskerErrorCodeUnixCommandError
                                    userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                              desc, NSLocalizedDescriptionKey,
                                              [NSNumber numberWithInt:errno], @"errno",
                                              nil]] ;
        }
    }
    
    return error ;
}

@end
