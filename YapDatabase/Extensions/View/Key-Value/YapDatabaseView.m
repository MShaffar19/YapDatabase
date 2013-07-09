#import "YapDatabaseView.h"
#import "YapDatabaseViewPrivate.h"
#import "YapAbstractDatabaseExtensionPrivate.h"

#import "YapDatabase.h"
#import "YapDatabaseLogging.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

/**
 * Define log level for this file: OFF, ERROR, WARN, INFO, VERBOSE
 * See YapDatabaseLogging.h for more information.
**/
#if DEBUG
  static const int ydbLogLevel = YDB_LOG_LEVEL_WARN;
#else
  static const int ydbLogLevel = YDB_LOG_LEVEL_WARN;
#endif


@implementation YapDatabaseView

+ (BOOL)createTablesForRegisteredName:(NSString *)registeredName
                             database:(YapAbstractDatabase *)database
                               sqlite:(sqlite3 *)db
{
	if (![database isKindOfClass:[YapDatabase class]])
	{
		YDBLogError(@"YapDatabaseView only supports YapDatabase, not YapCollectionsDatabase");
		return NO;
	}
	
	NSString *keyTableName = [self keyTableNameForRegisteredName:registeredName];
	NSString *pageTableName = [self pageTableNameForRegisteredName:registeredName];
	
	YDBLogVerbose(@"Creating view tables for registeredName(%@): %@, %@", registeredName, keyTableName, pageTableName);
	
	NSString *createKeyTable = [NSString stringWithFormat:
	    @"CREATE TABLE IF NOT EXISTS \"%@\""
	    @" (\"key\" CHAR NOT NULL PRIMARY KEY,"
	    @"  \"pageKey\" CHAR NOT NULL"
	    @" );", keyTableName];
	
	NSString *createPageTable = [NSString stringWithFormat:
	    @"CREATE TABLE IF NOT EXISTS \"%@\""
	    @" (\"pageKey\" CHAR NOT NULL PRIMARY KEY,"
	    @"  \"data\" BLOB,"
		@"  \"metadata\" BLOB"
	    @" );", pageTableName];
	
	int status;
	
	status = sqlite3_exec(db, [createKeyTable UTF8String], NULL, NULL, NULL);
	if (status != SQLITE_OK)
	{
		YDBLogError(@"%@ - Failed creating key table (%@): %d %s",
		            THIS_METHOD, keyTableName, status, sqlite3_errmsg(db));
		return NO;
	}
	
	status = sqlite3_exec(db, [createPageTable UTF8String], NULL, NULL, NULL);
	if (status != SQLITE_OK)
	{
		YDBLogError(@"%@ - Failed creating page table (%@): %d %s",
		            THIS_METHOD, pageTableName, status, sqlite3_errmsg(db));
		return NO;
	}
	
	return YES;
}

+ (BOOL)dropTablesForRegisteredName:(NSString *)registeredName
                           database:(YapAbstractDatabase *)database
                             sqlite:(sqlite3 *)db
{
	if (![database isKindOfClass:[YapDatabase class]])
	{
		YDBLogError(@"YapDatabaseView only supports YapDatabase, not YapCollectionsDatabase");
		return NO;
	}
	
	NSString *keyTableName = [self keyTableNameForRegisteredName:registeredName];
	NSString *pageTableName = [self pageTableNameForRegisteredName:registeredName];
	
	NSString *dropKeyTable = [NSString stringWithFormat:@"DROP TABLE IF EXISTS \"%@\";", keyTableName];
	NSString *dropPageTable = [NSString stringWithFormat:@"DROP TABLE IF EXISTS \"%@\";", pageTableName];
	
	int status;
	
	status = sqlite3_exec(db, [dropKeyTable UTF8String], NULL, NULL, NULL);
	if (status != SQLITE_OK)
	{
		YDBLogError(@"%@ - Failed dropping key table (%@): %d %s",
		            THIS_METHOD, keyTableName, status, sqlite3_errmsg(db));
		return NO;
	}
	
	status = sqlite3_exec(db, [dropPageTable UTF8String], NULL, NULL, NULL);
	if (status != SQLITE_OK)
	{
		YDBLogError(@"%@ - Failed dropping page table (%@): %d %s",
		            THIS_METHOD, pageTableName, status, sqlite3_errmsg(db));
		return NO;
	}
	
	return YES;
}

+ (NSString *)keyTableNameForRegisteredName:(NSString *)registeredName
{
	return [NSString stringWithFormat:@"kv_view_%@_key", registeredName];
}

+ (NSString *)pageTableNameForRegisteredName:(NSString *)registeredName
{
	return [NSString stringWithFormat:@"kv_view_%@_page", registeredName];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Instance
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@synthesize groupingBlock;
@synthesize sortingBlock;

@synthesize groupingBlockType;
@synthesize sortingBlockType;

- (id)initWithGroupingBlock:(YapDatabaseViewGroupingBlock)inGroupingBlock
          groupingBlockType:(YapDatabaseViewBlockType)inGroupingBlockType
               sortingBlock:(YapDatabaseViewSortingBlock)inSortingBlock
           sortingBlockType:(YapDatabaseViewBlockType)inSortingBlockType
{
	if ((self = [super init]))
	{
		NSAssert(inGroupingBlockType == YapDatabaseViewBlockTypeWithKey ||
		         inGroupingBlockType == YapDatabaseViewBlockTypeWithObject ||
		         inGroupingBlockType == YapDatabaseViewBlockTypeWithMetadata ||
		         inGroupingBlockType == YapDatabaseViewBlockTypeWithObjectAndMetadata,
		         @"Invalid grouping block type");
		
		NSAssert(inSortingBlockType == YapDatabaseViewBlockTypeWithKey ||
		         inSortingBlockType == YapDatabaseViewBlockTypeWithObject ||
		         inSortingBlockType == YapDatabaseViewBlockTypeWithMetadata ||
		         inSortingBlockType == YapDatabaseViewBlockTypeWithObjectAndMetadata,
		         @"Invalid sorting block type");
		
		groupingBlock = inGroupingBlock;
		groupingBlockType = inGroupingBlockType;
		
		sortingBlock = inSortingBlock;
		sortingBlockType = inSortingBlockType;
	}
	return self;
}

- (YapAbstractDatabaseExtensionConnection *)newConnection:(YapAbstractDatabaseConnection *)databaseConnection
{
	return [[YapDatabaseViewConnection alloc] initWithView:self
	                                    databaseConnection:(YapDatabaseConnection *)databaseConnection];
}

- (NSString *)keyTableName
{
	return [[self class] keyTableNameForRegisteredName:self.registeredName];
}

- (NSString *)pageTableName
{
	return [[self class] pageTableNameForRegisteredName:self.registeredName];
}

@end