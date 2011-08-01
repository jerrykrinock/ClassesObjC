#import <Cocoa/Cocoa.h>

#define MAX_SEARCH_BYTES 255  // I'm not sure if there is an ultimate limit on this.  Needs further research to see if any Pascal strings or similar nonsense get involved.
#define MAX_PATH_BYTES 255  // I believe this is limited by the size of a HFSUniStr255.


/*!
 @brief    A key to the current array of paths in the search results.  This may contain only the results from the current iteration, or also the results from prior iteration(s), depending on whether prior callbacks returned SSYCarbonSearcherContinue or SSYCarbonSearcherClearAndContinue 

 @details  This is one of the keys in the dictionary returned to the callback in asynchronous operation.
 */
extern NSString* const SSYCarbonSearcherResultsKeyPaths ;

/*!
 @const	     SSYCarbonSearcherResultsKeyContainerChanged
 @brief    I'm not quite sure I understand this, so I quote from the documentation of PBCatalogSearch[A]Sync.  This is an NSNumber BOOL "indicating whether the container’s contents have changed. If true, the container’s contents changed since the previous PBCatalogSearchSync call. Objects may still be returned even though the container changed. Note that if the container has changed, then the total set of items returned may be incorrect; some items may be returned multiple times, and some items may not be returned at all."  I always thought that this simply meant that the disk was modified during the search, which happens frequently in any multitasking operating system.  A result of YES, I think, can usually be ignored unless you have some reason to believe that the "change" involved your search results.  If you want to be 100% sure your results are correct, you could re-run the search until this value is NO.  But since disks are changing all the time, is that really any better?

 @details  This is one of the keys in the dictionary returned to the callback in asynchronous operation.
 */
extern NSString* const SSYCarbonSearcherResultsKeyContainerChanged ;

/*!
 @brief    A key to an NSNumber integer giving the total nymber of paths found in the search, so far.  Unlike the SSYCarbonSearcherResultsKeyPaths array, this number is ^not^ cleared to zero when the callback returns SSYCarbonSearcherClearAndContinue. 

 @details  This is one of the keys in the dictionary returned to the callback in asynchronous operation.
 */
extern NSString* const SSYCarbonSearcherResultsKeyNumberFound  ;

/*!
 @brief    A key to an NSNumber integer giving the index of the current iteration being reported.  This number begins with 0 and increments by one with each iteration. 

 @details  This is one of the keys in the dictionary returned to the callback in asynchronous operation.
 */
extern NSString* const SSYCarbonSearcherResultsKeyIterationIndex  ;

/*!
 @brief    A key to the latest OSErr returned by PBCatalogSearch[A]Sync, or any of the other File Manager functions which are invoked to prepare the search.  Note that a value of -1417, indicating errFSNoMoreItems, is normal when the search is completed.

 @details  This is one of the keys in the dictionary returned to the callback in asynchronous operation.
 */
extern NSString* const SSYCarbonSearcherResultsKeyOSErr ;

/*!
 @brief    A key to an NSNumber BOOL indicating whether or not the search is complete.  A callback can use this to summarize the final results and stop waiting for further invocations.

 @details  This is one of the keys in the dictionary returned to the callback in asynchronous operation.
 */
extern NSString* const SSYCarbonSearcherResultsKeyIsDone ;

/*!
 @brief    A key to an NSNumber BOOL indicating whether or not results should be printed verbosely.
 
 @details  This is one of the keys in the dictionary returned to the callback in asynchronous operation.
 */
extern NSString* const SSYCarbonSearcherResultsKeyVerbose ;

/*!
 @enum       SSYCarbonSearcherContinueStyle
 @brief    Values returned by the callback in asynchronous operation which tell SSYCarbonSearcher how to proceed with further iterations.
 @constant   SSYCarbonSearcherContinue Tells SSYCarbonSearcher to continue with the next iteration and do not clear paths found so far from the value of SSYCarbonSearcherResultsKeyPaths.
 @constant   SSYCarbonSearcherClearAndContinue Tells SSYCarbonSearcher to clear paths found so far from the value of SSYCarbonSearcherResultsKeyPaths and then continue with the next iteration. 
 @constant   SSYCarbonSearcherAbort Tells SSYCarbonSearcher to abort the search, do no more iterations and not return any more results.
 */
enum SSYCarbonSearcherContinueStyle {
    SSYCarbonSearcherContinue,
    SSYCarbonSearcherClearAndContinue,
    SSYCarbonSearcherAbort
} ;


/*!
 @superclass  NSObject { }
 @brief    This class provides a class method for searching the startup disk for files matching a given name, returning paths.

 @details  This class uses Carbon's old File Manager.  PBCatalogSearch[A]Sync() does the actual work.  This is way faster than Unix 'find', but not as fast as a Spotlight search.  However it is more comprehensive than a Spotlight search because (1) user cannot exclude directories using Spotlight's Preferences, (2) it searches inside packages.  There may be other differences that I am not aware of.
 
 I believe this class should work at least down to Mac OS 10.3, but have not tested it in Mac OS 10.3.
 
 A unix command-line wrapper, CarbonSearch, and also a Cocoa application (windowless, prints to log), CarbonSearcherApp, are available to demonstrate the class and to use as a utility.
 */
@interface SSYCarbonSearcher : NSObject {
}

/*!
 @brief    Performs a synchronous or asynchronous search of the startup disk catalog, finding the full paths of files matching a given name

 @details  My apologies for having so many arguments, but believe me it's better than filling out a parameter block.  Much of the complication comes from the fact that the search is broken up into partial searches called "iterations".  This is necessary since the PBCatalogSearch[A]Sync() which does the actual work returns results in 'C' arrays which must be dimensioned to a finite size.  In other words, if there are many results you need to empty the bucket once in awhile.  This can be thought of as "feature" in that you can print partial results after each iteration.  In this implementation, partial results just get printed to the console.  If a non-NULL syncResults argument is provided, the search is performed synchronously (blocking the calling thread until the search is complete).  If syncResults is NULL, the method returns immediately after configuring and starting the search; the search is performed asynchronously (not blocking, using PBCatalogSearchAsync), and results are returned to the asyncCallbackTarget via the asyncCallbackSelector with for each iteration.  The asynchronous mode is recommended in applcations where it is undesirable to freeze the user interface.
 @param    searchString  filename, or part of a filename, to be searched for.
 @param    fullNameSearch  If YES, narrowly filters results to require that filenames match the entire searchString.  If NO, a partial match is sufficient.
 @param    findDirectories  If NO, directories will be excluded from results.  If findDirectories is NO, then findFiles must be YES or an exception will be raised.
 @param    findFiles  If NO, regular files will be excluded from results.  If findFiles is NO, then findDirectories must be YES or an exception will be raised.
 @param    maxFindsPerIteration  The maximum number of paths allowed to be found per iteration.  When this is reached, another iteration is started.
 @param    maxSecondsPerIteration  The maximum time in seconds allowed per iteration.  When this is reached, another iteration is started.
 @param    maxIterations  The maximum number of iterations allowed.  When this is exceeded, the search is aborted.
 @param    maxFindsGrandTotal  The maximum number of paths allowed to be found.  When this is exceeded, the search is aborted.
 @param    verbose  If YES, prints diagnostics to console
 @param    printResultsEachIteration  If YES, prints paths found after each iteration
 @param    syncResults  Should be a handle to an NSDictionary in which all results will be returned synchronously.  The dictionary entries are the keys SSYCarbonSearcherResultsKeyXXXXXX.  See "Constants" for a list of the keys and description of their values.  If either asyncCallbackTarget or asyncCallbackSelector are nil, the search is performed asychronously and this parameter is ignored.
 @param    asyncCallbackTarget  The object (NSObject) to which results messages will be sent, if searching asynchronously.  This argument is required to be non-nil if asyncCallbackSelector is not NULL.  Otherwise, it is ignored.
 @param    asyncCallbackSelector  The selector (method) via which results messages will be sent, if searching asynchronously.  This argument is required to be non-NULL if asyncCallbackTarget is not nil.  Otherwise, it is ignored.  This selector must take one argument, an NSDictionary*, and return an integer.  The NSDictionary will contain the SSYCarbonSearcherResultsKeyXXXX keys.  The integer returned should be one of the enumeration constants in SSYCarbonSearcherContinueStyle.
 @param    err_p  If you pass a pointer to an OSErr, on output it will point to the last OSErr value generated by File Manager functions.  Note that a value of -1417, indicating errFSNoMoreItems, is normal when the search is completed.
 @result   For an asynchronous search, returns YES if the search was initiated with no errors and NO otherwise.  For a synchronous search, returns YES if the search was completed with no errors and NO otherwise.
 */
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
			  syncResults_p:(NSDictionary**)syncResults
		asyncCallbackTarget:(id)asyncCallbackTarget
	  asyncCallbackSelector:(SEL)asyncCallbackSelector
					  err_p:(OSErr*)err_p ;
	

@end
