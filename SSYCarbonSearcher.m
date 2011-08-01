#import "SSYCarbonSearcher.h"
#import "SSYVolumeServerGuy.h"

#include <CoreServices/CoreServices.h>

NSString* const SSYCarbonSearcherResultsKeyPaths            = @"Paths" ;
NSString* const SSYCarbonSearcherResultsKeyContainerChanged = @"ContainerChanged" ;
NSString* const SSYCarbonSearcherResultsKeyNumberFound      = @"NumberFound" ;
NSString* const SSYCarbonSearcherResultsKeyIterationIndex   = @"IterationIndex" ;
NSString* const SSYCarbonSearcherResultsKeyOSErr            = @"OSErr" ;
NSString* const SSYCarbonSearcherResultsKeyIsDone           = @"IsDone" ;
NSString* const SSYCarbonSearcherResultsKeyVerbose           = @"Verbose" ;

// Note that this function returns its result in two places, in a 
// pointer as well as a return value.
char* UnicodeToCString( HFSUniStr255 *uniStr, char *cString ) {
	CFStringRef cfString = CFStringCreateWithCharacters( kCFAllocatorDefault, uniStr->unicode, uniStr->length );
	CFStringGetCString(cfString, cString, CFStringGetLength(cfString)+1, kCFStringEncodingMacRoman);
	CFRelease( cfString );
	return( cString );
}

void CStringToUnicode(
					  const char* cString,                          // in
					  UniChar* unicodeString,                 // out
					  UniCharCount* unicodeCharacterCount     // out
) {
	CFStringRef	cfString;
	
	cfString = CFStringCreateWithCString( NULL, cString, CFStringGetSystemEncoding() );
	CFRange range = CFRangeMake(0, MIN(CFStringGetLength(cfString), MAX_SEARCH_BYTES)) ;
	*unicodeCharacterCount = CFStringGetBytes(
											  cfString,                   // string in
											  range,
											  kCFStringEncodingUnicode,
											  0,
											  false,
											  (UInt8 *)(unicodeString),   // bytes out
											  MAX_SEARCH_BYTES,
											  NULL
											  ) ;
	CFRelease(cfString) ;
}

struct SearchInfo {
	FSCatalogBulkParam searchPB ;  // Needed so we can back out of it using offsetof()
	FSCatalogBulkParamPtr searchPB_p ; // Needed so we can dealloc it
	UInt32 maxFindsGrandTotal ;
	int maxIterations ;
	BOOL runAsync ;
	BOOL verbose ;
	BOOL printResultsEachIteration ;
	UInt32 iIter ;
	UInt32 grandTotalFinds ;
	BOOL done ;
	BOOL containerChanged ;
	NSMutableArray* paths ;
	id asyncCallbackTarget ;
	SEL asyncCallbackSelector ;
} ;
typedef struct SearchInfo SearchInfo ;

void DisposeAndRelease(SearchInfo *searchInfo_p) {
	if (searchInfo_p->verbose) {
		printf("Disposing/Releasing allocations\n") ;
	}
	
	[searchInfo_p->paths release] ;

	DisposePtr((Ptr)(*((searchInfo_p->searchPB).searchParams)).searchInfo1) ;
	DisposePtr((Ptr)(*((searchInfo_p->searchPB).searchParams)).searchInfo2) ;
	DisposePtr((Ptr)(*((searchInfo_p->searchPB).searchParams)).searchName) ;
	DisposePtr((Ptr)((searchInfo_p->searchPB).searchParams)) ;
	DisposePtr((Ptr)((searchInfo_p->searchPB).catalogInfo)) ;
	DisposePtr((Ptr)((searchInfo_p->searchPB).refs)) ;
	DisposePtr((Ptr)((searchInfo_p->searchPB).names)) ;
	DisposePtr((Ptr)((searchInfo_p->searchPB).specs)) ;
	DisposePtr((Ptr)(searchInfo_p->searchPB_p)) ;
	DisposePtr((Ptr)searchInfo_p ) ;
}

NSDictionary* ExtractResults(SearchInfo *searchInfo_p) {
	NSArray* paths = [searchInfo_p->paths copy] ;
	
	if (searchInfo_p->verbose) {
		const char* pathsDesc = [[paths description] UTF8String] ;
		printf("Verbose Summary for Iteration %d:\nFound %u paths:\n%s\ncontainerChanged: %d\nerror: %d\n",
			   (int unsigned)searchInfo_p->iIter,
			   (int unsigned)searchInfo_p->grandTotalFinds,
			   pathsDesc,
			   searchInfo_p->containerChanged,
			   searchInfo_p->searchPB.ioResult) ;			
	}

	NSDictionary* summary = [NSDictionary dictionaryWithObjectsAndKeys:
							 paths, SSYCarbonSearcherResultsKeyPaths,
							 [NSNumber numberWithBool:searchInfo_p->containerChanged], SSYCarbonSearcherResultsKeyContainerChanged,
							 [NSNumber numberWithInt:searchInfo_p->grandTotalFinds], SSYCarbonSearcherResultsKeyNumberFound,
							 [NSNumber numberWithInt:searchInfo_p->iIter], SSYCarbonSearcherResultsKeyIterationIndex,
							 [NSNumber numberWithInt:searchInfo_p->searchPB.ioResult], SSYCarbonSearcherResultsKeyOSErr,
							 [NSNumber numberWithBool:searchInfo_p->done], SSYCarbonSearcherResultsKeyIsDone,
							 nil] ;
								 
	return summary ;
}

void SearchCompletionProc (FSCatalogBulkParamPtr searchPB_p) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init] ;
	
	// The following kludge/trick is to work around the fact that, somewhere in the
	// Apple garage in 1983, somebody neglected to recognize that some kind of 
	// userInfo pointer would be really nice to have in the FSCatalogBulkParam struct.
	// Thus, since we don't have one, and we need lots of info, we have packaged the
	// FSCatalogBulkParam struct as a member of a parent struct, SearchInfo,
	// containing the info we need, and now we use the offsetof() macro to back out
	// from the FSCatalogBulkParam member to the parent SearchInfo.  This idea is
	// taken from Apple's old GrabBag sample code project.  Note that, in our case,
	// offsetof() evaluates to 0 because searchPB happens to be the first member
	// in the definition of SearchInfo, so actually it would work without that term.
	SearchInfo* searchInfo_p = (SearchInfo*)( ((Ptr)searchPB_p) - offsetof(SearchInfo, searchPB) ) ;
	
	// Print summary statistics of search results
	if (searchInfo_p->verbose) {
		printf("Results of iteration %u:\n   %5u = containerChanged\n   %5d = OSErr result (-1417 is OK, means no more items to search)\n   %5u = number of items found\n   List of items found:\n",
			   (int unsigned)searchInfo_p->iIter,
			   (bool)searchInfo_p->searchPB.containerChanged,
			   (int)searchInfo_p->searchPB.ioResult,
			   (int unsigned)searchInfo_p->searchPB.actualItems) ;
	}
	if (searchInfo_p->searchPB.containerChanged) {
		// Remember this in the SearchInfo struct, since the raw data from
		// the searchPB may be NO for subsequent iterations.
		searchInfo_p->containerChanged = YES ;
	}
	
	// Loop through results and add each pathname found into paths (results)
	FSRef fr ;
	unsigned int j ;
	for (j=0; j<searchInfo_p->searchPB.actualItems; j++) {
		OSErr err1 ;
		
		fr = searchInfo_p->searchPB.refs[j] ;
		UInt8 path[MAX_SEARCH_BYTES+1] ;
		err1 = FSRefMakePath (&fr, path, MAX_PATH_BYTES+1) ;
		if (err1 == noErr) {
			NSString* nsPath = [NSString stringWithUTF8String:(char*)path] ;
			// nsPath could be nil if FSRefMakePath returns an error
			// We don't want to crash, so we make sure nsPath is not nil
			if (nsPath) {
				[searchInfo_p->paths addObject:nsPath] ;
			}
			if (searchInfo_p->printResultsEachIteration) {
				printf("%s\n", [nsPath UTF8String]) ;
			}
		}
		else {
			printf("FSRefMakePath returned %i\n", err1) ;
		}
		
	}
	searchInfo_p->grandTotalFinds += searchInfo_p->searchPB.actualItems ;
	
	if (searchInfo_p->searchPB.ioResult == errFSNoMoreItems) {
		searchInfo_p->done = YES ;
	}
	else if (searchInfo_p->searchPB.ioResult == noErr) {
		if (searchInfo_p->grandTotalFinds >= searchInfo_p->maxFindsGrandTotal)
		{
			if (searchInfo_p->verbose) {
				printf("Will exit since maxFindsGrandTotal of %u has been reached with %u.\n", (unsigned int)searchInfo_p->maxFindsGrandTotal, (unsigned int)searchInfo_p->grandTotalFinds) ;
			}
			searchInfo_p->done = YES ;
		}
		else if ((searchInfo_p->iIter >= (searchInfo_p->maxIterations - 1)) && (searchInfo_p->maxIterations>0))
		{
			if (searchInfo_p->verbose) {
				printf("Will exit since maxIterations of %u has been reached with %u.\n", (unsigned int)searchInfo_p->maxIterations, (unsigned int)searchInfo_p->iIter) ;
			}
			searchInfo_p->done = YES ;
		}
	}
	else {
		printf("PBCatalogSearch returned error %d.\n", searchInfo_p->searchPB.ioResult) ;
		searchInfo_p->done = YES ;
	}
	
	if (searchInfo_p->runAsync) {
		NSDictionary* summary = ExtractResults(searchInfo_p) ;

		NSMethodSignature* methSig = [(searchInfo_p->asyncCallbackTarget) methodSignatureForSelector:(searchInfo_p->asyncCallbackSelector)] ;
		NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:methSig] ;
		[invocation setTarget:(searchInfo_p->asyncCallbackTarget)] ;
		[invocation setSelector:(searchInfo_p->asyncCallbackSelector)] ;
		//[invoc retainArguments] ;
		[invocation setArgument:&summary atIndex:2] ;
		[invocation invoke] ;
		
		unsigned int returnLength = [[invocation methodSignature] methodReturnLength] ;
		// Assert that the callback is returning something that is at least of the correct size.
		assert(returnLength == sizeof(int)) ;
		void* returnBuffer = (void*)malloc(returnLength) ;
		[invocation getReturnValue:returnBuffer] ;
		
		int* returnValue_p = (int*)returnBuffer ;
		free(returnBuffer) ;
		
		switch(*returnValue_p) {
			case SSYCarbonSearcherAbort:
				searchInfo_p->done = YES ;
				if (searchInfo_p->verbose) {
					printf("Per callback return, will abort.\n") ;
				}
				break ;
			case SSYCarbonSearcherClearAndContinue:
				[searchInfo_p->paths removeAllObjects] ;
				if (searchInfo_p->verbose) {
					printf("Per callback return, will clear results and continue get more.\n") ;
				}
				break ;
			default:
				if (searchInfo_p->verbose) {
					printf("Per callback return, will continue adding more results.\n") ;
				}
		}
		//[(searchInfo_p->asyncCallbackTarget) performSelector:searchInfo_p->asyncCallbackSelector
		//										  withObject:summary] ;
	}
	
	if (searchInfo_p->done) {
		if (searchInfo_p->runAsync) {
			DisposeAndRelease(searchInfo_p) ;
		}
	}
	else {
		// Iterate again
		searchInfo_p->iIter++ ;
		if (searchInfo_p->verbose) {
			printf("Beginning PBCatalogSearch iteration %u (in callback).  Please wait.\n", (int unsigned)searchInfo_p->iIter) ;	
		}

		if (searchInfo_p->runAsync) {
			// Another asynchronous interation
			PBCatalogSearchAsync( &(searchInfo_p->searchPB) ) ;
		}
		else {
			// Another synchronous interation
			OSErr err = PBCatalogSearchSync( &(searchInfo_p->searchPB) ) ;

			// To emulate what PBCatalogSearchAsync does,
			{
				//  Feed the error back into the parameter block
				searchInfo_p->searchPB.ioResult = err ;
				
				//  Recurse on me to process the results
				SearchCompletionProc( &(searchInfo_p->searchPB) ) ;				
			}
			
		}
	}
	
	[pool release] ;
}	

@implementation SSYCarbonSearcher

+ (BOOL)catalogPathsForName:(NSString*)searchString
			 fullNameSearch:(BOOL)fullNameSearch
			findDirectories:(BOOL)findDirectories
				  findFiles:(BOOL)findFiles
	   maxFindsPerIteration:(UInt32)maxFindsPerIteration
	 maxSecondsPerIteration:(float)maxSecondsPerIteration
			  maxIterations:(int)maxIterations
		 maxFindsGrandTotal:(UInt32)maxFindsGrandTotal
					verbose:(BOOL)verbose
  printResultsEachIteration:(BOOL)printResultsEachIteration
			  syncResults_p:(NSDictionary**)syncResults_p
		asyncCallbackTarget:(id)asyncCallbackTarget
	  asyncCallbackSelector:(SEL)asyncCallbackSelector
					  err_p:(OSErr*)err_p {
	// Determine which mode to run
	BOOL runAsync = (asyncCallbackTarget || asyncCallbackSelector) ;
	
	const char* searchCString = [searchString UTF8String] ;
	
	// Raise assertion if illegal argument(s) 
	NSString* badCall ;
	badCall = @"Need both callback target *and* selector to run async." ;
	if (runAsync) {
		NSAssert(asyncCallbackTarget != nil, badCall) ;
		NSAssert(asyncCallbackSelector != NULL, badCall) ;
	}
	else  {
		badCall = @"Sync running requires syncResult_p" ;
		NSAssert((syncResults_p != NULL), badCall) ;
	}
	
	badCall = [NSString stringWithFormat:@"number of bytes in searchString must be <= %d", MAX_SEARCH_BYTES] ;
	NSAssert(strlen(searchCString) <= MAX_SEARCH_BYTES, badCall) ;
	badCall = @"One of findDirectories or findFiles must be true" ;
	NSAssert(findDirectories || findFiles, badCall) ;

	// Get FSRef of root directory
	FSVolumeRefNum actualVolume = 999 ; // bogus value to be overwritten
	HFSUniStr255 volumeName ;
	FSRef containerRef ;
	int volRefNum = [SSYVolumeServerGuy volumeRefNumberForPath:@"/"] ;
	if (verbose) {
		printf("Will search volRefNum (of root directory) = %i\n", volRefNum) ;
	}

	OSErr err = noErr;
	FSIterator iterator = NULL ;
	NSDictionary* summary = nil ;		
	
	if (err == noErr) {
		err =  FSGetVolumeInfo (
								volRefNum,			// in.  kFSInvalidVolumeRefNum "to index through the list of mounted volumes".  But when I do this, I get 0 search results.
								0,					// in.  0 to use the volume reference number in the volume (previous) parameter  
								&actualVolume,		// out
								kFSVolInfoNone,		// in 
								NULL,				// out
								&volumeName,		// out
								&containerRef		// out (This is the important output that is used below.)
								) ;
		
	}
	
	if (err != noErr) {
		printf("FSGetVolumeInfo returned error %d\n", err) ;
		goto end ;
	}
	else {
		if (verbose) {
			printf("FSGetVolumeInfo results:\n   %5d = result OSErr\n   %5d = volRefNum\n", err, actualVolume) ;
		}
		err =  FSOpenIterator (
							   &containerRef,		// in
							   kFSIterateSubtree,	// in
							   &iterator			// out
							   ) ;
	}

	if (err != noErr) {
		printf("FSOpenIterator returned OSErr %d\n", err) ;
		goto end ;
	}
	else {
		// This is the first of many allocations we will make.
		// Any variable accessed by PBCatalogSearchAsync() or SearchCompletionProc()
		// must be allocated because otherwise they will go away when this method exits
		// and thus cause a crash when access is attempted.
		// These many allocations are deallocced in DisposeAndRelease().
		FSSearchParams* searchParams_p = (FSSearchParams*)NewPtrClear(sizeof(FSSearchParams)) ;
		
		// Assign searchTime member of searchParams struct
		searchParams_p->searchTime = maxSecondsPerIteration * 1000 ; // search timeout in milliseconds, or 0 for no limit ;
		
		// Assign searchBits, searchInfo1 and searchInfo2 members of searchParams struct.
		if (fullNameSearch) {
			searchParams_p->searchBits = fsSBFullName ; 
		}
		else {
			searchParams_p->searchBits = fsSBPartialName ; 
		}
		FSCatalogInfo* searchInfo1_p = (FSCatalogInfo*)NewPtrClear(sizeof(FSCatalogInfo)) ;
		FSCatalogInfo* searchInfo2_p = (FSCatalogInfo*)NewPtrClear(sizeof(FSCatalogInfo)) ; ;
		if (!findDirectories || !findFiles)
		{
			// Exclude directories, or exclude files
			searchParams_p->searchBits += fsSBFlAttrib ;  // We want search bits to include file attributes
			searchInfo2_p->nodeFlags    = kFSNodeIsDirectoryMask ;  // Within the fileInfo, unmask the isDirectory bit  
			if (findDirectories) {
				searchInfo1_p->nodeFlags = kFSNodeIsDirectoryMask ; // set the isDirectory bit
			}
			else {
				// findFiles must be YES (since they cannot both be NO)
				searchInfo1_p->nodeFlags = 0 ; // unset the isDirectory bit
			}
		}
		else {
			; // User wants both directories and files, so we have no additional search bits; do nothing
		}
		searchParams_p->searchInfo1 = searchInfo1_p ;
		searchParams_p->searchInfo2 = searchInfo2_p ;
		
		// Declare arrays to receive search results
		FSCatalogInfo* catalogInfos_p = (FSCatalogInfo*)NewPtrClear(maxFindsPerIteration * sizeof(FSCatalogInfo)) ;
		FSRef* refs_p = (FSRef*)NewPtrClear(maxFindsPerIteration * sizeof(FSRef)) ;
		FSSpec* specs_p = (FSSpec*)NewPtrClear(maxFindsPerIteration * sizeof(FSSpec)) ;
		HFSUniStr255* names_p = (HFSUniStr255*)NewPtrClear(maxFindsPerIteration * sizeof(HFSUniStr255)) ;
		
		// Create and populate the parameter block
		FSCatalogBulkParam*	searchPB_p = (FSCatalogBulkParam*)NewPtrClear(sizeof(FSCatalogBulkParam)) ;
		searchPB_p->iterator		= iterator ;
		searchPB_p->searchParams	= searchParams_p ;
		searchPB_p->maximumItems	= maxFindsPerIteration ;
		searchPB_p->whichInfo		= kFSCatInfoContentMod ;
		searchPB_p->catalogInfo	    = catalogInfos_p ;
		searchPB_p->refs			= refs_p ;
		searchPB_p->specs			= specs_p ;
		searchPB_p->names			= names_p ;
		searchPB_p->ioCompletion    = (IOCompletionProcPtr)SearchCompletionProc ;
		// Note: NewIOCompletionUPP() is just a silly macro that typecasts to IOCompletionUPP
		
		SearchInfo* searchInfo_p = (SearchInfo*) NewPtrClear( sizeof(SearchInfo) );
		searchInfo_p->paths = [[NSMutableArray alloc] init] ;
		searchParams_p->searchName = (UniChar*) NewPtrClear(MAX_SEARCH_BYTES) ;
		// I suppose that if we broke up CStringTo Unicode so that we could get a
		// byte count first, we could have only allocated what was needed instead
		// of MAX_SEARCH_BYTES, but what the hell.
		
		CStringToUnicode(searchCString,                        // in
						 (UniChar*)searchParams_p->searchName, // out
						 &searchParams_p->searchNameLength     // out
						 ) ;
		
		searchInfo_p->searchPB = *searchPB_p ;
		searchInfo_p->searchPB_p = searchPB_p ; // Needed so we can dealloc it
		searchInfo_p->maxFindsGrandTotal = maxFindsGrandTotal ;
		searchInfo_p->maxIterations = maxIterations ;
		searchInfo_p->runAsync = runAsync ;
		searchInfo_p->verbose = verbose ;
		searchInfo_p->printResultsEachIteration = printResultsEachIteration ;
		searchInfo_p->iIter = 0 ;
		searchInfo_p->grandTotalFinds = 0 ;
		searchInfo_p->done = NO ;
		searchInfo_p->containerChanged = NO ;
		searchInfo_p->asyncCallbackTarget = asyncCallbackTarget ;
		searchInfo_p->asyncCallbackSelector = asyncCallbackSelector ;
		
		// Do the search.  
		// Each iteration will end when maxFindsPerIteration are found, or when
		// searchSecondsPerIteration elapses, whichever comes first, or when PBCatalogSearchXXXXX
		// is done searching the whole volume
		if (verbose) {
			printf("Searching...\n") ;
		}
		if (printResultsEachIteration) {
			printf("Will print paths found after each iteration.\n") ;
		}
		
		// If !runAsync, we invoke PBCatalogSearchSync in a "do-while" loop.
		// I see this idiom frequently in Apple Sample Code involving Carbon's File Manager.
		// This is apparently to overcome the restriction of the outputs being fixed-size C arrays,
		// and also it gives incremental results during the search for worried and/or impatient users.
		// If runAsync, the equivalent do-while is executed in the callback SearchCompletionProc(),
		// re-calling PBCatalogSearchSync() as needed.
		// The logic to determine when we're done is also in SearchCompletionProc()
		if (runAsync) {
			// To run asynchronously, just start it and then bail out
			PBCatalogSearchAsync( &(searchInfo_p->searchPB) ) ;
		}
		else {		
			if (verbose) {
				printf("Beginning PBCatalogSearch iteration %u.  Please wait.\n", (int unsigned)searchInfo_p->iIter) ;	
			}
			
			err = PBCatalogSearchSync( &(searchInfo_p->searchPB) ) ;
			
			// Feed the error into searchPB, to emulate an async completion
			searchInfo_p->searchPB.ioResult = err ;
			SearchCompletionProc( &(searchInfo_p->searchPB) ) ;					
		}	
		
		if (!runAsync) {
			summary = ExtractResults(searchInfo_p) ;
			DisposeAndRelease(searchInfo_p) ;
		}		
	}	

end:
	if (syncResults_p != NULL) {
		*syncResults_p = summary ;
	}
	
	if (err_p != NULL) {
		*err_p = err ;
	}
	
	return ((err == noErr) || (err == errFSNoMoreItems)) ;
}

@end