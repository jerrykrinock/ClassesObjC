#import "SSYFoo.h"

#if SSY_FOO_INCLUDED

static NSInteger static_nextSerialNumber = 0 ;

@interface SSYFoo ()

@property (assign) NSInteger serialNumber ;
@property (retain) NSString* identifier ;

@end


@implementation SSYFoo

@synthesize serialNumber = m_serialNumber ;
@synthesize identifier = m_identifier ;

- (id)initWithIdentifier:(NSString*)identifier {
	self = [super init] ;
	if (self) {
		[self setSerialNumber:++static_nextSerialNumber] ;
		[self setIdentifier:identifier] ;
	}
	NSLog(@"Initted Foo %d %@ %p", [self serialNumber], [self identifier], self) ;

	return self ;
}

+ (SSYFoo*)fooWithIdentifier:(NSString*)identifier {
	return [[[SSYFoo alloc] initWithIdentifier:identifier] autorelease] ;
}

- (void)dealloc {
	NSLog(@"Dealloc: Foo %d %@ %p", [self serialNumber], [self identifier], self) ;
	[m_identifier release] ;
	
	[super dealloc] ;
}

+ (void)log:(NSString*)msg {
	NSLog(@"%@", msg) ;
}

@end

#endif
