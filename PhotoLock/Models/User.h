//
//  User.h
//  PhotoLock
//
//  Created by 泉华 官 on 14/12/28.
//  Copyright (c) 2014年 CQMH. All rights reserved.
//

#import "Base.h"

@interface User : Base

@property (nonatomic, readwrite, strong) NSString *username;
@property (nonatomic, readwrite, strong) NSString *password;

@end
