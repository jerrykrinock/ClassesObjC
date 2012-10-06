#import <Cocoa/Cocoa.h>


/*!
 @brief    To log all queries, their results, and any error which occurs,
 set this #if to 1
*/
#if 0
#define SSY_SQLITER_LOG_QUERIES 1
#endif

extern NSString* const SSYSqliterErrorDomain ;
extern NSString* const SSYSqliterSqliteErrorCode ;

// These are the resultCode definitions from sqlite3 source code:
#define	SQLITE_OK           0   // Successful result 
#define	SQLITE_ERROR        1   // SQL error or missing database 
#define	SQLITE_INTERNAL     2   // NOT USED. Internal logic error in SQLite 
#define	SQLITE_PERM         3   // Access permission denied 
#define	SQLITE_ABORT        4   // Callback routine requested an abort 
#define	SQLITE_BUSY         5   // The database file is locked 
#define	SQLITE_LOCKED       6   // A table in the database is locked 
#define	SQLITE_NOMEM        7   // A malloc() failed 
#define	SQLITE_READONLY     8   // Attempt to write a readonly database 
#define	SQLITE_INTERRUPT    9   // Operation terminated by sqlite3_interrupt()
#define	SQLITE_IOERR       10   // Some kind of disk I/O error occurred 
#define	SQLITE_CORRUPT     11   // The database disk image is malformed 
#define	SQLITE_NOTFOUND    12   // NOT USED. Table or record not found 
#define	SQLITE_FULL        13   // Insertion failed because database is full 
#define	SQLITE_CANTOPEN    14   // Unable to open the database file 
#define	SQLITE_PROTOCOL    15   // Database lock protocol error 
#define	SQLITE_EMPTY       16   // Database is empty 
#define	SQLITE_SCHEMA      17   // The database schema changed 
#define	SQLITE_TOOBIG      18   // Too much data for one row 
#define	SQLITE_CONSTRAINT  19   // Abort due to constraint violation 
#define	SQLITE_MISMATCH    20   // Data type mismatch 
#define	SQLITE_MISUSE      21   // Library used incorrectly 
#define	SQLITE_NOLFS       22   // Uses OS features not supported on host 
#define	SQLITE_AUTH        23   // Authorization denied 
#define	SQLITE_FORMAT      24   // Auxiliary database format error 
#define	SQLITE_RANGE       25   // 2nd parameter to sqlite3_bind out of range 
#define	SQLITE_NOTADB      26   // File opened that is not a database file 
#define	SQLITE_ROW         100  // sqlite3_step() has another row ready 
#define	SQLITE_DONE        101  // sqlite3_step() has finished executing 

@interface NSObject (HelpSQL) 

- (NSString*)stringEsquotedSQLValue ;
// Valid if receiver is an NSString*, NSNumber*, NSArray* or NSSet* or NSNull*.
//         - NSStrings 
//              will have single quotes escaped (by doubling them),
//              ane then will be 'single quoted'.
//         - NSNumbers
//              will be replaced with literal formatted number strings
//              which are readable by sqlite.
//		   - NSArray or NSSet
//              each object in the collection will be processed by
//              this method, i.e. esquoted.  The results will be
//              concatenated into a comma-separated list and surrounded
//              by parentheses.  The result is therefore useable in an
//              SQL 'IN' expression.  For example, if self is a collection 
//              containing the two strings "Tom" and "Dick", this method
//              will return the string "('Tom','Dick')" which is useable
//              in the SQL expression: "WHERE name IN ('Tom','Dick')".
//         - NSNulls
//              will be replaced with the sqlite keyword NULL.


@end

@interface NSMutableString (HelpSQL)

+ (NSMutableString*)queryStringWhereColumn:(NSString*)column
							 isAnyOfValues:(NSArray*)values ;
// if column is nil, values is nil, or values is empty, 
// this method will return nil

@end

@interface NSSet (HelpSQL)

- (NSArray*)stringsEsquotedSQLValue ;
// Returns an array with each object processed by -[NSObject stringEsquotedSQLValue]

@end

@interface NSArray (HelpSQL)

// All objects in receiver must be NSString* or exception will probably be raised.
- (NSArray*)stringsEsquotedSQLValue ;
// Returns an array with each object processed by -[NSObject stringEsquotedSQLValue]

@end


@interface SSYSqliter : NSObject
{
    // non-object instance variables
	void* m_db ;
	
	// object instance variables
    NSString* m_path ;
}

// Utility Methods for creating query strings
// These methods will process inputs per sqlite requirements:
//     - Column names:
//         - will be used as is.
//     - Values:
//         - will be processed by -[NSObject stringEsquotedForSQL]

/*!
 @brief    Returns a query string which, when executed, will delete
 all rows from a given table where a given column has a given value.

 @param    value  An NSString, NSNumber or NSNull object
*/
+ (NSMutableString*)queryDeleteFromTable:(NSString*)table
							 whereColumn:(NSString*)column
									  is:(id)value ;

/*!
 @brief    Returns a query string which, when executed, will delete
 all rows from a given table where a given column has a given value.
 
 @param    value  A set or array of NSString, NSNumber or NSNull objects
 */
+ (NSMutableString*)queryDeleteFromTable:(NSString*)table
							 whereColumn:(NSString*)column
									isIn:(id)targets ;

// Returns a query which will insert one row.
// values may be NSArray*, NSSet* or nil.
// Count of columns must equal count of values.
// if values is nil or empty, will return nil
+ (NSString*)queryInsertIntoTable:(NSString*)table
						  columns:(NSArray*)columns
						   values:(NSArray*)values ;

+ (NSString*)queryUpdateTable:(NSString*)table
					  updates:(NSDictionary*)updates
				  whereColumn:(NSString*)whereColumn
				   whereValue:(id)whereValue ;
	
// Manipulating Tables
- (BOOL)createTableOfBlobsNamed:(NSString*)table
					   withKeys:(NSArray*)keyNames
						  error:(NSError**)error_p ;
- (NSArray*)allTablesError:(NSError**)error_p ;
/*!
 @brief    Returns a dictionary of dictionaries describing
 the columns of a given table.

 @details  The keys of the outer dictionary are the column
 names.  The entries in the inner dictionary are:
 *  KEY           DESCRIPTION         EXAMPLE
 *  'cid'         columnIdentifier    "0", "1", "2", ...
 *  'type',       data type           "INTEGER", "TEXT", "LONGVARCHAR", "VARCHAR(32)", "BLOB", "LONG", "" (empty string)
 *  'notnull',    allow NULL value?   "0" or "99"
 *  'dflt_value', default value       "0", "1", "some string", "NULL"
 *  'pk'          is primary key      "0" or "1"
 It seems that the values of the above are all NSString objects.
 @param    table  The name of the table whose structure is desired
 @param    error_p  If an error occurs, and this parameter is not
 NULL, upon return it will point to an NSError describing the error.
*/
- (NSDictionary*)structureOfTable:(NSString*)table
					   error:(NSError**)error_p ;

- (NSInteger)numberOfColumnsInTable:(NSString*)table
						error:(NSError**)error_p ;
- (NSInteger)numberOfRowsInTable:(NSString*)table
					 error:(NSError**)error_p ;

// Getting primary keys

// In deciding the primary key for a table
// returns name of first column with attribute "pk" == "1".
// If no column has "pk" == "1", returns nil
- (NSString*)primaryKeyOfTable:(NSString*)table
						 error:(NSError**)error_p ;

- (NSArray*)allPrimaryKeysInTable:(NSString*)table
							error:(NSError**)error_p ;
	// Invokes -primaryKeyOfTable to decide which key is primary key

// Column must be integer type.
// Searches column for highest value and returns highest value plus 1.
// If table has no rows, returns 0
- (long long)nextLongLongInColumn:(NSString*)column
						  inTable:(NSString*)table
					 initialValue:(long long)initialLongLong
							error:(NSError**)error_p ;


// Will return nil if fails, empty array if no rows
// If 1 column, will return array of object values
// If >1 column, will return array of dictionaries of object values
/*!
 @brief    Returns all rows in a given table, as an array of
 dictionaries

 @param    table  
 @param    error_p  
 @result   If an error occurs, nil.
 
 Otherwise, if the subject table has no rows, an empty array. 
 
 Otherwise, if the subject table has exactly 1 column, an
 array of object values, one or each row.
 
 Otherwise, if the subject table has >1 column, an array of
 dictionaries, one for each row in the subject table.  All of
 these dictionaries contain a key for each column in the table.
 Values which are NULL in SQLite are represented in the dictionary
 by NSNull objects.
 */
- (NSArray*)allRowsInTable:(NSString*)table
					 error:(NSError**)error_p ;

// If 1 column, will return mutable dictionary of object values
// If >1 column, will return mutable dictionary of mutable dictionaries of object values
// Keys of dictionary are keyColumn.
// Therefore, you can "look up" a row by key in the returned dictionary.
- (NSMutableDictionary*)mutableDicFromTable:(NSString*)table
								  keyColumn:(NSString*)keyColumn
									  error:(NSError**)error_p ;

/*!
 @brief    Returns a dictionary created by extracting two values
 (a key and a value) from all of the rows of a given table in the
 receiver's database

 @details  This method was added in BookMacster 1.11.
 @param    attribute  The name of the table column whose values will
 become the values of the returned dictionary
 @param    key  The name of the table column whose values will
 become the keys of the returned dictionary
 @param    table  The SQLite table whose rows will be extracted to
 form the returned dictionary
 @param    error_p  If not NULL and if an error occurs, upon return,
           will point to an error object encapsulating the error.
 @result   
*/
- (NSDictionary*)dicForAttribute:(NSString*)attribute
							 key:(NSString*)key
						   table:(NSString*)table
						   error:(NSError**)error_p ;

- (NSArray*)selectColumn:(NSString*)targetColumn
					from:(NSString*)table
				   error:(NSError**)error_p ;

- (NSArray*)selectColumn:(NSString*)targetColumn
					from:(NSString*)table
			 whereColumn:(NSString*)predicateColumn
					  is:(id)predicateValue
				   error:(NSError**)error_p ;

/*!
 @brief    Returns the number of database rows that were changed or inserted
 or deleted by the most recently completed SQL statement

 @details  Only changes that are directly specified by the INSERT, UPDATE,
 or DELETE statement are counted. Auxiliary changes caused by triggers or
 foreign key actions are not counted.
*/
- (NSInteger)countChangedRows ;

/*!
 @brief    If the receiver's database is still open, executes a
 sqlite3_wal_checkpoint() upon it.  Otherwise, this method is a no-op.
 
 @details  The reason for closing the database after checkpointing
 is that closing is necessary for the -shm and -wal files to 
 disappear, which probably doesn't matter technically, but is
 a good indicator for troubleshooting.
 */
- (BOOL)checkpointAndCloseError_p:(NSError**)error_p ;

/*!
 @brief    Runs a query in the receiver

 @param    error_p  If an error occurs, if this parameter is not
 nil it will point to an error describing the problem.  This error
 includes a stack backtrace.
 @result    If 1 column in result, will return array of object values
 If >1 column in result, will return array of dictionaries of object values
 If query is nil, will return nil.
 
*/
- (NSArray*)runQuery:(NSString*)query 
			   error:(NSError**)error_p ;

- (id)firstRowFromQuery:(NSString*)query
				  error:(NSError**)error_p ;

/*!
 @brief    Ensures that a given column exists in a table, by adding it
 if it does not exist.

 @details  This uses the ALTER TABLE syntax of SQLite, which has
 some limitations.  See http://www.sqlite.org/lang_altertable.html
 
 If the column already exists, does nothing and returns YES.

 @param    column  The name of the column to be added
 @param    type  The type of the column to be added, e.g. TEXT
 @param    table  The name of the table to add the column to
 @param    didAdd_p  If this parameter is not NULL, upon return
 will point to a BOOL indicating whether or not this method
 added the desired column.  NO means that either the column
 already existed, or an error occurred.
 @param    error_p  If an error occurs, and this parameter is not
 NULL, upon return it will point to an NSError describing the error.
 @result   YES if the operation succeeded with no error; NO if
 an error occurred.
*/
- (BOOL)ensureColumn:(NSString*)column
				type:(NSString*)type
			 inTable:(NSString*)table
			didAdd_p:(BOOL*)didAdd_p
			   error:(NSError**)error_p ;

/*!
 @brief    Ensures that a given index exists in a table, by adding it
 if it does not exist.

 @details  If an index with the given name already exists on 
 the given table, does nothing and returns YES, even if the
 'unique', and/or 'column' attributes of the existing index do
 not match the given parameters.
 @param    name  The name of the subject index.  Must not be nil.
 @param    unique  If YES, and if a new index is created, the new
 index will have the UNIQUE property.  If NO, and if a new index is
 created, the new index will not have the UNIQUE property.
 @param    table  The table to be queried for an existing index,
 and the table which will be indexed by the new index, if one
 is created.  Must not be nil.
 @param    column The column to be indexed by the new index, if one
 is created.  Must not be nil. 
 @param    didAdd_p  If this parameter is not NULL, upon return
 will point to a BOOL indicating whether or not this method
 created the desired index.  NO means that either an index with
 the subject name already existed, or an error occurred.
 @param    error_p  If an error occurs, and this parameter is not
 NULL, upon return it will point to an NSError describing the error.
 @result   YES if the operation succeeded with no error; NO if
 an error occurred.
*/
- (BOOL)ensureIndex:(NSString*)name
			 unique:(BOOL)unique
			inTable:(NSString*)table
			 column:(NSString*)column
		   didAdd_p:(BOOL*)didAdd_p
			  error:(NSError**)error_p ;


// BLOBBING (OLD CODE FROM RESTORATION.  THESE METHODS ARE DEPRACATED!)

#if 0
// I don't know how others do it, but I decided to write all attributes as a NSData blobs using NSPropertyListSerialization,
// except an "identifier" which is an integer, the PRIMARY KEY.  Therefore this class can write any serializable Cocoa object
// (NSString, NSArray, NSDictionary, NSNumber, NSData) using only one attribute setter and one getter.

// Reading and writing attributes of items in a table
- (void)setObject:(id)object
		   forKey:(NSString*)attributeKey
		  forItem:(NSInteger)identifier
		  inTable:(NSString*)table
			error:(NSError**)error_p ;
	// The table named by table must exist, or this will show an error alert and fail.
	// The item need not exist.  item will be inserted if necessary.
	// It is OK to pass nil as object; this will overwrite NULL into the sqlite database file.
- (id)objectForKey:(NSString*)attributeKey
		   forItem:(NSInteger)identifier
		   inTable:(NSString*)table
			 error:(NSError**)error_p ;

// THIS METHOD ONLY READS PROPERLY IF ALL DATA ARE BLOBS
- (NSArray*)debugReadAllDataInTable:(NSString*)table
							  error:(NSError**)error_p ;

// Add/Removing entire items
- (void)addNewItemWithIdentifier:(NSInteger)identifier
					  attributes:(NSDictionary*)attributeDictionary
						 inTable:(NSString*)table
						   error:(NSError**)error_p ;
- (void)removeItem:(NSInteger)identifier
		   inTable:(NSString*)table
			 error:(NSError**)error_p ;

// Debugging and Benchmarking
- (void)logAllTablesError:(NSError**)error_p ;
- (void)demonstrateInsertPreparedTable:(NSString*)table ;
- (void)demonstrateInsertCompiledTable:(NSString*)table ;

#endif


// To support low-level operations
// This is recommended for debugging only
- (void*)db ; // returns pointer to SQLite database

- (NSString*)versionString ; // returns version of sqlite3 library

/*!
 @brief    Initializes an SSYSQLiter instance with a given
 file path.

 @details  Will return nil if given path is nil
*/
- (id)initWithPath:(NSString*)path
		   error_p:(NSError**)error_p ;

+ (NSInteger)sqlErrorCodeFromErrorCode:(NSInteger)errorCode ;


@end

