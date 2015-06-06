//
//  Base.m
//  PhotoLock
//
//  Created by 泉华 官 on 14/12/23.
//  Copyright (c) 2014年 CQMH. All rights reserved.
//

#import "Base.h"
#import <objc/message.h>

@interface Base()

@end

@implementation Base

+ (NSArray *)primaryKeys {
    return @[[self.class properties].firstObject];
}

+ (NSArray *)foreignKeys {
    return @[[self.class properties].lastObject];
}

+ (NSString *)fieldsStringForTableCreation {
    static NSMutableDictionary *fieldsStringForTableCreations = nil;
    if (fieldsStringForTableCreations == nil) {
        fieldsStringForTableCreations = [NSMutableDictionary dictionary];
    }
    
    NSString *tableName = [self.class tableName];
    if ([fieldsStringForTableCreations objectForKey:tableName]== nil) {
        NSString *fieldsStringForTableCreation = @" ";
        NSArray *properties = [self.class properties];
        NSArray *propertiesSQLType = [self.class propertiesSQLType];
        for (int i = 0; i < properties.count; i++) {
            fieldsStringForTableCreation = [fieldsStringForTableCreation stringByAppendingString:[NSString stringWithFormat:@" %@ %@,", properties[i], propertiesSQLType[i]]];
        }
        fieldsStringForTableCreation = [fieldsStringForTableCreation substringToIndex:fieldsStringForTableCreation.length - 1];
        fieldsStringForTableCreation = [fieldsStringForTableCreation stringByAppendingString:@" "];
        
        fieldsStringForTableCreations[tableName] = fieldsStringForTableCreation;
    }
    
    return fieldsStringForTableCreations[tableName];
    //return @" createdTime double, name varchar(20), icon varchar(20) ";
}

+ (NSString *)primaryFieldBeSetString {
    static NSMutableDictionary *primaryFieldBeSetStrings = nil;
    
    if (primaryFieldBeSetStrings == nil) {
        primaryFieldBeSetStrings = [NSMutableDictionary dictionary];
    }
    
    NSString *tableName = [self.class tableName];
    if ([primaryFieldBeSetStrings objectForKey:tableName] == nil) {
        NSString *primaryFieldBeSetString = @" ";
        NSArray *primaryKeys = [self.class primaryKeys];
        for (NSString *key in primaryKeys) {
            primaryFieldBeSetString = [primaryFieldBeSetString stringByAppendingString:[NSString stringWithFormat:@" %@=:%@,", key, key]];
        }
        primaryFieldBeSetString = [[primaryFieldBeSetString substringToIndex:primaryFieldBeSetString.length - 1] stringByAppendingString:@" "];
        
        primaryFieldBeSetStrings[tableName] = primaryFieldBeSetString;
    }
    return primaryFieldBeSetStrings[tableName];
}

+ (NSString *)allFieldsBeSetString {
    static NSMutableDictionary *allFieldsBeSetStrings = nil;
    
    if (allFieldsBeSetStrings == nil) {
        allFieldsBeSetStrings = [NSMutableDictionary dictionary];
    }
    
    NSString *tableName = [self.class tableName];
    if ([allFieldsBeSetStrings objectForKey:tableName] == nil) {
        NSString *allFieldsBeSetString = @" ";
        NSArray *properties = [self.class properties];
        for (int i = 0; i < properties.count; i++) {
            allFieldsBeSetString = [allFieldsBeSetString stringByAppendingString:[NSString stringWithFormat:@" %@=:%@,", properties[i], properties[i]]];
        }
        allFieldsBeSetString = [allFieldsBeSetString substringToIndex:allFieldsBeSetString.length - 1];
        allFieldsBeSetString = [allFieldsBeSetString stringByAppendingString:@" "];
        
        allFieldsBeSetStrings[tableName] = allFieldsBeSetString;
    }
    
    return allFieldsBeSetStrings[tableName];
    //return @" createdTime=:p, name=:a, icon=:b ";
}

- (NSDictionary *)parameterArgs {
    NSMutableDictionary *parameterArgs = @{}.mutableCopy;
    NSArray *properties = [self.class properties];
    for (NSString *property in properties) {
        parameterArgs[property] = [self valueForKey:property];
    }
    return parameterArgs;
}

- (NSDictionary *)parameterArgsForOnlyPrimaryKey {
    NSArray *primaryKeys = [self.class primaryKeys];
    NSMutableDictionary *parameterArgsForOnlyPrimaryKey = [NSMutableDictionary dictionary];
    for (NSString *key in primaryKeys) {
        parameterArgsForOnlyPrimaryKey[key] = [self valueForKey:key];
    }
    return parameterArgsForOnlyPrimaryKey;
}

+ (NSString *)parameterArgsKeysListString {
    static NSMutableDictionary *parameterArgsKeysListStrings = nil;
    
    if (parameterArgsKeysListStrings == nil) {
        parameterArgsKeysListStrings = [NSMutableDictionary dictionary];
    }
    
    NSString *tableName = [self.class tableName];
    if ([parameterArgsKeysListStrings objectForKey:tableName] == nil) {
        NSString *parameterArgsKeysListString = @" ";
        NSArray *properties = [self.class properties];
        for (int i = 0; i < properties.count; i++) {
            parameterArgsKeysListString = [parameterArgsKeysListString stringByAppendingString:[NSString stringWithFormat:@" :%@,", properties[i]]];
        }
        parameterArgsKeysListString = [parameterArgsKeysListString substringToIndex:parameterArgsKeysListString.length - 1];
        parameterArgsKeysListString = [parameterArgsKeysListString stringByAppendingString:@" "];
        // 加入
        parameterArgsKeysListStrings[tableName] = parameterArgsKeysListString;
    }
    
    return parameterArgsKeysListStrings[tableName];
    //return @" :p, :a, :b ";
}

+ (NSString *)tableName {
    return NSStringFromClass(self.class);
}

- (void)setValues:(NSDictionary *)values {
    for (NSString *property in values.allKeys) {
        [self setValue:values[property] forKey:property];
    }
}

#pragma mark - Functions

+ (NSArray *)properties {
    static NSMutableDictionary *_propertiesArray = nil;
    if (_propertiesArray == nil) {
        _propertiesArray = [NSMutableDictionary dictionary];
    }
    
    NSString *tableName = [self.class tableName];
    if ([_propertiesArray objectForKey:tableName] == nil) {
        NSMutableArray *_properties = [NSMutableArray array];
        
        id class = self.class;
        unsigned int outCount, i;
        objc_property_t *properties = class_copyPropertyList(class, &outCount);
        for (i = 0; i < outCount; i++) {
            objc_property_t property = properties[i];
            NSString *propName = [NSString stringWithUTF8String:property_getName(property)];
            [_properties addObject:propName];
        }
        
        _propertiesArray[tableName] = _properties;
    }
    return _propertiesArray[tableName];/* _properties = @[@"属性1", @"属性2", @"属性3", ...] */
}

+ (NSArray *)propertiesSQLType {    
    @throw [NSException exceptionWithName:@"Fatal Error"
                                   reason:@"You MUST override this selector in subclass"
                                 userInfo:nil];
}

@end
