#import "SSYLoginItems.h"
#import "NSError+LowLevel.h"


NSString* const constSSYLoginItemsErrorDomain = @"SSYLoginItemsErrorDomain" ;
NSInteger const SSYLoginItemsCouldNotProbeItemErrorCode = 144760 ;
NSInteger const SSYLoginItemsCouldNotRemoveItemHiLevelErrorCode = 144761 ;
NSInteger const SSYLoginItemsCouldNotSynchronizeItemErrorCode = 144762 ;
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
    NSError* error = nil ;
	
	LSSharedFileListRef list ;
	BOOL ok = [self createLoginItemsList:&list
								   error:&error] ;
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
	BOOL ok = YES ;
    NSError* error = nil ;
    
	
	LSSharedFileListItemRef targetItem = NULL ;
	if (url == nil) {
		goto end ;
	}
	
	// First, get a snapshot of all login items
	ok = [self copySnapshotOfLoginItems:snapshot_p
								  error:&error] ;
	if (!ok) {
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
                CFSafeRelease(aURL) ;  // Memory leak fixed in BookMacster 1.16.5
				break ;
			}
		}
		else {
			// This branch will execute if any of the user's Login Items in System Preferences
			// references a path has been deleted (not trashed, deleted).  (It may execute
			// in other situations also.  We don't know, due to lack of LSSharedFileList
			// documentation from Apple.)
            
            // Bug fixed in BookMacster 1.13.6 right here.  The condition
            // "if (error)" on the next 2  dozen lines, which made no sense,
            // was removed.
            NSError* underlyingError = [NSError errorWithMacErrorCode:status] ;
            NSString* desc = @"Mac OS X could not resolve your Login Items." ;
            NSString* path = [url path] ;
            if (!path) {
                path = [url absoluteString] ;
            }
            if (!path) {
                path = [url description] ;
            }
            
            NSString* reason = [NSString stringWithFormat:
                                @"Login Item Number %ld is broken.",
                                (long)i] ;
            NSMutableDictionary* userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                             desc, NSLocalizedDescriptionKey,  // won't be nil
                                             reason, NSLocalizedFailureReasonErrorKey, // won't be nil
                                             underlyingError, NSUnderlyingErrorKey,     // won't be nil
                                             [NSNumber numberWithInteger:i], @"Broken Item Index", // won't be nil
                                             [NSNumber numberWithInteger:status], @"Underlying Error Status Code",  // won't be nil
                                             path , @"Path Looking For",   // might be nil
                                             nil] ;
            
            if ((status == fnfErr) || (status == nsvErr)) {
                NSString* suggestion = [NSString stringWithFormat:
                                        @"Visit your System Preferences and delete or reinstall Login Item Number %ld.",
                                        (long)i] ;
                [userInfo setObject:suggestion
                             forKey:NSLocalizedRecoverySuggestionErrorKey] ;
            }
            
            error = [NSError errorWithDomain:constSSYLoginItemsErrorDomain
                                        code:SSYLoginItemsCouldNotResolveExistingItemErrorCode
                                    userInfo:userInfo] ;

			ok = NO ;
            CFSafeRelease(aURL) ;  // Memory leak fixed in BookMacster 1.16.5
			break ;
		}
        
        // Memory leak fixed in BookMacster 1.16.5
        CFSafeRelease(aURL) ;
        
		i++ ;
	}
	
end:
	if (error && error_p) {
        *error_p = error ;
    }
    if (ref_p != NULL) {
		*ref_p = (LSSharedFileListItemRef)targetItem ;
	}
	
	return (ok) ;
}

+ (BOOL)isURL:(NSURL*)url
	loginItem:(NSNumber**)loginItem_p
	   hidden:(NSNumber**)hidden_p
		error:(NSError**)error_p {
    BOOL ok = YES ;
	NSError* error = nil ;
    
	LSSharedFileListItemRef targetItem = NULL ;
	CFArrayRef snapshot = NULL ;
	
	if (url == nil) {
		goto end ;
	}
	
	ok = [self loginItemWithURL:url
                            ref:&targetItem
                     snapshot_p:&snapshot
                          error:&error] ;
	if (!ok) {
		// error has already been assigned
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
	if (error_p && !ok) {
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary] ;
        [userInfo setObject:@"Error probing your Mac OS X Login Items"
                     forKey:NSLocalizedDescriptionKey] ;
		[userInfo setValue:[url absoluteString]
                        forKey:@"Url"] ;
        [userInfo setValue:error
                    forKey:NSUnderlyingErrorKey] ;
		*error_p = [NSError errorWithDomain:constSSYLoginItemsErrorDomain
									   code:SSYLoginItemsCouldNotProbeItemErrorCode
								   userInfo:userInfo] ;
	}
	CFSafeRelease(snapshot) ;
	return ok ;
}

+ (BOOL)addLoginURL:(NSURL*)url
			 hidden:(NSNumber*)hidden
			  error:(NSError**)error_p {
    NSError* error = nil ;
	NSDictionary* propsToSet = [NSDictionary dictionaryWithObject:hidden
														   forKey:(id)kLSSharedFileListItemHidden] ;
	LSSharedFileListRef loginItems ;
	BOOL ok = [self createLoginItemsList:&loginItems
								   error:&error] ;
	
	if (!ok) {
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
        error = [NSError errorWithDomain:constSSYLoginItemsErrorDomain
                                    code:SSYLoginItemsCouldNotInsertItemErrorCode
                                userInfo:[NSDictionary dictionaryWithObject:@"LSSharedFileListInsertItemURL returned NULL"
                                                                     forKey:NSLocalizedDescriptionKey]] ;
    }
	else {
        // Note 21030229
		// Documentation for LSSharedFileListInsertItemURL says I should release
		// (Maybe because CF does not feature autorelease?).  But if I do, it
        // causes a crash, not on my Mac, but on that of user Burke Townsend.
		// CFRelease(item) ;
        
        // Memory leak fixed in BookMacster 1.16.5.
        // Probably the reason why the above crashed for that user is because
        // I was using CFRelease() instead of CFSafeRelease()?  Maybe his
        // url was nil, so item was NULL?  We'll release this as a beta and
        // see how if anyone reports any crashes, I guess.
        CFSafeRelease(item) ;
	}

end:
	CFSafeRelease(loginItems) ;
    if (error_p) {
        *error_p = error ;
    }
	
	return ok ;
}

+ (BOOL)removeLoginItemRef:(LSSharedFileListItemRef)item
					 error:(NSError**)error_p {
	BOOL ok ;
    NSError* error = nil ;
	
	LSSharedFileListRef loginItems ;
	ok = [self createLoginItemsList:&loginItems
							  error:&error] ;
	if (!ok) {
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
	
    if (error_p) {
        *error_p = error ;
    }
    
	return (ok) ;
}

+ (BOOL)removeLoginURL:(NSURL*)url
				 error:(NSError**)error_p {
    NSError* error = nil ;
	LSSharedFileListItemRef item = NULL ;
	CFArrayRef snapshot = NULL ;
	BOOL ok = [self loginItemWithURL:url
								ref:&item
						  snapshot_p:&snapshot
							  error:&error] ;

	if (ok && (item != NULL)) {
		[self removeLoginItemRef:item
						   error:&error] ;
	}
	
	CFSafeRelease(snapshot) ;
	
	if (error_p && !ok) {
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary] ;
        [userInfo setObject:@"Error removing a Mac OS X Login Item"
                     forKey:NSLocalizedDescriptionKey] ;
		[userInfo setValue:[url absoluteString]
                    forKey:@"Url"] ;
        [userInfo setValue:error
                    forKey:NSUnderlyingErrorKey] ;
		*error_p = [NSError errorWithDomain:constSSYLoginItemsErrorDomain
									   code:SSYLoginItemsCouldNotRemoveItemHiLevelErrorCode
								   userInfo:userInfo] ;
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
    BOOL ok = YES ;
    NSError* error = nil ;
	NSMutableArray* mutableRefs = nil ;
	CFArrayRef snapshot = NULL ;
    
	ok = [self copySnapshotOfLoginItems:&snapshot
                                  error:&error] ;
	if (!ok) {
		goto end ;
	}
		
	OSStatus status = noErr ;
	name = [name stringByDeletingPathExtension] ;
	mutableRefs = [NSMutableArray array] ;
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
        // But I commented it out for some reason, apparently long ago.
        // See also Note 21030229.
		////CFSafeRelease(aURL) ;
        // Added back in BookMacster 1.16.5…
        CFSafeRelease(aURL) ;
		
		if (breakAfterCleanup) {
			break ;
		}
	}
	
	if (status != noErr) {
		if (!error) {
			error = [NSError errorWithDomain:constSSYLoginItemsErrorDomain
                                        code:SSYLoginItemsCouldNotResolveGivenItemErrorCode
                                    userInfo:[NSDictionary dictionaryWithObject:@"LSSharedFileListItemResolve returned error"
                                                                         forKey:NSLocalizedDescriptionKey]] ;
		}
		ok = NO ;
		goto end ;
	}
	
end:
	CFSafeRelease(snapshot) ;
	
	if (error_p) {
		*error_p = error ;
	}
	if (refs_p) {
		*refs_p = [NSArray arrayWithArray:mutableRefs] ;
	}
	
	return (ok) ;
}


+ (SSYSharedFileListResult)synchronizeLoginItemPath:(NSString*)path
								  shouldBeLoginItem:(BOOL)shouldBeLoginItem
										  setHidden:(BOOL)setHidden 
											  error:(NSError**)error_p {
    BOOL ok = YES ;
    NSError* error = nil ;
	SSYSharedFileListResult result ;
	CFArrayRef snapshot = NULL ;
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
	
	ok = [self loginItemWithURL:url
                            ref:&existingItemRef
                     snapshot_p:&snapshot
                          error:&error] ;
	if (!ok) {
		goto end ;
	}
	
	// We'll change the result if we find it necessary to do some action
	if (shouldBeLoginItem) {
		if (existingItemRef == NULL) {
			// path needs to be added to login items
			ok = [self addLoginURL:url
							hidden:[NSNumber numberWithBool:setHidden]
							 error:&error] ;
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
									error:&error] ;
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
	if (error_p && !ok) {
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary] ;
        [userInfo setObject:@"Error synchronizing a Mac OS X Login Item"
                     forKey:NSLocalizedDescriptionKey] ;
		[userInfo setValue:[url absoluteString]
                    forKey:@"Url"] ;
        [userInfo setValue:error
                    forKey:NSUnderlyingErrorKey] ;
		*error_p = [NSError errorWithDomain:constSSYLoginItemsErrorDomain
									   code:SSYLoginItemsCouldNotSynchronizeItemErrorCode
								   userInfo:userInfo] ;
	}
	
	CFSafeRelease(snapshot) ;
	return result ;
}


+ (SSYSharedFileListResult)removeAllLoginItemsWithName:(NSString*)name
										   thatAreNotInPath:(NSString*)path
													  error:(NSError**)error_p {
    NSError* error = nil ;
	SSYSharedFileListResult result = SSYSharedFileListResultNoAction ;
	
	NSArray* loginItemRefsToRemove ;
	BOOL ok = [self loginItemsWithAppName:name
								notInPath:path
									 refs:&loginItemRefsToRemove
									error:&error] ;
	if (ok) {
		if ([loginItemRefsToRemove count] == 0) {
			result = SSYSharedFileListResultNoAction ;
		}
		else {
			for (id item in loginItemRefsToRemove) {
				ok = [self removeLoginItemRef:(LSSharedFileListItemRef)item
										error:&error] ;
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
    if (error && error_p) {
        *error_p = error ;
    }
    
	return result ;
}

+ (NSArray*)allLoginPathsError:(NSError**)error_p {
    BOOL ok = YES ;
    NSError* error = nil ;
	NSMutableArray* paths = nil ;
	CFArrayRef snapshot = NULL ;
    
	ok = [self copySnapshotOfLoginItems:&snapshot
                                  error:&error] ;
	if (!ok) {
		goto end ;
	}
    
	OSStatus status = noErr ;
	paths = [NSMutableArray array] ;
	for (id item in (NSArray*)snapshot) {
		NSURL* aURL ;
		status = LSSharedFileListItemResolve(
                                             (LSSharedFileListItemRef)item,
                                             0,
                                             (CFURLRef*)&aURL,
                                             NULL) ;
		if (status == noErr) {
			NSString* aPath = [aURL path]  ;
            [paths addObject:aPath] ;
		}
        
		// Documentation says to release this
		// (Maybe because CF does not feature autorelease?)
		CFSafeRelease(aURL) ;
		
	}
	
	if (status != noErr) {
		if (!error) {
			error = [NSError errorWithDomain:constSSYLoginItemsErrorDomain
                                        code:SSYLoginItemsCouldNotResolveGivenItemErrorCode
                                    userInfo:[NSDictionary dictionaryWithObject:@"LSSharedFileListItemResolve returned error"
                                                                         forKey:NSLocalizedDescriptionKey]] ;
		}
		ok = NO ;
		goto end ;
	}
	
end:
	CFSafeRelease(snapshot) ;
	
	if (error_p) {
		*error_p = error ;
	}
	
    NSArray* answer = nil  ;
    if (ok) {
        answer = [NSArray arrayWithArray:paths] ;
    }
    else {
        answer = nil ;
    }
    
	return (answer) ;
}


@end