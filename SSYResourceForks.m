#import "SSYResourceForks.h"


@implementation SSYResourceForks

+ (NSArray*)weblocFilenamesAndUrlsInPaths:(NSArray*)paths {
	OSErr err ;
	FSRef fsRef ;
	NSInteger fileRef ;
	NSMutableArray* filenamesAndURLs = [NSMutableArray array] ;
	
	for (NSString* path in paths) {
		err = !noErr ;
		
		 // Try and open resource fork for path
		if( [[NSFileManager defaultManager] fileExistsAtPath:path] )
		{
			const unsigned char* pathU = (const unsigned char*) [path UTF8String] ;
			err = FSPathMakeRef(pathU, &fsRef, NULL ) ;
		}
		if (err == noErr) {
			fileRef = FSOpenResFile ( &fsRef, fsRdPerm );
			err = fileRef > 0 ? ResError( ) : !noErr;
		}
		
		if (err == noErr)
		{
			UseResFile(fileRef) ;
			Handle aResHandle = NULL ;
			aResHandle = Get1Resource( 'TEXT', 256) ;
			NSData* theData = nil;
			if( aResHandle )
			{
				HLock(aResHandle);
				theData = [NSData dataWithBytes:*aResHandle length:GetHandleSize( aResHandle )];
				HUnlock(aResHandle);
				ReleaseResource(aResHandle );
			}
            
            // Added in BookMacster 1.12
            CloseResFile(fileRef) ;
			
			// theData is the 'TEXT' resource data
			NSString*url = [[NSString alloc] initWithData:theData encoding:kCFStringEncodingMacRoman] ;
			NSString* filename = [[path lastPathComponent] stringByDeletingPathExtension] ;
			
			NSDictionary* filenameAndURL = [NSDictionary dictionaryWithObjectsAndKeys:
											filename, @"filename",
											url, @"url",
											nil] ;
			
			[filenamesAndURLs addObject:filenameAndURL] ;
			
			[url release] ;
		}
		else
			NSLog(@"Reading resource fork failed with OSErr %ld", (long)err) ;
	}
	
	if ([filenamesAndURLs count])
		return [[[NSArray alloc] initWithArray:filenamesAndURLs] autorelease] ;
	else
		return nil ;	
}

@end
