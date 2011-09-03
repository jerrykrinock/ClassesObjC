#import <Cocoa/Cocoa.h>

extern NSString* const SSYNetServiceResolverDidFinishNotification ;
extern NSString* const SSYNetServiceResolverDidFailNotification ;
extern NSString* const SSYNetServiceResolverDidStopNotification ;

enum SSYNetServiceResolverState_enum {
	SSYNetServiceResolverStateNotEvenStarted,
	SSYNetServiceResolverStateResolving,
	SSYNetServiceResolverStateDone,
	SSYNetServiceResolverStateStopped,
	SSYNetServiceResolverStateFailed
} ;
typedef enum SSYNetServiceResolverState_enum SSYNetServiceResolverState ;

@interface SSYNetServiceResolver : NSObject
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= 1060) 
	<NSNetServiceDelegate>
#endif
{
	SSYNetServiceResolverState state ;
	NSNetService* service ;
	NSError* error ;
}

/*!
 @brief    The service that is being or was attempted to be
 or was resolved.
*/
@property (readonly, retain) NSNetService* service ;

/*!
 @brief    The current state of the receiver.
 */
@property (readonly) SSYNetServiceResolverState state ;

/*!
 @brief    Any error encountered by the receiver.
 
 @details  If the receiver's state is SSYNetServiceResolverStateFailed,
 the value of this property will be an NSError indicating what went
 wrong.
 */
@property (readonly, retain) NSError* error ;

/*!
 @brief    Designated initializer for its class.
 
 @details  Immediately commences resolving the given service.
 @param    service  The service that is to be resolved
 */
- (id) initWithService:(NSNetService*)service_
			   timeout:(NSTimeInterval)timeout ;

@end

