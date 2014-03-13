#import "SSYDocFileObserver.h"
#import "SSYPathObserver.h"
#import "NSError+InfoAccess.h"
#import "NSFileManager+SomeMore.h"
#import "NSFileManager+SSYFileDescriptor.h"
#import <sys/event.h>

NSString* const SSYDocFileMovedNotification = @"SSYDocFileMovedNotification" ;
NSString* const SSYDocFileReplacedNotification = @"SSYDocFileReplacedNotification" ;

NSString* const SSYDocFileOriginalURLKey = @"SSYDocFileOriginalURLKey" ;
NSString* const SSYDocFileNewPathKey = @"SSYDocFileNewPathKey" ;
NSString* const SSYDocFileErrorGettingNewPathKey = @"SSYDocFileErrorGettingNewPathKey" ;

NSString* const SSYDocFileObserverErrorDomain = @"SSYDocFileObserverErrorDomain" ;

@interface SSYDocFileObserver ()

@property (assign) NSDocument* document ;
@property (retain) NSURL* originalURL ;

@end

@implementation SSYDocFileObserver

@synthesize document = m_document ;
@synthesize originalURL = m_originalURL ;

- (SSYPathObserver*)pathObserver {
	if (!m_pathObserver) {
		m_pathObserver = [[SSYPathObserver alloc] init] ;
	}
	
	return m_pathObserver ;
}

- (id)initWithDocument:(NSDocument*)document
			   error_p:(NSError**)error_p {
	self = [super init] ;
	BOOL ok = YES ;

	if (self) {
		[self setDocument:document] ;
		NSURL* url = [[self document] fileURL] ;
		
		ok = YES ;
		if (!url) {
			if (error_p) {
				*error_p = [NSError errorWithDomain:SSYDocFileObserverErrorDomain
											   code:905101
										   userInfo:[NSDictionary dictionaryWithObject:@"Nil fileURL"
																				forKey:NSLocalizedDescriptionKey]] ;
			}

			ok = NO ;
			goto end ;
		}

		NSString* path = [url path] ;
		[self setOriginalURL:url] ;
		
		if ([[NSFileManager defaultManager] fileIsPermanentAtPath:path]) {		
			NSError* underlyingError ;

			/*
             Test results on 2014-01-08
             When file is updated by Dropbox, you only get one change flag,
             *  SSYPathObserverChangeFlagsRename    = 0x20
             When file is updated by ChronoSync, you get the sume of two change flags,
             *  SSYPathObserverChangeFlagsDelete    = 0x01
             *  SSYPathObserverChangeFlagsLinkCount = 0x10
             The following was changed in BookMacster 1.20.2, to catch updates
             by both Dropbox and ChronoSync.
             */
            uint32_t watchFlags = (SSYPathObserverChangeFlagsRename | SSYPathObserverChangeFlagsDelete) ;

			ok = [[self pathObserver] addPath:path
								   watchFlags:watchFlags
								 notifyThread:nil
									 userInfo:nil
									  error_p:&underlyingError] ;
			if (!ok) {
				if (error_p) {
					*error_p = [NSError errorWithDomain:SSYDocFileObserverErrorDomain
												   code:905102
											   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
														 @"Adding path to kqueue failed", NSLocalizedDescriptionKey,
														 path, @"Path",  // Should not be nil, but maybe it might be
														 nil]] ;
					*error_p = [*error_p errorByAddingUnderlyingError:underlyingError] ;		
				}
				
				goto end ;
			}
		}
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(pathChangedNote:)
													 name:SSYPathObserverChangeNotification
												   object:[self pathObserver]] ;
		
	}
	
end:
	if (!ok) {
		// See http://lists.apple.com/archives/Objc-language/2008/Sep/msg00133.html ...
		[super dealloc] ;
		self = nil ;
	}	
	
	return self ;
}

- (oneway void)release {
	// Make sure that our being self-retained does not keep us from being
	// deallocced.  Below, -[super release] will invoke -dealloc if
	// retainCount==1.  But we don't want our being self-retained by a timer
	// to affect that retain count for purposes of dealloc.  So if we're in
    // that dealloc situation, we need to cancel the performSelector.
	if (([self retainCount] == 2) && m_retainedByPerformSelector) {
		// 
		m_retainedByPerformSelector = NO ;
        // The following line has a bug fixed in BookMacster 1.17.  Prior to
        // that, @selector(analyzePathChange:) was lacking the colon!
		[NSObject cancelPreviousPerformRequestsWithTarget:self
												 selector:@selector(analyzePathChange:)
												   object:nil] ;
		// But we don't invoke -dealloc directly.  The above cancellation
		// will send us a -release (since the timer retains us) which
		// will cause this method to be re-entered.  Upon re-entry,
		// m_retainedByPerformSelector will be NO, so this branch will not execute,
		// but super will be invoked, with a retainCount of 2, which will
		// reduce the retain count to 1.  When super returns, we will execute
		// from this comment, invoking super a second time, which, because
		// retainCount == 1, will now cause -dealloc to be invoked.
	}
	
	[super release] ;
	return ;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self] ;
	[m_pathObserver release] ;
	[m_originalURL release] ;
	
	[super dealloc] ;
}

- (void)pathChangedNote:(NSNotification*)note {
	// No need to look at flags since we registered for only SSYPathObserverChangeFlagsRename.
	
#if 0
#warning Debugging SSYDocFileObserver
	NSLog(@"Received notification of filesystem change:\n"
		  "   Path:           %@\n"
		  "   FileDescriptor: %ld\n"
		  "   Change Flags:   0x%lx\n"
		  "   UserInfo:       %@\n",
		  [[note userInfo] objectForKey:SSYPathObserverPathKey],
		  (long)[[[note userInfo] objectForKey:SSYPathObserverFileDescriptorKey] integerValue],
		  (long)[[[note userInfo] objectForKey:SSYPathObserverChangeFlagsKey] integerValue],
		  [[note userInfo] objectForKey:SSYPathObserverUserInfoKey]) ;
#endif
	
	m_retainedByPerformSelector = YES ;
	
	[self performSelector:@selector(analyzePathChange:)
			   withObject:[note userInfo]
			   afterDelay:1.0] ;
}

- (void)analyzePathChange:(NSDictionary*)userInfoFromPathObserver {
	m_retainedByPerformSelector = NO ;
	
	NSMutableDictionary* userInfo = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
									 [self originalURL], SSYDocFileOriginalURLKey,
									 nil] ;
	
	NSString* notificationName ;
	if ([[NSFileManager defaultManager] fileExistsAtPath:[[self originalURL] path]]) {
		// File has been REPLACED
		notificationName = SSYDocFileReplacedNotification ;
	}
	else {
		// File has merely MOVED
		notificationName = SSYDocFileMovedNotification ;
		NSNumber* fileDescriptor = [userInfoFromPathObserver objectForKey:SSYPathObserverFileDescriptorKey] ;
		NSError* error = nil ;
		NSString* newPath = [NSFileManager pathForFileDescriptor:[fileDescriptor integerValue]
															 pid:0 // this process
														 error_p:&error] ;
		if (newPath) {
			[userInfo setObject:newPath
						 forKey:SSYDocFileNewPathKey] ;
		}
		else {
			[userInfo setValue:error
						forKey:SSYDocFileErrorGettingNewPathKey] ;
		}
	}
	
	NSDocument* document = [self document] ;
	if (document) {
		[[NSNotificationCenter defaultCenter] postNotificationName:notificationName
															object:document
														  userInfo:userInfo] ;
	}
	else {
		NSLog(@"Internal Error 513-8943") ;
	}
			 
	[userInfo release] ;
}

@end