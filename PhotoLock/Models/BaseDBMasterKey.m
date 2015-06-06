//
//  BaseDBMasterKey.m
//  PhotoLock
//
//  Created by 泉华 官 on 14/12/23.
//  Copyright (c) 2014年 CQMH. All rights reserved.
//

#import "BaseDBMasterKey.h"
#import "FMDatabase.h"
#import "Base.h"

static NSString *const kDBName = @"cqmh.sqlite";

@interface BaseDBMasterKey()
{
    FMDatabase     *fmdb;      // 数据库
    NSString       *dbName;    // 数据库名
    NSMutableArray *tableNames; // 表名数组
}

@end

@implementation BaseDBMasterKey

#pragma mark - 初始化和清理

- (id)init
{
    if (self = [super init]) {
        dbName = kDBName;
        tableNames = [NSMutableArray array];
        // 初始化数据库
        [self initDB];
    }
    return self;
}

- (void)dealloc
{
    if (fmdb) {
        [fmdb close];//关闭数据库
    }
}

#pragma mark - 若某个表未创建,则创建它

- (NSString *)checkBeforeQueryOrUpdateTable:(Class)tableClass {
    NSString *tableName = [tableClass tableName];
    if (![tableNames containsObject:tableName]) {
        if ([self createTable:tableName fields:[tableClass fieldsStringForTableCreation]]) {
            [tableNames addObject:tableName];
            NSLog(@"%@-%@: Table \"%@\" Created^_^", NSStringFromClass([self class]), NSStringFromSelector(_cmd), tableName);
        } else {
            NSLog(@"%@-%@: Failed to Create Table \"%@\"-_-", NSStringFromClass([self class]), NSStringFromSelector(_cmd), tableName);
        }
    }
    return tableName;
}

#pragma mark - 建数据库创建和表创建
// 获取document目录, 返回数据库目录
- (NSString *)DBFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:dbName];
}

// 初始化数据库,打开数据库(直到对象销毁的时候才关闭)
- (void)initDB
{
    // 创建数据库对象
    NSString *dbFilePath = [self DBFilePath];
    fmdb = [FMDatabase databaseWithPath:dbFilePath];
    // 打开数据库
    if ([fmdb open]) {
        [fmdb setShouldCacheStatements:YES];// 设置缓存指令
    } else {
        NSLog(@"ERROR:CAN NOT OPEN DATABASE!!!!");
    }
}

/**
 创建表
 @param tableName 表名, 字符串
 @param fieldsString 表的字段属性类型(键), 字段名(值).
 @reture YES,数据表创建成功. NO,数据表创建失败.
 */
- (BOOL)createTable:(NSString *)tableName fields:(NSString *)fieldsString
{
    if (fmdb && fieldsString.length > 0) {
        NSMutableString *sql = [NSMutableString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@( ", tableName];// 多加一个空格
        [sql appendString:fieldsString];
        [sql appendString:@")"];
        
        if ([fmdb executeUpdate:sql]) {
            return YES;
        }
    }
    return NO;
}

//获取所有,默认按照主键中的第一个字段降序
- (NSMutableArray *)getAll:(Class)tableClass
{
    NSString *tableName = [self checkBeforeQueryOrUpdateTable:tableClass];
    NSMutableArray *resultArray = [NSMutableArray array];
    //获取查询结果
    FMResultSet *rs = [fmdb executeQuery:[NSString stringWithFormat:@"SELECT * FROM %@ ORDER BY %@ DESC", tableName, ((NSArray *)[tableClass primaryKeys]).firstObject]];
    while ([rs next]) {
        Base *base = [[[tableClass class] alloc] init];
        [base setValues:rs.resultDictionary];
        [resultArray addObject:base];
    }
    [rs close];//关闭结果集
    
    return ([resultArray count] == 0) ? nil : resultArray;
}

- (NSMutableArray *)findInTable:(Class)tableClass whereField:(NSString *)field equalToValue:(id)value {
    NSString *tableName = [self checkBeforeQueryOrUpdateTable:tableClass];
    NSMutableArray *resultArray = [NSMutableArray array];
    //获取查询结果
    FMResultSet *rs = [fmdb executeQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@=? ORDER BY %@ DESC", tableName, field, field], value];
    while ([rs next]) {
        Base *base = [[tableClass alloc] init];
        [base setValues:rs.resultDictionary];
        [resultArray addObject:base];
    }
    [rs close];//关闭结果集
    
    return ([resultArray count] == 0) ? nil : resultArray;
}

- (NSMutableArray *)findInTable:(Class)tableClass whereFields:(NSArray *)fields equalToValues:(NSArray *)values {
    NSString *tableName = [self checkBeforeQueryOrUpdateTable:tableClass];
    NSMutableArray *resultArray = [NSMutableArray array];
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE ", tableName];
    NSMutableDictionary *sqlParameterDic = [NSMutableDictionary dictionary];
    for (int i = 0; i < fields.count; i++) {
        sql = [sql stringByAppendingString:[NSString stringWithFormat:@" %@=:%@,", fields[i], fields[i]]];
        sqlParameterDic[fields[i]] = values[i];
    }
    //获取查询结果
    FMResultSet *rs = [fmdb executeQuery:sql withParameterDictionary:sqlParameterDic];
    while ([rs next]) {
        Base *base = [[tableClass alloc] init];
        [base setValues:rs.resultDictionary];
        [resultArray addObject:base];
    }
    [rs close];//关闭结果集
    
    return ([resultArray count] == 0) ? nil : resultArray;
}

//添加
- (BOOL)add:(Base *)base
{
    NSString *tableName = [self checkBeforeQueryOrUpdateTable:base.class];
    NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ VALUES (%@)", tableName, [base.class parameterArgsKeysListString]];
    return [fmdb executeUpdate:sql withParameterDictionary:base.parameterArgs];
}

- (BOOL)addObjects:(NSArray *)objects {
    [fmdb beginTransaction];
    BOOL isRollBack = NO;
    BOOL result = YES;
    @try {
        for (Base *base in objects) {
            if (![self add:base]) {
                result = NO;
            }
        }
    } @catch (NSException *exception) {
        isRollBack = YES;
        [fmdb rollback];
    } @finally {
        if (!isRollBack) {
            [fmdb commit];
        }
    }
    return result;
}

//删除
- (BOOL)delete:(Base *)base
{
    NSString *tableName = [self checkBeforeQueryOrUpdateTable:base.class];
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@", tableName, [base.class primaryFieldBeSetString]];
    return [fmdb executeUpdate:sql withParameterDictionary:base.parameterArgsForOnlyPrimaryKey];
}

//删除
- (BOOL)deleteObjects:(NSArray *)objects {
    [fmdb beginTransaction];
    BOOL isRollBack = NO;
    BOOL result = YES;
    @try {
        for (Base *base in objects) {
            if (![self delete:base]) {
                result = NO;
            }
        }
    } @catch (NSException *exception) {
        isRollBack = YES;
        [fmdb rollback];
    } @finally {
        if (!isRollBack) {
            [fmdb commit];
        }
    }
    return result;
}

//修改
- (BOOL)update:(Base *)base
{
    NSString *tableName = [self checkBeforeQueryOrUpdateTable:base.class];
    NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@", tableName, [base.class allFieldsBeSetString], [base.class primaryFieldBeSetString]];
    return [fmdb executeUpdate:sql withParameterDictionary:base.parameterArgs];
}

//删除所有
- (BOOL)clearAll:(Class)tableClass
{
    return [fmdb executeUpdate:[NSString stringWithFormat:@"DELETE FROM %@", [tableClass tableName]]];
}

@end
