#import "SSYLoginItems.h"
#import "NSError+LowLevel.h"


NSString* const constSSYLoginItemsErrorDomain = @"SSYLoginItemsErrorDomain" ;
NSInteger const SSYLoginItemsCouldNotResolveExistingItemErrorCode = 144770 ;
NSInteger const SSYLoginItemsCouldNotResolveGivenItemErrorCode = 144771 ;
NSInteger const SSYLoginItemsCouldNotCreateFileListErrorCode = 144772 ;
NSInteger const SSYLoginItemsCouldNotInsertItemErrorCode = 144773 ;
NSInteger const SSYLoginItemsCouldNotRemoveItemErrorCode = 144774 ;
NSInteger const SSYLoginItemsCallerGaveNilPathErrorCode = 144775 ;

/*
 Unlike [object release], which is a no-op if object is nil,
 CFRelease(itemRef) will cause a crash if itemRef is NULL.
 So, we use this idea, which is the same as CFQRelease()
 in Quinn "The Eskimo"'s MoreCFQ.c.
 */
static void CFSafeRelease(CFTypeRef item) {
	if (item != NULL) {
		CFRelease(item) ;
	}
}

@implementation SSYLoginItems

/*
 Note "create" in name.  Invoker must release the result.
 */
+ (BOOL)createLoginItemsList:(LSSharedFileListRef*)list_p 
					   error:(NSError**)error_p {
	if (error_p != NULL) {
		*error_p = nil ;
	}
	
	BOOL ok = NO ;
	
	if (list_p != NULL) {
		ok = YES ;
		*list_p = LSSharedFileListCreate(
										 kCFAllocatorDefault,
										 kLSSharedFileListSessionLoginItems,
										 NULL) ;
		if (*list_p == NULL) {
			if (error_p != NULL) {
				*error_p = [NSError errorWithDomain:constSSYLoginItemsErrorDomain
											   code:SSYLoginItemsCouldNotCreateFileListErrorCode
										   userInfo:nil] ;
			}
			ok = NO ;
		}
	}
	
	return ok ;
}

/*
 Note "copy" in name.  Invoker must release the result.
*/
+ (BOOL)copySnapshotOfLoginItems:(CFArrayRef*)snapshot_p 
						   error:(NSError**)error_p {
	if (error_p != NULL) {
		*error_p = nil ;
	}
	
	LSSharedFileListRef list ;
	BOOL ok = [self createLoginItemsList:&list
								   error:error_p] ;
	if (!ok) {
		// error_p has already been assigned
		goto end ;
	}
	
	if (snapshot_p != NULL) {
		UInt32 seed ;
		*snapshot_p = LSSharedFileListCopySnapshot(
												 list,
												 &seed) ;
		//NSLog(@"Snapshot seed = %x (What the hell is this used for?)", seed) ;  // It always returns 1 for me.
	}
	
end:
	CFSafeRelease(list) ;

	return ok ;
}

/* This is very weird.  The snapshot_p is a pointer to a
 CFArrayRef which the invoker must provide.  It
 will be set to a CFArray which the invoker must release when
 it is done with the ref_p.
 */
+ (BOOL)loginItemWithURL:(NSURL*)url
					 ref:(LSSharedFileListItemRef*)ref_p
			  snapshot_p:(CFArrayRef*)snapshot_p
				   error:(NSError**)error_p {
	if (error_p != NULL) {
		*error_p = nil ;
	}
	BOOL ok ;
	
	LSSharedFileListItemRef targetItem = NULL ;
	if (url == nil) {
		goto end ;
	}
	
	// First, get a snapshot of all login items
	ok = [self copySnapshotOfLoginItems:snapshot_p
								  error:error_p] ;
	if (!ok) {
		// error_p has already been assigned
		goto end ;
	}
	
	// Now, iterate through the items in the snapshot.  Resolve each item
	// to a URL, and if it matches the given URL, assign it to targetItem
	// and break.
	OSStatus status = noErr ;
	NSInteger i = 1 ;
	for (id item in (NSArray*)*snapshot_p) {
		NSURL* aURL = nil ;
		status = LSSharedFileListItemResolve(
											  (LSSharedFileListItemRef)item,
											  0,
											  (CFURLRef*)&aURL,
											  NULL) ;
		if ((status == noErr) && (aURL != nil)) {
			if ([aURL isEqual:url]) {
				targetItem = (LSSharedFileListItemRef)item ;
				break ;
			}
		}
		else {
			// This branch will execute if any of the user's Login Items in System Preferences
			// references a path has been deleted (not trashed, deleted).  (It may execute
			// in other situations also.  We don't know, due to lack of LSSharedFileList
			// documentation from Apple.)
			if (error_p) {
				NSError* error = [NSError errorWithMacErrorCode:status] ;
				NSString* msg = @"LSSharedFileListItemResolve failed" ;
				NSString* path = [url path] ;
				if (!path) {
					path = [url absoluteString] ;
				}
				if (!path) {
					path = [url description] ;
				}
				
				NSMutableDictionary* userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
												 msg, NSLocalizedDescriptionKey,  // won't be nil
												 error, NSUnderlyingErrorKey,     // won't be nil
												 [NSNumber numberWithInt:i], @"Broken Item Index",  // won't be nil
												 path , @"Path Looking For",   // might be nil
												 nil] ;

				msg = [NSString stringWithFormat:
					   @"While we were analyzing your Login Items for proper settings, "
					   @"the Mac OS told us that it could not find item %d.  "
					   @"It returned an error status code %d.",
					   i,
					   status] ;
				[userInfo setObject:msg
							 forKey:NSLocalizedFailureReasonErrorKey] ;

				if ((status == fnfErr) || (status == nsvErr)) {				
					msg = [NSString stringWithFormat:
						   @"In the %C menu, click 'System Preferences', then the 'Users & Groups' or 'Accounts' button.  "
						   @"Select your account from the list, and then the 'Login Items' tab.  "
						   @"Starting with number 1 at the top of the list, count down until you reach item %d.  "
						   @"If its 'Kind' is 'Unknown', this item has probably disappeared.  "
						   @"Otherwise, hover your mouse over it until its path appears in a tooltip.  "
						   @"Then activate Finder and navigate to that path.\n\n"
						   @"In either case, if the app indicated by that Login Item is indeed no longer available, you should delete that Login Item.  "
						   @"To delete a Login Item, select it and click the [-] button.",
						   0xf8ff, // The Apple character
						   i] ;
					[userInfo setObject:msg
								 forKey:NSLocalizedRecoverySuggestionErrorKey] ;
				}
				
				error = [NSError errorWithDomain:constSSYLoginItemsErrorDomain
											code:SSYLoginItemsCouldNotResolveExistingItemErrorCode
										userInfo:userInfo] ;
				*error_p = error ;
			}
			ok = NO ;
			break ;
		}
		i++ ;
	}
	
end:
	if (ref_p != NULL) {
		*ref_p = (LSSharedFileListItemRef)targetItem ;
	}
	
	return (ok) ;
}

+ (BOOL)isURL:(NSURL*)url
	loginItem:(NSNumber**)loginItem_p
	   hidden:(NSNumber**)hidden_p
		error:(NSError**)error_p {
	if (error_p != NULL) {
		*error_p = nil ;
	}
	if (url == nil) {
		goto end ;
	}
	
	LSSharedFileListItemRef targetItem = NULL ;
	CFArrayRef snapshot = NULL ;
	
	BOOL ok = [self loginItemWithURL:url
								 ref:&targetItem
						  snapshot_p:&snapshot
							   error:error_p] ;
	if (!ok) {
		// error_p has already been assigned
		goto end ;
	}
	
	BOOL isLoginItem = (targetItem != nil) ;
	
	if (loginItem_p != NULL) {
		*loginItem_p = [NSNumber numberWithBool:isLoginItem] ;
	}

	if (isLoginItem) {
		if (hidden_p != NULL) {
			*hidden_p = (NSNumber*)LSSharedFileListItemCopyProperty(
																	(LSSharedFileListItemRef)targetItem,
																	kLSSharedFileListItemHidden) ;
			// Documentation says to release this
			CFSafeRelease(*hidden_p) ;
		}
	}
	
end:
	if (*error_p) {
		int code = [*error_p code] ;
		NSString* domain = [*error_p domain] ;
		NSMutableDictionary* userInfo = [[*error_p userInfo] mutableCopy] ;
		[userInfo setObject:NSStringFromSelector(_cmd)
					 forKey:@"Method Name"] ;
		NSString* urlString = [url absoluteString] ;
		if (urlString) {
			[userInfo setObject:urlString
						 forKey:@"Url"] ;
		}
		*error_p = [NSError errorWithDomain:domain
									   code:code
								   userInfo:userInfo] ;
		[userInfo release] ;	
	}
	CFSafeRelease(snapshot) ;
	return ok ;
}

+ (BOOL)addLoginURL:(NSURL*)url
			 hidden:(NSNumber*)hidden
			  error:(NSError**)error_p {
	if (error_p != NULL) {
		*error_p = nil ;
	}
	NSDictionary* propsToSet = [NSDictionary dictionaryWithObject:hidden
														   forKey:(id)kLSSharedFileListItemHidden] ;
	LSSharedFileListRef loginItems ;
	BOOL ok = [self createLoginItemsList:&loginItems
								   error:error_p] ;
	
	if (!ok) {
		// error_p has already been assigned
		goto end ;
	}
	
	LSSharedFileListItemRef item ;
	item = LSSharedFileListInsertItemURL(
										 loginItems,
										 kLSSharedFileListItemLast,
										 NULL,
										 NULL,
										 (CFURLRef)url,
										 (CFDictionaryRef)propsToSet,
										 NULL) ;
	
	if (item == NULL) {
		if (error_p != NULL) {
			*error_p = [NSError errorWithDomain:constSSYLoginItemsErrorDomain
										   code:SSYLoginItemsCouldNotInsertItemErrorCode
									   userInfo:[NSDictionary dictionaryWithObject:@"LSSharedFileListInsertItemURL returned error"
																			forKey:NSLocalizedDescriptionKey]] ;
		}
	}
	else {
		// Documentation for LSSharedFileListInsertItemURL says I should release
		// (Maybe because CF does not feature autorelease?)
		CFRelease(item) ;
	}

end:
	CFSafeRelease(loginItems) ;
	
	return ok ;
}

+ (BOOL)removeLoginItemRef:(LSSharedFileListItemRef)item
					 error:(NSError**)error_p {
	if (error_p != NULL) {
		*error_p = nil ;
	}
	BOOL ok ;
	
	LSSharedFileListRef loginItems ;
	ok = [self createLoginItemsList:&loginItems
							  error:error_p] ;
	if (!ok) {
		// error_p has already been assigned
		goto end ;
	}
	
	OSStatus status ;
	status = LSSharedFileListItemRemove(
										loginItems,
										item) ;
	if (status != noErr) {
		if (error_p != NULL) {
			*error_p = [NSError errorWithMacErrorCode:status] ;
			*error_p = [NSError errorWithDomain:constSSYLoginItemsErrorDomain
										   code:SSYLoginItemsCouldNotRemoveItemErrorCode
									   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
												 @"LSSharedFileListItemRemove returned error", NSLocalizedDescriptionKey,
												 *error_p, NSUnderlyingErrorKey,
												 nil]] ;
		}
		ok = NO ;
		goto end ;
	}
	
end:
	CFSafeRelease(loginItems) ;
	
	return (ok) ;
}

+ (BOOL)removeLoginURL:(NSURL*)url
				 error:(NSError**)error_p {
	if (error_p != NULL) {
		*error_p = nil ;
	}
	
	LSSharedFileListItemRef item = NULL ;
	CFArrayRef snapshot = NULL ;
	BOOL ok = [self loginItemWithURL:url
								ref:&item
						  snapshot_p:&snapshot
							  error:error_p] ;

	if (ok && (item != NULL)) {
		[self removeLoginItemRef:item
						   error:error_p] ;
	}
	else {
		// error_p has already been assigned
		// We are already at the end goto end ;
	}
	
	CFSafeRelease(snapshot) ;
	
	if (*error_p) {
		int code = [*error_p code] ;
		NSString* domain = [*error_p domain] ;
		NSMutableDictionary* userInfo = [[*error_p userInfo] mutableCopy] ;
		[userInfo setObject:NSStringFromSelector(_cmd)
					 forKey:@"Method Name"] ;
		NSString* urlString = [url absoluteString] ;
		if (urlString) {
			[userInfo setObject:urlString
						 forKey:@"Url"] ;
		}
		*error_p = [NSError errorWithDomain:domain
									   code:code
								   userInfo:userInfo] ;
		[userInfo release] ;	
	}
	return ok ;	
}

/*
 If dontDeletePath is nil, will delete all of current user's
 login items with name
 */
+ (BOOL)loginItemsWithAppName:(NSString*)name
					notInPath:(NSString*)dontDeletePath
						 refs:(NSArray**)refs_p
						error:(NSError**)error_p {
	if (error_p != NULL) {
		*error_p = nil ;
	}
	
	CFArrayRef snapshot ;
	BOOL ok = [self copySnapshotOfLoginItems:&snapshot
									   error:error_p] ;
	if (!ok) {
		// error_p has already been assigned
		goto end ;
	}
		
	OSStatus status = noErr ;
	name = [name stringByDeletingPathExtension] ;
	NSMutableArray* mutableRefs = [NSMutableArray array] ;
	for (id item in (NSArray*)snapshot) {
		NSURL* aURL ;
		BOOL breakAfterCleanup = NO ;
		status = LSSharedFileListItemResolve(
											  (LSSharedFileListItemRef)item,
											  0,
											  (CFURLRef*)&aURL,
											  NULL) ;
		if (status == noErr) {
			NSString* aPath = [aURL path]  ;
			if ((dontDeletePath == nil) || ![dontDeletePath isEqualToString:aPath]) {
				NSString* aName = [[aPath lastPathComponent] stringByDeletingPathExtension]  ;
				if ([aName isEqual:name]) {
					[mutableRefs addObject:(id)item] ;
				}
			}
		}
		else {
			breakAfterCleanup = YES ;
		}

		// Documentation says to release this
		// (Maybe because CF does not feature autorelease?)
		////CFSafeRelease(aURL) ;
		
		if (breakAfterCleanup) {
			break ;
		}
	}
	
	if (status != noErr) {
		if (error_p != NULL) {
			*error_p = [NSError errorWithDomain:constSSYLoginItemsErrorDomain
										   code:SSYLoginItemsCouldNotResolveGivenItemErrorCode
									   userInfo:[NSDictionary dictionaryWithObject:@"LSSharedFileListItemResolve returned error"
																			forKey:NSLocalizedDescriptionKey]] ;
		}
		ok = NO ;
		goto end ;
	}
	
end:
	CFSafeRelease(snapshot) ;
	
	if (refs_p != NULL) {
		*refs_p = [NSArray arrayWithArray:mutableRefs] ;
	}
	
	return (ok) ;
}


+ (SSYSharedFileListResult)synchronizeLoginItemPath:(NSString*)path
								  shouldBeLoginItem:(BOOL)shouldBeLoginItem
										  setHidden:(BOOL)setHidden 
											  error:(NSError**)error_p {
	if (error_p != NULL) {
		*error_p = nil ;
	}
	SSYSharedFileListResult result ;
	result = SSYSharedFileListResultNoAction ;

	LSSharedFileListItemRef existingItemRef = NULL ;
	if (path == nil) {
		if (error_p != NULL) {
			*error_p = [NSError errorWithDomain:constSSYLoginItemsErrorDomain
										   code:SSYLoginItemsCallerGaveNilPathErrorCode
									   userInfo:[NSDictionary dictionaryWithObject:@"Cannot synchronize login item for nil path."
																			forKey:NSLocalizedDescriptionKey]] ;
		}
		goto end ;
	}
	
	NSURL* url = [NSURL fileURLWithPath:path] ;
	
	CFArrayRef snapshot ;
	BOOL ok = [self loginItemWithURL:url
								 ref:&existingItemRef
						  snapshot_p:&snapshot
							   error:error_p] ;
	if (!ok) {
		// error_p has already been assigned
		goto end ;
	}
	
	// We'll change the result if we find it necessary to do some action
	if (shouldBeLoginItem) {
		if (existingItemRef == NULL) {
			// path needs to be added to login items
			ok = [self addLoginURL:url
							hidden:[NSNumber numberWithBool:setHidden]
							 error:error_p] ;
			if (ok) {
				result = SSYSharedFileListResultAdded ;
			}
			else {
				result = SSYSharedFileListResultFailed ;
				// error_p has already been assigned
				goto end ;
			}
		}
	}
	else {
		if (existingItemRef != NULL) {
			// existingItemRef needs to be removed
			ok = [self removeLoginItemRef:existingItemRef
									error:error_p] ;
			if (ok) {
				result = SSYSharedFileListResultRemoved ;
			}
			else {
				result = SSYSharedFileListResultFailed ;
				// error_p has already been assigned
				goto end ;
			}
		}
	}

end:
	if (*error_p) {
		int code = [*error_p code] ;
		NSString* domain = [*error_p domain] ;
		NSMutableDictionary* userInfo = [[*error_p userInfo] mutableCopy] ;
		[userInfo setObject:NSStringFromSelector(_cmd)
					 forKey:@"Method Name"] ;
		if (path) {
			[userInfo setObject:path
						 forKey:@"Path"] ;
		}
		*error_p = [NSError errorWithDomain:domain
									   code:code
								   userInfo:userInfo] ;
		[userInfo release] ;	
	}
	
	CFSafeRelease(snapshot) ;
	return result ;
}


+ (SSYSharedFileListResult)removeAllLoginItemsWithName:(NSString*)name
										   thatAreNotInPath:(NSString*)path
													  error:(NSError**)error_p {
	if (error_p != NULL) {
		*error_p = nil ;
	}
	SSYSharedFileListResult result ;
	
	NSArray* loginItemRefsToRemove ;
	BOOL ok = [self loginItemsWithAppName:name
								notInPath:path
									 refs:&loginItemRefsToRemove
									error:error_p] ;
	if (ok) {
		if ([loginItemRefsToRemove count] == 0) {
			result = SSYSharedFileListResultNoAction ;
		}
		else {
			for (id item in loginItemRefsToRemove) {
				ok = [self removeLoginItemRef:(LSSharedFileListItemRef)item
										error:error_p] ;
				if (ok) {
					result = SSYSharedFileListResultRemoved ;
				}
				else {
					result = SSYSharedFileListResultFailed ;
					// error_p has already been set
					goto end ;
				}
			}
		}
		
	}
	else {
		result = SSYSharedFileListResultFailed ;
	}
	
end:
	return result ;
}

@end