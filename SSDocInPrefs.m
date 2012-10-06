#import "SSDocInPrefs.h"
#import "SSUtils.h"

// globals

@implementation SSDocInPrefs

SSAOm(NSString*,aggregateKey,setAggregateKey)
SSAOm(NSString*,documentKey,setDocumentKey)
SSAOm(NSDictionary*,defaultDefaults,setDefaultDefaults)

- (id)initWithAggregateKey:(NSString*)aggregateKey 
				documentKey:(NSString*)documentKey
			defaultDefaults:(NSDictionary*)defaultDefaults {
	if ((self = [super init]))
	{
		[self setAggregateKey:aggregateKey] ;
		[self setDocumentKey:documentKey] ;
		[self setDefaultDefaults:defaultDefaults] ;
	}
	
	return self ;
}

+ (id)SSBuiltInDocumentWithAggregateKey:(NSString*)aggregateKey
							documentKey:(NSString*)documentKey
						defaultDefaults:(NSDictionary*)defaultDefaults {
	SSDocInPrefs *x = [[SSDocInPrefs alloc]
			initWithAggregateKey:aggregateKey	
					 documentKey:documentKey 
				 defaultDefaults:defaultDefaults] ;
 	return [x autorelease];
}
	

- (void)dealloc
{
	[self setAggregateKey:nil] ;
	[self setDocumentKey:nil] ;
	[self setDefaultDefaults:nil] ;
	
	[super dealloc] ;
}


- (void)setObject:(id)object forKey:(NSString*)attributeKey
{
	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults] ;
	NSString* aggregateKey = [self aggregateKey] ;
	NSString* documentKey = [self documentKey] ;
	
	NSMutableDictionary* documentDics = [[userDefaults objectForKey:aggregateKey] mutableCopy] ;
	if (!documentDics)
		documentDics = [[NSMutableDictionary alloc] init] ;
	NSMutableDictionary* documentDic = [[documentDics objectForKey:documentKey] mutableCopy] ;
	if (!documentDic)
		documentDic = [[NSMutableDictionary alloc] init] ;
		
	[documentDic setObject:object forKey:attributeKey] ;
	[documentDics setObject:documentDic forKey:documentKey] ;
	[documentDic release] ;
	[userDefaults setObject:documentDics forKey:aggregateKey] ;
	[documentDics release] ;
	[userDefaults synchronize] ;
}

- (id)objectForKey:(NSString*)attributeKey
{
	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults] ;
	id object = [[[userDefaults objectForKey:[self aggregateKey]] objectForKey:[self documentKey]] objectForKey:attributeKey] ;
	if (!object)
		object = [[self defaultDefaults] objectForKey:attributeKey] ; 
	return  object ;
}

- (void)setBool:(BOOL)yn forKey:(NSString*)attributeKey
{
	[self setObject:[NSNumber numberWithBool:yn] forKey:attributeKey] ;
}

- (BOOL)boolForKey:(NSString*)attributeKey 
{
	BOOL output = ([[self objectForKey:attributeKey] boolValue] != 0) ;
	return output;
}

- (void)setInteger:(NSInteger)n forKey:(NSString*)attributeKey
{
	[self setObject:[NSNumber numberWithInteger:n] forKey:attributeKey] ;
}

- (NSInteger)integerForKey:(NSString*)attributeKey 
{
	return ([[self objectForKey:attributeKey] integerValue]) ;
}

- (void)removeObjectForKey:(NSString*)attributeKey
{
	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults] ;

	NSString* aggregateKey = [self aggregateKey] ;
	NSString* documentKey = [self documentKey] ;
	
	NSMutableDictionary* documentDics = [[userDefaults objectForKey:aggregateKey] mutableCopy] ;
	if (documentDics)
	{
		NSMutableDictionary* documentDic = [[documentDics objectForKey:documentKey] mutableCopy] ;
		if (documentDic)
		{
			[documentDic removeObjectForKey:attributeKey] ;
			[documentDics setObject:documentDic forKey:documentKey] ;
			[userDefaults setObject:documentDics forKey:aggregateKey] ;
			[documentDic release] ;
			[documentDics release] ;
			[userDefaults synchronize] ;
		}
	}
}

- (void)removeAllAttributes
{
	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults] ;

	NSString* aggregateKey = [self aggregateKey] ;
	NSString* documentKey = [self documentKey] ;

	NSMutableDictionary* documentDics = [[userDefaults objectForKey:aggregateKey] mutableCopy] ;
	[documentDics removeObjectForKey:documentKey] ;
	
	[userDefaults setObject:documentDics forKey:aggregateKey] ;
	[userDefaults synchronize] ;
}


@end
