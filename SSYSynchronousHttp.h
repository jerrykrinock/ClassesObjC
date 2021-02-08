#import <Cocoa/Cocoa.h>

extern NSString* const SSYSynchronousHttpErrorDomain ;

extern NSString* const SSYSynchronousHttpRequestUrlErrorKey ;
extern NSString* const SSYSynchronousHttpRequestHttpMethodErrorKey ;
extern NSString* const SSYSynchronousHttpRequestBodyErrorKey ;
extern NSString* const SSYSynchronousHttpRequestTimeoutErrorKey ;
extern NSString* const SSYSynchronousHttpReceivedDataErrorKey ;
/*!
 @brief    The result of an attempt to decode the received data to
 a string, using UTF8 decoding, if it is under 2048 bytes.
*/
extern NSString* const SSYSynchronousHttpReceivedStringErrorKey ;

enum SSYSynchronousHttpErrorDomainErrorCodes {
    SSYSynchronousHttpStateInitial = 23000,
    SSYSynchronousHttpStateWaiting = 23001,
	SSYSynchronousHttpStateSucceeded = 23002,
    SSYSynchronousHttpStateBadUrlString = 23004,
    SSYSynchronousHttpStateRedirected = 23010, // Not used at this time because we follow redirects
    SSYSynchronousHttpStateNeedUsernamePasswordToMakeCredential = 23020,
    SSYSynchronousHttpStateCredentialNotAccepted = 23025,
	SSYSynchronousHttpStateResponseNotHTTP = 23030,
    SSYSynchronousHttpStateTimeout = 23040,
	SSYSynchronousHttpStateCancelled = 23050,
	SSYSynchronousHttpStateBadHttpStatusCode = 23070,
	SSYSynchronousHttpStateCouldNotCreateRequestObject = 23085,
	SSYSynchronousHttpStateCouldNotCreateConnectionObject = 23090,
	SSYSynchronousHttpStateResponseOver299 = 100000,  // For internal use only
	SSYSynchronousHttpStateConnectionFailed = 200000  // For internal use only
} ;


@interface SSYSynchronousHttp : NSObject <NSURLSessionDelegate> {
	NSString* m_username ;
	NSString* m_password ;
	NSHTTPURLResponse* m_response ;
	NSMutableData* m_responseData ;
	NSError* m_underlyingError ;
	NSInteger m_connectionState ;
    dispatch_semaphore_t m_semaphore;
    NSURLSession* m_session;
}

/*!
 @brief    A wrapper around the Apple URL Loading System which blocks
 the invoking thread until a response is received, or timeout occurs.

 @param    url
 @param    httpMethod  
 @param    headers  A dictionary of additional headers which will be added
 to the request.  These should be percent-escape encoded, but because of the
 various character sets which should or should not be encoded, "we let you do it".
 The headers will be added as key=value, derived from the keys and values in the
 given dictionary, and of course all must be strings.
 @param    bodyString  
 @param    username  
 @param    password  
 @param    timeout  
 @param    userAgent  defaults to CFNetwork if nil
 @param    response_p  
 @param    receiveData_p  
 @param    error_p  Pointer which will, upon return, if an error
 occured and said pointer is not NULL, point to an NSError
 describing said error.  The error's domain will be
 SSYSynchronousHttpErrorDomain.  The error's code may be one of the
 enumerated values in SSYSynchronousHttpErrorDomainErrorCodes (1-99), 
 or one of the codes defined for NSURLErrorDomain in NSURLError.h (<0),
 or one of the HTTP Status Codes defined in the IETF's RFC 2616,
 http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html  (100-199).
 @result   YES if the operation completed successfully, otherwise NO.
 */
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
					  error_p:(NSError**)error_p ;
/*
 completionHandler:(void (^_Nonnull)(
                                     NSURLResponse* _Nullable response,
                                     NSData* _Nullable data,
                                     NSError* _Nullable error))completionHandler;
*/
@end
