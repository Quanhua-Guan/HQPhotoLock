//
//  Photo.h
//  PhotoLock
//
//  Created by 泉华 官 on 14/12/23.
//  Copyright (c) 2014年 CQMH. All rights reserved.
//

#import "Base.h"

@interface Photo : Base

/**
 *  文件创建时间
 */
@property (nonatomic, readwrite, strong) NSNumber *createdTime;
/**
 *  名称
 */
@property (nonatomic, readwrite, strong) NSString *name;
/**
 *  原图文件名
 */
@property (nonatomic, readwrite, strong) NSString *originalFilename;
/**
 *  缩略图文件名
 */
@property (nonatomic, readwrite, strong) NSString *thumbnailFilename;
/**
 *  所属相册
 */
@property (nonatomic, readwrite, strong) NSNumber *albumCreatedTime;

@end
