#import "SSYInterappClient.h"

NSString* const SSYInterappClientErrorDomain = @"SSYInterappClientErrorDomain" ;

@implementation SSYInterappClient

+ (BOOL)sendHeaderByte:(char)txHeaderByte
			 txPayload:(NSData*)txPayload
			  portName:(NSString*)portName
				  wait:(BOOL)wait
		rxHeaderByte_p:(char*)rxHeaderByte_p
		   rxPayload_p:(NSData**)rxPayload_p
			 txTimeout:(NSTimeInterval)txTimeout
			 rxTimeout:(NSTimeInterval)rxTimeout
			   error_p:(NSError**)error_p {
	BOOL ok = kCFMessagePortSuccess ;
	SInt32 result ;
    CFMessagePortRef remotePort ;
    NSTimeInterval txStartTime = [NSDate timeIntervalSinceReferenceDate] ;
    NSTimeInterval txTimeSpent ;
	do {
        remotePort = CFMessagePortCreateRemote(
                                               NULL,
                                               (CFStringRef)portName
                                               ) ;
        txTimeSpent = [NSDate timeIntervalSinceReferenceDate] - txStartTime ;
        if (txTimeSpent > txTimeout) {
            break ;
        }
        if (!remotePort) {
            usleep(100000) ;
        }
    } while (!remotePort) ;
    
	if (!remotePort) {
		ok = NO ;
		result = SSYInterappClientErrorCantFindReceiver ;
		goto end ;
	}
	
	NSMutableData* aggrTxData = [[NSMutableData alloc] init] ;
	if (txHeaderByte) {
		[aggrTxData appendBytes:(const void*)&txHeaderByte
						 length:1] ;
	}
	if (txHeaderByte) {
		[aggrTxData appendData:txPayload] ;
	}
	NSData* aggrRxData = nil ;
	CFStringRef replyMode = wait ? kCFRunLoopDefaultMode : NULL ;
    NSTimeInterval txTimeoutUsedUp = [NSDate timeIntervalSinceReferenceDate] - txStartTime ;
    txTimeout -= txTimeoutUsedUp ;
	result = CFMessagePortSendRequest(
									  remotePort,
									  0, 
									  (CFDataRef)aggrTxData,
									  txTimeout,
									  rxTimeout,
									  replyMode,
									  (CFDataRef*)&aggrRxData
									  ) ;
	
	// As always, we are careful not to CFRelease(NULL) ;
	CFRelease(remotePort) ;
	[aggrTxData release] ;
	
	ok = (result == kCFMessagePortSuccess) ;
	
	if (ok) {
		if (rxHeaderByte_p) {
			if ([aggrRxData length] > 0) {
				[aggrRxData getBytes:rxHeaderByte_p
							   range:NSMakeRange(0,1)] ;
			}
			else {
				*rxHeaderByte_p = 0 ;
			}
		}
		if (rxPayload_p) {
			if ([aggrRxData length] > 1) {
				*rxPayload_p = [aggrRxData subdataWithRange:NSMakeRange(1,[aggrRxData length] - 1)] ;
			}
			else {
				*rxPayload_p = 0 ;
			}
		}
	}
	
end:
	if (!ok && error_p) {
		NSString* errorDetail ;
		switch (result) {
			case kCFMessagePortSendTimeout:
				errorDetail = @"Send Timeout" ;
				break ;
			case kCFMessagePortIsInvalid:
				errorDetail = @"Port is Invalid" ;
				break ;
			case kCFMessagePortReceiveTimeout:
				errorDetail = @"Receive Timeout" ;
				break ;
			case kCFMessagePortTransportError:
				errorDetail = @"Transport Error" ;
				break ;
			case -5:  // Mac OS X 10.6 SDK defines this as kCFMessagePortBecameInvalidError
				errorDetail = @"Port Became Invalid" ;
				break ;
			case SSYInterappClientErrorCantFindReceiver:
				errorDetail = [NSString stringWithFormat:
							   @"Server port (%@) not found",
							   portName] ;
				break ;
			default:
				errorDetail = [NSString stringWithFormat:
							   @"Unknown Error Code: %ld",
							   (long)result] ;
				break ;
		}
		
		NSString* errorDescription = [NSString stringWithFormat:
									  @"Interapp messaging error : %@",
									  errorDetail] ;
		NSString* txHeaderString = txHeaderByte ? [[[NSString alloc] initWithBytes:&txHeaderByte
																			length:1
																		  encoding:NSUTF8StringEncoding] autorelease] : @"No header byte" ;
		NSNumber* txPayloadLength = [NSNumber numberWithInteger:[txPayload length]] ;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								  errorDescription, NSLocalizedDescriptionKey,
								  portName, @"Port Name",
								  txHeaderString, @"Tx Header Byte",
								  txPayloadLength, @"Tx Data Byte Count",
								  [NSNumber numberWithDouble:txTimeout], @"Tx Timeout (secs)",
								  [NSNumber numberWithDouble:rxTimeout], @"Rx Timeout (secs)",
								  nil] ;
		*error_p = [NSError errorWithDomain:SSYInterappClientErrorDomain
									   code:result
								   userInfo:userInfo] ;
	}		
	
	return ok ;
}

@end