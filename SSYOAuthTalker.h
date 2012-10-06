#import <Cocoa/Cocoa.h>

extern NSString* const constPathOAuth ;

/*!
 @brief    Provides two levels of identifier which are used
 by SSYOAuthTalker to create a keychain service identifier

 @details  The two methods in this protocol could have been
 instance variables in SSYOAuthTalker.  However, they may
 not be known when SSYOAuthTalker is initially created
 to access a new account.  See, for example, this thread:
 http://developer.yahoo.net/forum/index.php?showtopic=5011&hl=krinock
 in Yahoo! Developer Network . YDN Forums . Y!OS . OAuth, date 20100323.
 
 So why not just set as ivars when they become known?
 Well, OAuth is so complicated, and I figure most apps
 are going to have an object which contains the account
 information which will conform to this protocol.  So rather
 than having redundant instance variables in two different
 objects, it should be less buggy for SSYOAuthTalker to
 only access the real variable via this delegation.
*/
@protocol SSYOAuthAccounter

/*!
 @brief    Lower-level identifier
 
 @details  Equals profileName in BookMacster
 */
- (NSString*)accountName ;

@optional

/*!
 @brief    Optional Upper-level identifier, typically identifies the
 the third-party app which the current app accesses using OAuth,
 for apps which may access more than one, or just want to be concise.
 
 @details  Equals extoreClass in BookMacster
 */
- (NSString*)serviceName ;

@end


/*!
 @brief    A name for a notification which you can register an 
 SSYOAuth instance to observe, invoking processOAuthInfo:, and
 program your app's URL handler to send when an OAuth authorization
 callback is received from the web browser.

 @details  SSYOAuthTalker does not refer to this internally.  You
 can use it as described in the brief.  Note that an SSYOAuthTalker
 sends [[NSNotificationCenter defaultCenter] removeObserver:self]
 before deallocating itself, in case the notification is posted
 after it is deallocated.
*/
extern NSString* const constNoteGotOAuthInfo ;

extern NSString* const SSYOAuthTalkerErrorDomain ;
enum SSYOAuthTalkerErrorDomainErrorCodes {
	SSYOAuthTalkerCredentialNotFoundErrorCode = 153022,
    SSYOAuthTalkerNoVerifierNoSessionHandleErrorCode = 153023,
    SSYOAuthTalkerRequestFailedErrorCode = 153024
} ;


extern NSString* const constKeyOAuthRequestUrl ;
extern NSString* const constKeyOAuthToken ;
extern NSString* const constKeyOAuthTokenSecret ;

@interface SSYOAuthTalker : NSObject {
	NSString* m_consumerKey ;
	NSString* m_consumerSecret ;
	NSString* m_oAuthToken ;
	NSString* m_oAuthTokenSecret ;
	NSString* m_oAuthVerifier ;
	NSString* m_oAuthSessionHandle ;
	NSString* m_guid ;
	NSString* m_oAuthRealm ;
	NSString* m_requestAccessUrl ;
	NSString* m_apiUrl ;
	NSTimeInterval m_timeout ;
	NSInvocation* m_gotAccessInvocation ;
	
	NSObject <SSYOAuthAccounter> * m_accounter ; // weak
}

@property (retain) NSString* consumerKey ;
@property (retain) NSString* consumerSecret ;
@property (retain) NSString* oAuthToken ;
@property (retain) NSString* oAuthTokenSecret ;
@property (retain) NSString* oAuthVerifier ;
@property (retain) NSString* oAuthSessionHandle ;
@property (retain) NSString* guid ;
@property (retain) NSString* oAuthRealm ;
@property (retain) NSString* requestAccessUrl ;
@property (retain) NSString* apiUrl ;
@property (assign) NSObject <SSYOAuthAccounter> * accounter ;

+ (NSString*)keychainServiceNameForAccounter:(NSObject <SSYOAuthAccounter> *)accounter ;

/*!
 @brief    Returns the Service Name in the Mac OS X Keychain which
 stores the OAuth Token and OAuth Token Secret for the receiver.
 */
- (NSString*)keychainServiceName ;

/*!
 @brief    Designated initializer for SSYOAuthTalker

 @param    accounter  An object from which the account name and
 optional service name will be obtained just in time for writing
 an item to the Mac OS X Keychain.  This is kept only as a weak
 reference.  Make sure it doesn't go away.  (For example, a
 temporary Clientoid produced by a BookMacster Client is not a
 good object to use here.)
*/
- (id)initWithAccounter:(NSObject <SSYOAuthAccounter> *)accounter ;

/*!
 @brief    Timeout which the receiver uses for requesting from the
 server either authorization info, initial access token, or
 refresh access token.  If not set, defaults to 17.0 seconds.
*/
@property (assign) NSTimeInterval timeout ;

@property (retain) NSInvocation* gotAccessInvocation ;


/*!
 @brief    Gets initial authorization from the provider (server)

 @details  To receive the reply from the web browser after the user
 OKs the link, your app must have installed a URL handler.
 
 @param    requestUrl  
 @param    authorizationInfo  
 @param    error_p  
 @result   
*/
- (BOOL)getAuthorizationInfoFromRequestUrl:(NSString*)requestUrl
					   authorizationInfo_p:(NSDictionary**)authorizationInfo
								   error_p:(NSError**)error_p ;

/*!
 @brief    Gets an access token, either initially or a refresh, from
 the provider (server).
 
 @details  
 */
- (BOOL)getAccessError_p:(NSError**)error_p ;

/*!
 @brief    Direct input of oauth_verifier which bypasses
 processOAuthInfo:

 @details  Use for services which do not allow callbacks to 
 private URL schemes and require the user to get the verifier
 from their web page.
 @param    verifier  The code (oauth_verifier) copied by the user
 from the service's web page.
*/
- (BOOL)processOAuthVerifier:(NSString*)verifier ;

/*!
 @brief    Notification handler which should be invoked when the 
 constNoteGotOAuthInfo notification has been received from your app's
 URL handler.
 
 @details  In your URL handler, when you send the notification, set
 the notification object to the query string that was received
 from the server.  This method will extract the value of the oauth_verifier key
 from that string.
 */
- (void)processOAuthInfo:(NSNotification*)note ;

/*!
 @brief    Writes the receiver's current credential information (token,
 token secret, user guid, and session handle) to the Mac OS X Keychain
 as a generic (application) password, under the current values of
 keychainServiceName and profileName
*/
- (void)setPasswordToKeychain ;

/*!
 @brief    Sends an API request to the provider (server) and returns
 the received data by reference.

 @details  
 @param    url  
 @param    parms  
 @param    timeout  
 @param    returnData_p  
 @param    error_p  
 @result   
*/
- (BOOL)requestCommand:(NSString*)url
				 parms:(NSDictionary*)parms
			   timeout:(NSTimeInterval)timeout
		  returnData_p:(NSData**)returnData_p 
			   error_p:(NSError**)error_p ;

/*!
 @brief    Method which may be used for unit testing of the internal
 OAuth request routine which is used throughout this class

 @details  The test formulates a request and sends it to
   http://term.ie/oauth/example/request_token.php
 For more information, see http://term.ie/oauth/example/
 Some test details are printed to console during test.
 @result   YES if the test passes, otherwise NO.
*/
+ (BOOL)testRequest ;

@end

