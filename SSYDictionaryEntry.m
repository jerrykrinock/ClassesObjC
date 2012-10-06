#import "SSYDictionaryEntry.h"


@implementation SSYDictionaryEntry

- (id)key {
	if (_key == nil) {
		// We use an empty NSData to symbolize nil because
		// NSNull is not serializable.
		return [NSData data] ;
	}
	else {
		return [[_key retain] autorelease] ;
	}
}

- (id)value {
	if (_value == nil) {
		// We use an empty NSData to symbolize nil because
		// NSNull is not serializable.
		return [NSData data] ;
	}
	else {
		return [[_value retain] autorelease] ;
	}
}

- (NSMutableDictionary *)parent {
    return [[_parent retain] autorelease];
}

- (void)setParent:(NSMutableDictionary *)value {
    if (_parent != value) {
        [_parent release];
        _parent = [value retain];
    }
}

- (void)updateParent {
	// Update the parent dic, such as to trigger KVO
	[[self parent] setObject:[self value] forKey:[self key]];
}

- (void)setKey:(id)key {
    if (_key != key) {
        [_key release];
		_key = [key retain];
		
		[self updateParent] ;
    }
}

- (void)setValue:(id)value {
    if (_value != value) {
        [_value release];
		_value = [value retain];
		
		[self updateParent] ;
    }
}

- (NSString*)description {
	return [NSString stringWithFormat:@"SSDictionaryEntry with parent %@ <%p> and:\nkey <%@>:%@\nvalue <%@>: %@",
			[[self parent] class],
			[self parent],
			[[self key] class],
			[self key],
			[[self value] class],
			[self value]] ;
}

- (id)initWithParent:(NSMutableDictionary*)parent
				key:(id)key  
			  value:(id)value {
	[self setParent:parent] ;
	[self setKey:key] ;
	[self setValue:value] ;

	[self bind:@"value"
	  toObject:parent
   withKeyPath:key
	   options:nil];

	return self;
}

@end


@implementation DicToReadableValuesArray

+ (Class)transformedValueClass {
    return [NSMutableArray class];
}

+ (BOOL)allowsReverseTransformation {
    return YES ;
}

+ (id)readableNull {
	return @"<NULL>" ;
}

- (id)transformedValue:(id)dic {
	NSMutableArray* array = [[NSMutableArray alloc] initWithCapacity:[dic count]] ;
	NSEnumerator* e = [dic keyEnumerator] ;
	NSString* key ;
	while ((key = [e nextObject]) != nil) {
		id value = [dic objectForKey:key] ;

		// We used an empty NSData to symbolize nil because
		// NSNull is not serializable.
		if ([value isKindOfClass:[NSData class]]) {
			if ([value length] == 0) {
				value = [DicToReadableValuesArray readableNull] ;
			}
		}
		
		SSYDictionaryEntry* entry = [[SSYDictionaryEntry alloc] initWithParent:dic
																		 key:key
																	   value:value] ;
		
		[array addObject:entry] ;
		[entry release] ;
	}
	return [array autorelease] ;
}

- (id)reverseTransformedValue:(id)array {
	NSMutableDictionary* dic = [[NSMutableDictionary alloc] initWithCapacity:[array count]] ;
	NSEnumerator* e = [array objectEnumerator] ;
	SSYDictionaryEntry* entry ;
	while ((entry = [e nextObject]) != nil) {
		id key = [entry valueForKey:@"key"] ;

		if (key == nil) {
			key = @"New Key" ;
		}

		id value = [entry valueForKey:@"value"] ;
		if (value == nil) {
			// We use an empty NSData to symbolize nil because
			// NSNull is not serializable.
			value = [NSData data] ;
		}
			
		[dic setObject:value forKey:key] ;
	}
	return [dic autorelease] ;
}

@end