#import "SSYSynchronousHttp.h"
#import "NSError+SSYAdds.h"
#import "NSString+Data.h"
#import "NSString+LocalizeSSY.h"
#import "NSString+MorePaths.h"

NSString* const SSYSynchronousHttpErrorDomain = @"SSYSynchronousHttpErrorDomain" ;

NSString* const SSYSynchronousHttpRequestUrlErrorKey = @"Request's URL" ;
NSString* const SSYSynchronousHttpRequestHttpMethodErrorKey = @"Request's HTTP Method" ;
NSString* const SSYSynchronousHttpRequestBodyErrorKey = @"Request's body" ;
NSString* const SSYSynchronousHttpRequestTimeoutErrorKey = @"Request's Timeout (seconds)" ;
NSString* const SSYSynchronousHttpReceivedDataErrorKey = @"Received Data" ;
NSString* const SSYSynchronousHttpReceivedStringErrorKey = @"Received Data, UTF8 Decoded" ;

#if USE_MY_OLD_CODE_INSTEAD_OF_QUINNS_SYNTHETIC_SYNCHRONOUS
#else
NSString* const constRunLoopModeSSYSynchronousHttp = @"com.sheepsystems.SSYSynchronousHttpRunLoopMode" ;
#endif

enum {
	constEnumSynchronousHttpBlocked,
	constEnumSynchronousHttpDone
} ;


@interface SSYSynchronousHttp ()

@property (copy) NSString* username ;
@property (copy) NSString* password ;
#if USE_MY_OLD_CODE_INSTEAD_OF_QUINNS_SYNTHETIC_SYNCHRONOUS
@property (retain) NSConditionLock* lock ;
#endif
@property (retain) NSHTTPURLResponse* response ;
@property (retain) NSMutableData* responseData ;
@property (retain) NSError* underlyingError ;
@property (assign) NSInteger connectionState ;

@end


@implementation SSYSynchronousHttp

@synthesize username = m_username ;
@synthesize password = m_password ;
#if USE_MY_OLD_CODE_INSTEAD_OF_QUINNS_SYNTHETIC_SYNCHRONOUS
@synthesize lock = m_lock ;
#endif
@synthesize response = m_response ;
@synthesize responseData = m_responseData ;
@synthesize underlyingError = m_underlyingError ;
@synthesize connectionState = m_connectionState ;

- (void)dealloc {
	[m_username release] ;
	[m_password release] ;
#if USE_MY_OLD_CODE_INSTEAD_OF_QUINNS_SYNTHETIC_SYNCHRONOUS
	[m_lock release] ;
#endif
	[m_response release] ;
	[m_responseData release] ;
	[m_underlyingError release] ;
	
	[super dealloc] ;
}

- (void)endConnection:(NSURLConnection*)connection {
	[connection cancel] ;
	[connection unscheduleFromRunLoop:[NSRunLoop currentRunLoop]
							  forMode:NSDefaultRunLoopMode] ;
}

- (void)  connection:(NSURLConnection*)connection
  didReceiveResponse:(NSURLResponse*)response {
	// It would be nice to read Content-Length here, but unfortunately I always get -1 when
	// talking to del.icio.us.  I presume this is because they don't put a
	// "Content-Length" in their header.  Oh, well.
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
		[self setResponse:(NSHTTPURLResponse*)response] ;
	}
	else {
		[self setConnectionState:SSYSynchronousHttpStateResponseNotHTTP] ;
		[self endConnection:connection] ;
	}

	[[self responseData] setLength:0] ;
}

- (void)connection:(NSURLConnection *)connection
	didReceiveData:(NSData *)data {
	[[self responseData] appendData:data] ;
}

- (void)connection:(NSURLConnection*)connection
  didFailWithError:(NSError*)error {
	[self setResponse:nil] ;
	// The following was commented out in BookMacster 1.7/1.6.8, because when
	// Diigo sends a throttling error it puts a "message" in the response data.
	// [self setResponseData:nil] ;
	[self setUnderlyingError:error] ;
	[self setConnectionState:SSYSynchronousHttpStateConnectionFailed] ;
	[self endConnection:connection] ;	
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
	if ([[self response] statusCode] >= 300) {
		[self setConnectionState:SSYSynchronousHttpStateResponseOver299] ;
	}
	else {
		[self setConnectionState:SSYSynchronousHttpStateSucceeded] ;
	}
	
	[self endConnection:connection] ;
}

-(NSURLRequest *)connection:(NSURLConnection *)connection
			willSendRequest:(NSURLRequest *)request
		   redirectResponse:(NSURLResponse *)redirectResponse {
    if ([redirectResponse isKindOfClass:[NSHTTPURLResponse class]]) {
		// Probably this will be overwritten when connectionDidFinishLoading:
		// with the response from the redirect, but maybe in case the
		// redirect fails, this would be useful.  I don't know.
		[self setResponse:(NSHTTPURLResponse*)redirectResponse] ;
	}
	
	return request ;
}

- (void)                 connection:(NSURLConnection *)connection
  didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	// This method is never invoked under Tiger, but they fixed it in Leopard.
	// In Tiger, instead of this, they use the default credential set in,
	// for example -[DeliciousTalker tryPayload].
	NSString* username = [self username] ;
	NSString* password = [self password] ;
	
	if ([challenge previousFailureCount] > 2) {
		// Obviously our username+password is no good, so bail out.
		[self setConnectionState:SSYSynchronousHttpStateCredentialNotAccepted] ;
		[self endConnection:connection] ;
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
		[self endConnection:connection] ;
	}	
}


- (void)               connection:(NSURLConnection *)connection
 didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
}

-(NSCachedURLResponse *)connection:(NSURLConnection *)connection
				 willCacheResponse:(NSCachedURLResponse *)cachedResponse {
	return cachedResponse ;
}

#if USE_MY_OLD_CODE_INSTEAD_OF_QUINNS_SYNTHETIC_SYNCHRONOUS

/*!
 @details  Method which makes the connection in a secondary thread
*/
- (void)connectWithRequest:(NSURLRequest*)request {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init] ; 
	
	[[self lock] lock] ;

	// Initialize a place for received data
	[self setResponseData:[NSMutableData data]] ;
	
	// So our run loop will not exit immediately,
	[self setConnectionState:SSYSynchronousHttpStateWaiting] ;

	// Make the connection
	NSURLConnection* connection = [NSURLConnection connectionWithRequest:request
																delegate:self] ;
	if (!connection) {
		[self setConnectionState:SSYSynchronousHttpStateCouldNotCreateConnectionObject] ;
		goto end ;
	}
	
	NSRunLoop* runLoop = [NSRunLoop currentRunLoop] ;
	
	while (
		   ([self connectionState] == SSYSynchronousHttpStateWaiting)
		   &&
		   [runLoop runMode:NSDefaultRunLoopMode      
				 beforeDate:[NSDate distantFuture]]
		) {
	}
	/* Although the above is fairly well recommended in the Threading Programming Guide
	 in the section on Run Loops, there is a contrary opinion:
	 On 2009 Oct 06, at 01:55, Keith Duncan wrote to macnetworkprog@lists.apple.com:
	 
	 That's not the best way to solve this, pulsing the run loop won't let the thread go to sleep
	 and will burn CPU depending on how granular your interval. It's better to run the loop
	 unconditionally, then stop it explicitly when you want to exit the loop, I use CFRunLoop for
	 this as it has a stop function.
	 
	 Run the current loop using CFRunLoopRun(), then stop it using CFRunLoopStop(). This will guarantee that the loop exits.
	 */
	
	[[self lock] unlockWithCondition:constEnumSynchronousHttpDone] ;
	
end:	
	[pool release] ;
}	
#endif

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
	SSYSynchronousHttp *instance = nil ;
	
	// Apply the Johannnes Fahrenkrug workaround: Append a "#".  See:
	// http://www.springenwerk.com/2008/11/i-am-currently-building-iphone.html
	// (If that doesn't work, try replacing 'www' with 'blog')
	// This workaround fixes what I believe to be a bug in NSURLConnection that makes
	// it impossible to log out from a service such as del.icio.us and then log
	// back in as a different user.  You remain as the old user until you quit the
	// app/process.  It was very frustrating.
#if 0
#warning Bypassing Johannnes Fahrenkrug workaround in SSYSynchronousHttp
#else
	urlString = [urlString stringByAppendingString:@"#"] ;
#endif
	NSURL* url = [NSURL URLWithString:urlString] ;
	if (!url) {
		connectionState = SSYSynchronousHttpStateBadUrlString ;
		goto end ;
	}	
	
	//[url setProperty:[self userAgent] forKey:@"User-Agent"]; 
	// The above line does not seem to work; when I ask for "Safari", 
	// I still see "CFNetwork" in tcpflow.  However, setting
	// the User-Agent in the request, below, seems to work.
	NSURLRequest* request = [NSURLRequest requestWithURL:url
											 cachePolicy:NSURLRequestReloadIgnoringCacheData
										 timeoutInterval:timeout] ;
	
	NSMutableURLRequest *mutableRequest = [request mutableCopy] ;
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
	
#if 0
#warning Logging SSYSynchronousHttp request details
	NSLog(@"Request URL:\n%@", [[mutableRequest URL] absoluteString]) ;
	NSLog(@"HTTP Method: %@", [mutableRequest HTTPMethod]) ;
	NSLog(@"All HTTP Request Headers:\n%@", [mutableRequest allHTTPHeaderFields]) ;
	NSLog(@"Request Body:\n%@", [NSString stringWithDataUTF8:[mutableRequest HTTPBody]]) ;
#endif

	instance = [[SSYSynchronousHttp alloc] init] ;
	
	if (!mutableRequest) {
		connectionState = SSYSynchronousHttpStateCouldNotCreateRequestObject ;
		goto end ;
	}

	[instance setUsername:username] ;
	[instance setPassword:password] ;
	
#if USE_MY_OLD_CODE_INSTEAD_OF_QUINNS_SYNTHETIC_SYNCHRONOUS
#warning SSYSynchronousHttp is using my old code
	NSConditionLock* lock = [[NSConditionLock alloc] initWithCondition:constEnumSynchronousHttpBlocked] ;
	[instance setLock:lock] ;
	[lock release] ;

	[NSThread detachNewThreadSelector:@selector(connectWithRequest:)
							 toTarget:instance
						   withObject:mutableRequest] ;
	
	// Will block here:
	[lock lockWhenCondition:constEnumSynchronousHttpDone] ;
	[lock unlock] ;
#else
	// Using Quinn "The Eskimo"'s "Synthetic Synchronous" technique…
	
	// Initialize a place for received data
	[instance setResponseData:[NSMutableData data]] ;
	
	// So our run loop will not exit immediately,
	[instance setConnectionState:SSYSynchronousHttpStateWaiting] ;
	
	// Make the connection
	NSRunLoop* runLoop = [NSRunLoop currentRunLoop] ;
	
	NSURLConnection * connection = [[NSURLConnection alloc] initWithRequest:mutableRequest
																   delegate:instance
														   startImmediately:NO] ;
	if (!connection) {
		[instance setConnectionState:SSYSynchronousHttpStateCouldNotCreateConnectionObject] ;
		goto end ;
	}
	
	[connection scheduleInRunLoop:runLoop
						  forMode:constRunLoopModeSSYSynchronousHttp] ;
	[connection start] ;
	while (
		   ([instance connectionState] == SSYSynchronousHttpStateWaiting)
		   &&
		   [runLoop runMode:constRunLoopModeSSYSynchronousHttp      
				 beforeDate:[NSDate distantFuture]]
		   ) {
	}
	
	[connection release] ;
#endif
	
	[mutableRequest release] ;
	
	// Set output variables and exit
	if (response_p) {
		*response_p = [[[instance response] retain] autorelease] ;
		// The retain] autorelease] above actually does something!
		// Note that *hdlResponse is "owned" by instance, which we
		// are going to release before the end of this method.
		// It is not in the autorelease pool, and therefore will 
		// disappear when we release instance.
		
		connectionState = [instance connectionState] ;
	}
	if (receiveData_p) {
		NSData* responseData = [instance responseData] ;
		if ([responseData length] > 0) {
			*receiveData_p = [[responseData copy] autorelease] ;
			// copy to make it immutable, and also to put it into the
			// autorelease pool so it does not go away when we release 'instance',
			// which is its only owner
		}
		
		connectionState = [instance connectionState] ;
	}

end:;
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
				cuz = [NSString localize:@"accountInfoMissing"] ;
				break ;
			case SSYSynchronousHttpStateCredentialNotAccepted:
				cuz = [NSString localizeFormat:
					   @"accountInfoBadX",
					   username] ;
				break ;
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
				connectionState = [[instance response] statusCode] ;
				if (connectionState >= 500) {
					serverError = YES ;
				}
				NSString* cuzHttp = [NSHTTPURLResponse localizedStringForStatusCode:[[instance response] statusCode]] ;
				cuz = [NSString stringWithFormat:
					   @"We received an HTTP Status Code %d, which is in the range indicating '%@'.",
					   connectionState,
					   cuzHttp] ;
				if (connectionState > 519) {
					cuz = [cuz stringByAppendingString:@"  However, this exact status code is not defined "
						   @"in the standards published by the Internet Engineering Task Force."] ;
				}
				break ;
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
				cuz = [NSString stringWithFormat:@"The connection terminated in an unknown state.", connectionState] ;
				break ;
		}
		NSString* host = [url host] ;
		NSString* toHost = @"" ;
		if (host) {
			toHost = [NSString stringWithFormat:@" to %@", host] ;
		}
		
		NSString* desc = [NSString localizeFormat:
						  @"failedX",
						  [NSString stringWithFormat:
						   @"HTTP Request%@",
						   toHost]] ;
		
		*error_p = [NSError errorWithDomain:SSYSynchronousHttpErrorDomain
									   code:connectionState
								   userInfo:nil] ;
		*error_p = [*error_p errorByAddingLocalizedDescription:desc] ;
		*error_p = [*error_p errorByAddingLocalizedFailureReason:cuz] ;
		*error_p = [*error_p errorByAddingUserInfoObject:urlString
												  forKey:SSYSynchronousHttpRequestUrlErrorKey] ;
		*error_p = [*error_p errorByAddingUserInfoObject:httpMethod
												  forKey:SSYSynchronousHttpRequestHttpMethodErrorKey] ;
		*error_p = [*error_p errorByAddingUserInfoObject:bodyString
												  forKey:SSYSynchronousHttpRequestBodyErrorKey] ;
		*error_p = [*error_p errorByAddingUserInfoObject:[NSNumber numberWithDouble:timeout]
												  forKey:SSYSynchronousHttpRequestTimeoutErrorKey] ;
		*error_p = [*error_p errorByAddingUnderlyingError:[instance underlyingError]] ;
		// Some people, e.g. Yahoo/Delicious, put error information into the
		// receive data when the response is, e.g., 401 or 999.
		*error_p = [*error_p errorByAddingUserInfoObject:[instance responseData]
												  forKey:SSYSynchronousHttpReceivedDataErrorKey] ;
		if ([instance responseData] && [[instance responseData] length] < 2048) {
			NSString* stringData = [NSString stringWithDataUTF8:[instance responseData]] ;
			if (!stringData) {
				stringData = [NSString stringWithFormat:
							  @"%d bytes, failed UTF8 decoding",
							  [[instance responseData] length]] ;
			}
			*error_p = [*error_p errorByAddingUserInfoObject:stringData
													  forKey:SSYSynchronousHttpReceivedStringErrorKey] ;
		}
		
		if (serverError) {
			NSString* msg = [NSString stringWithFormat:
							 @"Retry later."] ;
			*error_p = [*error_p errorByAddingLocalizedRecoverySuggestion:msg] ;
		}
	}

	[instance release] ;
	
	return (connectionState == SSYSynchronousHttpStateSucceeded) ;
}

@end