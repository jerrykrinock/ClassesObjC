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
 Although documented, CFMessagePort has a rather odd behavior.  If you invalidate
 it with CFMessagePortInvalidate(), it becomes a "dead" port.  It can no longer
 send or receive messages, but if you try and create a new port with the same
 name, CFMessagePortCreateLocal() will fail.  You'll get the following message
 logged to stderr:
 
 *** CFMessagePort: bootstrap_register(): failed 1103 (0x44f) 'Service name already exists'

 And, of course, CFMessagePortCreateLocal() will return NULL.
 
 This will occur until the port is deallocated.  Wrapping a CFMessagePort into
 a Cocoa object object such as SSYInterappServer, however, makes the time of
 deallocation indeterminate, due to autorelease pools.
 
 To fix this, I maintain this singleton/static NSSet of portsInUse which contains
 pointers to CFMessagePortRefs wrapped as NSValue.  In the init method, I check
 this set for a port with the requested name and, if so, send it a CFRetain and
 return it.  Otherwise, I CFCreate a new one.  In -dealloc, I call CFGetRetainCount()
 upon the indicated port and, if this is 2, remove it from portsInUse, also calling
 CFRelease() upon it in any case.
 
 This seems to make everything work OK.
*/
static NSMutableSet* static_portsInUse = nil ;
static NSCountedSet* static_serversInUse = nil ;


NSString* const SSYInterappServerErrorDomain = @"SSYInterappServerErrorDomain" ;

@interface SSYInterappServer () 

@end


CFDataRef SSYInterappServerCallBackCreateData(
									CFMessagePortRef port,
									SInt32 msgid,
									CFDataRef data,
									void* info) {
	// Unpack the data and send to delegate
	char headerByte = 0 ;
	if ([(__bridge NSData*)data length] > 0) {
		[(__bridge NSData*)data getBytes:&headerByte
						 length:1] ;
	}
	NSData* rxPayload = nil ;
	if ([(__bridge NSData*)data length] > 1) {
		rxPayload = [(__bridge NSData*)data subdataWithRange:NSMakeRange(1, [(__bridge NSData*)data length] - 1)] ;
	}
	
	SSYInterappServer* server = (__bridge SSYInterappServer*)info ;
	
	NSObject <SSYInterappServerDelegate> * delegate = [server delegate] ;
	[delegate interappServer:server
		didReceiveHeaderByte:headerByte
						data:rxPayload] ;

	// Get response from delegate and return to Client
	NSMutableData* responseData = [[NSMutableData alloc] init];
	char responseHeaderByte = [delegate responseHeaderByte] ;
	[responseData appendBytes:(const void*)&responseHeaderByte
					   length:1] ;

	NSData* responsePayload = [delegate responsePayload] ;
	if (responsePayload) {
		[responseData appendData:responsePayload] ;
	}
	
	// From CFMessagePortCallBack documentation, we return the
	// "data to send back to the sender of the message.  The system
	// releases the returned CFData object."
    
    CFDataRef outputData = CFDataCreateCopy(kCFAllocatorDefault, (CFDataRef)responseData) ;
#if NO_ARC
    [responseData release] ;
#endif
    
	return outputData ;
}


@implementation SSYInterappServer

@synthesize delegate = m_delegate ;
@synthesize contextInfo = m_contextInfo ;

- (CFMessagePortRef)port {
	return m_port ;
}


- (void)dealloc {	
	
	// Defensive programming: Ensure that m_port exists because calling
	// either CFMessagePortInvalidate(NULL) or CFRelease(NULL)
	// will cause a crash.
	if (m_port) {
		// See documentation above for static_portsInUse to understand
		// what in the world we are doing in here.
		
		CFIndex portRetainCount = CFGetRetainCount(m_port) ;
		if (portRetainCount <= 2) {
			[static_portsInUse removeObject:[NSValue valueWithPointer:m_port]] ;
			CFMessagePortInvalidate(m_port) ;
		}
		
		CFRelease(m_port) ;
		m_port = NULL ;
	}
	
#if NO_ARC
	[super dealloc] ;
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
				m_port = aPort ;
				CFRetain(aPort) ;
			}
		}
		
		if (!m_port) {
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
                /*SSYDBL*/ NSLog(@"Creating CFMessagePort named %@", portName) ;
                m_port = CFMessagePortCreateLocal(
                                                  NULL,
                                                  (__bridge CFStringRef)portName,
                                                  SSYInterappServerCallBackCreateData,
                                                  &context,
                                                  NULL) ;
                if (m_port) {
                    break ;
                }
                if ([endDate timeIntervalSinceNow] < 0.0) {
                    break ;
                }
                sleep(1) ;
            } while (YES) ;

			if (m_port) {
				[self setDelegate:delegate] ;
				CFRunLoopSourceRef source = CFMessagePortCreateRunLoopSource(
																			 NULL, 
																			 m_port,
																			 0) ;
				CFRunLoopAddSource(
								   CFRunLoopGetCurrent(),
								   source, 
								   kCFRunLoopDefaultMode) ;
				// Note: Leaking 'source' will also leak m_port in an apparent retain cycle.
				CFRelease(source) ;
				
				[static_portsInUse addObject:[NSValue valueWithPointer:m_port]] ;
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
                errorCode = 287101 ;
			}
		}
	}
	else {
		errorCode = 287103 ;
	}
	
	if (errorCode != 0) {
		// See http://lists.apple.com/archives/Objc-language/2008/Sep/msg00133.html ...
#if NO_ARC
		[super dealloc] ;
#endif
		self = nil ;
		
		if (error_p) {
            // Added in BookMacster 1.22.8.
            // See if the port with our target portName is already in use by
            // seeing if sending a message to it succeeds.
            BOOL portAppearsToBeInUse = [SSYInterappClient sendHeaderByte:'t'
                                                                txPayload:nil
                                                                 portName:portName
                                                                     wait:YES
                                                           rxHeaderByte_p:NULL
                                                              rxPayload_p:NULL
                                                                txTimeout:1.0
                                                                rxTimeout:1.0
                                                                  error_p:NULL] ;
            NSString* localizedFailureReason = nil ;
            if ((errorCode == 287101) && portAppearsToBeInUse) {
                localizedFailureReason = @"This can happen if your program tries to open a port which it has already opened by that name, or if another running instance of your program already has such a port open." ;
            }
			*error_p = [NSError errorWithDomain:SSYInterappServerErrorDomain
										   code:errorCode
									   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
												 @"Mac OS X failed to create a local message port.", NSLocalizedDescriptionKey,
												 portName, @"Port Name",
                                                 portAppearsToBeInUse ? @"Si" : @"No", @"Port appears to be already in use?",
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
								  contextInfo:(void*)contextInfo
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
	
    /*SSYDBL*/ NSLog(@"Will lease server for %@", portName) ;
	if (server) {
		// Increase the retain count of server in the static counted set
		[static_serversInUse addObject:server] ;
	}
	else {
        /*SSYDBL*/ NSLog(@"Will init server for %@", portName) ;
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
#if NO_ARC
		[server release] ;
#endif
	}
	
	[server setDelegate:delegate] ;
	[server setContextInfo:contextInfo] ;
	
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