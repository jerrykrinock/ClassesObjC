#import "SSYSqliter.h"
#import "NSError+InfoAccess.h"
#import "NSArray+SafeGetters.h"
#import "NSError+MoreDescriptions.h"
#import "NSError+MyDomain.h"
#import "NSError+SSYInfo.h"

#include "sqlite3.h"

NSString* const SSYSqliterErrorDomain = @"SSYSqliterErrorDomain" ;
NSString* const SSYSqliterSqliteErrorCode = @"SqliteErrorCode" ;

@implementation NSObject (HelpSQL) 

- (NSString*)stringEsquotedSQLValue {
	NSString* answer ;
	if ([self isKindOfClass:[NSNumber class]]) {
		answer = [(NSNumber*)self descriptionWithLocale:nil] ;
		// -descriptionWithLocale: is documented to return the
		// the number in the expected "normal-looking" format for the
		// type (integer, float, double, etc.) "that the number
		// was created with".
	}
	else if ([self isKindOfClass:[NSString class]]) {
		NSString* work ;
		if ([(NSString*)self rangeOfString:@"'"].location == NSNotFound) {
			work = [self copy] ;
		}
		else {
			work = [[NSMutableString alloc] initWithString:(NSString*)self] ;
			[(NSMutableString*)work replaceOccurrencesOfString:@"'"
													withString:@"''"
													   options:0
														 range:NSMakeRange(0, [(NSString*)self length])] ;
		}
		
		answer = [NSString stringWithFormat:@"'%@'", work] ;
		[work release] ;
	}
	else if ([self isKindOfClass:[NSSet class]]) {
		answer = [NSString stringWithFormat:@"(%@)",
				  [[(NSSet*)self stringsEsquotedSQLValue] componentsJoinedByString:@","]] ;
	}
	else if ([self isKindOfClass:[NSArray class]]) {
		answer = [NSString stringWithFormat:@"(%@)",
				  [[(NSArray*)self stringsEsquotedSQLValue] componentsJoinedByString:@","]] ;
	}
	else if ([self isKindOfClass:[NSNull class]]) {
		answer = @"NULL" ;
		// Note that, because this not quoted as in 'NULL', this will be
		// interpreted by sqlite as the sqlite keyword NULL.
	}
	else {
		NSLog(@"%s Error: Class %@ cannot be stringified.",
                  __PRETTY_FUNCTION__,
                  [self class]) ;
        answer = nil ;
	}

	return answer ;
}

@end


@implementation NSMutableString (HelpSQL)

+ (NSMutableString*)queryStringWhereColumn:(NSString*)column
							 isAnyOfValues:(NSArray*)values {
	NSMutableString* query = nil ;
	if ((column != nil) && (values !=nil) && ([values count] > 0)) {
		query = [[NSMutableString alloc] initWithFormat:@"(%@=%@",
				 column,
				 [[values objectAtIndex:0] stringEsquotedSQLValue]] ;
		NSInteger i ;
		NSInteger N = [values count] ;
		for (i=1; i<N; i++) {
			[query appendFormat:@" OR %@=%@",
			 column,
			 [[values objectAtIndex:i] stringEsquotedSQLValue]] ;
		}
		[query appendString:@")"] ;
	}
	
	return [query autorelease] ;
}

@end

@implementation NSSet (HelpSQL)

- (NSArray*)stringsEsquotedSQLValue {
	NSMutableArray* stringsEsquotedSQLValue = [[NSMutableArray alloc] init] ;
	NSEnumerator* e = [self objectEnumerator] ;
	id object ;
	while ((object = [e nextObject])) {
		[stringsEsquotedSQLValue addObject:[object stringEsquotedSQLValue]] ;
	}
	
	NSArray* output = [stringsEsquotedSQLValue copy] ;
	[stringsEsquotedSQLValue release] ;
	
	return [output autorelease] ;
}

@end

@implementation NSArray (HelpSQL) 

- (NSArray*)stringsEsquotedSQLValue {
	NSMutableArray* stringsEsquotedSQLValue = [[NSMutableArray alloc] init] ;
	NSEnumerator* e = [self objectEnumerator] ;
	id object ;
	while ((object = [e nextObject])) {
		[stringsEsquotedSQLValue addObject:[object stringEsquotedSQLValue]] ;
	}
	
	NSArray* output = [stringsEsquotedSQLValue copy] ;
	[stringsEsquotedSQLValue release] ;
	
	return [output autorelease] ;
}

@end

@interface NSDictionary (HelpSQL) 

- (NSString*)sqlQuotedUpdateString ;

@end

@implementation NSDictionary (HelpSQL) 

- (NSString*)sqlQuotedUpdateString {
	NSMutableArray* kvPairs = [[NSMutableArray alloc] init] ;
	NSEnumerator* e = [self keyEnumerator] ;
	NSString* key ;
	while ((key = [e nextObject])) {
		NSString* kvPair = [[NSString alloc] initWithFormat:@"%@=%@",
							key,
							[[self objectForKey:key] stringEsquotedSQLValue]] ;
		[kvPairs addObject:kvPair] ;
		[kvPair release] ;
	}	
	
    NSString* answer = [kvPairs componentsJoinedByString:@","] ;
    [kvPairs release] ;
    
    return answer ;
}

@end

NSString* SSAppDatabaseKeysAndTypesFromArray(NSArray* a) {
	NSEnumerator* e = [a objectEnumerator] ;
	NSString* s ;
	NSMutableString* sList = [[NSMutableString alloc] initWithString:@"identifier INTEGER PRIMARY KEY,"] ;
	BOOL wasKey = NO ; // otherwise, wasType
	while ((s = [e nextObject])) {
		[sList appendString:s] ;
		if (wasKey) {
			wasKey = YES ;
		}
		else {
			[sList appendString:@","] ;
			wasKey = NO ;
		}
	}
	NSString* answer = [sList substringToIndex:([sList length]-1)] ; // -1 to eliminate the final ","
	[sList release] ;
	return answer ;
}
	
NSString* SSAppDatabaseKeysAndBlobsFromArray(NSArray* a) {
	NSEnumerator* e = [a objectEnumerator] ;
	NSString* s ;
	NSMutableString* sList = [[NSMutableString alloc] initWithString:@"identifier INTEGER PRIMARY KEY,"] ;
	while ((s = [e nextObject])) {
		[sList appendString:s] ;
		[sList appendString:@" blob,"] ;
	}
	NSString* answer = [sList substringToIndex:([sList length]-1)] ; // -1 to eliminate the final ","
	[sList release] ;
	return answer ;
}

// struct used in the demo methods
typedef struct {
	NSInteger     a;
	CGFloat   b;
	char    c[50];
} sampleRecord;


// callbacks from sqlite_exec()

static int CheckExistenceOfSQLiteRow(void* sneakback, int nFound, char **values, char **colKeys){
	BOOL itemExists = (nFound > 0) ;
	*((BOOL*)sneakback) = itemExists ;
	return 0;
}

static int AddValueStringToArray(void* sneakback, int nColumns, char **colValues, char **colKeys) {
	// sneakback must be the address of an initialized NSMutableArray*.

	int result = 0 ;
	
	if (nColumns != 1) {
		result = nColumns ;
	}
	
	if (result == 0) {
		NSString* value = [NSString stringWithCString:colValues[0]
											 encoding:NSUTF8StringEncoding] ;

		NSMutableArray* array = *((NSMutableArray**)sneakback) ;
		[array addObject:value] ;
	}
	
	return result;
}

#if 0
!! This function is no longer used.
static NSInteger AddKeyStringToArray(void* sneakback, NSInteger nColumns, char **colValues, char **colKeys) {
	// sneakback must be the address of an initialized NSMutableArray*.
	
	NSInteger i;
	for(i=0; i<nColumns; i++){
		NSString* attributeKey = [NSString stringWithCString:colKeys[i]
													encoding:NSUTF8StringEncoding] ;
		NSLog(@"Got attributeKey = \"%@\"", attributeKey ) ;
		[*((NSMutableArray**)sneakback) addObject:attributeKey] ;
		
	}

	return 0;
}
#endif

#if 0
!! This function is no longer used.
static NSInteger AddValueIntegerToArray(void* sneakback, NSInteger nColumns, char **colValues, char **colKeys) {
	// sneakback must be the address of an initialized NSMutableArray*.
	
	NSInteger result = 0 ;
	
	if (nColumns != 1) {
		result = nColumns ;
	}
	
	if (result == 0) {
		NSNumber* value = [NSNumber numberWithInteger:[[NSString stringWithCString:colValues[0]
																	  encoding:NSUTF8StringEncoding] integerValue]] ;
		
		NSMutableArray* array = *((NSMutableArray**)sneakback) ;
		[array addObject:value] ;
	}
	
	return result;
}
#endif

#if 0
!! This function is no longer used.
static NSInteger CountColumns(void* sneakback, NSInteger nColumns, char **colValues, char **colKeys) {
	// sneakback must be the address of an int.
	
	*((NSInteger*)(sneakback)) = nColumns ;
	
	return 0 ;
}
#endif

#if 0
!! This callback is no longer used.
static NSInteger SSAppSQLiteCallback(void* NotUsed, NSInteger nColumns, char **colValues, char **colKeys) {
	NSInteger i;
	for(i=0; i<nColumns; i++){
		NSString* attributeKey = [NSString stringWithCString:colKeys[i]
													encoding:NSUTF8StringEncoding] ;
		NSLog(@"Got attributeKey = \"%@\"", attributeKey ) ;
		
		NSString* dataS = [NSString stringWithCString:colValues[i]
											 encoding:NSUTF8StringEncoding] ;
		NSLog(@"Got dataS = \"%@\"", dataS ) ;		
	}
	return 0;
}
#endif

@implementation SSYSqliter

+ (NSMutableString*)queryDeleteFromTable:(NSString*)table
							 whereColumn:(NSString*)column
									  is:(id)value {
	NSMutableString* query = nil ;
	
	if (value) {
		query = [NSMutableString stringWithFormat:@"DELETE FROM %@ WHERE %@ = %@",
				 table,
				 column,
				 [value stringEsquotedSQLValue]] ;
		
	}
	
	return query ;
}

+ (NSMutableString*)queryDeleteFromTable:(NSString*)table
							 whereColumn:(NSString*)column
									isIn:(id)values {
	NSMutableString* query = nil ;
	
	if ((values != nil) && [values count] > 0) {
		if ([values isKindOfClass:[NSSet class]]) {
			// Convert from set to array
			values = [(NSSet*)values allObjects] ;
		}
				
		query = [NSMutableString stringWithFormat:@"DELETE FROM %@ WHERE %@ IN %@",
				 table,
				 column,
				 [values stringEsquotedSQLValue]] ;
		
	}
	return query ;
}

+ (NSString*)queryInsertIntoTable:(NSString*)table
						  columns:(NSArray*)columns
						   values:(NSArray*)values {
	return [NSString stringWithFormat:@"InSERT INTO %@ (%@) VALUES %@",
			table,
			[columns componentsJoinedByString:@","],
			[values stringEsquotedSQLValue]] ;
}

+ (NSString*)queryAlterTable:(NSString*)table
				   addColumn:(NSString*)column
						type:(NSString*)type {
	return [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ %@",
			table,
			[column stringEsquotedSQLValue],
			[type stringEsquotedSQLValue]] ;
}

+ (NSString*)queryUpdateTable:(NSString*)table
					  updates:(NSDictionary*)updates
				  whereColumn:(NSString*)whereColumn
				   whereValue:(id)whereValue {
	NSString* updateString = [updates sqlQuotedUpdateString] ;
	
	return [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE (%@=%@)",
			table,
			updateString,
			whereColumn,
			[whereValue stringEsquotedSQLValue]] ;
}



- (NSString *)path {
    return m_path ; 
}

- (void)setPath:(NSString *)newPath {
    [newPath retain] ;
    [m_path release] ;
    m_path = newPath ;
}

- (NSError*)makeErrorWithAppCode:(NSInteger)appCode
					  sqliteCode:(NSInteger)sqliteCode
			   sqliteDescription:(const char*)sqliteDescriptionC
						   query:(NSString*)query
				  prettyFunction:(const char*)prettyFunction {
	
	NSError* error = [NSError errorWithDomain:SSYSqliterErrorDomain
										 code:appCode
									 userInfo:nil] ;
	
	error = [error errorByAddingUnderlyingError:[NSError errorWithDomain:SSYSqliterErrorDomain
																	code:sqliteCode
																userInfo:nil]] ;
	
	NSString* sqliteDescription ;
	if (sqliteDescriptionC) {
		sqliteDescription = [NSString stringWithCString:sqliteDescriptionC
											   encoding:NSUTF8StringEncoding] ;
	}
	else {
		sqliteDescription = @"[No error message from sqlite.]" ;
	}
	error = [error errorByAddingUserInfoObject:sqliteDescription
										forKey:@"sqlite's Error Description"] ;
	
	error = [error errorByAddingUserInfoObject:query
										forKey:@"Query"] ;
    
    error = [error errorByAddingUserInfoObject:[self path]
                                        forKey:@"Database path"] ;
	
	if (prettyFunction != NULL) {
		error = [error errorByOverwritingUserInfoObject:[NSString stringWithCString:prettyFunction
																		   encoding:NSUTF8StringEncoding]
												 forKey:SSYMethodNameErrorKey] ;
	}
	
	return error ;
}

- (BOOL)initDatabaseError_p:(NSError**)error_p {
	BOOL ok = YES ;
    NSInteger result;
    @synchronized([self class]) {
        /* When multiple .bmco documents are opened during launch of
         BookMacster, without the above @synchronized, we get a Thread
         Sanitizer violation inside sqlite3 at this line of code:

         pTo->xMutexAlloc = pFrom->xMutexAlloc;

         in this call stack:

         #0 sqlite3_initialize sqlite3.c:139153 (Bkmxwork:x86_64+0x6af7f9)
         #1 openDatabase sqlite3.c:141782 (Bkmxwork:x86_64+0x715932)
         #2 sqlite3_open sqlite3.c:142101 (Bkmxwork:x86_64+0x71583f)
         #3 -[SSYSqliter initDatabaseError_p:] SSYSqliter.m:418 (Bkmxwork:x86_64+0x366a04)
         #4 -[SSYSqliter initWithPath:error_p:] SSYSqliter.m:2082 (Bkmxwork:x86_64+0x373cba)
         #5 +[BSManagedDocument(SSYMetadata) metadataAtPath:] BSManagedDocument+SSYMetadata.m:17 (Bkmxwork:x86_64+0x5f8cc2)
         #6 +[BSManagedDocument(SSYMetadata) metadataObjectForKey:path:] BSManagedDocument+SSYMetadata.m:99 (Bkmxwork:x86_64+0x5f96cd)
         #7 -[BSManagedDocument(SSYMetadata) metadataObjectForKey:] BSManagedDocument+SSYMetadata.m:114 (Bkmxwork:x86_64+0x5f9973)
         #8 -[BkmxDoc configurePersistentStoreCoordinatorForURL:ofType:modelConfiguration:storeOptions:error:] BkmxDoc.m:1704 (Bkmxwork:x86_64+0x41f2a2)
         #9 -[BSManagedDocument configurePersistentStoreCoordinatorForURL:ofType:error:] BSManagedDocument.m:256 (Bkmxwork:x86_64+0x3e3f77)
         #10 -[BSManagedDocument readFromURL:ofType:error:] BSManagedDocument.m:375 (Bkmxwork:x86_64+0x3e512e)

         This stack will run concurrently, on different threads for each
         document.

         Although this method only runs once for each document, and both
         parameters (the path and &m_db) are different for each document,
         using @synchronize(self) or @synchronize([self path]) does not fix the
         violation.  It looks like the explanation is that, in sqlite3,
         pTo->MutexAlloc is a global variable.  Therefore, in order to fix the
         violation, we need to @synchronize on something global ([self class]).
         Anyhow, doing that cleared the Thread Sanitizer violation. */
        result = sqlite3_open([[self path] UTF8String], (sqlite3**)&m_db) ;
    }

	if (result != SQLITE_OK) {
		if (error_p) {
			m_db = NULL ;
			*error_p = [self makeErrorWithAppCode:453026
									   sqliteCode:result
								sqliteDescription:sqlite3_errmsg(m_db)
											query:nil
								   prettyFunction:__PRETTY_FUNCTION__] ;				
		}
		// See http://lists.apple.com/archives/Objc-language/2008/Sep/msg00133.html ...
		
		ok = NO ;
	}
	
	return ok ;
}

- (void *)db {
    if (!m_db) {
		NSError* error = nil  ;
		BOOL ok = [self initDatabaseError_p:&error] ;
		if (!ok) {
			NSLog(@"Internal Error 928-2928 %@", [error longDescription]) ;
		}
	}
	
	return m_db ; 
}

- (BOOL)createTable:(NSString*)table
   withKeysAndTypes:(NSArray*)keysAndTypes
			  error:(NSError**)error_p {
	NSString* cts = SSAppDatabaseKeysAndTypesFromArray(keysAndTypes) ;
	char* errMsg = 0 ;
	void* db = [self db] ;
	NSInteger result ;

	NSString* statement = [[NSString alloc] initWithFormat:
		@"create table %@ (%@)",
		table,
		cts] ;
	
	result = sqlite3_exec(db, [statement UTF8String], NULL, NULL, &errMsg);
	NSError* error = nil ;
	if (!(result == SQLITE_OK)) {
		error = [self makeErrorWithAppCode:453001
								sqliteCode:result
						 sqliteDescription:errMsg
									 query:statement
								prettyFunction:__PRETTY_FUNCTION__] ;
		sqlite3_free(errMsg) ;
	}
	[statement release] ;
	
	if (error && error_p) {
		*error_p = error ;
	}
    
    return (error == nil) ;
}

- (BOOL)removeTable:(NSString*)table
			  error:(NSError**)error_p {
	const char* tableC = [table UTF8String] ;
	char statement[255] ;
	char* errMsg = 0 ;
	void* db = [self db] ;
	NSInteger result ;
	
	// drop the table
	sprintf(statement, "drop table if exists %s", tableC) ;
	result = sqlite3_exec(db, statement, NULL, NULL, &errMsg) ;
	
	NSError* error = nil ;
	if (result == SQLITE_OK) {
		// remove the empty space
		sprintf(statement, "vacuum %s", tableC) ;
		result = sqlite3_exec(db, statement, NULL, NULL, &errMsg) ;
		if (result != SQLITE_OK) {  
			error = [self makeErrorWithAppCode:453002
									sqliteCode:result
							 sqliteDescription:errMsg
										 query:[NSString stringWithCString:statement
																  encoding:NSUTF8StringEncoding]
									prettyFunction:__PRETTY_FUNCTION__] ;
			sqlite3_free(errMsg) ;
			goto end ;
		}
	}
	else {  
		error = [self makeErrorWithAppCode:453003
								sqliteCode:result
						 sqliteDescription:errMsg
									 query:[NSString stringWithCString:statement
															  encoding:NSUTF8StringEncoding]
								prettyFunction:__PRETTY_FUNCTION__] ;
		sqlite3_free(errMsg) ;
	}
end:
	if (error && error_p) {
		*error_p = error ;
	}
    
    return (error == nil) ;
}

- (BOOL)createTableOfBlobsNamed:(NSString*)table
					   withKeys:(NSArray*)keys
						  error:(NSError**)error_p {
	NSString* cts = SSAppDatabaseKeysAndBlobsFromArray(keys) ;
	char* errMsg = 0 ;
	void* db = [self db] ;
	NSInteger result ;
	
	NSString* statement = [[NSString alloc] initWithFormat:
		@"create table %@ (%@)",
		table,
		cts] ;
	
	NSError* error = nil ;
	result = sqlite3_exec(db, [statement UTF8String], NULL, NULL, &errMsg);
	if (!(result == SQLITE_OK)) {  
		error = [self makeErrorWithAppCode:453004
								sqliteCode:result
						 sqliteDescription:errMsg
									 query:statement
								prettyFunction:__PRETTY_FUNCTION__] ;
		sqlite3_free(errMsg) ;
	}
	
	[statement release] ;

	if (error_p != nil) {
		*error_p = error ;
	}
    
    return (error == nil) ;
}

- (NSArray*)allTablesError:(NSError**)error_p {
	void* db = [self db] ;
	char* errMsg = NULL ;
	NSInteger result ;
	
	NSError* error = nil ;
	NSString* statement ;
	statement = @"SELECT name FROM sqlite_master WHERE type='table' ORDER BY name" ;
	NSMutableArray* names = [[NSMutableArray alloc] init] ;
	result = sqlite3_exec(db, [statement UTF8String], AddValueStringToArray, &names, &errMsg);
	if (!(result == SQLITE_OK)) {  
		error = [self makeErrorWithAppCode:453005
								sqliteCode:result
						 sqliteDescription:errMsg
									 query:statement
								prettyFunction:__PRETTY_FUNCTION__] ;
		sqlite3_free(errMsg) ;
	}
	
	NSArray* output = [names copy] ;
	[names release] ;

	if (error_p != nil) {
		*error_p = error ;
	}

	return [output autorelease] ;
}

- (NSDictionary*)structureOfTable:(NSString*)table
							error:(NSError**)error_p {
    // Will return nil if fails, empty array if no columns
	void* db = [self db] ;
	char* errMsg = NULL ;
	NSInteger result ;
	
	NSString* statement ;
	statement = [[NSString alloc] initWithFormat:@"pragma table_info(%@)", table] ;
	char** results ;
	int nRows ;
	int nColumns ;
	NSError* error = nil ;
	result = sqlite3_get_table(
							   db,             /* An open database */
							   [statement UTF8String], /* SQL to be executed */
							   &results,       /* Result written to a char *[]  that this points to */
							   &nRows,         /* Number of result rows written here */
							   &nColumns,      /* Number of result columns written here */
							   &errMsg         /* Error msg written here */
	) ;
	
	/* 'results' is a two-dimensional array of C strings, actually a char***.
	 The number of strings in 'results' is (nColumns+1) x nRows.
	 'nRows' is typically 6, corresponding to the number of fields given for each column.
	 The columns correspond to the columns in the table, except for the
	 first column which is the array of strings:
	 'cid'         columnIdentifier    "0", "1", "2", ...
	 'name',       name                "FirstName", "LastName"
	 'type',       data type           "INTEGER", "TEXT", "LONGVARCHAR", "VARCHAR(32)", "BLOB", "LONG", "" (empty string)
	 'notnull',    allow NULL value?   "0" or "99"
	 'dflt_value', default value       "0", "1", "some string", "NULL"
	 'pk'          is primary key      "0" or "1"
	 and of course this first column is responsible for the "+1" in (nColumns+1)
	 */
	NSMutableDictionary* columnDics = nil ;
	if (!(result == SQLITE_OK)) {  
		error = [self makeErrorWithAppCode:453006
								sqliteCode:result
						 sqliteDescription:errMsg
									 query:statement
								prettyFunction:__PRETTY_FUNCTION__] ;
		sqlite3_free(errMsg) ;
		goto end ;
	}
	else {
		NSInteger j ;
		NSMutableArray* keys = [NSMutableArray array] ;
		NSInteger nameColumnIndex = NSNotFound ;
		for (j=0; j<nColumns; j++) {
			/*  Column keys (names) (strings) in this table are:
			 'cid'         columnIdentifier    "0", "1", "2", ...
			 'name',       name                "FirstName", "LastName"
			 'type',       data type           "INTEGER", "TEXT", "LONGVARCHAR", "VARCHAR(32)", "BLOB", "LONG", "" (empty string)
			 'notnull',    allow NULL value?   "0" or "99"
			 'dflt_value', default value       "0", "1", "some string", "NULL"
			 'pk'          is primary key      "0" or "1"
			 */
			NSString* key = [NSString stringWithCString:results[j]
											   encoding:NSUTF8StringEncoding] ;
			if ([key isEqualToString:@"name"]) {
				nameColumnIndex = j ;
			}
			[keys addObject:key] ;
		}
		
		if (nameColumnIndex == NSNotFound) {
			error = SSYMakeError(453027, @"No 'name' key in table structure") ;
			goto end ;
		}
		
		NSInteger i ;
		columnDics = [[NSMutableDictionary alloc] init] ;
		for (i=0; i<nRows; i++) {
			NSMutableDictionary* columnDic = [[NSMutableDictionary alloc] init] ;
			NSString* columnName ;
			for (j=0; j<nColumns; j++) {
				NSInteger k = (i+1)*nColumns + j ;
				char* result = results[k] ;
				// result will either be a null-terminated string, or NULL.
				// (Note that for a zero-length string, result will not be NULL
				//  but will be a pointer to NULL.)
				id object ;
				if (result != NULL) {
					object = [NSString stringWithCString:result
												encoding:NSUTF8StringEncoding] ;
				}
				else {
					object = [NSNull null] ;
				}
				
				if (j == nameColumnIndex) {
					columnName = object ;
				}
				else {
					[columnDic setObject:object
								  forKey:[keys objectAtIndex:j]] ;
				}
			}
			[columnDics setObject:columnDic
						   forKey:columnName] ;
			[columnDic release] ;
		}
	}

	sqlite3_free_table(results) ;

end:
	[statement release] ;

	NSDictionary* output = [columnDics copy] ;
	[columnDics release] ;

	if (error_p != nil) {
		*error_p = error ;
	}

	return [output autorelease] ;
}

- (NSInteger)numberOfColumnsInTable:(NSString*)table
						error:(NSError**)error_p {
	return [[self structureOfTable:table
							 error:error_p] count]  ;
}

- (NSInteger)numberOfRowsInTable:(NSString*)table
						error:(NSError**)error_p {
	NSString* query = [NSString stringWithFormat:@"SELECT count(*) FROM %@",
					   [table stringEsquotedSQLValue]] ;					   

	NSError* error = nil ;
	NSArray* result = [self runQuery:query
							   error:&error] ;
	if (error_p && error) {
		*error_p = error ;
	}

	NSInteger answer = NSNotFound ;
	if ([result count] > 0) {
		answer = [[result objectAtIndex:0] integerValue] ;
	}
	
	return answer ;
}

- (NSString*)primaryKeyOfTable:(NSString*)table
						 error:(NSError**)error_p {
    NSDictionary* columnDics = [self structureOfTable:table
												error:error_p] ;

	NSString* primaryKey = nil ;
	for (NSString* columnName in columnDics) {
		if ([[[columnDics objectForKey:columnName] objectForKey:@"pk"] isEqualToString:@"1"]) {
			primaryKey = columnName ;
			break ;
		}
	}

	return primaryKey ;
}

- (NSArray*)keysInTable:(NSString*)table
				  error:(NSError**)error_p {
    NSDictionary* columnDics = [self structureOfTable:table
												error:error_p] ;
	return [columnDics allKeys] ;
}

- (NSArray*)allPrimaryKeysInTable:(NSString*)table
							error:(NSError**)error_p {
	void* db = [self db] ;
	char* errMsg = NULL ;
	NSInteger result ;
	NSArray* output = nil ;

	NSError* error = nil ;
	NSString* primaryKey = [self primaryKeyOfTable:table
											 error:&error] ;
	if (!primaryKey) {
		return nil ;
	}
	
	if (error != nil) {
		goto end ;
	}
	
	NSString* statement ;
	NSMutableArray* primaryKeys = [[NSMutableArray alloc] init] ;
	statement = [[NSString alloc] initWithFormat:@"SELECT %@ FROM %@", primaryKey, table] ;
	result = sqlite3_exec(db, [statement UTF8String], AddValueStringToArray, &primaryKeys, &errMsg);
	if (!(result == SQLITE_OK)) {  
		error = [self makeErrorWithAppCode:453007
								sqliteCode:result
						 sqliteDescription:errMsg
									 query:statement
								prettyFunction:__PRETTY_FUNCTION__] ;
		sqlite3_free(errMsg) ;
	}
	[statement release] ;

	output = [primaryKeys copy] ;
	[primaryKeys release] ;

end:
	if (error_p != nil) {
		*error_p = error ;
	}

	return [output autorelease] ;
}

- (BOOL)checkpointAndCloseError_p:(NSError**)error_p {
	if (!m_db) {
		return YES ;
	    // because sqlite3_wal_checkpoint(NULL, NULL) will crash
	}
	
	NSInteger result ;
    int nFramesLogged ;
    int nFramesCheckpointed ;
	result = sqlite3_wal_checkpoint_v2(
                                       m_db,  /* Database handle */
                                       NULL,  /* Name of attached database, NULL for main/only database */
                                       SQLITE_CHECKPOINT_PASSIVE,
                                       &nFramesLogged,
                                       &nFramesCheckpointed) ;
    if (result == SQLITE_BUSY) {
        /* I've found that this happens when deallocating an ExtoreFirefox,
         after an export in style 2, which should not even have used an
         SSYSQLiter.  So we ignore this error. */
        result = SQLITE_OK ;
    }
	if ((result != SQLITE_OK) && error_p) {
		*error_p = [self makeErrorWithAppCode:453035
								   sqliteCode:result
							sqliteDescription:sqlite3_errmsg([self db])
										query:@"Doing checkpoint (not a query)"
							   prettyFunction:__PRETTY_FUNCTION__] ;
        *error_p = [*error_p errorByAddingUserInfoObject:[NSNumber numberWithInteger:nFramesLogged]
                                                  forKey:@"Frames Logged"] ;
        *error_p = [*error_p errorByAddingUserInfoObject:[NSNumber numberWithInteger:nFramesCheckpointed]
                                                  forKey:@"Frames Checkpointed"] ;
	}
	
	sqlite3_close(m_db) ;
	m_db = NULL ;
	
	return (result == SQLITE_OK) ;
}

- (long long)nextLongLongInColumn:(NSString*)column
						  inTable:(NSString*)table
					 initialValue:(long long)initialValue
							error:(NSError**)error_p  {
	NSString* query = [NSString stringWithFormat:@"SELECT %@ FROM %@ ORDER BY %@ DESC LIMIT 1",
					   column,
					   table,
					   column] ;
	// In above, DESC means descending order and LIMIT 1 says to only return 1 row.

	NSError* error = nil ;
	NSNumber* lastNumber = [[self runQuery:query
									 error:&error] firstObjectSafely] ;
	if (error_p && error) {
		*error_p = error ;
	}
	
	long long next = initialValue ;
	if ([lastNumber respondsToSelector:@selector(integerValue)]) {
		next = [lastNumber integerValue] + 1 ;
	}
	
	return next ;
}

- (NSDictionary*)nextRowFromPreparedStatement:(sqlite3_stmt*)preparedStatement {
	// If 1 column, will return object value
	// If >1 column, will return dictionary of object values
	id row = nil ;
	
	NSInteger nColumns = sqlite3_column_count(preparedStatement) ;
	
	if (nColumns > 1) {
		row = [[NSMutableDictionary alloc] init] ;
	}
		
	int iColumn  ;
	for (iColumn= 0; iColumn<nColumns; iColumn++) {
		NSInteger type = sqlite3_column_type(preparedStatement, iColumn) ;
		// The sqlite3_column_type() routine returns datatype code for the initial data type of the result column.
		// The returned value is one of SQLITE_INTEGER, SQLITE_FLOAT, SQLITE_TEXT, SQLITE_BLOB, or SQLITE_NULL
		
		// Initialize to null in case object is not found
		const void* pFirstByte = NULL ;
		NSInteger nBytes = 0 ;
		id object = nil ;
		int64_t intValue ;
		const unsigned char* utf8String ;
		double doubleValue ;
		switch(type) {
			case SQLITE_BLOB:
				nBytes = sqlite3_column_bytes(preparedStatement, iColumn) ;
				// "The return value from sqlite3_column_blob() for a zero-length
				// blob is an arbitrary pointer, possibly even a NULL pointer."
				// Therefore, we qualify...
				if (nBytes > 0) {
					pFirstByte = sqlite3_column_blob(preparedStatement, iColumn) ;
					object = [NSData dataWithBytes:pFirstByte
                                            length:nBytes] ;
				}
				break ;
            case SQLITE_INTEGER:
				// The INTEGER type in sqlite3 is 64 bits, so it is always
				// OK to use sqlite3_column_int64().  If we knew that the
				// value was < 32 bits, we could use sqlite3_column_int(),
				// we don't.  As a matter of fact, the addDate and
				// lastModifiedDate in Firefox 3 are microseconds since
				// year 1970, and this does indeed exceed 32 bits.
				intValue = sqlite3_column_int64(preparedStatement, iColumn) ;
				object = [NSNumber numberWithLongLong:intValue] ;
				break ;
            case SQLITE_TEXT:
				// "Strings returned by sqlite3_column_text() and sqlite3_column_text16(),
				// even zero-length strings, are always zero terminated."
				// So, we ignore the length and just convert it
				utf8String = sqlite3_column_text(preparedStatement, iColumn) ;
				object = [NSString stringWithUTF8String:(char*)utf8String] ;
				break ;
            case SQLITE_FLOAT:
				doubleValue = sqlite3_column_double(preparedStatement, iColumn) ;
				object = [NSNumber numberWithDouble:doubleValue] ;
				break ;
            case SQLITE_NULL:
            default:
				// Just leave object nil, will replace with [NSNull null] soon.
				;
		}
		
		if (object == nil) {
			object = [NSNull null] ;
		}
		
		NSString* key = [NSString stringWithCString:sqlite3_column_name(preparedStatement, iColumn)
										   encoding:NSUTF8StringEncoding] ;
		if (row != nil) {
			[row setObject:object
                    forKey:key] ;
		}
		else {
            [row release] ;  // Really it's nil, but this is to satisfy Clang
			row = [object retain] ;
		}
	}
	
	NSDictionary* output = [row copy] ;
	[row release] ;
	return [output autorelease] ;
}

- (NSArray*)runQuery:(NSString*)query
			   error:(NSError**)error_p {
	// If 1 column, will return array of object values
	// If >1 column, will return array of dictionaries of object values
	NSArray* output = nil ;
	NSError* error = nil ;
#if SSY_SQLITER_LOG_QUERIES
	NSLog(@"%s: %@", __PRETTY_FUNCTION__, query) ;
#endif
	if (query != nil) {
		void* db = [self db] ;
		int result ;
		
		// Compile the query into a virtual machine
		sqlite3_stmt* preparedStatement = NULL ;
		result = sqlite3_prepare(db, [query UTF8String], -1, &preparedStatement, NULL) ;
		
		if (result != SQLITE_OK) {  
			error = [self makeErrorWithAppCode:453008
									sqliteCode:result
							 sqliteDescription:sqlite3_errmsg(db)
										 query:query
								prettyFunction:__PRETTY_FUNCTION__] ;
			goto end ;
		}
		else {
			NSMutableArray* rows = [[NSMutableArray alloc] init] ;
			while (sqlite3_step(preparedStatement) == SQLITE_ROW) {			
				id row = [self nextRowFromPreparedStatement:preparedStatement];
				[rows addObject:row] ;
			}
			
			output = [rows copy] ;
			[rows release] ;
			[output autorelease] ;
		}
		
		// Finalize the query (this releases resources allocated by sqlite3_prepare()
		/* 
		 According to D. Richard Hipp on 20080303:
		 I have modified the documentation so that SQLite now guarantees
		 that it will never require a call to sqlite3_finalize() if
		 sqlite3_prepare() returns anything other than SQLITE_OK.
		 See the latest CVS check-in.
		 */
		result = sqlite3_finalize(preparedStatement) ;
		if (result != SQLITE_OK) {  
			error = [self makeErrorWithAppCode:453009
									sqliteCode:result
							 sqliteDescription:sqlite3_errmsg(db)
										 query:query
									prettyFunction:__PRETTY_FUNCTION__] ;
#if SSY_SQLITER_LOG_QUERIES
			NSLog(@"  --> query error: %@", error) ;
#endif
		}
	}
	
end:
	if (error_p != nil) {
		*error_p = [error errorByAddingBacktrace] ;
	}

#if SSY_SQLITER_LOG_QUERIES
	NSLog(@"  --> query result: %@", output) ;
#endif
	return output ;
}

- (id)firstRowFromQuery:(NSString*)query
				  error:(NSError**)error_p {
	NSError* error = nil ;
	NSArray* results = [self runQuery:query
							   error:&error] ;
	if (error_p && error) {
		*error_p = error ;
	}
	
	return [results firstObjectSafely] ;
}

- (BOOL)ensureColumn:(NSString*)column
				type:(NSString*)type
			 inTable:(NSString*)table
			didAdd_p:(BOOL*)didAdd_p
			   error:(NSError**)error_p {
	NSError* error = nil ;
	if (didAdd_p) {
		*didAdd_p = NO ;
	}
	
	// Note that if we tell SQLite to ALTER TABLE and ADD COLUMN a column
	// that already exists, it will return an error (SQLite 3.7.5).
	// So, we check first.
	
	NSDictionary* structure = [self structureOfTable:table
											   error:error_p] ;
	if (error) {
		return NO ;
	}
	
	if ([structure objectForKey:column]) {
		return YES ;
	}
	
	// table does not have column; one must be inserted
	NSString* query = [SSYSqliter queryAlterTable:table
										addColumn:column
											 type:type] ;
	char* errMsg = 0 ;
	void* db = [self db] ;
	NSInteger result ;
	result = sqlite3_exec(db, [query UTF8String], NULL, NULL, &errMsg);
	if (result != SQLITE_OK) {  
		error = [self makeErrorWithAppCode:453028
								sqliteCode:result
						 sqliteDescription:errMsg
									 query:query
							prettyFunction:__PRETTY_FUNCTION__] ;
		sqlite3_free(errMsg) ;
	}
	
	if (didAdd_p) {
		*didAdd_p = YES ;
	}

	if (error_p != nil) {
		*error_p = error ;
	}
	
	return (!error) ;
}

- (BOOL)ensureIndex:(NSString*)name
			 unique:(BOOL)unique
			inTable:(NSString*)table
			 column:(NSString*)column
		   didAdd_p:(BOOL*)didAdd_p
			  error:(NSError**)error_p {
	NSError* error = nil ;
	if (didAdd_p) {
		*didAdd_p = NO ;
	}
	
	NSString* query ;
	
	// Note that if we tell SQLite to CREATE INDEX with a name of an index
	// that already exists, it will return an error (SQLite 3.7.5).
	// So, we check first.
	query = [NSString stringWithFormat:
			 @"PRAGMA index_list(%@)",
			 [table stringEsquotedSQLValue]] ;
	// Note that with this PRAGMA, we can't tell sqlite which columns
	// to return.  It returns 3 columns: 'seq', 'name', and 'unique'
	NSArray* results = [self runQuery:query
								error:&error] ;
	if (error) {
		goto end ;
	}
	
	for (NSDictionary* result in results) {
		if ([[result objectForKey:@"name"] isEqualToString:name]) {
			return YES ;
		}
	}
	
	// Database does not have the named index.  Create one.
	query = [NSString stringWithFormat:
			 @"CREATE %@ INDEX %@ ON %@ (%@)",
			 unique ? @"UNIQUE " : @"",
			 [name stringEsquotedSQLValue],
			 [table stringEsquotedSQLValue],
			 [column stringEsquotedSQLValue]] ;
	
	char* errMsg = 0 ;
	void* db = [self db] ;
	NSInteger result ;
	result = sqlite3_exec(db, [query UTF8String], NULL, NULL, &errMsg);
	if (result != SQLITE_OK) {  
		error = [self makeErrorWithAppCode:641507
								sqliteCode:result
						 sqliteDescription:errMsg
									 query:query
							prettyFunction:__PRETTY_FUNCTION__] ;
		sqlite3_free(errMsg) ;
	}
	
	if (didAdd_p) {
		*didAdd_p = YES ;
	}
	
end:
	if (error && error_p) {
		*error_p = error ;
	}
	
	return (!error) ;
}


- (NSArray*)allRowsInTable:(NSString*)table
					 error:(NSError**)error_p {
	
	NSString* query = [[NSString alloc] initWithFormat:@"SELECT * FROM '%@'", table] ;
	
	NSError* error = nil ;
	NSArray* results = [self runQuery:query
								error:&error] ;
	if (error_p && error) {
		*error_p = error ;
	}
	
	[query release] ;
	
	return results ;
}

- (NSMutableDictionary*)mutableDicFromTable:(NSString*)table
								  keyColumn:(NSString*)keyColumn
									  error:(NSError**)error_p {
    // Will return nil if fails, empty array if no rows
	// If 1 column, will return mutable dictionary of object values
	// If >1 column, will return mutable dictionary of mutable dictionaries of object values
	// Keys of dictionary are keyColumn.
	// Therefore, you can "look up" a row by key in the returned dictionary.
	
	NSMutableDictionary* dic = nil ;
	NSArray* rows = [self allRowsInTable:table
								   error:error_p] ;
	if (rows != nil) {
		dic = [[NSMutableDictionary alloc] init] ;
		for (NSDictionary* row in rows) {
			id key = [row objectForKey:keyColumn] ;
			[dic setObject:[NSMutableDictionary dictionaryWithDictionary:row]
					forKey:key] ;
		}
	}
	
	return [dic autorelease] ;
}

- (NSInteger)countChangedRows {
	void* db = [self db] ;
	NSInteger count = sqlite3_changes(db) ;
	return count ;
}

- (NSDictionary*)dicForAttribute:(NSString*)attribute
							 key:(NSString*)key
						   table:(NSString*)table
						   error:(NSError**)error_p {
	NSDictionary* answer = nil ;
	NSMutableDictionary* dic = nil ;
	NSArray* rows = [self allRowsInTable:table
								   error:error_p] ;
	if (rows != nil) {
		dic = [[NSMutableDictionary alloc] init] ;
		for (NSDictionary* row in rows) {
			id aKey = [row objectForKey:key] ;
			id value = [row objectForKey:attribute] ;
			[dic setObject:value
					forKey:aKey] ;
		}
		
		answer = [NSDictionary dictionaryWithDictionary:dic] ;
		[dic release] ;
	}

	return answer ;
}

- (NSArray*)selectColumn:(NSString*)targetColumn
					from:(NSString*)table 
			 whereColumn:(NSString*)predicateColumn
					  is:(id)predicateValue
				   error:(NSError**)error_p {
    // Will return nil if fails, empty array if no rows
	// if >0 rows, will return array of object values
	
	NSString* query = [[NSString alloc] initWithFormat:@"SELECT %@ FROM %@ WHERE %@=%@",
						   targetColumn,
						   table,
						   predicateColumn,
						   [predicateValue stringEsquotedSQLValue]] ;
	
	NSError* error = nil ;
	NSArray* results = [self runQuery:query
								error:&error] ;
	if (error_p && error) {
		*error_p = error ;
	}
	
	[query release] ;
	
	return results ;
}

- (NSArray*)selectColumn:(NSString*)targetColumn
					from:(NSString*)table
				   error:(NSError**)error_p {
    // Will return nil if fails, empty array if no rows
	
	NSString* query = [[NSString alloc] initWithFormat:@"SELECT %@ FROM %@",
					   targetColumn,
					   table] ;
	
	NSError* error = nil ;
	NSArray* results = [self runQuery:query
								error:&error] ;
	if (error_p && error) {
		*error_p = error ;
	}
	
	[query release] ;
	
	return results ;
}

- (BOOL)setBlobData:(NSData*)blobData
             forKey:(NSString*)blobKey
              where:(NSString*)whereKey
                 is:(id)whereValue
            inTable:(NSString*)table
              error:(NSError**)error_p {
	void* db = [self db] ;
	char* errMsg = NULL ;
	NSInteger result ;
	
	// Find if the target item exists or not.  We will need this BOOL later
	// because if it does not exist we do INSERT but if it does we do UPDATE.
	NSString* statement = [[NSString alloc] initWithFormat:
                           @"SELECT * FROM `%@` WHERE `%@` = %@",
                           table,
                           whereKey,
                           [whereValue stringEsquotedSQLValue]] ;
	BOOL itemExists = NO ;
	NSError* error = nil ;
	result = sqlite3_exec(db, [statement UTF8String], CheckExistenceOfSQLiteRow, &itemExists, &errMsg) ;
	if (result != SQLITE_OK) {
		NSString* errNS = [[NSString stringWithCString:errMsg
											  encoding:NSUTF8StringEncoding] lowercaseString] ;
		if ([errNS rangeOfString:@"no such table"].location != NSNotFound) {
			result = SQLITE_NOTFOUND ;
		}
		error = [self makeErrorWithAppCode:453040
								sqliteCode:result
						 sqliteDescription:errMsg
									 query:statement
                            prettyFunction:__PRETTY_FUNCTION__] ;
		sqlite3_free(errMsg) ;
		[statement release] ;
		goto end ;
	}
	else {
		
		// open transaction
		result = sqlite3_exec(db, "begin transaction", NULL, NULL, &errMsg);
		if (result != SQLITE_OK) {
			error = [self makeErrorWithAppCode:453041
									sqliteCode:result
							 sqliteDescription:errMsg
										 query:statement
                                prettyFunction:__PRETTY_FUNCTION__] ;
			sqlite3_free(errMsg) ;
			[statement release] ;
			goto end ;
		}
	}
	[statement release] ;
	
	sqlite3_stmt* preparedStatement ;
	if (result == SQLITE_OK) {
		// write the SQL statement to UPDATE or INSERT
		if (itemExists) {
			// Note that in the WHERE clause, the column name is not enclosed in single quotes, but the value after the equals sign is
			// Otherwise, it "just doesn't work"
			statement = [[NSString alloc] initWithFormat:
                         @"UPDATE %@ SET %@=? WHERE `%@` = %@",
                         table,
                         blobKey,
                         whereKey,
                         [whereValue stringEsquotedSQLValue]] ;
		}
		else {
			statement = [[NSString alloc] initWithFormat:@"INSERT INTO %@ (`%@`,`%@`) VALUES (%@,?)",
						 table,
                         whereKey,
						 blobKey,
						 [whereValue stringEsquotedSQLValue]] ;
		}

		// compile (prepare?) the statement
		result = sqlite3_prepare(db, [statement UTF8String], -1, &preparedStatement, NULL) ;
		if (result != SQLITE_OK) {
			error = [self makeErrorWithAppCode:453042
									sqliteCode:result
							 sqliteDescription:sqlite3_errmsg(db)
										 query:statement
                                prettyFunction:__PRETTY_FUNCTION__] ;
			[statement release] ;
			goto end ;
		}
		[statement release] ;
	}
	
	if (result == SQLITE_OK) {
		// bind attribute object
		result = sqlite3_bind_blob(preparedStatement, 1, [blobData bytes], (int)[blobData length], SQLITE_TRANSIENT) ;
		if (result != SQLITE_OK) {
			error = [self makeErrorWithAppCode:453043
									sqliteCode:result
							 sqliteDescription:sqlite3_errmsg(db)
										 query:@"sqlite3_bind_blob()"
                                prettyFunction:__PRETTY_FUNCTION__] ;
		}
	}
	
	if (result == SQLITE_OK) {
		// execute the preparedStatement
		result = sqlite3_step(preparedStatement);
		if (result != SQLITE_DONE) {
			error = [self makeErrorWithAppCode:453044
									sqliteCode:result
							 sqliteDescription:sqlite3_errmsg(db)
										 query:@"sqlite3_bind_blob()"
                                prettyFunction:__PRETTY_FUNCTION__] ;
			goto end ;
		}
	}
	
	//  If this were in a loop, we would need to do this
	//	// reset for next loop
	//	sqlite3_reset(preparedStatement);
	
	// finalize simply frees memory
	sqlite3_finalize(preparedStatement);
	
	// commit transaction
	result = sqlite3_exec(db, "commit transaction", NULL, NULL, &errMsg);
	if (result != SQLITE_OK) {
		error = [self makeErrorWithAppCode:453045
								sqliteCode:result
						 sqliteDescription:errMsg
									 query:@"commit transaction"
                            prettyFunction:__PRETTY_FUNCTION__] ;
		sqlite3_free(errMsg) ;
		goto end ;
	}
    
end:
	if (error && error_p) {
		*error_p = error ;
	}
    
    return (error == nil) ;
}





// If I added the itemExists switch to the addNewItem... method below, I could invoke that method from
// this one, with an attributeDictionary of one object, and eliminate most of this method
- (BOOL)setObject:(id)object
		   forKey:(NSString*)attributeKey
		  forItem:(NSInteger)identifier
		  inTable:(NSString*)table
			error:(NSError**)error_p {
	void* db = [self db] ;
	char* errMsg = NULL ;
	NSInteger result ;
	
	// Find if the target item exists or not.  We will need this BOOL later
	// because if it does not exist we do INSERT but if it does we do UPDATE.
	NSString* statement ;
	statement = [[NSString alloc] initWithFormat:@"SELECT * FROM %@ WHERE identifier=%li", table, (long)identifier] ;
	BOOL itemExists = NO ;
	NSError* error = nil ;
	result = sqlite3_exec(db, [statement UTF8String], CheckExistenceOfSQLiteRow, &itemExists, &errMsg) ;
	if (result != SQLITE_OK) {  
		NSString* errNS = [[NSString stringWithCString:errMsg
											  encoding:NSUTF8StringEncoding] lowercaseString] ;
		if ([errNS rangeOfString:@"no such table"].location != NSNotFound) {
			result = SQLITE_NOTFOUND ;
		}
		error = [self makeErrorWithAppCode:453010
								sqliteCode:result
						 sqliteDescription:errMsg
									 query:statement
								prettyFunction:__PRETTY_FUNCTION__] ;
		sqlite3_free(errMsg) ;
		[statement release] ;
		goto end ;
	}
	else {
		// Because we need to insert a blob, which requires bind_blob, we cannot use the
		// simple "exec" and instead use a transaction (begin, prepare, bind, step, finalize, exec)
		
		// open transaction
		result = sqlite3_exec(db, "begin transaction", NULL, NULL, &errMsg);
		if (result != SQLITE_OK) {  
			error = [self makeErrorWithAppCode:453011
									sqliteCode:result
							 sqliteDescription:errMsg
										 query:statement
									prettyFunction:__PRETTY_FUNCTION__] ;
			sqlite3_free(errMsg) ;
			[statement release] ;
			goto end ;
		}
	}
	[statement release] ;
	
	sqlite3_stmt* preparedStatement ;
	if (result == SQLITE_OK) {
		// write the SQL statement to UPDATE or INSERT
		if (itemExists) {
			// Note that in the WHERE clause, the column name is not enclosed in single quotes, but the value after the equals sign is
			// Otherwise, it "just doesn't work"
			statement = [[NSString alloc] initWithFormat:@"UPDATE %@ SET %@=? WHERE identifier = %li", table, attributeKey, (long)identifier] ;
		}
		else {
			statement = [[NSString alloc] initWithFormat:@"INSERT INTO %@ ('identifier','%@') VALUES (%li,?)",
						 table,
						 attributeKey,
						 (long)identifier] ;
		}
		
		// compile (prepare?) the statement
		result = sqlite3_prepare(db, [statement UTF8String], -1, &preparedStatement, NULL) ;
		if (result != SQLITE_OK) {  
			error = [self makeErrorWithAppCode:453012
									sqliteCode:result
							 sqliteDescription:sqlite3_errmsg(db)
										 query:statement
									prettyFunction:__PRETTY_FUNCTION__] ;
			[statement release] ;
			goto end ;
		}
		[statement release] ;
	}
	
	if (result == SQLITE_OK) {
		NSError* error = nil ;
		NSData* data = [NSPropertyListSerialization dataWithPropertyList:object
                                                                  format:NSPropertyListBinaryFormat_v1_0
                                                                 options:0
                                                                   error:&error] ;
        if (!data) {
            goto end ;
        }
		
		// bind attribute object
		result = sqlite3_bind_blob(preparedStatement, 1, [data bytes], (int)[data length], SQLITE_TRANSIENT) ;
		if (result != SQLITE_OK) {  
			error = [self makeErrorWithAppCode:453013
									sqliteCode:result
							 sqliteDescription:sqlite3_errmsg(db)
										 query:@"sqlite3_bind_blob()"
									prettyFunction:__PRETTY_FUNCTION__] ;
		}
	}
	
	if (result == SQLITE_OK) {
		// execute the preparedStatement
		result = sqlite3_step(preparedStatement);
		if (result != SQLITE_DONE) {  
			error = [self makeErrorWithAppCode:453014
									sqliteCode:result
							 sqliteDescription:sqlite3_errmsg(db)
										 query:@"sqlite3_bind_blob()"
									prettyFunction:__PRETTY_FUNCTION__] ;
			goto end ;
		}
	}
	
	//  If this were in a loop, we would need to do this
	//	// reset for next loop
	//	sqlite3_reset(preparedStatement);
	
	// finalize simply frees memory
	sqlite3_finalize(preparedStatement);
	
	// close transaction
	result = sqlite3_exec(db, "commit transaction", NULL, NULL, &errMsg);
	if (result != SQLITE_OK) {  
		error = [self makeErrorWithAppCode:453015
								sqliteCode:result
						 sqliteDescription:errMsg
									 query:@"commit transaction"
								prettyFunction:__PRETTY_FUNCTION__] ;
		sqlite3_free(errMsg) ;
		goto end ;
	}

end:
	if (error && error_p) {
		*error_p = error ;
	}
    
    return (error == nil) ;
}

- (id)objectForKey:(NSString*)attributeKey
		   forItem:(NSInteger)identifier
		   inTable:(NSString*)table
			 error:(NSError**)error_p {
	void* db = [self db] ;
	//char* errMsg = NULL ;
	NSInteger result ;
	
	// There next line had a bug which took me 4 hours to find.  If you put single quotes around the
	// placeholder for attributeKey, i.e. SELECT '%@', then the blob you get from sqlite3_column_blob
	// and sqlite3_column_bytes will be the ASCII characters of attributeKey, instead of the blob value.
	NSString* statement = [[NSString alloc] initWithFormat:@"SELECT %@ FROM '%@' WHERE identifier = '%li'", attributeKey, table, (long)identifier] ;
	
	// Compile the statement into a virtual machine
	sqlite3_stmt* preparedStatement ;
	result = sqlite3_prepare(db, [statement UTF8String], -1, &preparedStatement, NULL) ;
	
	id plist = nil ;
	NSError* error = nil ;
	if (result != SQLITE_OK) {  
		error = [self makeErrorWithAppCode:453016
								sqliteCode:result
						 sqliteDescription:sqlite3_errmsg(db)
									 query:statement
								prettyFunction:__PRETTY_FUNCTION__] ;
		goto end ;
	}
	else {
		
		/* Run the virtual machine. We can tell by the SQL statement that
		** at most 1 row will be returned. So call sqlite3_step() once
		** only. Normally, we would keep calling sqlite3_step until it
		** returned something other than SQLITE_ROW.
		*/
		result = sqlite3_step(preparedStatement);
		
		if(result==SQLITE_ROW) {
			/* The pointer returned by sqlite3_column_blob() points to memory
			that is owned by the statement handle (pStmt). It is only good
			until the next call to an sqlite3_XXX() function
			(e.g. the sqlite3_finalize() below) that involves the statement handle. 
			So we need to make a copy of the blob into memory obtained from 
			malloc() to return to the caller.
			*/
			
			// Initialize to null in case blob is not found
			const void* pFirstByte = NULL ;
			NSInteger nBytes = 0;
			
			pFirstByte = sqlite3_column_blob(preparedStatement, 0);
			nBytes = sqlite3_column_bytes(preparedStatement, 0);	
			
			NSData* data = [[NSData alloc] initWithBytes:pFirstByte length:nBytes] ;				
			
			if ([data length] > 0) {
				NSError *plistError ;
				NSPropertyListFormat format ;
				plist = [NSPropertyListSerialization propertyListWithData:data
                                                                  options:NSPropertyListImmutable
                                                                   format:&format
                                                                    error:&plistError] ;
				
				if (!plist) {
					error = SSYMakeError(453026, @"Could not make plist from data") ;
					error = [error errorByAddingUserInfoObject:statement
														forKey:@"query"] ;
					error = [error errorByAddingUnderlyingError:plistError] ;
				}
			}
            
            [data release] ;
		}
	}
	
	// Finalize the statement (this releases resources allocated by ** sqlite3_prepare()
	result = sqlite3_finalize(preparedStatement) ;
	if (result != SQLITE_OK) {  
		error = [self makeErrorWithAppCode:453017
								sqliteCode:result
						 sqliteDescription:sqlite3_errmsg(db)
									 query:statement
								prettyFunction:__PRETTY_FUNCTION__] ;
	}			

end:
 	if (error && error_p) {
		*error_p = error ;
	}
	
	[statement release] ;
	
	return plist ;
}

- (NSArray*)debugReadAllDataInTable:(NSString*)table
							  error:(NSError**)error_p {
	// THIS METHOD ONLY READS PROPERLY IF ALL DATA ARE BLOBS
	void* db = [self db] ;
	//char* errMsg = NULL ;
	NSInteger result ;
	NSMutableArray* rows = [[NSMutableArray alloc] init] ;
	
	// There next line had a bug which took me 4 hours to find.  If you put single quotes around the
	// placeholder for attributeKey, i.e. SELECT '%@', then the blob you get from sqlite3_column_blob
	// and sqlite3_column_bytes will be the ASCII characters of attributeKey, instead of the blob value.
	NSString* statement = [[NSString alloc] initWithFormat:@"SELECT * FROM '%@'", table] ;
	
	// Compile the statement into a virtual machine
	sqlite3_stmt* preparedStatement ;
	NSError* error = nil ;
	result = sqlite3_prepare(db, [statement UTF8String], -1, &preparedStatement, NULL) ;

	NSInteger numberOfColumns = [self numberOfColumnsInTable:table
												 error:&error] ;
	if (error != nil) {
		goto end ;
	}
	
	if (result != SQLITE_OK) {
		error = [self makeErrorWithAppCode:453018
								sqliteCode:result
						 sqliteDescription:sqlite3_errmsg(db)
									 query:statement
								prettyFunction:__PRETTY_FUNCTION__] ;
		goto end ;
	}
	else {
		
		/* Run the virtual machine.  We keep calling sqlite3_step until it
		returns something other than SQLITE_ROW. */
		while ((sqlite3_step(preparedStatement)==SQLITE_ROW)) {
			/* The pointer returned by sqlite3_column_blob() points to memory
			** that is owned by the statement handle (pStmt). It is only good
			** until the next call to an sqlite3_XXX() function (e.g. the 
			** sqlite3_finalize() below) that involves the statement handle. 
			** So we need to make a copy of the blob into memory obtained from 
			** malloc() to return to the caller.
			*/
			
			// Initialize to null in case blob is not found
			const void* pFirstByte = NULL ;
			NSInteger nBytes = 0;

			NSMutableArray* rowColumns = [[NSMutableArray alloc] init] ;
			int iColumn ;
			for (iColumn=0; iColumn<numberOfColumns; iColumn++) {
				pFirstByte = sqlite3_column_blob(preparedStatement, iColumn) ;
				nBytes = sqlite3_column_bytes(preparedStatement, iColumn);	
				
				NSData* data = [[NSData alloc] initWithBytes:pFirstByte length:nBytes] ;				

				if ([data length] > 0) {
					NSPropertyListFormat format ;
                    NSError* plistError = nil ;
					id plist = [NSPropertyListSerialization propertyListWithData:data
                                                                         options:NSPropertyListImmutable
                                                                          format:&format
                                                                           error:&plistError] ;
                    if (error) {
                        error = SSYMakeError(453036, @"Could not make plist from data") ;
                        error = [error errorByAddingUserInfoObject:data
                                                            forKey:@"Data"] ;
                        error = [error errorByAddingUnderlyingError:plistError] ;
                        goto end ;
                    }

                    if(plist) {
						[rowColumns addObject:plist] ;
					}
					else {
						[rowColumns addObject:data] ;
					}		
				}
				else {
					[rowColumns addObject:@"NoData"] ;
				}
                
                [data release] ;
			}
			
			[rows addObject:rowColumns] ;
			[rowColumns release] ;
		}
	}

	// Finalize the statement (this releases resources allocated by ** sqlite3_prepare()
	result = sqlite3_finalize(preparedStatement) ;
	if (result != SQLITE_OK) {  
		error = [self makeErrorWithAppCode:453019
								sqliteCode:result
						 sqliteDescription:sqlite3_errmsg(db)
									 query:statement
								prettyFunction:__PRETTY_FUNCTION__] ;
	}			
end:
	if (error_p != nil) {
		*error_p = error ;
	}

	[statement release] ;

	return [rows autorelease] ;
}

- (BOOL)addNewItemWithIdentifier:(NSInteger)identifier
					  attributes:(NSDictionary*)attributeDictionary
						 inTable:(NSString*)table
						   error:(NSError**)error_p {
	void* db = [self db] ;
	char* errMsg = NULL ;
	NSInteger result ;
	
	NSArray* keysArray = [attributeDictionary allKeys] ;
	NSArray* valuesArray = [attributeDictionary allValues] ;
	NSInteger nAttributes = [keysArray count] ;
	
	// Because we need to insert blobs, which requires bind_blob, we cannot use the
	// simple "exec" and instead use a transaction (begin, prepare, bind, step, finalize, exec)
	
	// open transaction
	NSError* error = nil ;
	result = sqlite3_exec(db, "begin transaction", NULL, NULL, &errMsg);
	if (result != SQLITE_OK) {  
		error = [self makeErrorWithAppCode:453020
								sqliteCode:result
						 sqliteDescription:errMsg
									 query:@"begin transaction"
								prettyFunction:__PRETTY_FUNCTION__] ;
		sqlite3_free(errMsg) ;
		goto end ;
	}

	sqlite3_stmt* preparedStatement ;
	if (result == SQLITE_OK) {
		// write the SQL statement to INSERT
		NSMutableString* keysList = [[NSMutableString alloc] initWithString:@"'identifier'"] ;
		NSMutableString* valuesList = [[NSMutableString alloc] initWithFormat:@"%li", (long)identifier] ;
		NSInteger i ;
		for (i=0; i<nAttributes; i++) {
			NSString* keyClause = [[NSString alloc] initWithFormat:@",'%@'", [keysArray objectAtIndex:i]] ;
			[keysList appendString:keyClause] ;
			[keyClause release] ;
			[valuesList appendString:@",?"] ;
		}
		NSString* statement = [[NSString alloc] initWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)",
							   table,
							   keysList,
							   valuesList] ;
		[keysList release] ;
		[valuesList release] ;
		
		// compile (prepare?) the statement
		result = sqlite3_prepare(db, [statement UTF8String], -1, &preparedStatement, NULL) ;
		if (result != SQLITE_OK) {  
			error = [self makeErrorWithAppCode:453021
									sqliteCode:result
							 sqliteDescription:sqlite3_errmsg(db)
										 query:statement
									prettyFunction:__PRETTY_FUNCTION__] ;
			[statement release] ;
			goto end ;
		}
		[statement release] ;
	}
	
	// If we were inserting more than one record (row) we would execute
	// the following block of code as a loop
	{
		if (result == SQLITE_OK) {
			// Now, another loop to bind each parameter value to its question mark
			int i ;
			for (i=0; i<nAttributes; i++) {
				NSError* plistError = nil ;
				NSData* data = [NSPropertyListSerialization dataWithPropertyList:[valuesArray objectAtIndex:i]
                                                                          format:NSPropertyListBinaryFormat_v1_0
                                                                         options:0
                                                                           error:&plistError] ;
                if (plistError) {
                    error = SSYMakeError(453037, @"Could not make data from value") ;
                    error = [error errorByAddingUnderlyingError:plistError] ;
                    error = [error errorByAddingUserInfoObject:[valuesArray objectAtIndex:i]
                                                        forKey:@"Value"] ;
                    goto end ;
                }
                
				// i+1 in next line is because the question marks in sqlite are indexed starting with 1, not 0
				result = sqlite3_bind_blob(preparedStatement, i+1, [data bytes], (int)[data length], SQLITE_TRANSIENT) ;
				if (result != SQLITE_OK) {  
					error = [self makeErrorWithAppCode:453022
											sqliteCode:result
									 sqliteDescription:sqlite3_errmsg(db)
												 query:nil
											prettyFunction:__PRETTY_FUNCTION__] ;
					goto end ;
				}
			}
		}
		
		if (result == SQLITE_OK) {
			// execute the preparedStatement
			result = sqlite3_step(preparedStatement);
			if (result != SQLITE_DONE) {  
				error = [self makeErrorWithAppCode:453023
										sqliteCode:result
								 sqliteDescription:sqlite3_errmsg(db)
											 query:nil
										prettyFunction:__PRETTY_FUNCTION__] ;
				goto end ;
			}
			else {
				result = SQLITE_OK ;
			}
		}
		
		// Uncomment the following to insert more than one record (row) in a loop
		//if (result == SQLITE_OK) {
		//	// reset for next loop
		//	sqlite3_reset(preparedStatement);
		//}
	}
	
	if (result == SQLITE_OK) {
		// finalize simply frees memory
		// 
		/* 
		 According to D. Richard Hipp on 20080303:
		 I have modified the documentation so that SQLite now guarantees
		 that it will never require a call to sqlite3_finalize() if
		 sqlite3_prepare() returns anything other than SQLITE_OK.
		 See the latest CVS check-in.
		 */
		sqlite3_finalize(preparedStatement);
		
	}	
	// close transaction
	result = sqlite3_exec(db, "commit transaction", NULL, NULL, &errMsg);
	if (result != SQLITE_OK) {  
		error = [self makeErrorWithAppCode:453024
								sqliteCode:result
						 sqliteDescription:errMsg
									 query:nil
								prettyFunction:__PRETTY_FUNCTION__] ;
		sqlite3_free(errMsg) ;
	}
	
end:
	if (error && error_p) {
		*error_p = error ;
	}
    
    return (error == nil) ;
}

- (BOOL)removeItem:(NSInteger)identifier
		   inTable:(NSString*)table
			 error:(NSError**)error_p {
	char* errMsg = 0 ;
	void* db = [self db] ;
	NSInteger result ;
	
	NSString* statement = [[NSString alloc] initWithFormat:
		@"DELETE FROM %@ WHERE identifier='%li'",
		table,
		(long)identifier] ;
	
	result = sqlite3_exec(db, [statement UTF8String], NULL, NULL, &errMsg);
	NSError* error = nil ;
	if (!(result == SQLITE_OK)) {  
		error = [self makeErrorWithAppCode:453025
								sqliteCode:result
						 sqliteDescription:errMsg
									 query:statement
								prettyFunction:__PRETTY_FUNCTION__] ;
		sqlite3_free(errMsg) ;
	}
	
	[statement release] ;

	if (error && error_p) {
		*error_p = error ;
	}
    
    return (error == nil) ;
}

- (void)demonstrateInsertPreparedTable:(NSString*)table {
	// Error checking omitted for "clarity" ;)
	const char* tableC = [table UTF8String] ;
	char statement[255] ;
	sqlite3_stmt* insert;
	sampleRecord sample;
	NSInteger samples = 60000;
	NSInteger i;
	time_t bgn, end;
	double t;
	
	void* db = [self db] ;
	
	// create a table
	sprintf(statement, "create table %s (a integer, b float, c text)", tableC) ;
	sqlite3_exec(db, statement, NULL, NULL, NULL);
	
	// open transaction to speed inserts
	sqlite3_exec(db, "begin transaction", NULL, NULL, NULL);
	
	// compile an SQL insert statement
	sprintf(statement, "insert into %s values (?, ?, ?)", tableC) ;
	sqlite3_prepare(db, statement, -1, &insert, NULL);
	
	// records start time
	bgn = time(NULL);
	
	// loop to insert sample values
	for (i = 0; i < samples; i++) {
		// generate the next sample values
		sample.a = i;
		sample.b = i * 1.1;
		sprintf(sample.c, "sample %ld %f", (long)(sample.a), sample.b );
		
		// bind parameter values
		sqlite3_bind_int(insert, 1, (int)(sample.a));
		sqlite3_bind_double(insert, 2, sample.b);
		sqlite3_bind_text(insert, 3, sample.c, -1, SQLITE_STATIC);
		
		// execute the insert
		sqlite3_step(insert);
		
		// reset for next loop
		sqlite3_reset(insert);
	}
	// record end time
	end = time(NULL);
	
	// finalize compiled statement to free memory
	sqlite3_finalize(insert);
	
	// close transaction
	sqlite3_exec(db, "commit transaction", NULL, NULL, NULL);
	
	// report timing
	t = difftime(end, bgn);
	NSLog(@"Executed %ld inserts prepared in %.0f seconds, %.0f inserts/sec", (long)samples, t, samples / t);
}	

- (void)demonstrateInsertCompiledTable:(NSString*)table {
	// Error checking omitted for "clarity" ;)
	const char* tableC = [table UTF8String] ;
	char statement[255] ;
	char insert[200];
	sampleRecord sample;
	NSInteger samples = 20000;
	NSInteger i;
	time_t bgn, end;
	double t;
	
	void* db = [self db] ;
	
	// create a table
	sprintf(statement, "create table %s (a integer, b float, c text)", tableC) ;
	sqlite3_exec(db, statement, NULL, NULL, NULL);
	
	// open transaction to speed inserts
	sqlite3_exec(db, "begin transaction", NULL, NULL, NULL);
	
	// records start time
	bgn = time(NULL);
	
	// loop to insert sample values
	for (i = 0; i < samples; i++) {
		// generate the next sample values
		sample.a = i;
		sample.b = i * 1.1;
		sprintf(sample.c, "sample %ld %f", (long)(sample.a), sample.b );
		
		// build next insert statement
		sprintf(statement, "insert into %s values (%%d, %%#f, '%%s')", tableC) ;  // %% is to escape the percents; they are for the next statement.
		sprintf(insert, statement, sample.a, sample.b, sample.c); // execute the insert

		sqlite3_exec(db, insert, NULL, NULL, NULL);
	}
	// record end time
	end = time(NULL);
	
	// close transaction
	sqlite3_exec(db, "commit transaction", NULL, NULL, NULL);
	
	// report timing
	t = difftime(end, bgn);
	NSLog(@"Executed %ld inserts compiled in %.0f seconds, %.0f inserts/sec", (long)samples, t, samples / t);
}	

- (BOOL)logAllTablesError:(NSError**)error_p {
	NSError* error = nil ;
    NSArray* tables = [self allTablesError:&error] ;
	NSEnumerator* e = [tables objectEnumerator] ;
	NSString* table ;
	while ((table = [e nextObject])) {
		NSLog(@"*** Table \"%@\" ***", table) ;
		NSLog(@"primary key is: %@", [self primaryKeyOfTable:table
													   error:error_p]) ;
		NSLog(@"column definitions:\n%@", [self structureOfTable:table
														   error:error_p]) ;
		NSLog(@"row data:\n%@", [self allRowsInTable:table
											   error:error_p]) ;
	}
    
	if (error && error_p) {
		*error_p = error ;
	}
    
    return (error == nil) ;    
}

- (NSString*)versionString {
	return [NSString stringWithFormat:@"Using SQLite version %s", sqlite3_version] ;
	// sqlite3_version is a global variable in the sqlite3 library
}

- (id)initWithPath:(NSString*)path
		   error_p:(NSError**)error_p {
	if (!path) {
		return nil ;
	}
	
	self = [super init] ;
	
	if(self) {		
		[self setPath:path] ;
		
		BOOL ok = [self initDatabaseError_p:error_p] ;
		if (!ok) {
			[super dealloc] ;
			self = nil ;
		}
	}

	return self ;
}

+ (NSInteger)sqlErrorCodeFromErrorCode:(NSInteger)errorCode {
	NSInteger answer = 0 ;
	if (errorCode > 1000) {
		answer = errorCode % 1000 ;
	}
	
	return answer ;
}


- (void)dealloc {
	NSError* error = nil ;
	BOOL ok = [self checkpointAndCloseError_p:&error] ;
	if (!ok) {
		NSLog(@"Internal Error 624-0404 %@ closing %@", [error longDescription], m_path) ;
	}

	[m_path release] ;
	
    [super dealloc] ;
}

@end
