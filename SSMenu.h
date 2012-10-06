 @interface SSMenu : NSMenu {

	NSMenuItem* owningMenuItem ; // the NSMenuItem which this object is the submenu of
								// weak reference, to avoid retain cycles
}

- (NSMenuItem *)owningMenuItem;
- (void)setOwningMenuItem:(NSMenuItem *)value;


- (id)initWithOwningMenuItem:(id)owningMenuItem ;
// Note: Retains weak reference to owningMenuItem, to avoid retain cycle

@end
