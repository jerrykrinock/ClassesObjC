/*!
 @brief    This class contains a single method which creates a plain-text email message.
*/
@interface SSYMailto : NSObject

/*!
 @brief    Method creates an email with a given address, subject and body by sending
 a mailto: URL to the shared NSWorkspace.

 @details  Any characters in any argument not allowed by RFC 2396 will be 
 percent-escape encoded.
 @param    address  The addressee, email address, of the message
 @param    subject  The message subject
 @param    body     The message body
*/
+ (void)emailTo:(NSString*)addres
		subject:(NSString*)subject
		   body:(NSString*)body ;

@end
