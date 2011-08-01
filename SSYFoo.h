#import <Cocoa/Cocoa.h>

/*!
 @brief    When you are using this class for debugging,
 #if the following directive to 1.
*/
#if 0
#warning SSYFoo Debugging Utility class is included
#define SSY_FOO_INCLUDED 1
#endif
  
#if SSY_FOO_INCLUDED

/*!
 @brief    Class which logs each instance when initialized and when
 deallocced; useful for checking retain cycles in, for example,
 dictionaries.

 @details  This class is useful for finding retain cycles when objects
 are put in collections and invocations, for example, so you can see
 if and when these objects get deallocced.  For collections,
 add/set a +fooWithIdentifier: into the collection.  (For dictionaries,
 set for an arbitrary key like @"Test Key".)  For invocations,
 add it as an extra, unused argument.  For example, if creating with
 -invocationWithTarget:selector:retainArguments:argumentAddresses:,
    SSYFoo* foo = [SSYFoo fooWithIdentifer:@"Checkpoint 1234"] ;
 and then add ,&foo to the end of argumentAddresses varargs.  The 
 argument will, I *think*, be ignored, but it will be released when
 the invocation is released.
 
 In either case, the SSYFoo object will log when it is allocced
 and deallocced, showing the identifier you give and also a unique
 serial number.
 
 Serial numbers begin with 1 when the application launches and increment.
*/
@interface SSYFoo : NSObject {
	NSInteger m_serialNumber ;
	NSString* m_identifier ;
}

/*!
 @brief    Object that logs when it is initialized and when it
 is deallocced.

 @param    identifier  Whatever you want.  It will be logged.
*/
+ (id)fooWithIdentifier:(NSString*)identifier ;

/*!
 @brief    A wrapper around NSLog which may be used when you need
 to send a message to an object, for example if you want to log
 as the result of an invocation

 @param    msg  The string to be logged.  Does not support varargs
 format strings.
*/
+ (void)log:(NSString*)msg ;

@end

#endif
