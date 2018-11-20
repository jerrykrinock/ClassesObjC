#import <Cocoa/Cocoa.h>

// We need to import the following system header in this header, so that
// classes including this headers know the definitions of the NOTE_XXX
// constants which are used to define our SSYPathObserverChangeFlagsXxxx
// constants.
#import <sys/event.h>


// See class documentation 
#define KQUEUES_WATCHER_THREAD_NEEDS_KILL_TO_EXIT ((MAC_OS_X_VERSION_MAX_ALLOWED < 1060) || (MAC_OS_X_VERSION_MIN_REQUIRED < 1060))


/*!
 @brief    Error domain for the SSYPathObserver class
 */
extern NSString* const SSYPathObserverErrorDomain ;

/*!
 @brief    Notification which will be passed on the designated
 notifee thread when a watched change is observed on a watched filesystem item.
 
 The combination of notifications you will receive due to any
 given filesystem change is not predictable.  For example,
 I have found that when I change the data in an ASCII text
 file from "Hello1" to "Hello2", I may receive two notifications
 with these flags:
 (SSYPathObserverChangeFlagsAttributes+SSYPathObserverChangeFlagsBigger)
 (SSYPathObserverChangeFlagsData+SSYPathObserverChangeFlagsBigger)
 or three notifications with these flags:
 (SSYPathObserverChangeFlagsBigger)
 (SSYPathObserverChangeFlagsData+SSYPathObserverChangeFlagsBigger)
 (SSYPathObserverChangeFlagsAttributes)
 Note that, in this case the SSYPathObserverChangeFlagsBigger flag was
 received twice.  (The above was observed running in Mac OS 10.6, 32-bits,
 compiled with 10.5 SDK.)
 */
extern NSString* const SSYPathObserverChangeNotification ;

/*!
 @brief    Name of the watcher thread which is created when an
 SSYPathObserver is initialized and should exit when its
 ssyPathObserver is deallocated.
 
 @details  This has no use that we know of, other than for quality
 assurance testing and debugging, but that's important!
 */
extern NSString* const SSYPathObserverWatcherThread ;

/*!
 @brief    Keys in the user info dictionary of an
 SSYPathObserverChangeNotification
 */

/*!
 @brief    The path of the filesystem item which changed
 */
extern NSString* const SSYPathObserverPathKey ;

/*!
 @brief    The BSD file descriptor which has been opened by
 SSYPathObserver for the watched file.
 @details  If you require the new path to the watched file
 after it has been moved, you can get it by giving the value
 of this key to -[NSFileManager(SSYFileDescriptor)pathForFileDescriptor:::].
 We don't do that because it's a fairly expensive process.
 */
extern NSString* const SSYPathObserverFileDescriptorKey ;

/*!
 @brief    Flags which indicate which properties of the changed
 filesystem item changed.
 @details  Bitwise OR of SSYPathObserverChangeFlags values
 */
extern NSString* const SSYPathObserverChangeFlagsKey ;

/*!
 @brief    User info which was passed in to addPath:watchFlags:notifyThread:userInfo:error_p:
 */
extern NSString* const SSYPathObserverUserInfoKey ;

/*!
 @brief    File's Vnode was removed.  Note that this is "removed"
 in the unix sense.  Moving a file to the Trash does not
 count here.
 @details  For debugging only, the value of this constant, compiled
 with the macOS 10.6 SDK, 32-bit i386, is: 1
 */
#define SSYPathObserverChangeFlagsDelete     NOTE_DELETE
/*!
 @brief    For regular files, the contents of file's data fork changed; for
 directories, the contents of the directory has changed, meaning that one of
 the files it contains has been added, deleted, renamed or had its data
 modified
 @details  For debugging only, the value of this constant, compiled
 with the macOS 10.6 SDK, 32-bit i386, is: 2
 */
#define SSYPathObserverChangeFlagsData       NOTE_WRITE
/*!
 @brief    Size of file was increased
 @details  For debugging only, the value of this constant, compiled
 with the macOS 10.6 SDK, 32-bit i386, is: 4
 */
#define SSYPathObserverChangeFlagsBigger     NOTE_EXTEND
/*!
 @brief    File attributes were changed
 @details  For debugging only, the value of this constant, compiled
 with the macOS 10.6 SDK, 32-bit i386, is: 8
 */
#define SSYPathObserverChangeFlagsAttributes NOTE_ATTRIB
/*!
 @brief    The Link Count of the file was changed
 @details  For debugging only, the value of this constant, compiled
 with the macOS 10.6 SDK, 32-bit i386, is: 16
 */
#define SSYPathObserverChangeFlagsLinkCount  NOTE_LINK
/*!
 @brief    The file was renamed, which in Macintosh parlance
 includes *moving* a file, including *moving* to the Trash.
 @details  For debugging only, the value of this constant, compiled
 with the macOS 10.6 SDK, 32-bit i386, is: 32
 */
#define SSYPathObserverChangeFlagsRename     NOTE_RENAME
/*!
 @brief    Access (permissions) to the file was revoked
 @details  For debugging only, the value of this constant, compiled
 with the macOS 10.6 SDK, 32-bit i386, is: 64
 */
#define SSYPathObserverChangeFlagsAccessGone NOTE_REVOKE

/*!
 @brief    A Cocoa wrapper around the kqueue path-watching
 notification system which will watch a set of filesystem items.
 
 @details
 
 * Background
 
 Although File system events (FSEvents) became available
 for watching directories in Mac OS 10.5, according to Apple's
 "File System Events Programming Guide" > Appendix A,
 
 "File system events are intended to provide notification of changes
 with directory-level granularity.  For most purposes, this is sufficient.
 In some cases, however, you may need to receive notifications with
 finer granularity.  For example, you might need to monitor only changes
 made to a single file.  For that purpose, the kernel queue (kqueue)
 notification system is more appropriate."
 
 This class uses the kqueue notification system.  However, you can use this
 class to watch directories.  To do so, pass in a path ending in a slash ("/")
 and flags SSYPathObserverChangeFlagsData.  You will get a notification
 whenever any file in the directory is added, removed, or modified.

 IMPORTANT: You cannot use a kqueue, and therefore cannot use this class,
 to observe a file/folder which does not exist yet.  If you try,
 -addPath::::: will an error.


 * Interface
 
 An instance of this class is typically configured to watch one or
 more filesystem items, identified by their paths.  When any of these
 items changes and triggers a kqueue event, the instance will issue
 a notification via NSNotificationCenter.
 
 * Availability
 
 This class requires macOS 10.5 or later.
 
 * Hack to kill kqueue watcher thread for macOS 10.5
 
 When this class is compiled using the Mac OS 10.5 SDK, the constant
 KQUEUES_WATCHER_THREAD_NEEDS_KILL_TO_EXIT is set to 1, which causes
 inclusion of some extra code which works around the fact that in this
 SDK a camped kevent() call does not return when the file descriptor
 of its kqueue is closed, and we need to kill its thread by sending
 it a signal.  With the Mac OS 10.6 SDK, the camped kevent() does
 return when its kqueue is closed, so this hack is not needed. See:
 http://lists.apple.com/archives/darwin-kernel/2010/Aug/msg00040.html

* Acknowledgements
 
 Thanks to Uli Kusterer for publishing UKKQueue,
 http://www.zathras.de/angelweb/sourcecode.htm#UKKQueue  
 Learned alot from that but thought it was time for an update.
 Later, I found that Uli may have updated his earlier work.  Check
 out http://www.github.com/uliwitness/UliKit before using this class.
 
 Special thanks to Terry Lambert for the macOS 10.5 workaround.
 
 In *Advanced macOS Programming* by Dalrymple & Hillegass,
 Chapter 15 has information on kqueues.
 
* Todo
 
 64-bit.  Seems there are 64-bit kqueue functions.  Do I need them?
 */

@interface SSYPathObserver : NSObject {
    uint32_t m_kqueueFileDescriptor ;
    CFSocketRef	 runLoopSocket ;
	NSMutableSet* m_pathWatches ;
	BOOL m_isWatching ;
	BOOL m_isAlive ;
#if KQUEUES_WATCHER_THREAD_NEEDS_KILL_TO_EXIT
	pthread_t m_threadId ;
#endif
}


/*!
 @brief    Adds a given path, which must currently exist in the filesystem,
 to the receiver's watched paths
 
 @details  If the given path does not currently exist in the filesystem, this
 method will return NO and return error 812002 in error_p.
 @param    path  The path to be watched.  May be nil.
 @param    watchFlags  Bitwise OR of one or more SSYPathObserverChangeFlags
 constants you wish to receive notifications for.  If 0, will
 default to the three most popular flags:
 *  SSYPathObserverChangeFlagsData
 *  SSYPathObserverChangeFlagsRename
 *  SSYPathObserverChangeFlagsDelete
 @param    userInfo  An object which will be retained and passed 
 in the SSYPathObserverChangeNotification in the notification's
 userInfo dictionary for key SSYPathObserverUserInfoKey.  
 May be nil if you have no userInfo to pass.
 @param    notifyThread  Thread on which the SSYPathObserverChangeNotification
 notification to be sent when a watched change occurs.  If nil, will be
 passed on the main thread.  You might want [NSThread currentThread]?
 @param    error_p  Pointer which will, upon return, if this method
 returns NO and said pointer is not NULL, point to an NSError
 describing said error.
 @result   YES if the given path was added, or is nil.
 NO only if the given non-nil path could not be added.
 */
- (BOOL)addPath:(NSString*)path
	 watchFlags:(uint32_t)watchFlags
   notifyThread:(NSThread*)notifeeThread
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
@property (assign) BOOL isWatching;

/*!
 @brief    Returns a set of strings, each one representing a path that is
 currently being watched

 @details  If .isWatching is NO, or if no paths are currently being watched,
 returns an empty set.

 */
- (NSSet*)currentlyWatchedPaths;

@end

/*************************************************************************/
/****************** TEST CODE FOR SSYPathObserver ************************/
/*************************************************************************/
#if 0

#import <Cocoa/Cocoa.h>
#import "SSYPathObserver.h"

/*
 Note that this demo runs in three threads:
 * Main thread, in which main() sits and listens for notifications
 of filesystem changes from SSYPathObserver.
 * Demo Stimulator thread, detached from main thread to make changes to
 files.  This thread is a demo artifact.
 * Watcher thread, detached in -[SSYPathObserver init].  This thread camps on
 the kqueue system's kevent() function.  That is to say: One of these threads
 is created internally by each SSYPathObserver instance.
 */

/*
 If you would like to watch files appear and disappear during this
 demo, change the following from 0 to 1000000 or so
 */
#define SLEEP_MICROSECONDS 100000


NSString* const SSYPathObserverDemoIsDoneNotification = @"DaDemoDone" ;


@interface Notifee : NSObject {
	BOOL m_demoIsDone ;
}

@property BOOL demoIsDone ;

@end

@implementation Notifee

@synthesize demoIsDone = m_demoIsDone ;

- (void)getNote:(NSNotification*)note {
	NSString* msg = [NSString stringWithFormat:
					 @"Received %@",
					 [note name]] ;
	if ([[note name] isEqualToString:SSYPathObserverChangeNotification]) {
		msg = [msg stringByAppendingFormat:
			   @"\n   Path:         %@\n"
			   "   Change Flags: %p\n"
			   "   UserInfo:     %@\n",
			   [[note userInfo] objectForKey:SSYPathObserverPathKey],
			   [[[note userInfo] objectForKey:SSYPathObserverChangeFlagsKey] integerValue],
			   [[note userInfo] objectForKey:SSYPathObserverUserInfoKey]] ;
	}
	else if ([[note name] isEqualToString:NSThreadWillExitNotification]) {
		msg = [msg stringByAppendingFormat:
			   @" for thread named %@\n",
			   [note object]] ;
	}
	else if ([[note name] isEqualToString:SSYPathObserverDemoIsDoneNotification]) {
		[self setDemoIsDone:YES] ;
	}
	
	NSLog(@"%@", msg) ;
}

@end


@interface DemoFileStimulator : NSObject

+ (void)demoStimulateWithPathObserver:(SSYPathObserver*)pathObserver ;

@end

@implementation DemoFileStimulator

+ (void)demoStimulateWithPathObserver:(SSYPathObserver*)pathObserver {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init] ;	
	
	BOOL ok ;
	NSError* error = nil  ;
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
					  notifyThread:nil
						  userInfo:@"First round"
						   error_p:&error] ;
		NSLog(@"Attempted to set watch for nonexisting path: %@\n(This should have made an error)\nok=%ld, error:\n%@", path, (long)ok, [error description]) ;
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
					  notifyThread:nil
						  userInfo:@"Second round"
						   error_p:&error] ;
		error = nil ;
		NSLog(@"   Setting kqueue for existing path: %@\nok=%ld, error:\n%@", path, (long)ok, error) ;
	}
	
	NSLog(@"Modifying files") ;
	data = [@"hello2" dataUsingEncoding:NSUTF8StringEncoding] ;
	for (i=0; i<N_PATHS; i++) {
		NSString* path = paths[i] ;
		[data writeToFile:path
			   atomically:NO] ;
		usleep(SLEEP_MICROSECONDS) ;
	}
	
	NSLog(@"Suspending path watcher.  Should be no notifications.") ;
	[pathObserver setIsWatching:NO] ;
	
	NSLog(@"Modifying files again.") ;
	data = [@"hello3" dataUsingEncoding:NSUTF8StringEncoding] ;
	for (i=0; i<N_PATHS; i++) {
		NSString* path = paths[i] ;
		[data writeToFile:path
			   atomically:NO] ;
		usleep(SLEEP_MICROSECONDS) ;
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
		usleep(SLEEP_MICROSECONDS) ;
	}
	
	NSLog(@"Removing files") ;
	for (i=0; i<N_PATHS; i++) {
		NSString* path = paths[i] ;
		path = [path stringByAppendingString:appendage] ;
		[[NSFileManager defaultManager] removeItemAtPath:path
												   error:NULL] ;
		usleep(SLEEP_MICROSECONDS) ;
	}
	
	NSLog(@"Demo Stimulation is done.") ;
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
	// and also thread exit notification
	[[NSNotificationCenter defaultCenter] addObserver:notifee
											 selector:@selector(getNote:)
												 name:SSYPathObserverChangeNotification
											   object:pathObserver] ;
	[[NSNotificationCenter defaultCenter] addObserver:notifee
											 selector:@selector(getNote:)
												 name:SSYPathObserverDemoIsDoneNotification
											   object:nil] ;
	[[NSNotificationCenter defaultCenter] addObserver:notifee
											 selector:@selector(getNote:)
												 name:NSThreadWillExitNotification
											   object:nil] ;
	
	// The demo stimulator is run on a secondary thread so that the
	// main thread can enter a run loop and listen for
	// notifications.
	[NSThread detachNewThreadSelector:@selector(demoStimulateWithPathObserver:)
							 toTarget:[DemoFileStimulator class]
						   withObject:pathObserver] ;
	
	// Enter a run loop to listen for notifications until the demo
	// program is done
	while (![notifee demoIsDone] && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
															 beforeDate:[NSDate distantFuture]]) {
	}
	
	[pathObserver release] ;
	
	// For purposes of this demo, we insert a couple sleeps here.  The reasons are:
	// 1.  As explained in comments for -[SSYPathObserver dealloc],
	//     -[SSYPathObserver dealloc] is invoked by the watcher thread.
	// 2.  To make sure that the NSThreadWillExitNotification is 
	//     received.
	// 3.  To make sure there is no crash or exception triggered by
	//     the deallocation or thread exitting
	usleep(500000) ;
	
	[[NSNotificationCenter defaultCenter] removeObserver:notifee] ;
	[notifee release] ;
	
	[pool release] ;
	
	usleep(500000) ;
	
	return 0 ;	 
}

#endif
