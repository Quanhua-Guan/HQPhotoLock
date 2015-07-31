//
//  CQMHPhotoSlicer.h
//  PhotoLock
//
//  Created by 泉华 官 on 15/7/19.
//  Copyright (c) 2015年 CQMH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CQMHPhotoSlicer : NSObject

+ (CGSize) imageSizeWithImageData:(NSData *)imageData;
+ (NSArray *)sliceImageData:(NSData *)imageData tileSize:(CGFloat)tileSize destinationFoldPath:(NSString *)outputPath tileImageBaseName:(NSString *)tileImageBaseName shouldDoLossyCompression:(BOOL)shouldDoLossyCompression;

@end
