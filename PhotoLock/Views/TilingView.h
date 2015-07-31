//
//  TilingView.h
//  PhotoLock
//
//  Created by 泉华 官 on 15/7/19.
//  Copyright (c) 2015年 CQMH. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TilingView : UIView

- (instancetype)initWithImageFoldPath:(NSString *)imageFoldPath
              imageBaseName:(NSString *)imageBaseName
                      frame:(CGRect)frame
                   tileSize:(CGSize)tileSize
       tilesCountHorizontal:(int)tilesCountHorizontal
         tilesCountVertical:(int)tilesCountVertical;

@end
