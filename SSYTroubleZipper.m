#import "SSYTroubleZipper.h"
#import "NSFileManager+TempFile.h"
#import "SSYShellTasker.h"
#import "SSYAlert.h"
#import "SSYUuid.h"

NSString* const SSYTroubleZipperErrorDomain = @"SSYTroubleZipperErrorDomain" ;
NSString* const constKeySSYTroubleZipperURL = @"SSYTroubleZipperURL" ;

@interface  SSYTroubleZipper ()

@property (retain) NSURLDownload* download ;
@property (copy) NSString* destinationPath ;
@property BOOL downloadDone ;

@end

@implementation SSYTroubleZipper

@synthesize download = m_download ;
@synthesize destinationPath = m_destinationPath ;
@synthesize downloadDone = m_downloadDone ;

- (void)dealloc {
	[m_download release] ;
	[m_destinationPath release] ;
	
	[super dealloc] ;
}

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

- (id)init {
	self = [super init] ;
	if (self) {
		NSString* urlString = [[NSBundle mainBundle] objectForInfoDictionaryKey:constKeySSYTroubleZipperURL] ;
		if (urlString) {
			[self setDestinationPath:[[[NSFileManager defaultManager] temporaryFilePath] stringByAppendingPathExtension:@"zip"]] ;
            NSURL* url = [NSURL URLWithString:urlString] ;
            NSURLRequest* request = [NSURLRequest requestWithURL:url] ;
            NSURLDownload* download = [[NSURLDownload alloc] initWithRequest:request
                                                                    delegate:self] ;
            [self setDownload:download] ;
            [download release] ;
            [[self download] setDestination:[self destinationPath]
                             allowOverwrite:YES] ;
		}
		else {
			[self alertErrorCode:159425] ;
            [self release] ;
			self = nil ;
		}		
	}
	
	if (!self) {
		// See http://lists.apple.com/archives/Objc-language/2008/Sep/msg00133.html ...
		[SSYTroubleZipper alertErrorCode:159426] ;
		[super dealloc] ;
	}
	
	return self ;
}

- (void)downloadDidFinish:(NSURLDownload*)download {
	[self setDownloadDone:YES] ;	
}

- (void)       download:(NSURLDownload*)download
	   didFailWithError:(NSError *)error {
	[self alertErrorCode:159427] ;
	[self setDownloadDone:YES] ;
}

+ (void)troubleZipper {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init] ;

	SSYTroubleZipper* instance = [[SSYTroubleZipper alloc] init] ;

	while (![instance downloadDone] && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
																beforeDate:[NSDate distantFuture]]) {
	}
	
	NSError* error = nil ;
	NSString* directory = [[instance destinationPath] stringByDeletingLastPathComponent] ;
	// Create a subdirectory as a sibling of the destinationPath, 
	// and unzip into this subdirectory, because otherwise we
	// have no way to positively identify which extracted file
	// in the temporary directory is ours.
	NSString* extractionDirectory = [directory stringByAppendingPathComponent:[SSYUuid compactUuid]] ;

	BOOL ok = [[NSFileManager defaultManager] createDirectoryAtPath:extractionDirectory
										withIntermediateDirectories:YES
														 attributes:nil
															  error:&error] ;
	
	if (ok) {
		NSInteger result = [SSYShellTasker doShellTaskCommand:@"/usr/bin/unzip"
											  arguments:[NSArray arrayWithObjects:@"-o", @"-d", extractionDirectory, [instance destinationPath], nil]
											inDirectory:directory
											  stdinData:nil
										   stdoutData_p:NULL
										   stderrData_p:NULL
												timeout:5.0
												error_p:&error] ;
		if (result == 0) {
			NSArray* filenames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:extractionDirectory
																					 error:NULL] ;
			NSString* appFilename = nil ;
			for (NSString* filename in filenames) {
				if ([[filename pathExtension] isEqualToString:@"app"]) {
					appFilename = filename ;
				}
			}

			if (appFilename) {
				NSString* appleScriptAppPath = [extractionDirectory stringByAppendingPathComponent:appFilename] ;
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
	
	[[NSFileManager defaultManager] removeItemAtPath:[instance destinationPath]
											   error:NULL] ;

	[instance release] ;
	[pool release] ;
}

+ (void)getAndRun {
	[NSThread detachNewThreadSelector:@selector(troubleZipper)
							 toTarget:self
						   withObject:nil] ;
}

@end