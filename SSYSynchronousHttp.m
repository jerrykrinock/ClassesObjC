#import "SSYSynchronousHttp.h"

NSString* const SSYSynchronousHttpErrorDomain = @"SSYSynchronousHttpErrorDomain" ;

NSString* const SSYSynchronousHttpRequestUrlErrorKey = @"Request's URL" ;
NSString* const SSYSynchronousHttpRequestHttpMethodErrorKey = @"Request's HTTP Method" ;
NSString* const SSYSynchronousHttpRequestBodyErrorKey = @"Request's body" ;
NSString* const SSYSynchronousHttpRequestTimeoutErrorKey = @"Request's Timeout (seconds)" ;
NSString* const SSYSynchronousHttpReceivedDataErrorKey = @"Received Data" ;
NSString* const SSYSynchronousHttpReceivedStringErrorKey = @"Received Data, UTF8 Decoded" ;

NSString* const constRunLoopModeSSYSynchronousHttp = @"com.sheepsystems.SSYSynchronousHttpRunLoopMode" ;

enum {
	constEnumSynchronousHttpBlocked,
	constEnumSynchronousHttpDone
} ;

#if 11
#warning Debug logging is on in SSYSynchronousHttp
#define SSY_SYNCHRONOUS_HTTP_DEBUG_LOGGING 1
#endif

@interface SSYSynchronousHttp ()

@property (copy) NSString* username ;
@property (copy) NSString* password ;
@property (retain) dispatch_semaphore_t semaphore;
@property (retain) NSHTTPURLResponse* response ;
@property (retain) NSData* responseData ;
@property (retain) NSError* underlyingError ;
@property (assign) NSInteger connectionState ;
@property (assign) BOOL isFinished;
@property (retain) NSURLSession* session;

@end


@implementation SSYSynchronousHttp

@synthesize username = m_username ;
@synthesize password = m_password ;
@synthesize response = m_response ;
@synthesize responseData = m_responseData ;
@synthesize underlyingError = m_underlyingError ;
@synthesize connectionState = m_connectionState ;

#if !__has_feature(objc_arc)
- (void)dealloc {
    if (m_semaphore) {
        dispatch_release(m_semaphore);
    }
	[m_username release] ;
	[m_password release] ;
	[m_response release] ;
	[m_responseData release] ;
	[m_underlyingError release] ;

	[super dealloc] ;
}
#endif

- (void)URLSession:(NSURLSession *)session
didBecomeInvalidWithError:(NSError *)error {
    [self setResponse:nil] ;
	// The following was commented out in BookMacster 1.7/1.6.8, because when
	// Diigo sends a throttling error it puts a "message" in the response data.
	// [self setResponseData:nil] ;
	[self setUnderlyingError:error] ;
	[self setConnectionState:SSYSynchronousHttpStateConnectionFailed];
    [self finish];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    /*SSYDBL*/ NSLog(@"Did complete with status code %ld error %@", ((NSHTTPURLResponse*)task.response).statusCode, error) ;
	if (((NSHTTPURLResponse*)task.response).statusCode >= 300) {
		[self setConnectionState:SSYSynchronousHttpStateResponseOver299] ;
	}
	else {
		[self setConnectionState:SSYSynchronousHttpStateSucceeded] ;
	}
	
	[self finish] ;
}

- (void)       URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
               newRequest:(NSURLRequest *)request
        completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    /*SSYDBL*/ NSLog(@"Will perform redirect");
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        // Probably this will be overwritten when connectionDidFinishLoading:
        // with the response from the redirect, but maybe in case the
        // redirect fails, this would be useful.  I don't know.
        [self setResponse:(NSHTTPURLResponse*)response] ;
    }
    if (completionHandler) {
        completionHandler(request);
    }
}

- (void)    URLSession:(NSURLSession *)session
   didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
     completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    
    NSURLProtectionSpace* protectionSpace = challenge.protectionSpace;
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    NSURLCredential* credential = nil;
    if (protectionSpace.authenticationMethod ==  NSURLAuthenticationMethodServerTrust) {
        //protectionSpace.host.contains("example.com")
        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    } else {
        NSString* username = [self username] ;
        NSString* password = [self password] ;
        
        if ([challenge previousFailureCount] > 2) {
            // Obviously our username+password is no good, so bail out.
            [self setConnectionState:SSYSynchronousHttpStateCredentialNotAccepted] ;
            [session invalidateAndCancel];
        }
        else if (username && password) {
            // NSLog(@"Responding to challenge with new credential.  username:%@ password:%@", username, password) ;
            NSURLCredential* credential = [NSURLCredential credentialWithUser:username
                                                                     password:password
                                                                  persistence:NSURLCredentialPersistenceNone] ;
            // Note: If persistence is set to NSURLCredentialPersistenceForSession, you'll never get this message
            // again and thus be unable to change the account for any given realm/protectionSpace without
            // relaunching the app.
            
            [[challenge sender] useCredential:credential
                   forAuthenticationChallenge:challenge] ;
        }
        else {
            // We don't handle an authentication challenge; we simply
            // return the fact and let our invoker handle it.  This is
            // the logical thing to do because, for example, when
            // requesting data or uploading with Google, sometimes we get
            // an authentication challenge and sometimes we don't,
            // depending on the request, and we have to detect the
            // need for login by other means.
            [self setConnectionState:SSYSynchronousHttpStateNeedUsernamePasswordToMakeCredential] ;
            [self finish];
        }
    }
    
    completionHandler(disposition, credential);
}

- (void)finish {
    /*SSYDBL*/ NSLog(@"Finished") ;
    if (self.semaphore) {
        dispatch_semaphore_signal(self.semaphore);
        self.semaphore = nil;
    }
    [self.session invalidateAndCancel];
    self.session = nil;
}

+ (BOOL)SSYSynchronousHttpUrl:(NSString*)urlString
				   httpMethod:(NSString*)httpMethod
					  headers:(NSDictionary*)headers
				   bodyString:(NSString*)bodyString 
					 username:(NSString*)username
					 password:(NSString*)password
					  timeout:(NSTimeInterval)timeout 
					userAgent:(NSString*)userAgent
				   response_p:(NSHTTPURLResponse**)response_p 
				receiveData_p:(NSData**)receiveData_p 
					  error_p:(NSError**)error_p {
	NSInteger connectionState = SSYSynchronousHttpStateInitial ;
	SSYSynchronousHttp* instance = nil ;
    NSMutableURLRequest* mutableRequest = nil ;

	// Apply the Johannnes Fahrenkrug workaround: Append a "#".  See:
	// http://www.springenwerk.com/2008/11/i-am-currently-building-iphone.html
	// (If that doesn't work, try replacing 'www' with 'blog')
	// This workaround fixes what I believe to be a bug in NSURLConnection that makes
	// it impossible to log out from a service such as del.icio.us and then log
	// back in as a different user.  You remain as the old user until you quit the
	// app/process.  It was very frustrating.
#if 11
#warning Bypassing Johannnes Fahrenkrug workaround in SSYSynchronousHttp
#else
	urlString = [urlString stringByAppendingString:@"#"] ;
#endif
	NSURL* url = [NSURL URLWithString:urlString] ;
	if (!url) {
		return SSYSynchronousHttpStateBadUrlString ;
	}
	
	//[url setProperty:[self userAgent] forKey:@"User-Agent"]; 
	// The above line does not seem to work; when I ask for "Safari", 
	// I still see "CFNetwork" in tcpflow.  However, setting
	// the User-Agent in the request, below, seems to work.
	NSURLRequest* request = [NSURLRequest requestWithURL:url
											 cachePolicy:NSURLRequestReloadIgnoringCacheData
										 timeoutInterval:timeout] ;
    if (!request) {
        return SSYSynchronousHttpStateCouldNotCreateRequestObject ;
    }


	mutableRequest = [request mutableCopy] ;
	if (userAgent) {
		[mutableRequest setValue:userAgent
			  forHTTPHeaderField:@"User-Agent"];
	}
	if (httpMethod) {
		[mutableRequest setHTTPMethod:httpMethod] ;
	}
	if (bodyString) {
		[mutableRequest setHTTPBody:[bodyString dataUsingEncoding:NSUTF8StringEncoding]] ;
	}
	
	for (NSString* key in headers) {
		NSString* value = [headers objectForKey:key] ;
		[mutableRequest setValue:value
			  forHTTPHeaderField:key] ;
	}
	
	// [mutableRequest setTimeoutInterval:_timeout] ; // This does not work.
	[mutableRequest setCachePolicy:NSURLRequestReloadIgnoringCacheData] ;
	[mutableRequest setHTTPShouldHandleCookies:YES] ;
	// This will cause a cookie to be set when we log in to a site such as Google
	// Possibly the above line is not needed since YES is probably default
	// But the default behavior is not documented.
	
#if SSY_SYNCHRONOUS_HTTP_DEBUG_LOGGING
	NSLog(@"Request URL:\n%@", [[mutableRequest URL] absoluteString]) ;
	NSLog(@"HTTP Method: %@", [mutableRequest HTTPMethod]) ;
	NSLog(@"All HTTP Request Headers:\n%@", [mutableRequest allHTTPHeaderFields]) ;
#endif

	instance = [[SSYSynchronousHttp alloc] init] ;
	
	[instance setUsername:username] ;
	[instance setPassword:password] ;
	
	// Using Quinn "The Eskimo"'s "Synthetic Synchronous" technique…
	
	// Initialize a place for received data
	[instance setResponseData:[NSMutableData data]] ;
	
	// So our run loop will not exit immediately,
	[instance setConnectionState:SSYSynchronousHttpStateWaiting] ;
	
    instance.semaphore = dispatch_semaphore_create(0);
    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:instance
                                                     delegateQueue:nil];
    /* Of course, the actual work needs to be done on a secondary thread since
     we are going to block this thread with dispatch_semaphore_wait(). */
    dispatch_queue_t aSerialQueue = dispatch_queue_create(
                                                          "SSYSynchronousHttp Worker",
                                                          DISPATCH_QUEUE_SERIAL
                                                          ) ;

    dispatch_async(aSerialQueue, ^{
        /*SSYDBL*/ NSLog(@"Creating task with request %@", request) ;
        NSURLSessionDataTask* task = [session dataTaskWithRequest:mutableRequest
                                                completionHandler:^(NSData * _Nullable data,
                                                                    NSURLResponse * _Nullable response,
                                                                    NSError * _Nullable error) {
#if SSY_SYNCHRONOUS_HTTP_DEBUG_LOGGING
            NSLog(@"Completion Handler got:\n*** response: %@\n*** error: %@\n*** data: %@", response, error, data);
#endif
            instance.response = (NSHTTPURLResponse*)response;
            instance.responseData = data;

            if (((NSHTTPURLResponse*)response).statusCode >= 300) {
                [instance setConnectionState:SSYSynchronousHttpStateResponseOver299] ;
            }
            else {
                [instance setConnectionState:SSYSynchronousHttpStateSucceeded] ;
            }

            if (!error) {
                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                    [instance setResponse:(NSHTTPURLResponse*)response] ;
                }
                else {
                    [instance setConnectionState:SSYSynchronousHttpStateResponseNotHTTP] ;
                }
            } else {
                [instance setResponse:nil] ;
                // The following was commented out in BookMacster 1.7/1.6.8, because when
                // Diigo sends a throttling error it puts a "message" in the response data.
                // [self setResponseData:nil] ;
                [instance setUnderlyingError:error] ;
                [instance setConnectionState:SSYSynchronousHttpStateConnectionFailed] ;
            }
            
            [instance finish];
        }];
        [task resume];
        /*SSYDBL*/ NSLog(@"Did resume task %@", task) ;
    });
    
    NSTimeInterval semaphoreTimeoutSeconds = (timeout + 2.0);
    dispatch_time_t semaphoreTimeout = dispatch_time(
                                                     DISPATCH_TIME_NOW,
                                                     semaphoreTimeoutSeconds * NSEC_PER_SEC);
    long result = dispatch_semaphore_wait(
                                          instance.semaphore,
                                          semaphoreTimeout);
    if (result != 0) {
        NSLog(@"Error 382-9773 Result=%ld indicates timeout after %0.2f secs.  Session timeout of %0.2f should have timed out first",
              result,
              semaphoreTimeoutSeconds,
              timeout);
    }

#if !__has_feature(objc_arc)
    dispatch_release(instance.semaphore) ;
    [mutableRequest release] ;  // Prior to 20100312, was -autorelease
#endif
    
    
	// Set output variables and exit
	if (response_p) {
#if !__has_feature(objc_arc)
        [[[instance response] retain] autorelease];
#endif
        // The retain] autorelease] above actually does something!
        // Note that *hdlResponse is "owned" by instance, which we
        // are going to release before the end of this method.
        // It is not in the autorelease pool, and therefore will
        // disappear when we release instance.
		*response_p = [instance response];
		
		connectionState = [instance connectionState];
	}
	if (receiveData_p) {
		NSData* responseData = [instance responseData] ;
		if ([responseData length] > 0) {
            *receiveData_p = [responseData copy] ;
#if !__has_feature(objc_arc)
            [*receiveData_p autorelease];
            // copy to make it immutable, and also to put it into the
            // autorelease pool so it does not go away when we release 'instance',
            // which is its only owner
#endif
		}
		
		connectionState = [instance connectionState] ;
	}

end:;
    
#if !__has_feature(objc_arc)
	[mutableRequest release] ;
#endif
    
	BOOL serverError = NO ;

	if (
		(error_p != nil)
		&&
		(connectionState != SSYSynchronousHttpStateSucceeded)
		) {
		NSString* cuz ;
		switch (connectionState) {
			case SSYSynchronousHttpStateInitial:
				cuz = @"We never even tried." ;
				break ;
			case SSYSynchronousHttpStateWaiting:
				cuz = @"Connection is still waiting." ;
				break ;
			case SSYSynchronousHttpStateBadUrlString:
				cuz = @"We could not create a valid URL from given string." ;
				break ;
			case SSYSynchronousHttpStateNeedUsernamePasswordToMakeCredential:
				cuz = NSLocalizedString(@"accountInfoMissing", nil) ;
				break ;
            case SSYSynchronousHttpStateCredentialNotAccepted:
            {
                NSString* format = NSLocalizedString(@"accountInfoBadX", nil);
                cuz = [NSString stringWithFormat:
                       format,
                       username];
				break ;
            }
			case SSYSynchronousHttpStateResponseNotHTTP:
				cuz = @"Response received was not an HTTP response." ;
				break ;
			case SSYSynchronousHttpStateCouldNotCreateRequestObject:
				cuz = @"We could not create a request object." ;
				break ;
			case SSYSynchronousHttpStateCouldNotCreateConnectionObject:
				cuz = @"We could not create a connection object." ;
				break ;
			case SSYSynchronousHttpStateCancelled:
				cuz = @"The connection was cancelled before it completed." ;
				break ;
			case SSYSynchronousHttpStateResponseOver299:
            {
				connectionState = [[instance response] statusCode] ;
				if (connectionState >= 500) {
					serverError = YES ;
				}
				NSString* cuzHttp = [NSHTTPURLResponse localizedStringForStatusCode:[[instance response] statusCode]] ;
				cuz = [NSString stringWithFormat:
					   @"We received an HTTP Status Code %ld, which is in the range indicating '%@'.",
					   (long)connectionState,
					   cuzHttp] ;
				if (connectionState > 519) {
					cuz = [cuz stringByAppendingString:@"  However, this exact status code is not defined "
						   @"in the standards published by the Internet Engineering Task Force."] ;
				}
				break ;
            }
			case SSYSynchronousHttpStateConnectionFailed:
				cuz = @"The connection failed." ;
				connectionState = [[instance underlyingError] code] ;
				switch ([[instance underlyingError] code]) {
					case NSURLErrorCancelled:
						cuz = @"It was cancelled." ;
						break ;
					case NSURLErrorBadURL:
						cuz = @"It has a bad URL." ;
						break ;
					case NSURLErrorTimedOut:
						cuz = @"It took longer than the timeout which was alotted." ;
						break ;
					case NSURLErrorUnsupportedURL:
						cuz = @"It has an unsupported URL." ;
						break ;
					case NSURLErrorCannotFindHost:
						cuz = @"The host could not be found." ;
						break ;
					case NSURLErrorCannotConnectToHost:
						cuz = @"The host would not let us establish a connection." ;
						break ;
					case NSURLErrorNetworkConnectionLost:
						cuz = @"We established a connection but it was lost." ;
						break ;
					case NSURLErrorDNSLookupFailed:
						cuz = @"Domain name server (DNS) lookup failed." ;
						break ;
					case NSURLErrorHTTPTooManyRedirects:
						cuz = @"We received too many redirects from the server while processing the request." ;
						break ;
					case NSURLErrorResourceUnavailable:
						cuz = @"The requested resource is not available." ;
						break ;
					case NSURLErrorNotConnectedToInternet:
						cuz = @"This computer appears to not have an internet connection." ;
						break ;
					case NSURLErrorRedirectToNonExistentLocation:
						cuz = @"We were redirected to a nonexistent location." ;
						break ;
					case NSURLErrorBadServerResponse:
						cuz = @"We got a bad response from the server." ;
						break ;
					case NSURLErrorUserCancelledAuthentication:
						cuz = @"The user cancelled when asked for authentication." ;
						break ;
					case NSURLErrorUserAuthenticationRequired:
						cuz = @"User authentication is required." ;
						break ;
					case NSURLErrorZeroByteResource:
						cuz = @"The requested resource contains no data." ;
						break ;
					case NSURLErrorCannotDecodeRawData:
						cuz = @"We could not decode the raw data." ;
						break ;
					case NSURLErrorCannotDecodeContentData:
						cuz = @"We could not decode the content." ;
						break ;
					case NSURLErrorCannotParseResponse:
						cuz = @"We could not parse the response." ;
						break ;
					case NSURLErrorFileDoesNotExist:
						cuz = @"The requested file does not exist." ;
						break ;
					case NSURLErrorFileIsDirectory:
						cuz = @"The requested file is in fact a directory." ;
						break ;
					case NSURLErrorNoPermissionsToReadFile:
						cuz = @"We lack sufficient permissions to read the requested file." ;
						break ;
					case NSURLErrorDataLengthExceedsMaximum:
						cuz = @"The length of the requested data exceeds the limit.." ;
						break ;
					case NSURLErrorSecureConnectionFailed:
						cuz = @"We could not establish a secure connection." ;
						break ;
					case NSURLErrorServerCertificateHasBadDate:
						cuz = @"The server's SSL certificate appears to have expired." ;
						break ;
					case NSURLErrorServerCertificateUntrusted:
						cuz = @"The server's SSL certificate is not trusted." ;
						break ;
					case NSURLErrorServerCertificateHasUnknownRoot:
						cuz = @"The server's SSL certificate has an unknown root." ;
						break ;
					case NSURLErrorServerCertificateNotYetValid:
						cuz = @"The server's SSL certificate is not yet valid." ;
						break ;
					case NSURLErrorClientCertificateRejected:
						cuz = @"The server rejected our client certificate." ;
						break ;
					case NSURLErrorCannotLoadFromNetwork:
						cuz = @"We could not load from the network." ;
						break ;
					case NSURLErrorCannotCreateFile:
						cuz = @"We could not create a file." ;
						break ;
					case NSURLErrorCannotOpenFile:
						cuz = @"We could not open a file." ;
						break ;
					case NSURLErrorCannotCloseFile:
						cuz = @"We could not close a file." ;
						break ;
					case NSURLErrorCannotWriteToFile:
						cuz = @"We could not write to a file." ;
						break ;
					case NSURLErrorCannotRemoveFile:
						cuz = @"We could not remove a file." ;
						break ;
					case NSURLErrorCannotMoveFile:
						cuz = @"We could not move a file." ;
						break ;
					case NSURLErrorDownloadDecodingFailedMidStream:
						cuz = @"Decoding the downloaded data failed in midstream." ;
						break ;
					case NSURLErrorDownloadDecodingFailedToComplete:
						cuz = @"Decoding the downloaded data failed to complete." ;
						break ;
					case NSURLErrorUnknown:
						cuz = @"There was an unknown error." ;
						break ;
				}
				break ;
			default:
				cuz = [NSString stringWithFormat:@"The connection terminated in an unknown state=%ld.", (long)connectionState] ;
				break ;
		}
		
        NSMutableDictionary* userInfo = [NSMutableDictionary new];
    
        NSString* host = [url host] ;
        NSString* toHost = @"" ;
        if (host) {
            toHost = [NSString stringWithFormat:@" to %@", host] ;
        }
        NSString* desc = [NSString stringWithFormat:
                          @"SSYSynchronousHTTP Request%@ failed",
                          toHost];
        [userInfo setObject:desc
                     forKey:NSLocalizedDescriptionKey];
        [userInfo setValue:cuz
                    forKey:NSLocalizedFailureReasonErrorKey];
        [userInfo setValue:urlString
                    forKey:SSYSynchronousHttpRequestUrlErrorKey];
        [userInfo setValue:httpMethod
                     forKey:SSYSynchronousHttpRequestHttpMethodErrorKey];
        [userInfo setValue:bodyString
                    forKey:SSYSynchronousHttpRequestBodyErrorKey];
        [userInfo setValue:[NSNumber numberWithDouble:timeout]
                    forKey:SSYSynchronousHttpRequestTimeoutErrorKey];
        [userInfo setValue:[instance underlyingError]
                    forKey:NSUnderlyingErrorKey];
        // Some people, e.g. Yahoo/Delicious, put error information into the
        // receive data when the response is, e.g., 401 or 999.
        [userInfo setValue:[instance responseData]
                    forKey:SSYSynchronousHttpReceivedDataErrorKey];
		if ([instance responseData] && [[instance responseData] length] < 2048) {
            NSString* stringData = [[NSString alloc] initWithData:[instance responseData] encoding:NSUTF8StringEncoding];
			if (!stringData) {
                stringData = [[NSString alloc] initWithFormat:
                @"%ld bytes, failed UTF8 encoding",
                (long)[[instance responseData] length]] ;
			}
            [userInfo setObject:stringData
             forKey:SSYSynchronousHttpReceivedStringErrorKey];
#if !__has_feature(objc_arc)
            [stringData release];
#endif
            
        }
		
		if (serverError) {
			NSString* msg = [NSString stringWithFormat:
							 @"Retry later."];
            [userInfo setObject:msg
                         forKey:NSLocalizedRecoverySuggestionErrorKey];
		}
        
        NSDictionary* userInfoCopy = [userInfo copy];
        *error_p = [NSError errorWithDomain:SSYSynchronousHttpErrorDomain
                                       code:connectionState
                                   userInfo:userInfoCopy];
#if !__has_feature(objc_arc)
        [userInfo release];
#endif
	}

#if !__has_feature(objc_arc)
    [instance release] ;
#endif
	
	return (connectionState == SSYSynchronousHttpStateSucceeded) ;
}

@end
