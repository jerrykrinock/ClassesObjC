#import <Cocoa/Cocoa.h>

extern NSString* const SSYPythonPicklesErrorDomain ;
extern NSString* const SSYPythonPicklesUnderErrorDomain ;

@interface NSString (PythonPickles)

- (NSString*)pythonUnpickledError_p:(NSError**)error_p ;

@end


#if 0 
TEST CODE

int main(int argc, char *argv[]) {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init] ;
	
	// The following string is an actual Python pickle.
	// Of course, one would never hard code such a thing in a real program.
	// This is just a test  :)
	NSString* s = @"V/Users/jk/Dropbox2/Dropbox\np1\n.\n" ;
	NSError* error = nil ;
	
	// Do it three times to test for Python initialization issues.
	NSLog(@"Unpickled result: %@\n",
		  [s pythonUnpickledError_p:&error]) ;
	
	NSLog(@"Unpickled result: %@\n",
		  [s pythonUnpickledError_p:&error]) ;
	
	NSLog(@"Unpickled result: %@\n",
		  [s pythonUnpickledError_p:&error]) ;
	
	// The correct answer for Unpickled result is:
	//    "/Users/jk/Dropbox2/Dropbox"
	NSLog(@"error:\n%@", error) ;
	
	
	[pool release] ;
	return 0 ;
}

#endif