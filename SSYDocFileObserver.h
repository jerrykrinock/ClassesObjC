#import <Cocoa/Cocoa.h>

@class SSYPathObserver ;

extern NSString* const SSYDocFileMovedNotification ;
extern NSString* const SSYDocFileReplacedNotification ;

extern NSString* const SSYDocFileOriginalURLKey ;
extern NSString* const SSYDocFileNewPathKey ;
extern NSString* const SSYDocFileErrorGettingNewPathKey ;

extern NSString* const SSYDocFileObserverErrorDomain ;

/*!
 @brief    An observer class which sends out a notification forthwith if
 the file underlying its subject document is ever moved or replaced with
 another file.
 
 @details  One would think that an alternative to using this class would
 be to observe NSDocument's key path 'fileURL'.  Strangely, that does
 not change until the *application* is de-activated and the reactivated.
 (De/reactivating the document window is not good enough.)  Apparently,
 Apple has designed it to work if the user changes a file in Finder, but
 not if some background app (such as the Dropbox client) does it.
 
 This class works by registering a kqueue observation for a file to be
 moved (= renamed, in Unix parlance).  When the kqueue fires it waits
 1.0 second for a new file to appear in its place.  If a new file appears,
 it issues an SSYDocFileReplacedNotification.  If no new file appears after
 1.0 second, it issues an SSYDocFileMovedNotification.  In either case,
 the notification object is the document being watched, and its userInfo
 dictionary contains one key, SSYDocFileOriginalURLKey, whose value is the
 original fileURL that the document had when the receiver was initialized.
 
 To use this class, first wait until the the document you're interested
 in watching has a fileURL.  Not during -init.  We recommend establishing
 KVO on the document's fileURL and doing this in the observer after it is
 changed to a non-nil value.
 
 The following is from a post I sent to Dropbox Developer Forum:
 
 http://forums.dropbox.com/topic.php?id=20771
 
 By setting the Dropbox download throttle to a low value, I've confirmed that
 nothing happens until the download (and processing?) is complete. Then, as
 I expected, the Dropbox client app moves the old file to the ~/.dropbox/cache
 archive and finally moves in the new file. However, what it's actually doing
 at the Unix level, of course, is to rename the paths of the virtual
 filesystem nodes (vnodes). This causes a slight issue with the kqueue... Even
 when I monitor for all seven kqueue events (DELETE, WRITE, EXTEND, ATTRIB,
 LINK, RENAME, REVOKE), I only get one notification, that of RENAME.  The
 reason is because, although I register the kqueue observation by giving
 kqueue a path, it actually monitors the vnode.  So when the Dropbox client
 app "moves" (actually, renames) this file to the archive, kqueue "follows the
 data".  To verify this, I renamed a file after it was moved into the archive,
 now at a different path than what I had registered for and, yup, my kqueue
 observer still fired.
 
 So I have no problem seeing that someone moved a file to the archive, but I
 still need to know (a) if this is really a file replacement by Dropbox, or if
 someone just decided to trash the file and (b) how long I need to wait before
 the updated file is in place and available for reading. The empirical
 evidence I've gathered leads to one ugly solution -- just wait a reasonable
 time and see if a (new) file exists at the old path. What's reasonable? I've
 found that 0 milliseconds is not sufficient, but 50 milliseconds is OK, after
 testing it twice.  Ugly stuff.  Delaying even a few seconds would be
 acceptable; therefore a fairly robust algorithm might be: Check for the
 replacement file, oh, every 1.0 seconds or so, for 10 seconds. If something
 appears, open it. If nothing appears after 10 seconds, assume that this was a
 trashing action by the user and not a replacement by the Dropbox client app.
 
 I suppose I could monitor the file's original parent directory (the Dropbox)
 for an addition, using either kqueue or FSEvents, but it seems that a signal
 or status output from the Dropbox client app saying "I'm done now and my
 queue is empty" would be a much nicer solution.
 */
@interface SSYDocFileObserver : NSObject {
	NSDocument* m_document ; // weak reference
	SSYPathObserver* m_pathObserver ;
	NSURL* m_originalURL ;
	BOOL m_retainedByTimer ;
}

/*!
 @brief    Initializes a new SSYDocFileObserver instance
 
 @details  If the document's fileURL is nil, or if a kqueue
 cannot be established on it, this method returns nil and
 sets a value on error_p, if it is non-nil.
 @param    document  The document whose fileURL the receiver
 should observe.  The receiver keeps this as a weak reference
 until it is deallocced, so be careful.
 */
- (id)initWithDocument:(NSDocument*)document
			   error_p:(NSError**)error_p ;

@end