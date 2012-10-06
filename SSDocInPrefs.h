#import <Cocoa/Cocoa.h>

////////////////////////////////////////////////
//  ACCESSOR MACROS
//  
//  These macros may be used in the document .m file
//  to generate accessors
//
//  Note: SSBIDA = Sheep Systems Built-In Document Accessor
////////////////////////////////////////////////

// for objects (O)
#define SSBIDAO(NAME,SETNAME,KEY) - (void)SETNAME:(id)in { \
	[self setObject:in forKey:KEY] ; \
} \
\
- (id)NAME { \
	return [self objectForKey:KEY] ; \
} \

// for integer (I)
#define SSBIDAI(NAME,SETNAME,KEY) - (void)SETNAME:(NSInteger)in { \
	[self setInteger:in forKey:KEY] ; \
} \
\
- (NSInteger)NAME { \
	return [self integerForKey:KEY] ; \
} \

// for BOOL (B)
#define SSBIDAB(NAME,SETNAME,KEY) - (void)SETNAME:(BOOL)in { \
	[self setBool:in forKey:KEY] ; \
} \
\
- (BOOL)NAME { \
	return [self boolForKey:KEY] ; \
} \

@interface SSDocInPrefs : NSObject
{
	NSString* _aggregateKey ;
	NSString* _documentKey ;
	NSDictionary* _defaultDefaults ;
}

- (id)initWithAggregateKey:(NSString*)aggregateName 
			   documentKey:(NSString*)documentKey
		   defaultDefaults:(NSDictionary*)defaultDefaults ;

+ (id)SSBuiltInDocumentWithAggregateKey:(NSString*)aggregateKey
							documentKey:(NSString*)documentKey
						defaultDefaults:(NSDictionary*)defaultDefaults ;

- (void)setObject:(id)object forKey:(NSString*)attributeKey ;
- (id)objectForKey:(NSString*)attributeKey ;
- (void)setBool:(BOOL)yn forKey:(NSString*)attributeKey ;
- (BOOL)boolForKey:(NSString*)attributeKey ;
- (void)setInteger:(NSInteger)n forKey:(NSString*)attributeKey ;
- (NSInteger)integerForKey:(NSString*)attributeKey ;

- (void)removeObjectForKey:(NSString*)attributeKey ;
- (void)removeAllAttributes ;

@end