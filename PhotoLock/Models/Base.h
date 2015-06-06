//
//  Base.h
//  PhotoLock
//
//  Created by 泉华 官 on 14/12/23.
//  Copyright (c) 2014年 CQMH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Base : NSObject

// 支持默认主键, 为类的第一个属性.
// 若子类对应的数据表有多个字段组成主键, 则子类需要自己实现该类.
+ (NSArray *)primaryKeys;

// 支持默认外键, 为类的最后一个属性.
// 若子类对应的数据表有多个字段组成外键, 则子类需要自己实现该类.
// 若子类没有外键,则谨慎调用次函数,否则会造成不可预测的错误
+ (NSArray *)foreignKeys;

+ (NSString *)fieldsStringForTableCreation;
+ (NSString *)primaryFieldBeSetString;
+ (NSString *)allFieldsBeSetString;
- (NSDictionary *)parameterArgs;
- (NSDictionary *)parameterArgsForOnlyPrimaryKey;
+ (NSString *)parameterArgsKeysListString;
+ (NSString *)tableName;
- (void)setValues:(NSDictionary *)values;

+ (NSArray *)properties;// 子类可自己实现, 顺序注意与-propertiesSQLType的返回值的顺序对应
+ (NSArray *)propertiesSQLType;// 子类必须实现, 顺序(同上)

@end