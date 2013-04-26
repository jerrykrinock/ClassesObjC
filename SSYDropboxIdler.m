#import "SSYDropboxIdler.h"
#import "SSYOTherApper.h"
#import "NSDate+NiceFormats.h"

#define PRIMARY_TEST_THRESHOLD_AVERAGE_CPU_PERCENT 1.0
#define SECONDARY_TEST_THRESHOLD_AVERAGE_CPU_PERCENT 0.25
#define COUNT_OF_SECONDARY_TESTS 3

NSString* const SSYDropboxIdlerErrorDomain = @"SSYDropboxIdlerErrorDomain" ;

@interface SSYDropboxIdler ()

@property (assign) NSObject <SSYDropboxIdlerDelegate> * delegate ;
@property (retain) NSString* logPath ;

@end

@implementation SSYDropboxIdler

@synthesize delegate = m_delegate ;
@synthesize logPath = m_logPath ;

- (NSFileHandle*)logFileHandle {
    NSString* logPath = [self logPath] ;
    NSFileHandle* fileHandle = nil ;
    if (logPath) {
        NSFileManager* fileManager = [NSFileManager defaultManager] ;
        if (![fileManager fileExistsAtPath:logPath]) {
            [fileManager createFileAtPath:logPath
                                 contents:[NSData data]
                               attributes:nil] ;
        }
        fileHandle = [NSFileHandle fileHandleForWritingAtPath:logPath] ;
    }
    
    return fileHandle ;
}

- (id)initWithDelegate:(NSObject <SSYDropboxIdlerDelegate> *)delegate
               logPath:(NSString*)logPath {
    self = [super init] ;
    if (self) {
        [self setDelegate:delegate] ;
        [self setLogPath:logPath] ;
    }
    
    return self ;
}

- (void)appendProgress:(NSString*)progress {
    [[self delegate] appendProgress:progress] ;
	NSFileHandle* fileHandle = [self logFileHandle] ;
	if (fileHandle) {
        [fileHandle seekToEndOfFile] ;
        NSData* data = [progress dataUsingEncoding:NSUTF8StringEncoding] ;
		[fileHandle writeData:data] ;
        [fileHandle closeFile] ;
	}
}

- (BOOL)cpuUsageForInterval:(const NSTimeInterval)innerLoopPeriod
                        pid:(pid_t)dropboxPid
              avgCpuUsage_p:(CGFloat *)avgCpuUsage_p
                    error_p:(NSError **)error_p {
    BOOL ok = YES ;
    NSDate* innerEndDate = [NSDate dateWithTimeIntervalSinceNow:innerLoopPeriod] ;
    NSInteger n = 0 ;
    CGFloat total = 0.0 ;
    CGFloat cpuPercent ;
    
    [self appendProgress: @"   Samples: "] ;
    do {
        ok = [SSYOtherApper processPid:dropboxPid
                               timeout:innerLoopPeriod  // better be much less than this, to get lots of samples
                          cpuPercent_p:&cpuPercent
                               error_p:&(*error_p)] ;
        [self appendProgress:[NSString stringWithFormat:@"%0.1f%% ", cpuPercent]] ;
        
        if (ok) {
            total += cpuPercent ;
            n++ ;
        }
        else {
            if (*error_p) {
                NSString* errorDescription = @"Could not get Dropbox average CPU Usage" ;
                *error_p = [NSError errorWithDomain:SSYDropboxIdlerErrorDomain
                                               code:651106
                                           userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                     errorDescription, NSLocalizedDescriptionKey,
                                                     [NSNumber numberWithInteger:dropboxPid], @"PID",
                                                     *error_p, NSUnderlyingErrorKey,
                                                     nil]] ;
            }
            break ;
        }
        
        usleep(1800000) ; // 1.8 seconds
    } while ([(NSDate*)[NSDate date] compare:innerEndDate] == NSOrderedAscending) ;
    
    cpuPercent = (n>0) ? total/n : 100.0 ;
    if (avgCpuUsage_p) {
        *avgCpuUsage_p = cpuPercent ;
    }
    
    return ok ;
}

- (BOOL)waitForIdleDropboxTimeout:(NSTimeInterval)timeout
						   isIdle:(BOOL*)isIdle_p
                      narrative_p:(NSString**)narrative_p
						  error_p:(NSError**)error_p {
	BOOL ok = YES;
    BOOL isIdle = YES ;
    NSError* error = nil ;
    NSDate* startDate = [NSDate date] ;
    
    
	[self appendProgress:[NSString stringWithFormat:
                          @"\n***** %@ Beginning Wait with timeout %0.1f seconds *****\n",
                          [[NSDate date] geekDateTimeString],
                          timeout]] ;
    
    // Since the Dropbox app does not appear in the Dock, I'm somehwat sure, we
	// get 0 pid from +[SSYOtherApper pidOfThisUsersAppWithBundleIdentifier:].  So
	// we use +[SSYOtherApper pidOfThisUsersProcessWithBundlePath:] instead
	NSString* bundlePath = [[NSWorkspace sharedWorkspace] fullPathForApplication:@"Dropbox"] ;
	pid_t dropboxPid = [SSYOtherApper pidOfThisUsersProcessWithBundlePath:bundlePath] ;
	if (dropboxPid != 0) {
		// Dropbox app is running
        isIdle = NO ;
        NSDate* outerEndDate = [NSDate dateWithTimeIntervalSinceNow:timeout] ;
        do {
            
            // Take about 5 samples over a 10-second period
            NSTimeInterval const innerLoopPeriod = 10.0 ;
            CGFloat cpuPercent;
            CGFloat avgCpuUsage ;
            [self appendProgress:[NSString stringWithFormat:@"Will perform primary test for %0.3f seconds.\n", innerLoopPeriod]] ;
            ok = [self cpuUsageForInterval:innerLoopPeriod
                                       pid:dropboxPid
                             avgCpuUsage_p:&avgCpuUsage
                                   error_p:&error] ;
            
            if (ok) {
                [self appendProgress:[NSString stringWithFormat:
                                      @"\nPrimary Test average result = %0.3f%%.  Requires < %0.3f%%\n",
                                      avgCpuUsage,
                                      PRIMARY_TEST_THRESHOLD_AVERAGE_CPU_PERCENT]] ;
                if (avgCpuUsage < PRIMARY_TEST_THRESHOLD_AVERAGE_CPU_PERCENT) {
                    [self appendProgress:[NSString stringWithFormat:
                                          @"Primary test passed.  Will try %ld secondary tests with threshold %0.3f%%.\n",
                                          (long)COUNT_OF_SECONDARY_TESTS,
                                          SECONDARY_TEST_THRESHOLD_AVERAGE_CPU_PERCENT]] ;
                    NSInteger i ;
                    [self appendProgress: @"   Samples: "] ;
                    for (i=0; i<COUNT_OF_SECONDARY_TESTS; i++) {
                        // See if we can get three more in a row with CPU usage 0.25 percent or less
                        ok = [SSYOtherApper processPid:dropboxPid
                                               timeout:innerLoopPeriod  // better be much less than this, to get lots of samples
                                          cpuPercent_p:&cpuPercent
                                               error_p:error_p] ;
                        [self appendProgress:[NSString stringWithFormat:@"%0.1f%% ", cpuPercent]] ;
                        if (cpuPercent > 0.25) {
                            [self appendProgress:[NSString stringWithFormat:
                                                  @"Threshold exceeded during %ld/%ld secondary tests.\nBack out to primary test.",
                                                  (long)(i+1),
                                                  (long)COUNT_OF_SECONDARY_TESTS]] ;
                            break ;
                        }
                        
                        if (!ok) {
                            if (error_p) {
                                NSString* errorDescription = @"Error getting Dropbox CPU Usage during secondary test" ;
                                error = [NSError errorWithDomain:SSYDropboxIdlerErrorDomain
                                                            code:651107
                                                        userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                  errorDescription, NSLocalizedDescriptionKey,
                                                                  [NSNumber numberWithInteger:dropboxPid], @"PID",
                                                                  error, NSUnderlyingErrorKey,
                                                                  nil]] ;
                            }
                            break ;
                        }
                        
                        sleep(1.0) ;
                    }
                    
                    if (i==3) {
                        [self appendProgress:[NSString stringWithFormat:
                                              @"\nPassed %ld secondary tests\n", (long)COUNT_OF_SECONDARY_TESTS]] ;
                        isIdle = YES ;
                        break ;
                    }
                }
            }
            else {
                break ;
            }
        } while (([(NSDate*)[NSDate date] compare:outerEndDate] == NSOrderedAscending) && (isIdle == NO));
    }
    else {
        sleep(1) ;
    }
    
    if (isIdle_p) {
        *isIdle_p = isIdle ;
    }
    if (narrative_p) {
        NSMutableString* narrative = [[NSMutableString alloc] init] ;
        [narrative appendFormat:
         @"%@ %0.1f secs elapsed.  ",
         [[NSDate date] geekDateTimeString],
         -[startDate timeIntervalSinceNow]] ;
        if (ok) {
            [narrative appendString:@"No error.  Dropbox is "] ;
            if (!isIdle) {
                [narrative appendString:@"not "] ;
            }
            [narrative appendString:@"idle."] ;
        }
        else {
            [narrative appendFormat:@"Error occurred:\n%@", error] ;
        }
        [narrative appendString:@"\n"] ;
        [self appendProgress:narrative] ;
        
        *narrative_p = [NSString stringWithString:narrative] ;
        [narrative release] ;
    }
    if (error && error_p) {
        *error_p = error ;
    }
    
	return ok ;
}

@end
