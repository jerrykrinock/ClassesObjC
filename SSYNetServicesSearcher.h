#import <Cocoa/Cocoa.h>

extern NSString* const SSYNetServicesSearcherDidFindDomainNotification ;
extern NSString* const SSYNetServicesSearcherDidFindServiceNotification ;
extern NSString* const SSYNetServicesSearcherDidFinishNotification ;
extern NSString* const SSYNetServicesSearcherDidFailNotification ;

enum SSYNetServicesSearcherState_enum {
	SSYNetServicesSearcherStateNotEvenStarted,
	SSYNetServicesSearcherStateSearchingForDomains,
	SSYNetServicesSearcherStateSearchingForServices,
	SSYNetServicesSearcherStateDone,
	SSYNetServicesSearcherStateStopped,
	SSYNetServicesSearcherStateFailed
} ;
typedef enum SSYNetServicesSearcherState_enum SSYNetServicesSearcherState ;

@interface SSYNetServicesSearcher : NSObject
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= 1060) 
	<NSNetServiceBrowserDelegate>
#endif
{
	NSDictionary* targets ;
	SSYNetServicesSearcherState state ;
	NSMutableArray* domains ;
	NSMutableArray* services ;
	NSMutableArray* targetTypesForCurrentDomain ;
	NSNetServiceBrowser* browser ;
	NSError* error ;
}

/*!
 @brief    Accessor for the receiver's 'targets' property

 @details  Just in case you have some need to read it back.
*/
@property (readonly, retain) NSDictionary* targets ;

/*!
 @brief    The current state of the receiver.
*/
@property (readonly) SSYNetServicesSearcherState state ;

/*!
 @brief    The array of (NSString*) domains found by the receiver.
 
 @details  This array will grow as more domains are found.
*/
@property (readonly, retain) NSMutableArray* domains ;

/*!
 @brief    The array of (NSNetService*) services found by the receiver.
 
 @details  This array will grow as more services are found.
 Services in all target domains and all types are combined into this
 single array.&nbsp;  If you specified multiple domains or targets,
 you can distinguish them by sending -domain and/or -type 
 messages to each element in the array.
 */
@property (readonly, retain) NSMutableArray* services ;

/*!
 @brief    Any error encountered by the receiver.

 @details  If the receiver's state is SSYNetServicesSearcherStateFailed,
 the value of this property will be an NSError indicating what went
 wrong.
*/
@property (readonly, retain) NSError* error ;

/*!
 @brief    Designated initializer for its class.

 @details  
 @param    targets  A dictionary indicating what domains and
 service types are to be searched for.&nbsp;  Each key in the
 dictionary should be a target domain, and its value should
 be an array of target types for that domain.
*/
- (id) initWithTargets:(NSDictionary*)targets ;

@end

