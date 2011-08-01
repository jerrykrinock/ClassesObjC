#import <Cocoa/Cocoa.h>

/*!
 @brief    Error domain for the SSYPathObserver class
 */
extern NSString* const SSYPathObserverErrorDomain ;

/*!
 @brief    Notification which will be passed on the main thread
 when a watched change is observed on a watched filesystem item
 */
extern NSString* const SSYPathObserverChangeNotification ;

/*!
 @brief    Keys in the user info dictionary of an
 SSYPathObserverChangeNotification
 */
/*!
 @brief    The path of the filesystem item which changed
 */
extern NSString* const SSYPathObserverPathKey ;
/*!
 @brief    Flags which indicate which properties of the changed
 filesystem item changed.
 @details  Bitwise AND of SSYPathObserverChangeFlags values
 */
extern NSString* const SSYPathObserverChangeFlagsKey ;
/*!
 @brief    User info which was passed in to addPath:watchFlags:userInfo:error_p:
 */
extern NSString* const SSYPathObserverUserInfoKey ;

/*!
 @brief    File's Vnode was removed
 */
#define SSYPathObserverChangeFlagsDelete     NOTE_DELETE
/*!
 @brief    Contents of file's data fork changed
 */
#define SSYPathObserverChangeFlagsData       NOTE_WRITE
/*!
 @brief    Size of file was increased
 */
#define SSYPathObserverChangeFlagsBigger     NOTE_EXTEND
/*!
 @brief    File attributes were chaned
 */
#define SSYPathObserverChangeFlagsAttributes NOTE_ATTRIB
/*!
 @brief    The Link Count of the file was changed
 */
#define SSYPathObserverChangeFlagsLinkCount  NOTE_LINK
/*!
 @brief    The file was renamed
 */
#define SSYPathObserverChangeFlagsRename     NOTE_RENAME
/*!
 @brief    Access (permissions) to the file was revoked
 */
#define SSYPathObserverChangeFlagsAccessGone NOTE_REVOKE


/*!
 @brief    A Cocoa wrapper around the kqueue path-watching
 notification system which will watch a set of filesystem items.
 
 @details  Although File system events (FSEvents) became available
 for watching directories in Mac OS 10.5, according to Apple's
 "File System Events Programming Guide" > Appendix A,
 
 "File system events are intended to provide notification of changes
 with directory-level granularity.  For most purposes, this is sufficient.
 In some cases, however, you may need to receive notifications with
 finer granularity.  For example, you might need to monitor only changes
 made to a single file.  For that purpose, the kernel queue (kqueue)
 notification system is more appropriate."
 
 This class uses the kqueue notification system.
 
 An instance of this class is typically configured to watch one or
 more filesystem items, identified by their paths.  When any of these
 items chcanges and triggers a kqueue event, the instance will issue
 a notification via NSNotificationCenter.
 
 This class requires Mac OS X 10.5 or later.
 
 Acknowledgements: I learned much of this from Uli Kusterer's UKKQueue,
 http://www.zathras.de/angelweb/sourcecode.htm#UKKQueue
 but I thought it was time for a modernization.
 
 Todo: 64-bit.  Seems there are 64-bit kqueue functions.
 */

@interface SSYPathObserver : NSObject {
    NSInteger m_kqueueFileDescriptor ;
	pthread_t m_threadId ;
    CFSocketRef	 runLoopSocket ;
	NSMutableSet* m_pathWatches ;
	BOOL m_isWatching ;
}


/*!
 @brief    Adds a given path to the receiver's watched paths
 
 @param    path  The path to be watched.  May be nil.
 @param    watchFlags  Bitwise AND of one or more SSYPathObserverChangeFlags
 constants, or 0 to pass all 7 flags.
 @param    error_p  Pointer which will, upon return, if this method
 returns NO and said pointer is not NULL, point to an NSError
 describing said error.
 @param    userInfo  An object which will be retained and passed 
 in the SSYPathObserverChangeNotification in the notification's
 userInfo dictionary for key SSYPathObserverPathKeyUserInfo.  
 May be nil if you have no userInfo to pass
 @result   YES if the given path was added, or is nil.
 NO only if the given non-nil path could not be added.
 */
- (BOOL)addPath:(NSString*)path
	 watchFlags:(NSInteger)watchFlags
	   userInfo:(id)userInfo
		error_p:(NSError**)error_p ;

/*!
 @brief    Removes a given path from the receiver's watched paths
 
 @param    path  The path to be removed
 @param    error_p  Pointer which will, upon return, if this method
 returns NO and said pointer is not NULL, point to an NSError
 describing said error.
 @result   YES if the item was removed, does not exist, or if
 the given path is nil.  NO only if the item exists but could
 not be removed.
 */
- (BOOL)removePath:(NSString*)path
		   error_p:(NSError**)error_p ;

/*!
 @brief    Setting this to NO will disable all of the receiver's path watches
 until it is set back to YES.
 
 @details  The default value is YES.
 */
@property (assign) BOOL isWatching ;

/*!
 @brief    Releases all resources being retained by the receiver, which
 includes the receiver itself.  Invoking this method when you are done with
 the receiver is highly recommended.
 
 @details  (1) Closes any file descriptors that the receiver is presently using
 to watch paths (each path requires one).  (2) Closes the one file descriptor
 which is used to maintain the kqueue itself, which causes the secondary
 thread which is used by the to monitor kqueue events to exit, which causes
 the NSThread instance in use by the receiver to be released and deallocated,
 which causes an internal NSNumber object passed to the thread to be
 released and deallocated and causes an internal retain on the receiver
 itself to be released, and therefore deallocated when any external retains
 are released.  Invoking this method is the only way to release the
 resources listed in (2).
 
 The equivalent operation in UKKQueue is triggered whenever the retainCount
 falls to 2, but I didn't like that and thought it would be better to do it
 manually.
 */
- (void)releaseResources ;

@end

/*************************************************************************/
/****************** TEST CODE FOR SSYPathObserver *************************/
/*************************************************************************/
#if 0
#import <Cocoa/Cocoa.h>
#import "SSYPathObserver.h"


NSString* const SSYPathObserverDemoIsDoneNotification = @"DaDemoDone" ;


@interface Notifee : NSObject {
	BOOL m_demoIsDone ;
}

@property BOOL demoIsDone ;
- (void)pathChangedNote:(NSNotification*)note ;
- (void)demoIsDoneNote:(NSNotification*)note ;

@end

@implementation Notifee

@synthesize demoIsDone = m_demoIsDone ;

- (void)pathChangedNote:(NSNotification*)note {
	NSLog(@"Received notification of filesystem change:\n"
		  "   Path:         %@\n"
		  "   Change Flags: %p\n"
		  "   UserInfo:     %@\n",
		  [[note userInfo] objectForKey:SSYPathObserverPathKey],
		  [[[note userInfo] objectForKey:SSYPathObserverChangeFlagsKey] integerValue],
		  [[note userInfo] objectForKey:SSYPathObserverUserInfoKey]) ;
}

- (void)demoIsDoneNote:(NSNotification*)note {
	[self setDemoIsDone:YES] ;
}

@end


@interface DemoFileTwiddler : NSObject

+ (void)twiddleWithPathObserver:(SSYPathObserver*)pathObserver ;

@end

@implementation DemoFileTwiddler

+ (void)twiddleWithPathObserver:(SSYPathObserver*)pathObserver {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init] ;	
	
	BOOL ok ;
	NSError* error ;
	NSInteger i ;
	NSData* data ;
	
	NSLog(@"Watch the files being created, renamed and removed on your Desktop") ;
	
	// Create paths	
	NSString* desktop = [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"] ;
#define N_PATHS 3
	NSString* paths[N_PATHS] ;
	paths[0] = [desktop stringByAppendingPathComponent:@"000Junk1.txt"] ;
	paths[1] = [desktop stringByAppendingPathComponent:@"000Junk2.txt"] ;
	paths[2] = [desktop stringByAppendingPathComponent:@"000Junk3.txt"] ;
	NSString* appendage = @"a" ;
	
	// Remove any files due to previous crashes of this test, and then
	// try to add the nonexistent paths to our path watcher
	i = 0 ;
	for (i=0; i<N_PATHS; i++) {
		NSString* path = paths[i] ;
		if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
			[[NSFileManager defaultManager] removeItemAtPath:path
													   error:NULL] ;
		}
		NSString* laterPath = [path stringByAppendingString:appendage] ;
		if ([[NSFileManager defaultManager] fileExistsAtPath:laterPath]) {
			[[NSFileManager defaultManager] removeItemAtPath:laterPath
													   error:NULL] ;
		}
		
		error = nil ;
		ok = [pathObserver addPath:path
						watchFlags:0  // Default to watch for all types of changes
						  userInfo:@"Here is your user info!"
						   error_p:&error] ;
		NSLog(@"Attempted to set watch for nonexisting path: %@\n(This should have made an error)\nok=%d, error:\n%@", path, ok, [error description]) ;
	}
	
	NSLog(@"Creating files...") ;
	data = [@"hello1" dataUsingEncoding:NSUTF8StringEncoding] ;
	for (i=0; i<N_PATHS; i++) {
		NSString* path = paths[i] ;
		[data writeToFile:path
			   atomically:NO] ;
	}
	
	NSLog(@"Adding the now-existing files to our path watcher.  This time it should work.") ;
	i = 0 ;
	for (i=0; i<N_PATHS; i++) {
		NSString* path = paths[i] ;
		ok = [pathObserver addPath:path
						watchFlags:0  // Default to watch for all types of changes
						  userInfo:@"Here is your user info!"
						   error_p:&error] ;
		error = nil ;
		NSLog(@"   Setting kqueue for existing path: %@\nok=%d, error:\n%@", path, ok, error) ;
	}
	
	NSLog(@"Modifying files") ;
	data = [@"hello2" dataUsingEncoding:NSUTF8StringEncoding] ;
	for (i=0; i<N_PATHS; i++) {
		NSString* path = paths[i] ;
		[data writeToFile:path
			   atomically:NO] ;
		sleep(1) ;
	}
	
	NSLog(@"Suspending path watcher.  Should be no notifications.") ;
	[pathObserver setIsWatching:NO] ;
	
	NSLog(@"Modifying files again.") ;
	data = [@"hello3" dataUsingEncoding:NSUTF8StringEncoding] ;
	for (i=0; i<N_PATHS; i++) {
		NSString* path = paths[i] ;
		[data writeToFile:path
			   atomically:NO] ;
		sleep(1) ;
	}
	
	NSLog(@"Unsuspending path watcher.  Should get notifications again.") ;
	[pathObserver setIsWatching:YES] ;
	
	NSLog(@"Renaming files, appending '%@'", appendage) ;
	for (i=0; i<N_PATHS; i++) {
		NSString* oldPath = paths[i] ;
		NSString* newPath = [oldPath stringByAppendingString:appendage] ;
		[[NSFileManager defaultManager] moveItemAtPath:oldPath
												toPath:newPath
												 error:NULL] ;
		sleep(1) ;
	}
	
	NSLog(@"Removing files") ;
	for (i=0; i<N_PATHS; i++) {
		NSString* path = paths[i] ;
		path = [path stringByAppendingString:appendage] ;
		[[NSFileManager defaultManager] removeItemAtPath:path
												   error:NULL] ;
		sleep(1) ;
	}
	
	NSLog(@"File-twiddling demo is done.") ;
	NSNotification* note = [NSNotification notificationWithName:SSYPathObserverDemoIsDoneNotification
														 object:nil
													   userInfo:nil] ;
	[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:)
														   withObject:note
														waitUntilDone:NO] ;
	
	[pool release] ;
}

@end


int main(int argc, char *argv[]) {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init] ;
	
	// Create a pathObserver.  (We'll add paths etc. in the other thread)
	SSYPathObserver* pathObserver = [[SSYPathObserver alloc] init] ;
	
	// Create a notifee to receive notifications
	Notifee* notifee = [[Notifee alloc] init] ;
	
	// Create a run loop and tell our Notifee class to observe notifications
	[[NSNotificationCenter defaultCenter] addObserver:notifee
											 selector:@selector(pathChangedNote:)
												 name:SSYPathObserverChangeNotification
											   object:pathObserver] ;
	[[NSNotificationCenter defaultCenter] addObserver:notifee
											 selector:@selector(demoIsDoneNote:)
												 name:SSYPathObserverDemoIsDoneNotification
											   object:nil] ;
	
	// The demo program is run on a secondary thread so that the
	// main thread can enter a run loop and listen for
	// notifications.
	[NSThread detachNewThreadSelector:@selector(twiddleWithPathObserver:)
							 toTarget:[DemoFileTwiddler class]
						   withObject:pathObserver] ;
	
	// Enter a run loop to listen for notifications until the demo
	// program is done
	while (![notifee demoIsDone] && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
															 beforeDate:[NSDate distantFuture]]) {
	}
	
	[[NSNotificationCenter defaultCenter] removeObserver:notifee] ;\
	[notifee release] ;
	[pathObserver releaseResources] ;
	[pathObserver release] ;
	
	return 0 ;	 
}

#endif