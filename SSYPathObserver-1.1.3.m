#import <errno.h>
#import "SSYPathObserver.h"
#import "NSObject+MoreDescriptions.h"
#import "NSError+LowLevel.h"
#import <sys/event.h>

NSString* const SSYPathObserverErrorDomain        = @"SSYPathObserverErrorDomain" ;
NSString* const SSYPathObserverChangeNotification = @"SSYPathObserverChangeNotification" ;
NSString* const SSYPathObserverPathKey            = @"Path" ;
NSString* const SSYPathObserverChangeFlagsKey     = @"Flag" ;
NSString* const SSYPathObserverUserInfoKey        = @"UsIn" ;

/*!
 @brief    Encapsulates a file system path, some userInfo, and
 a file descriptor
 
 @details  Typically used privately inside SSYPathObserver.
 */
@interface SSYPathWatch : NSObject {
	NSString* m_path ;
	id m_userInfo ;
	NSInteger m_fileDescriptor ;
}

@property (retain) NSString* path ;
@property (retain) id userInfo ;
@property (assign) NSInteger fileDescriptor ;

@end


@implementation SSYPathWatch

@synthesize path = m_path ;
@synthesize userInfo = m_userInfo ;
@synthesize fileDescriptor = m_fileDescriptor ;

- (NSString*)description {
	return [NSString stringWithFormat:
			@"<%@ %p> fd=%d, path=%@, userInfo=%@",
			[self className],
			self,
			[self fileDescriptor],
			[self path],
			[[self userInfo] shortDescription]] ;
}


- (BOOL)isEqual:(SSYPathWatch*)otherPathWatch {
	return ([[otherPathWatch path] isEqualToString:[self path]]) ;
}

- (void)dealloc {
	[m_path release] ;
	[m_userInfo release] ;
	
	[super dealloc] ;
}

@end


@interface SSYPathObserver ()

@property (retain) NSMutableSet* pathWatches ;
@property (assign) NSInteger kqueueFileDescriptor ;

@end



@implementation SSYPathObserver

@synthesize pathWatches = m_pathWatches ;
@synthesize kqueueFileDescriptor = m_kqueueFileDescriptor ;
@synthesize isWatching = m_isWatching ;

- (void)releaseResources {
	// Close any file descriptors which might still be open
	for (SSYPathWatch* pathWatch in [self pathWatches]) {
		NSInteger fileDescriptor = [pathWatch fileDescriptor] ;
		NSInteger result = close(fileDescriptor) ;
		if (result == -1) {
			// There's not much we can do about this error here.  Just log it.
            NSLog(@"Internal Error 614-0184.  %s couldn't close file descriptor %d errno=%d, %s",
				  __PRETTY_FUNCTION__,
				  fileDescriptor,
				  errno,
				  strerror(errno)) ;
		}
	}

	// For some reason, closing the kqueue file descriptor with close()
	// hangs indefinitely in Mac OS X 10.5, so we just leave it open.
	// It's a waste of a resource, so we hope that not too many
	// paths are observed during a typical program run.
	// For 10.5.8, AppKit version number is 949.54.  For 10.6.4 it's 1038.32.
#warning Broken kqueue for 10.5
	if (NSAppKitVersionNumber >= 1000.0) {
		NSInteger kqfd = [self kqueueFileDescriptor] ;
		close (kqfd) ;	
/*
 [self retain] ;
 [self performSelector:@selector(closeTheK)
			   withObject:nil
			   afterDelay:2.0] ;
*/
	}
}

/*- (void)closeTheK {
	NSInteger kqfd = [self kqueueFileDescriptor] ;
	close (kqfd) ;	
	[self release] ;
}
*/

- (void)dealloc {
    [self setPathWatches:nil] ;
	
    [super dealloc] ;
}


- (void)watchAndWaitKqueueFileDescriptor:(NSNumber*)fileDescriptorNumber {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init] ;
	
	struct kevent event ;	
	NSInteger fileDescriptor = [fileDescriptorNumber integerValue] ;
	
	while (YES) {
		NSInteger result = kevent(
								  fileDescriptor,  // Our kqueue
								  NULL,            // C array of events we want to change
								  0,               // count of items in the preceding array
								  &event,          // pointer to array of queued events
								  1,               // We want only 1 event in the preceding array
								  NULL             // No timeout
								  ) ;
		if (result != -1) {
			if(event.filter == EVFILT_VNODE ) {
				SSYPathWatch* pathWatch = (SSYPathWatch*)event.udata ;
				
				@synchronized(self) {
					// Retain pathWatch here, in case of the unlikely event that
					// pathWatch has just been removed on another thread
					[pathWatch retain] ;
					if ([self isWatching]) {
						NSNumber* filterFlags = [NSNumber numberWithInteger:event.fflags] ;
						NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
												  filterFlags, SSYPathObserverChangeFlagsKey,
												  [pathWatch path], SSYPathObserverPathKey,
												  [pathWatch userInfo], SSYPathObserverUserInfoKey,  // may be nil
												  nil] ;
						NSNotification* note = [NSNotification notificationWithName:SSYPathObserverChangeNotification
																			 object:self
																		   userInfo:userInfo] ;
						[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:)
																			   withObject:note
																			waitUntilDone:NO] ;
					}
					[pathWatch release] ;
				}
			}
		}
		else {
			// kevent() returned -1.  This means that an error occurred
			// in processing the event.
			// Although you could get a *real* error here, I've never seen one.
			// An error does occur here, with errno = 4, during -releaseResources, when
			// file descriptor kqueueFileDescriptor is closed.  We use that
			// to break out and allow this secondary thread to end.
			break ;
		}
	}
	
	[pool release] ;
} 

    
-(id)init {
	self = [super init] ;
	if (self) {	
		[self setIsWatching:YES] ;
		[self setPathWatches:[NSMutableSet set]] ;

		NSInteger kqueueFileDescriptor = kqueue() ;
		if (kqueueFileDescriptor == -1) {
			NSLog(@"Internal Error 153-9092.  Failed creating kqueue") ;
			// See http://lists.apple.com/archives/Objc-language/2008/Sep/msg00133.html ...
			[super dealloc] ;
			self = nil ;
		}
		else {
			// To simplify the documentation of the -releaseResources method,
			// we don't want this NSNumber to be in the autorelease
			// pool.  So we alloc] init] and release it.
			NSNumber* kqueueFileDescriptorNumber = [[NSNumber alloc] initWithInteger:kqueueFileDescriptor] ;
			[NSThread detachNewThreadSelector:@selector(watchAndWaitKqueueFileDescriptor:)
									 toTarget:self
								   withObject:kqueueFileDescriptorNumber] ;
			[kqueueFileDescriptorNumber release] ;
			[self setKqueueFileDescriptor:kqueueFileDescriptor] ;
		}
	}
	
	return self ;
}

/*!
 @param    pathWatch  Not nil
 @param    doAdd  YES to add, NO to remove
 @param    flags If 0, this means "all 7 flags"
 @result   YES if successful
 */
- (BOOL)kqueueRegisterPathWatch:(SSYPathWatch*)pathWatch
						  doAdd:(BOOL)doAdd
						  flags:(NSInteger)flags
						error_p:(NSError**)error_p ; {
	// Create kevent
	u_short actionFlags = doAdd ? (EV_ADD | EV_ENABLE) : (EV_DELETE | EV_DISABLE) ;
	actionFlags |= EV_CLEAR ;
	uint32_t fflags = (flags != 0) ? flags :
	+ NOTE_DELETE
	+ NOTE_WRITE
	+ NOTE_EXTEND
	+ NOTE_ATTRIB
	+ NOTE_LINK
	+ NOTE_RENAME
	+ NOTE_REVOKE ;
	
	struct kevent myEvent ;
    EV_SET (
			&myEvent,                       // kevent, out
            [pathWatch fileDescriptor],     // ident
            EVFILT_VNODE,                   // filter
            actionFlags,                    // flags
            fflags,                         // fflags
            0,                              // data
            pathWatch                       // udata, user data, aka "context info"
			) ;
	
    // Register filter
	NSInteger result = kevent(
							  [self kqueueFileDescriptor],  // Our kqueue
							  &myEvent,                     // list of events we want to change, const struct kevent
							  1,                            // number of items in the above list, int
							  NULL,                         // list of events that he kqueue is reporting, struct kevent
							  0,                            // We do not want any pending events
							  NULL                          // timeout, const struct timespec
							  ) ;
	
	// Create error if failed
	BOOL ok = YES ;
	if (result == -1) {
		if (error_p) {
			NSString* msg = [NSString stringWithFormat:
							 @"Error registering path watch %@",
							 doAdd ? @"add": @"remove"] ;
			NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									  msg, NSLocalizedDescriptionKey,
									  [pathWatch description], @"pathWatch",
									  [NSError errorWithPosixErrorCode:errno], NSUnderlyingErrorKey,
									  nil] ;
			*error_p = [NSError errorWithDomain:SSYPathObserverErrorDomain
										   code:812001
									   userInfo:userInfo] ;
		}
		
		ok = NO ;
    }
	
	// Clean up
	if (!doAdd) {
		close ([pathWatch fileDescriptor]) ;
	}
	
	return ok ;
}

- (BOOL)addPath:(NSString*)path
	 watchFlags:(NSInteger)watchFlags
	   userInfo:(id)userInfo
		error_p:(NSError**)error_p {
	if (!path) {
		return YES ;
	}
	
	BOOL ok = YES ;
	
	// Get file descriptor for given path
	NSInteger fileDescriptor = open([path UTF8String], O_RDONLY) ;	
	if (fileDescriptor == -1) {
		if (error_p) {
			NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									  @"Error opening file descriptor", NSLocalizedDescriptionKey,
									  path, @"path",
									  [NSError errorWithPosixErrorCode:errno], NSUnderlyingErrorKey,
									  nil] ;
			*error_p = [NSError errorWithDomain:SSYPathObserverErrorDomain
										   code:812002
									   userInfo:userInfo] ;
		}

		ok = NO ;
		goto end ;
	}

	// Create pathWatch
	SSYPathWatch* pathWatch = [[SSYPathWatch alloc] init] ;
	[pathWatch setPath:path] ;
	[pathWatch setUserInfo:userInfo] ;
	[pathWatch setFileDescriptor:fileDescriptor] ;
	@synchronized(self) {
		[[self pathWatches] addObject:pathWatch] ;
		[pathWatch release] ;
		
		// Register kqueue for it
		ok = [self kqueueRegisterPathWatch:pathWatch
									 doAdd:YES
									 flags:watchFlags
								   error_p:error_p] ;
	}
	
end:
	return ok ;
}

- (BOOL)removePath:(NSString*)path
		   error_p:(NSError**)error_p {
	if (!path) {
		return YES ;
	}
	
	BOOL ok = YES ;
	
	@synchronized(self) {
		// Find the existing pathWatch indicated by the given path
		SSYPathWatch* targetPathWatch = nil ;
		for (SSYPathWatch* pathWatch in [self pathWatches]) {
			if ([[pathWatch path] isEqual:path]) {
				targetPathWatch = pathWatch ;
				break ;
			}
		}
		
		if (targetPathWatch) {
			// Unregister kqueue of the target pathWatch
			ok = [self kqueueRegisterPathWatch:targetPathWatch
										 doAdd:NO
										 flags:0
									   error_p:error_p] ;
			
			// Forget targetPathWatch
			if (ok) {
				[[self pathWatches] removeObject:targetPathWatch] ;
			}
		}
	}
	
	return ok ;
}

- (void)setIsWatching:(BOOL)yn {	
	@synchronized(self) {
		m_isWatching = yn ;
	}
}

@end