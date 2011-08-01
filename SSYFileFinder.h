/* This class is adapted from Apple's Sample Code project "Spotlighter", class "AppController" */

#import <Cocoa/Cocoa.h>

/*!
 @superclass  NSObject { NSMetadataQuery *query ; id callbackTarget ; SEL callbackSelector ; }
 @brief    A class for programmatically conducting a Spotlight search for a named file,
 returning an array of paths.  

 @details  Two class methods is exposed.   findPathsWithPredicate:callbackTarget:callbackSelector:
 is the general, base method.  findPathsWithFilename:callbackTarget:callbackSelector: is a wrapper
 around the base method which shows how to construct predicates for a the search you need.  For a complete
 list of attributes, consult Apple's "MD Item Reference" documentation and scroll down to
 "File System Metadata Attribute Keys". 
 
 The class method creates an instance which self-destructs after the search is complete.
 This class requires Mac OS 10.5 or later.
 */
@interface SSYFileFinder : NSObject {
    NSMetadataQuery *query ;
	id callbackTarget ;
	SEL callbackSelector ;
}

@property(retain) NSMetadataQuery *query ;
@property(retain) id callbackTarget ;


/*!
 @brief    Finds paths of files with a given predicate, by doing a Spotlight search, i.e. using NSMetadaQuery

 @details  Runs asynchronously and returns an NSArray of NSString objects to a specified callback
 target object, via a specified callback selector.
 @param    predicate  The predicate used to filter items, or qualify results, in the search.
 @param    callbackTarget  The object which will receive the callback.
 @param    callbackSelector  The selector in the callback target which will be invoked.  This selector
 should take one argument, an NSArray, and should return void.
 */
+ (void)findPathsWithPredicate:(NSPredicate*)predicate
				callbackTarget:(id)callbackTarget
			  callbackSelector:(SEL)callbackSelector ;
	

/*!
 @brief    Invokes findPathsWithPredicate:callbackTarget:callbackSelector:
 after constructing a predicate requiring that a results' displayName equal 
 the passed filename.
 @param    filename  The filename to be searched for.  To search for an application, use the extension ".app".
 */
+ (void)findPathsWithFilename:(NSString*)filename
			   callbackTarget:(id)callbackTarget
			 callbackSelector:(SEL)callbackSelector ;

@end