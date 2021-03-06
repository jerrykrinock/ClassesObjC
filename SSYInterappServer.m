#import "SSYInterappServer.h"
#import "SSYInterappClient.h"

#if MAC_OS_X_VERSION_MAX_ALLOWED < 1070
#define NO_ARC 1
#else
#if __has_feature(objc_arc)
#define NO_ARC 0
#else
#define NO_ARC 1
#endif
#endif

/*!
 @brief    

 @details  WHY WE NEED THIS:
 Although documented, CFMessagePort has a rather odd behavior.  If you
 invalidate it with CFMessagePortInvalidate(), it becomes a "dead" port.  It
 can no longer send or receive messages, but if you try and create a new port
 with the same name, CFMessagePortCreateLocal() will fail.  You'll get the
 following message logged to stderr:
 
 *** CFMessagePort: bootstrap_register(): failed 1103 (0x44f) 'Service name already exists'

 And, of course, CFMessagePortCreateLocal() will return NULL.
 
 This will occur until the port is deallocated.  Wrapping a CFMessagePort into
 a Cocoa object object such as SSYInterappServer, however, makes the time of
 deallocation indeterminate, due to autorelease pools.
 
 To fix this, I maintain this singleton/static NSSet of portsInUse which
 contains pointers to CFMessagePortRefs wrapped as NSValue.  In the init
 method, I check this set for a port with the requested name and, if so, send
 it a CFRetain and return it.  Otherwise, I CFCreate a new one.  In -dealloc,
 I call CFGetRetainCount() upon the indicated port and, if this is 2, remove it
 from portsInUse, also calling CFRelease() upon it in any case.
 
 This seems to make everything work OK.
*/
static NSMutableSet* static_portsInUse = nil ;
static NSCountedSet* static_serversInUse = nil ;


NSString* const SSYInterappServerErrorDomain = @"SSYInterappServerErrorDomain" ;

@interface SSYInterappServer () 

@property CFMessagePortRef port ;

@end


CFDataRef SSYInterappServerCallBackCreateData(
									CFMessagePortRef port,
									SInt32 msgid,
									CFDataRef data,
									void* info) {
    // Unpack the header byte
    char headerByte = 0 ;
	if ([(__bridge NSData*)data length] > 0) {
		[(__bridge NSData*)data getBytes:&headerByte
						 length:1] ;
	}

    CFDataRef outputData = NULL;
    /* headerByte = 0 means that the client just wants to know if our port
     name exists on the system. */
    if (headerByte != 0) {
        // Unpack the payload data and send to delegate
        NSData* rxPayload = nil ;
        if ([(__bridge NSData*)data length] > 1) {
            rxPayload = [(__bridge NSData*)data subdataWithRange:NSMakeRange(1, [(__bridge NSData*)data length] - 1)] ;
        }

        SSYInterappServer* server = (__bridge SSYInterappServer*)info ;

        NSObject <SSYInterappServerDelegate> * delegate = [server delegate] ;
        /* We temporarily retain the delegate in case the delegate in case
         external actors release it too soon. */
        [delegate retain];
        [delegate interappServer:server
            didReceiveHeaderByte:headerByte
                            data:rxPayload] ;

        // Get response from delegate and return to Client
        NSMutableData* responseData ;
        char responseHeaderByte = [delegate responseHeaderByte] ;
        NSData* responsePayload = [delegate responsePayload] ;
        [delegate release];
        if (responseHeaderByte || responsePayload) {
            responseData = [[NSMutableData alloc] init] ;
            if (responseHeaderByte != 0) {
                [responseData appendBytes:(const void*)&responseHeaderByte
                                   length:1] ;
            }
            if (responsePayload) {
                [responseData appendData:responsePayload] ;
            }
        }
        else {
            responseData = NULL ;
        }

        // From CFMessagePortCallBack documentation, we return the
        // "data to send back to the sender of the message.  The system
        // releases the returned CFData object."
        if (responseData) {
            outputData = CFDataCreateCopy(kCFAllocatorDefault, (CFDataRef)responseData) ;
        }
        else {
            outputData = NULL ;
        }
#if !__has_feature(objc_arc)
        [responseData release] ;
#endif
    }
    
	return outputData ;
}


@implementation SSYInterappServer

- (void)dealloc {
	
	// Defensive programming: Ensure that _port exists because calling
	// either CFMessagePortInvalidate(NULL) or CFRelease(NULL)
	// will cause a crash.
	if (_port) {
		// See documentation above for static_portsInUse to understand
		// what in the world we are doing in here.
		
		CFIndex portRetainCount = CFGetRetainCount(_port) ;
		if (portRetainCount <= 2) {
			[static_portsInUse removeObject:[NSValue valueWithPointer:_port]] ;
			CFMessagePortInvalidate(_port) ;
		}
		
		CFRelease(_port) ;
		_port = NULL ;
	}
	
#if !__has_feature(objc_arc)
    [_userInfo release];

	[super dealloc];
#endif
}

- (id)initWithPortName:(NSString*)portName
			  delegate:(NSObject <SSYInterappServerDelegate> *)delegate
			   error_p:(NSError**)error_p {	
	NSInteger errorCode = 0 ;
	self = [super init] ;
	if (self) {
		if (!static_portsInUse) {
			// This is intentionally never released…
			static_portsInUse = [[NSMutableSet alloc] init] ;
		}
		
		for (NSValue* portPointer in static_portsInUse) {
			CFMessagePortRef aPort = [portPointer pointerValue] ;
			if ([portName isEqualToString:(__bridge NSString*)CFMessagePortGetName(aPort)]) {
				_port = aPort ;
				CFRetain(aPort) ;
			}
		}
		
		if (!_port) {
			CFMessagePortContext context ;
			context.version = 0 ;
			context.info = (__bridge void *)(self) ;
			context.retain = NULL ;
			context.release = NULL ;
			context.copyDescription = NULL ;
			
			// Loop added to retry in case of failure, in BookMacster 1.20
#define MESSAGE_PORT_CREATE_LOCAL_TIMEOUT 5.0
            NSDate* endDate = [NSDate dateWithTimeIntervalSinceNow:MESSAGE_PORT_CREATE_LOCAL_TIMEOUT] ;
            do {
                _port = CFMessagePortCreateLocal(
                                                  NULL,
                                                  (__bridge CFStringRef)portName,
                                                  SSYInterappServerCallBackCreateData,
                                                  &context,
                                                  NULL) ;

                /*If the system logs a message like this:
                 "*** CFMessagePort: dropping corrupt reply Mach message (***)"
                 Check out this:
                 https://github.com/opensource-apple/CF/blob/master/CFMessagePort.c
                 to decode the (***) */

                if (_port) {
                    break ;
                }
                if ([endDate timeIntervalSinceNow] < 0.0) {
                    break ;
                }
                sleep(1) ;
            } while (YES) ;

			if (_port) {
				[self setDelegate:delegate] ;
				CFRunLoopSourceRef source = CFMessagePortCreateRunLoopSource(
																			 NULL, 
																			 _port,
																			 0) ;
				CFRunLoopAddSource(
								   CFRunLoopGetCurrent(),
								   source, 
								   kCFRunLoopDefaultMode) ;
				// Note: Leaking 'source' will also leak _port in an apparent retain cycle.
				CFRelease(source) ;
				
				[static_portsInUse addObject:[NSValue valueWithPointer:_port]] ;
			}
			else {
				/* This means that CFMessagePortCreateLocal returned NULL
                 five times in 5 seconds.  Possibly the answer is in the
                 source code…
                 http://www.opensource.apple.com/source/CF/CF-855.11/CFMessagePort.c
                 where you can see that some NULL returns are preceded by a 
                 CFLog().  You should ask the user to run Trouble Zipper
                 and send logs.  Here is what I have so far
                 * Original code only tried once
                 * 20131007  User Thomas L., OS X 10.9.  I did not ask for console logs.
                 * 20131224  User Maarten K., OS X 10.9.  Asked for and received console logs.  They showed no entries.
                 If this happens again, in BookMacster 1.20 or later, I should
                 maybe submit a DTS Incident.  Could be a bug in 10.9 because
                 this code has been used for years with no prior such errors.
                 
                 One time I saw this happen when another running instance of
                 BookMacster, which had hung, already had open the port by the
                 same name.  Killing that hung instance fixed it.  It printed
                 this misleading message to the console:
                 *** CFMessagePort: bootstrap_register(): failed 1100 (0x44c) 'Permission denied', port = 0x12e33, name = 'com.sheepsystems.BookMacster.ExtoreFirefox.FromClient'
                 */
                errorCode = SSYInterappServerErrorFailedToCreatePort ;
			}
		}
	}
	else {
		errorCode = SSYInterappServerErrorFailedToInitializeSelf ;
	}
	
	if (errorCode != 0) {
        // See http://lists.apple.com/archives/Objc-language/2008/Sep/msg00133.html ...
#if !__has_feature(objc_arc)
		[super dealloc] ;
#endif
		self = nil ;
		
		if (error_p) {
            NSString* localizedFailureReason = nil;
            if (errorCode == SSYInterappServerErrorFailedToCreatePort) {
                // See if the port with our target portName is already in use by
                // seeing if sending a message to it succeeds.
                BOOL portAppearsToBeInUse = [SSYInterappClient sendHeaderByte:0
                                                                    txPayload:nil
                                                                     portName:portName
                                                                         wait:YES
                                                               rxHeaderByte_p:NULL
                                                                  rxPayload_p:NULL
                                                                    txTimeout:1.0
                                                                    rxTimeout:1.0
                                                                      error_p:NULL] ;
                if (portAppearsToBeInUse) {
                    errorCode = SSYInterappServerErrorPortNameAlreadyInUse;
                    localizedFailureReason = @"Port with requested name appears to be already in use on this system." ;
                }
            }

            *error_p = [NSError errorWithDomain:SSYInterappServerErrorDomain
										   code:errorCode
									   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
												 @"macOS failed to create a local message port.", NSLocalizedDescriptionKey,
												 portName, @"Port Name",
                                                 localizedFailureReason, NSLocalizedDescriptionKey, // may be nil
												 nil]] ;
		}
	}
	
	return self ;
}

- (NSString*)portName {
	return (__bridge NSString*)CFMessagePortGetName([self port]) ;
}

+ (SSYInterappServer*)leaseServerWithPortName:(NSString*)portName
									 delegate:(NSObject <SSYInterappServerDelegate> *)delegate
                                     userInfo:(NSDictionary*)userInfo
									  error_p:(NSError**)error_p {	
	NSError* error = nil ;
	if (!static_serversInUse) {
		// This is intentionally never released…
		static_serversInUse = [[NSCountedSet alloc] init] ;
	}
	
	SSYInterappServer* server = nil ;
	for (SSYInterappServer* aServer in static_serversInUse) {
		if ([[aServer portName] isEqualToString:portName]) {
			server = aServer ;
			break ;
		}
	}
	
	if (server) {
		// Increase the retain count of server in the static counted set
		[static_serversInUse addObject:server] ;
	}
	else {
		server = [[self alloc] initWithPortName:portName
									   delegate:delegate
										error_p:&error] ;
		if (server) {
			[static_serversInUse addObject:server] ;
		}
		else {
			// When testing, I got a crash of BookMacster-Worker here because
			// server was nil.  Until BookMacster 1.19, I logged
            // Internal Error 713-0192 here, but it was not providing any
            // useful information not already in the error.
		}
#if !__has_feature(objc_arc)
		[server release] ;
#endif
	}
	
	[server setDelegate:delegate] ;
    [server setUserInfo:userInfo] ;
	
	if (error && error_p) {
		*error_p = error ;
	}
	
	return server ;
}

- (void)unleaseForDelegate:(NSObject <SSYInterappServerDelegate> *)delegate {
	if ([self delegate] == delegate) {
		[self setDelegate:nil] ;
	}
	
	// Decrease the retain count of server in the static counted set
	[static_serversInUse removeObject:self] ;
}

@end
