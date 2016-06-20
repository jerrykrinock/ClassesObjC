#import "SSYLinearFileWriter.h"

// This is a singleton, but not a "true singletons", because
// I didn't bother to override
//    +allocWithZone:
//    -copyWithZone: 
//    -retain
//    -retainCount
//    -release
//    -autorelease
static SSYLinearFileWriter* sharedFileWriter = nil ;

@interface SSYLinearFileWriter () 

@property (retain) NSFileHandle* fileHandle ;

@end


@implementation SSYLinearFileWriter

@synthesize fileHandle = m_fileHandle ;

+ (SSYLinearFileWriter*)sharedFileWriter {
    @synchronized(self) {
        if (!sharedFileWriter) {
            sharedFileWriter = [[self alloc] init] ; 
        }
    }
	
	// No autorelease.  This sticks around forever.
    return sharedFileWriter ;
}

- (void)setPath:(NSString*)path {
	NSFileManager* fileManager = [NSFileManager defaultManager] ;
	[fileManager createFileAtPath:path
						 contents:[NSData data]
					   attributes:nil] ;
	
	NSFileHandle* fileHandle = [NSFileHandle fileHandleForWritingAtPath:path] ;
	[self setFileHandle:fileHandle] ;
}

- (void)writeLine:(NSString*)line {
	line = [line stringByAppendingString:@"\n"] ;
	NSData* data = [line dataUsingEncoding:NSUTF8StringEncoding] ;
	NSFileHandle* fileHandle = [self fileHandle] ;
	if (fileHandle) {
		[[self fileHandle] writeData:data] ;
	}
	else {
		NSLog(@"Internal Error 810-1149 No fileHandle") ;
	}
}
					
+ (void)setToPath:(NSString*)path {
	if (sharedFileWriter) {
		[sharedFileWriter release] ;
		sharedFileWriter = nil ;
	}
	[[SSYLinearFileWriter sharedFileWriter] setPath:path] ;
}

+ (void)writeLine:(NSString*)line {
	[[SSYLinearFileWriter sharedFileWriter] writeLine:line] ;
}

+ (void)close {
	[[SSYLinearFileWriter sharedFileWriter] setFileHandle:nil] ;
}

- (void)dealloc {
    [m_fileHandle release] ;
    
    [super dealloc] ;
}

@end

