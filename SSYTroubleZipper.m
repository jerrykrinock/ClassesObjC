#import "SSYTroubleZipper.h"
#import "NSFileManager+TempFile.h"
#import "SSYShellTasker.h"
#import "SSYAlert.h"
#import "SSYUuid.h"

NSString* const SSYTroubleZipperErrorDomain = @"SSYTroubleZipperErrorDomain" ;
NSString* const constKeySSYTroubleZipperURL = @"SSYTroubleZipperURL" ;

@interface SSYTroubleZipper()

@property (retain) dispatch_semaphore_t doneSemaphore;

@end


@implementation SSYTroubleZipper

@synthesize doneSemaphore;

#if !__has_feature(objc_arc)
- (void)dealloc {
    if (doneSemaphore) {
        dispatch_release(doneSemaphore);
    }
    
    [super dealloc];
}
#endif


+ (void)alertErrorCode:(NSInteger)code
	   underlyingError:(NSError*)error {
	NSString* msg = [NSString stringWithFormat:
					 @"Could not download, unzip, or run Trouble Zipper from %@",
					 [[NSBundle mainBundle] objectForInfoDictionaryKey:constKeySSYTroubleZipperURL]] ;
	error = [NSError errorWithDomain:SSYTroubleZipperErrorDomain
								code:code
							userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
									  msg, NSLocalizedDescriptionKey,
									  @"Try again, maybe later", NSLocalizedRecoverySuggestionErrorKey,
									  constKeySSYTroubleZipperURL, @"Info.plist key where URL expected",
									  error, NSUnderlyingErrorKey, // may be nil
									  nil]] ;
	[SSYAlert performSelectorOnMainThread:@selector(alertError:)
							   withObject:error
							waitUntilDone:NO] ;
}

- (void)alertErrorCode:(NSInteger)code
	   underlyingError:(NSError*)error {
	[SSYTroubleZipper alertErrorCode:code
					 underlyingError:error] ;
}

+ (void)alertErrorCode:(NSInteger)code {
	[self alertErrorCode:code
		 underlyingError:nil] ;
}

- (void)alertErrorCode:(NSInteger)code {
	[SSYTroubleZipper alertErrorCode:code] ;
}

+ (void)getAndRun {
    dispatch_queue_t aSerialQueue = dispatch_queue_create(
                                                          "com.sheepsystems.SSYTroubleZipper.getAndRun",
                                                          DISPATCH_QUEUE_SERIAL
                                                          );
    dispatch_async(aSerialQueue, ^{
        SSYTroubleZipper* instance = [[SSYTroubleZipper alloc] init];
        dispatch_semaphore_t doneSemaphore = dispatch_semaphore_create(0);
        instance.doneSemaphore = doneSemaphore;
        dispatch_release(doneSemaphore); // OK since .doneSemaphore is a retained property
        NSTimeInterval timeout = 20.0;
        [instance downloadAndRunWithTimeout:timeout];
        NSTimeInterval semaphoreTimeoutSeconds = (timeout + 2.0);
        dispatch_time_t semaphoreTimeout = dispatch_time(
                                                         DISPATCH_TIME_NOW,
                                                         semaphoreTimeoutSeconds * NSEC_PER_SEC);
        long result = dispatch_semaphore_wait(
                                              doneSemaphore,
                                              semaphoreTimeout);
        if (result != 0) {
            [instance alertErrorCode:159422];
        }
        
        [instance release] ;
    });
}

- (void)downloadAndRunWithTimeout:(NSTimeInterval) timeout{
    NSString* urlString = [[NSBundle mainBundle] objectForInfoDictionaryKey:constKeySSYTroubleZipperURL] ;
    if (urlString) {
        NSURL* url = [NSURL URLWithString:urlString];
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
        request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        request.timeoutInterval = timeout;
        dispatch_queue_t aSerialQueue = dispatch_queue_create(
                                                              "SSYTroubleZipper",
                                                              DISPATCH_QUEUE_SERIAL
                                                              );
        dispatch_async(aSerialQueue, ^{
            NSURLSessionDownloadTask* task = [[NSURLSession sharedSession] downloadTaskWithRequest:request
                                                                                 completionHandler:^(NSURL* _Nullable location,
                                                                                                     NSURLResponse* _Nullable response,
                                                                                                     NSError* _Nullable error) {
                if (location) {
                    NSURL* directory = [location URLByDeletingLastPathComponent];
                    /* If macOS 10.15+ you could use -[NSData decompressedDataUsingAlgorithm:error:] instead of this… */
                    NSInteger result = [SSYShellTasker doShellTaskCommand:@"/usr/bin/unzip"
                                                                arguments:[NSArray arrayWithObjects:@"-o", @"-d", directory.path, location.path, nil]
                                                              inDirectory:[location.path stringByDeletingLastPathComponent]
                                                                stdinData:nil
                                                             stdoutData_p:NULL
                                                             stderrData_p:NULL
                                                                  timeout:5.0
                                                                  error_p:&error] ;
                    if (result == 0) {
                        NSArray* fileUrls = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:directory
                                                                           includingPropertiesForKeys:nil
                                                                                              options:0
                                                                                                error:&error];
                        if (error == nil) {
                            NSURL* appUrl = nil ;
                            for (NSURL* aAppUrl in fileUrls) {
                                if ([[aAppUrl pathExtension] isEqualToString:@"app"]) {
                                    appUrl = aAppUrl ;
                                }
                            }
                            
                            if (appUrl) {
                                NSString* appleScriptAppPath = appUrl.path;
                                BOOL ok = [[NSWorkspace sharedWorkspace] launchApplication:appleScriptAppPath] ;
                                if (!ok) {
                                    [self alertErrorCode:159433
                                         underlyingError:error] ;
                                }
                            }
                            else {
                                [self alertErrorCode:159429] ;
                            }
                        }
                        else {
                            [self alertErrorCode:159430
                                 underlyingError:error] ;
                        }
                    }
                    else {
                        [self alertErrorCode:159431
                             underlyingError:error] ;
                    }
                    
                    [[NSFileManager defaultManager] removeItemAtPath:location.path
                                                               error:NULL] ;
                }

                if (error) {
                    [self alertErrorCode:159420
                     underlyingError:error];
                }
                
                dispatch_semaphore_signal(self.doneSemaphore);
            }];
            [task resume];
        });
    } else {
        [self alertErrorCode:159421];
    }
}

@end
