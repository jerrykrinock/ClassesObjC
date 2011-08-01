#import "SSYInvocationOperation.h"


@implementation SSYInvocationOperation

- (id)owner {
	return m_owner ;
}

- (void)setOwner:(id)owner {
	m_owner = owner ;
}

- (id)initWithTarget:(id)target
			selector:(SEL)sel
			  object:(id)arg
			   owner:(id)owner {
	self = [super initWithTarget:target
						selector:sel
						  object:arg] ;
	if (self) {
		[self setOwner:owner] ;
	}
	else {
		// See http://lists.apple.com/archives/Objc-language/2008/Sep/msg00133.html ...
		[super dealloc] ;
	}
	
	return self ;
}

- (NSString*)description {
	return [NSString stringWithFormat:
			@"%@ %p selector=%@",
			[self className],
			self,
			NSStringFromSelector([[self invocation] selector])] ;
}

@end
