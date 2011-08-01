#import <Cocoa/Cocoa.h>
#import "SSYInterappServerDelegate.h"

extern NSString* const SSYInterappServerErrorDomain ;

@class SSYInterappServer ;

/*!
 @brief    A server object which responds to a message sent by an 
 SSYInterAppClient object from another thread or process.
 
 @details  Dave Keck has suggested an easier way to do this.
 See comment at bottom of this file.
 
 Troubleshooting tip> To see if a port is active in the system,
    sudo launchctl bstree | grep <fragmentOfYourPortName>
*/
@interface SSYInterappServer : NSObject {
	CFMessagePortRef m_port ;
	NSObject <SSYInterappServerDelegate> * m_delegate ;
	void* m_contextInfo ;
}

/*!
 @brief    The contextInfo which is set in +leaseServerWithPortName::::.
 
 @details  This accessor is typically used to retrieve the receiver's
 contextInfo in the delegate method -interappServer:didReceiveHeaderByte:data:.
*/
@property (assign, nonatomic) void* contextInfo ;


/*!
 @brief    Returns a server object which has given port name on the system

 @details  This method takes care of the fact that only one port with a
 given name may exist on the system.
 @param    portName  An arbitrary name you supply, which must be unique among
 CFMessagePorts on the computer.  Suggest including a reverse DNS identifier.
 @param    delegate  An object to which will be sent Objective-C messages whenever
 an interapp message is received by the receiver from a SSYInterAppClient.
 If an existing server is returned, its delegate will be overwritten with
 this value.  The receiver does not retain the delegate.
 @param    contextInfo  A pointer which may be used to pass information to the
 delegate.  If an existing server is returned, its contextInfo will be
 overwritten with this value.
 @param    error_p  If the receiver cannot be initialized, will point to an
 error object describing the problem.  You may pass NULL if uninterested in this.
 @result   If you have previously leased a server with the given name during
 the course of the current process, and if the lease is still active, the
 number of leases will be incremented and that same old server will be
 returned.  Otherwise, a new server will be created.
*/
+ (SSYInterappServer*)leaseServerWithPortName:(NSString*)portName
									 delegate:(NSObject <SSYInterappServerDelegate> *)delegate
								  contextInfo:(void*)contextInfo
									  error_p:(NSError**)error_p ;

/*!
 @brief    Informs the receiver's class that you are done with this instance.

 @details  When the number of leases on a server with a given port name falls
 to 0, the server and its underlying CFMessage port will be invalidated,
 released, and, eventually, deallocated.
*/
- (void)unlease ;
	
@end

#if 0
//  Dave Keck suggests that this can be done easier using Cocoa…
//  From: http://pastie.org/1435791
//  He implies sthat he tested it in one process with two threads
//  but says it should work equally well if split into two processes…

#import <Foundation/Foundation.h>

@interface MyObject : NSObject
@end

@implementation MyObject
+ (void)serverThread
{
    [[NSAutoreleasePool alloc] init];
    NSMachPort *serverPort = (id)[NSMachPort port];
    [serverPort setDelegate: (id)self];
    [serverPort scheduleInRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
    assert([[NSMachBootstrapServer sharedInstance] registerPort: serverPort name: @"Jerry's Server"]);
    [[NSRunLoop currentRunLoop] runUntilDate: [NSDate distantFuture]] ;
	[pool drain] ;
}

+ (void)handlePortMessage: (NSPortMessage *)message
{
    NSLog(@"Received message (msgid: 0x%X): %@", [message msgid], message);
}
@end

int main(int argc, const char *argv[])
{
    [[NSAutoreleasePool alloc] init];
    [NSThread detachNewThreadSelector: @selector(serverThread) toTarget: [MyObject class] withObject: nil];
    sleep(1);
	
    NSMachPort *clientPort = (id)[[NSMachBootstrapServer sharedInstance] portForName: @"Jerry's Server"];
    assert(clientPort);
    for (;;)
    {
        NSPortMessage *message = [[[NSPortMessage alloc] initWithSendPort: clientPort receivePort: nil
															   components: [NSArray arrayWithObject: [@"hello" dataUsingEncoding: NSUTF8StringEncoding]]] autorelease];
        [message setMsgid: 0xCAFEBABE];
		
        assert([message sendBeforeDate: [NSDate distantFuture]]);
        sleep(1);
    }
	
    return 0;
}
#endif