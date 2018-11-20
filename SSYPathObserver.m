#import <errno.h>
#import "SSYPathObserver.h"
#import "NSObject+MoreDescriptions.h"
#import "NSError+LowLevel.h"


NSString* const SSYPathObserverErrorDomain        = @"SSYPathObserverErrorDomain" ;
NSString* const SSYPathObserverChangeNotification = @"SSYPathObserverChangeNotification" ;
NSString* const SSYPathObserverPathKey            = @"Path" ;
NSString* const SSYPathObserverFileDescriptorKey  = @"FileDescriptor" ;
NSString* const SSYPathObserverChangeFlagsKey     = @"Flags" ;
NSString* const SSYPathObserverUserInfoKey        = @"UserInfo" ;
NSString* const SSYPathObserverWatcherThread      = @"SSYPathObserverWatcher" ;

/*!
 @brief    Encapsulates attributes of a path watch within SSYPathObserver
 */
@interface SSYPathWatch : NSObject {
	NSString* m_path ;
	id m_userInfo ;
	uint32_t m_fileDescriptor ;
	NSThread* m_notifyThread ;
}

@property (retain) NSString* path ;
@property (retain) id userInfo ;
@property (assign) uint32_t fileDescriptor ;  // file descriptor for the path/file which is being watched
@property (assign) uint32_t watchFlags;
@property (assign) NSThread* notifyThread ;

@end


@implementation SSYPathWatch

@synthesize path = m_path ;
@synthesize userInfo = m_userInfo ;
@synthesize fileDescriptor = m_fileDescriptor ;
@synthesize notifyThread = m_notifyThread ;

- (NSString*)description {
	return [NSString stringWithFormat:
			@"<%@ %p> fd=%ld, path=%@, userInfo=%@",
			[self className],
			self,
			(long)[self fileDescriptor],
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
@property (assign) uint32_t kqueueFileDescriptor ;

@end


@implementation SSYPathObserver

@synthesize pathWatches = m_pathWatches ;
@synthesize kqueueFileDescriptor = m_kqueueFileDescriptor ;  // file descriptor for the kqueue

/*
 Note that this method is always invoked by the watcher
 thread, not the main thread.  See commments in -release.
 */
- (void)dealloc {
	[self setPathWatches:nil] ;
	
	[super dealloc] ;
}

- (void)watchAndWait {
	/* Note that, in macOS 10.5, we may kill this thread in -release.
	 In Apple's Threading Programming Guide > Terminating a Thread,
	 killing a thread is "strongly discouraged" because memory or other
	 resources may be leaked and cause problems later.  One of the
	 reasons for using the @synchronized blocks in here, and *the*
	 reason for using the *two* autorelease pools, is to keep
	 memory from being leaked.  The call to pthread_kill() in -release,
	 as well as the two blocks of code in this method that allocate
	 memory temporarily and then release their autorelease pool, are
	 @synchronized so that killing cannot occur while memory is
	 allocated.  Of course, this is rarely needed because
	 99.9999% of the time that the thread is killed, it's going to be
	 camping on kevent(), outside of these two blocks of code, but,
	 oh, well if you don't try to write perfect code, you'll have
	 lots of bugs. */
	
	int fileDescriptor ;
	@synchronized(self) {
		NSAutoreleasePool* pool1 = [[NSAutoreleasePool alloc] init] ;
		
		[[NSThread currentThread] setName:SSYPathObserverWatcherThread] ;

		fileDescriptor = [self kqueueFileDescriptor] ;
		
		[pool1 release] ;
	}

	
	struct kevent event ;	

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
					NSAutoreleasePool* pool2 = [[NSAutoreleasePool alloc] init] ;
					// Retain pathWatch here, in case of the unlikely event that
					// pathWatch has just been removed on another thread
					[pathWatch retain] ;
                    NSString* path = [pathWatch path];
                    NSDictionary* pathWatchUserInfo = [pathWatch userInfo];
                    NSThread* notifyThread = [pathWatch notifyThread];
					if ([self isWatching]) {
						NSNumber* filterFlags = [NSNumber numberWithInteger:event.fflags] ;
						NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
												  filterFlags, SSYPathObserverChangeFlagsKey,
												  path, SSYPathObserverPathKey,
												  [NSNumber numberWithInteger:[pathWatch fileDescriptor]], SSYPathObserverFileDescriptorKey,
												  pathWatchUserInfo, SSYPathObserverUserInfoKey,  // may be nil
												  nil] ;
						NSNotification* note = [NSNotification notificationWithName:SSYPathObserverChangeNotification
																			 object:self
																		   userInfo:userInfo] ;
						[[NSNotificationCenter defaultCenter] performSelector:@selector(postNotification:)
																	 onThread:notifyThread
																   withObject:note
																waitUntilDone:NO] ;
					}

					/* In some cases, I think if the event we re no processing was
                     caused by an external actor *replacing* the file at the watched
                     path with a new file, our path watch will be watching the old file
                     which no longer exists, and therefore we will not get any subsequent
                     events when the *new* file at the watched path is touched.  Although I
                     have not verified that such file replacement is the cause, I have
                     definitely seen kqueues "die" like this.  I think it's a good theory,
                     and in at least one reproducible case, the following code, which
                     removes the "used" path watch adds back a new one) fixed the problem.
                     I theorize this is due to the fact that destroying the path watch
                     closes its (watched) file descriptor, and creating a new path
                     watch opens a new file descriptor.  I did verify that the new file
                     descriptor integer value is the same as the old one; presumably
                     the system uses the lowest unused file descriptor which is the old
                     one that was just released. */
                    BOOL ok;
                    NSError* error = nil;
                    ok = [self removePath:path
                                  error_p:&error];
                    NSAssert(ok, @"Error removing used path from kqueue : %@", error);
                    uint32_t watchFlags = pathWatch.watchFlags;
                    [pathWatch release] ;
                    [self addPath:path
                       watchFlags:watchFlags
                     notifyThread:notifyThread
                         userInfo:pathWatchUserInfo
                          error_p:&error];
                    NSAssert(ok, @"Error renewing used path from kqueue : %@", error);

					[pool2 release] ;
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
} 

    
-(id)init {
	self = [super init] ;
	if (self) {	
		[self setIsWatching:YES] ;
		[self setPathWatches:[NSMutableSet set]] ;

		uint32_t kqueueFileDescriptor = kqueue() ;
		if (kqueueFileDescriptor == -1) {
			NSLog(@"Internal Error 153-9092.  Failed creating kqueue") ;
			// See http://lists.apple.com/archives/Objc-language/2008/Sep/msg00133.html ...
			[super dealloc] ;
			self = nil ;
		}
		else {
			[self setKqueueFileDescriptor:kqueueFileDescriptor] ;
			[NSThread detachNewThreadSelector:@selector(watchAndWait)
									 toTarget:self
								   withObject:nil] ;
			m_isAlive = YES ;
		}
	}
	
	return self ;
}

#if 0
#define DEBUG_LOG_KQUEUE_SETTINGS 1
#endif

#if DEBUG_LOG_KQUEUE_SETTINGS
- (NSString*)readableStringForFlags:(u_short)flags {
    NSMutableString* s = [[NSMutableString alloc] init] ;
    if ((flags & NOTE_DELETE) != 0) {
        [s appendString:@", Delete-Remove"] ;
    }
    if ((flags & NOTE_WRITE) != 0) {
        [s appendString:@", Write-Change"] ;
    }
    if ((flags & NOTE_EXTEND) != 0) {
        [s appendString:@", Extend-Bigger"] ;
    }
    if ((flags & NOTE_ATTRIB) != 0) {
        [s appendString:@", Change-Attribs"] ;
    }
    if ((flags & NOTE_LINK) != 0) {
        [s appendString:@", Change-Link-Count"] ;
    }
    if ((flags & NOTE_RENAME) != 0) {
        [s appendString:@", Rename-File"] ;
    }
    if ((flags & NOTE_REVOKE) != 0) {
        [s appendString:@", Revoke-Access"] ;
    }
    if ((flags & NOTE_NONE) != 0) {
        [s appendString:@", None-Test"] ;
    }
    
    if ([s length] > 2) {
        // Remove leading @", "
        [s deleteCharactersInRange:NSMakeRange(0,2)] ;
    }
    
    NSString* answer = [s copy] ;
    [s release] ;
    [answer autorelease] ;
    
    return answer ;
}
#endif

/*!
 @param    pathWatch  Not nil
 @param    doAdd  YES to add, NO to remove
 @param    flags If 0, this means "all 7 flags"
 @result   YES if successful
 */
- (BOOL)kqueueRegisterPathWatch:(SSYPathWatch*)pathWatch
						  doAdd:(BOOL)doAdd
						  flags:(uint32_t)flags
						error_p:(NSError**)error_p ; {
	// Create kevent
	u_short actionFlags = doAdd ? (EV_ADD | EV_ENABLE) : (EV_DELETE | EV_DISABLE) ;
	actionFlags |= EV_CLEAR ;
	uint32_t fflags = (flags != 0) ? flags :
	+ NOTE_DELETE
	+ NOTE_WRITE
	// Not a popular/default flag: + NOTE_EXTEND
	// Not a popular/default flag: + NOTE_ATTRIB
	// Not a popular/default flag: + NOTE_LINK
	+ NOTE_RENAME
	// Not a popular/default flag: + NOTE_REVOKE 
	;
	
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
	
#if DEBUG_LOG_KQUEUE_SETTINGS
    NSLog(@"%@ kqueue on %@\nfilters: %@", doAdd?@"Added":@"Removed",
          [pathWatch path],
          [self readableStringForFlags:fflags]) ;
#endif
 	NSInteger result = kevent(
							  [self kqueueFileDescriptor],  // Our kqueue
							  &myEvent,                     // list of events we want to change, const struct kevent
							  1,                            // number of items in the above list, int
							  NULL,                         // list of events that the kqueue is reporting, struct kevent
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

- (oneway void)release {
	// The default behavior of -release is to decrement retainCount if
	// retainCount is greater than 1, and otherwise invoke -dealloc.
	//
	// However, we need to break a little retain cycle.  The problem
	// is that the watcher thread which we detached in -init has retained
	// us twice (once as the target and once as the object), and
	// does not balance those with a release until it exits.  Therefore
	// we will not be deallocced until that thread exits, and if we
	// put the following code in -dealloc, we would not force that
	// thread to exit until we are deallocced.  The solution, copied
	// from UKKqueue, is to force that thread to exit here, when
	// the retain count is 2.
	
	// After spending a fewe hours considering how best to do this,
	// I decided that Uli's method was best.  The next best alternative
	// was to define a -releaseResources method which would do the
	// stuff in the if() block below, and require the
	// developer to invoke it "manually" before allowing
	// SSYPathObserver to dealloc.
	
	// When the if() block below runs and causes the watcher thread
	// to exit, this method will be invoked two more times
	// (with retainCounts equal to 2 and 1, respectively), from the
	// watcher thread.  Of course, these last two times, the if()
	// block will not execute and it will immediately invoke super.
	@synchronized(self) {
		if (([self retainCount] == 2) && m_isAlive) {
			m_isAlive = NO ;
			
			// Close any file descriptors which might still be open
			for (SSYPathWatch* pathWatch in [self pathWatches]) {
				// Unregister kqueue of the target pathWatch
				uint32_t fileDescriptor = [pathWatch fileDescriptor] ;
				NSInteger result = close(fileDescriptor) ;
				if (result != 0) {
				}
			}

			uint32_t kqfd = [self kqueueFileDescriptor] ;
			
			// The following causes the watcher thread to exit.
			close (kqfd) ;
		}
	}

	[super release] ;
	return ;
}

#if 0
- (id)autorelease {
	id x = [super autorelease] ;
	return x ;
}
#endif


- (BOOL)addPath:(NSString*)path
	 watchFlags:(uint32_t)watchFlags
   notifyThread:(NSThread*)notifyThread
	   userInfo:(id)userInfo
		error_p:(NSError**)error_p {
	if (!path) {
		return YES ;
	}
	
	BOOL ok = YES ;
	
	// Get file descriptor for given path
	uint32_t fileDescriptor = open([path UTF8String], O_RDONLY) ;	
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
	[pathWatch setNotifyThread:(notifyThread ? notifyThread : [NSThread mainThread])] ;
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

- (NSSet*)currentlyWatchedPaths {
    NSMutableSet* paths = [NSMutableSet new];
    if (self.isWatching) {
        for (SSYPathWatch* pathWatch in [self pathWatches]) {
            [paths addObject:pathWatch.path];
        }
    }

    NSSet* answer = [paths copy];
    [paths release];
    [answer autorelease];

    return answer;
}



@synthesize isWatching = m_isWatching ;

@end
