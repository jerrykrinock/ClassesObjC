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
 There are actually two system calls involved here (1) "creating" the remote
 port and (2) sending the request to it and receiving an acknowledgment.  Prior
 to BookMacster 1.13.6, all of the txTimeout was allocated to step (2), and
 this method would return immediately with error if step (1) failed on the first
 try.  This would happen quite readily if the remote port was being vended by a 
 process which was just starting up!  From a high-level perspective, I have X
 seconds, and I don't care what it gets used for.  Therefore, starting with 
 BookMacster 1.13.6, if step (1) fails, it is retried every 100 milliseconds
 until it works, or up until the txTimeout, and whatever txTimeout remains is
 allowed for step (2).  Well, all that is a long way of saying that this
 parameter now does what you'd expect it to, the way it should have been
 designed to begin with, and you may get fewer unexpected errors!
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

