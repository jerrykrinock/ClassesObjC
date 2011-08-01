#import "SSYInterappServer.h"

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

@property (assign, nonatomic) NSObject <SSYInterappServerDelegate> * delegate ;

@end

CFDataRef SSYInterappServerCallBack(
									CFMessagePortRef port,
									SInt32 msgid,
									CFDataRef data,
									void* info) {
	// Unpack the data and send to delegate
	char headerByte = 0 ;
	if ([(NSData*)data length] > 0) {
		[(NSData*)data getBytes:&headerByte
						 length:1] ;
	}
	NSData* rxPayload = nil ;
	if ([(NSData*)data length] > 1) {
		rxPayload = [(NSData*)data subdataWithRange:NSMakeRange(1, [(NSData*)data length] - 1)] ;
	}
	
	SSYInterappServer* server = (SSYInterappServer*)info ;
	
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
	return (CFDataRef)responseData ;
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
	
	[super dealloc] ;
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
			if ([portName isEqualToString:(NSString*)CFMessagePortGetName(aPort)]) {
				m_port = aPort ;
				CFRetain(aPort) ;
			}
		}
		
		if (!m_port) {
			CFMessagePortContext context ;
			context.version = 0 ;
			context.info = self ;
			context.retain = NULL ;
			context.release = NULL ;
			context.copyDescription = NULL ;
			
			m_port = CFMessagePortCreateLocal(
											  NULL, 
											  (CFStringRef)portName,
											  SSYInterappServerCallBack,
											  &context,
											  NULL) ;
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
				errorCode = 287101 ;
			}
		}
	}
	else {
		errorCode = 287103 ;
	}
	
	if (errorCode != 0) {
		// See http://lists.apple.com/archives/Objc-language/2008/Sep/msg00133.html ...
		[super dealloc] ;
		self = nil ;
		
		if (error_p) {
			*error_p = [NSError errorWithDomain:SSYInterappServerErrorDomain
										   code:errorCode
									   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
												 @"Could not initialize server", NSLocalizedDescriptionKey,
												 portName, @"Port Name",
												 nil]] ;
		}
	}
	
	return self ;
}

- (NSString*)portName {
	return (NSString*)CFMessagePortGetName([self port]) ;
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
			// server was nil.  Maybe the port was already in use?
			NSLog(@"Internal Error 713-0192 %@ %@ %@ del=%@", portName, static_serversInUse, error, delegate) ;
		}
		[server release] ;
	}
	
	[server setDelegate:delegate] ;
	[server setContextInfo:contextInfo] ;
	
	if (error && error_p) {
		*error_p = error ;
	}
	
	return server ;
}

- (void)unlease {
	// Decrease the retain count of server in the static counted set
	[static_serversInUse removeObject:self] ;
}

@end