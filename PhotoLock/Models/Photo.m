//
//  Photo.m
//  PhotoLock
//
//  Created by 泉华 官 on 14/12/23.
//  Copyright (c) 2014年 CQMH. All rights reserved.
//

#import "Photo.h"

//NSNumber *createdTime;NSString *name;NSString *originalFilename;NSString *thumbnailFilename;NSNumber *albumCreatedTime;

@implementation Photo

+ (NSArray *)propertiesSQLType {
    return @[@"double", @"varchar(20)", @"varchar(20)", @"varchar(20)", @"double"];
}

@end
