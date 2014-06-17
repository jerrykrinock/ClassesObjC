#import <Cocoa/Cocoa.h>
#import "SSYInterappServerDelegate.h"

extern NSString* const SSYInterappServerErrorDomain ;

@class SSYInterappServer ;

/*!
 @brief    A server object which responds to a message sent by an 
 SSYInterAppClient object from another thread or process.
 
 @details  Dave Keck has suggested an easier way to do this.
 See comment at bottom of this file.
 
 Troubleshooting tip.  To see if a port is active in the system,
    sudo launchctl bstree | grep <fragmentOfYourPortName>
 Example:
    sudo launchctl bstree | grep sheepsystems
 For searching so I can find this comment later:
    command line, active mach port, active mach ports, 
*/
@interface SSYInterappServer : NSObject {
	CFMessagePortRef m_port ;
	NSObject <SSYInterappServerDelegate> * __unsafe_unretained m_delegate ;
	void* m_contextInfo ;
}

/*!
 @brief    The contextInfo which is set in +leaseServerWithPortName::::.
 
 @details  The getter is typically used to retrieve the receiver's
 contextInfo in the delegate method -interappServer:didReceiveHeaderByte:data:.
 The setter is typically used to re-purpose the receiver to handle a different
 message.
*/
@property (assign, nonatomic) void* contextInfo ;

/*!
 @brief    An object to which will be sent Objective-C messages whenever
 an interapp message is received by the receiver from a SSYInterAppClient.

 @details  The receiver does not retain the delegate.
*/
@property (assign, nonatomic) NSObject <SSYInterappServerDelegate> * delegate ;


/*!
 @brief    Returns a server object which has given port name on the system

 @details  This method takes care of the fact that only one port with a
 given name may exist on the system.  It should be sent whenever a delegate
 needs to use a server, and re-sent whenever there is any possibility that
 the server may have been leased to a different delegate.  To determine if
 this has happened, the delegate should do something like this…
      if ([[self server] delegate] == self) {
         // Send leaseServerWithPortName:::: again
         ...
      }
 @param    portName  An arbitrary name you supply, which must be unique among
 CFMessagePorts on the computer.  Suggest including a reverse DNS identifier.
 @param    delegate  See declaration of the 'delegate' property.  If an
 existing server is returned by this method, its delegate will be overwritten
 with this value.
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

 @details  Removes a given delegate from any of the receiver's servers.
 This message should be sent, at least, when the delegate is deallocated,
 and maybe sooner.
 Also, when the number of leases on a server with a given port name falls
 to 0, the server and its underlying CFMessage port will be invalidated,
 released, and, eventually, deallocated.
 
 The delegate: parameter was added in BookMacster 1.11 to eliminate crashes
 which occurred when this happened:
 
 • +leaseServerWithPortName:delegate::: assigns Delegate A to Server 1
 • +leaseServerWithPortName:delegate::: assigns Delegate B to Server 1
 • Delegate B is deallocated
 • Delegate A thinks that it is still assigned to Server 1 and does something which
      causes client to send IPC messages to Server 1, or maybe something goes haywire
      in the client and it sends an IPC message for some spurious reason 
 • Server 1 receives an IPC message, processes it and sends a message to its
      deallocated delegate, Delegate B, which causes a crash
 
 With this fix, in Delegate B's -dealloc method, when it sends this message, Server 1
 will now have nil delegate, so that it will not send a message to its deallocated
 delegate, Delegate B.
 
 However, although it won't crash, it will now be a no-op.  That's better, but still
 no go.  To complete the fix, delegates must check with their server when there
 is any possibility that the server may have been leased to a different delegate,
 as explained in details of -leaseServerWithPortName::::.
*/
- (void)unleaseForDelegate:(NSObject <SSYInterappServerDelegate> *)delegate ;
	
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
    NSLog(@"Received message (msgid: 0x%X): %@", (long)[message msgid], message);
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