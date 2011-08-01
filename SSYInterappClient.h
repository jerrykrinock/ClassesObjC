#import <Cocoa/Cocoa.h>

extern NSString* const SSYInterappClientErrorDomain ;

#define SSYInterappClientErrorSendTimeout kCFMessagePortSendTimeout
#define SSYInterappClientErrorPortIsInvalid kCFMessagePortIsInvalid
#define SSYInterappClientErrorReceiveTimeout kCFMessagePortReceiveTimeout
#define SSYInterappClientErrorPortTransportError kCFMessagePortTransportError
#define SSYInterappClientErrorCantFindReceiver 653041



/*!
 @brief    

 @details  Dave Keck has suggested an easier way to do this.  See
 comment at bottom of SSYInterappServer.h.
*/
@interface SSYInterappClient : NSObject {
}

/*!
 @brief    Sends an optional one-byte header, and a payload of data to another
 thread or process in which a SSYInterappServer is active, and returns a similar
 response from this server.

 @details  Uses CFMessagePort under the hood.
 @param    txHeaderByte  A header byte which will be transmitted to the server.
 @param    txPayload  Payload data to be sent to the server.
 @param    portName  Identifies the port of the SSYInterappServer to which
 the message will be sent.
 @param    rxHeaderByte_p  Pointer which, upon return, if not NULL and if a
 response was received, will point to the header byte received from the server.
 @param    rxPayload_p  Pointer which, upon return, if not NULL and if a
 response was received, will point to the payload data received from the server.
 @param   txTimeout  Timeout within which the system must find the indicated
 port and return it to this method, before NO and an error are returned.
 @param   rxTimeout  Timeout, after sending the message to the other thread or
 process, within which the other thread or process must return a response,
 before NO and an error are returned.
 @param    error_p  Pointer which, upon return, if not NULL and if a
 response was not received, will point to an error explaining the problem.

 @result   YES if a response was received from the server, otherwise NO.
*/
+ (BOOL)sendHeaderByte:(char)txHeaderByte
			 txPayload:(NSData*)txPayload
			  portName:(NSString*)portName
				  wait:(BOOL)wait
		rxHeaderByte_p:(char*)rxHeaderByte_p
		   rxPayload_p:(NSData**)rxPayload_p
			 txTimeout:(NSTimeInterval)txTimeout
			 rxTimeout:(NSTimeInterval)rxTimeout
			   error_p:(NSError**)error_p ;

@end

