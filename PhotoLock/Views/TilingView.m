//
//  TilingView.m
//  PhotoLock
//
//  Created by 泉华 官 on 15/7/19.
//  Copyright (c) 2015年 CQMH. All rights reserved.
//

#import "TilingView.h"
#import <QuartzCore/CATiledLayer.h>
#import "NSData+CommonCrypto.h"

@interface TilingView()

@property (nonatomic, readwrite, strong) NSString *imageFoldPath;// 图片所在文件夹路径
@property (nonatomic, readwrite, strong) NSString *imageBaseName;// 图片基本文件名(除去tile的row,column信息)
@property (nonatomic, readwrite, assign) int tilesCountHorizontal;// 水平方向上Tile个数
@property (nonatomic, readwrite, assign) int tilesCountVertical;// 竖直方向上Tile个数

@end

@implementation TilingView

+ (Class)layerClass
{
    return [CATiledLayer class];
}

- (instancetype)initWithImageFoldPath:(NSString *)imageFoldPath
              imageBaseName:(NSString *)imageBaseName
                      frame:(CGRect)frame
                   tileSize:(CGSize)tileSize
       tilesCountHorizontal:(int)tilesCountHorizontal
         tilesCountVertical:(int)tilesCountVertical
{
    self = [super initWithFrame:frame];
    if (self) {
        _imageFoldPath = imageFoldPath;
        _imageBaseName = imageBaseName;
        _tilesCountHorizontal = tilesCountHorizontal;
        _tilesCountVertical = tilesCountVertical;
        CATiledLayer *tiledLayer = (CATiledLayer *)[self layer];
        tiledLayer.levelsOfDetail = 4;
        tiledLayer.tileSize = tileSize;
    }
    return self;
}

// to handle the interaction between CATiledLayer and high resolution screens, we need to
// always keep the tiling view's contentScaleFactor at 1.0. UIKit will try to set it back
// to 2.0 on retina displays, which is the right call in most cases, but since we're backed
// by a CATiledLayer it will actually cause us to load the wrong sized tiles.
//
- (void)setContentScaleFactor:(CGFloat)contentScaleFactor
{
    [super setContentScaleFactor:1.f];
}

- (void)drawRect:(CGRect)rect
{
    CATiledLayer *tiledLayer = (CATiledLayer *)[self layer];
    CGSize tileSize = tiledLayer.tileSize;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat scaleX = CGContextGetCTM(context).a;
    
    // Calculate the rows and columns of tiles that intersect the rect we have been asked to draw
    int firstCol = floorf(CGRectGetMinX(rect) / tileSize.width);
    int lastCol = floorf((CGRectGetMaxX(rect)-1) / tileSize.width);
    int firstRow = floorf(CGRectGetMinY(rect) / tileSize.height);
    int lastRow = floorf((CGRectGetMaxY(rect)-1) / tileSize.height);
    
    for (int row = firstRow; row <= lastRow; row++) {
        for (int col = firstCol; col <= lastCol; col++) {
            UIImage *tileImage = [self tileImageForRow:row column:col];
            CGRect tileRect = CGRectMake(tileSize.width * col, tileSize.height * row, tileSize.width, tileSize.height);
            
            if (scaleX < 1.0) {
                tileRect.size.width += (1.0 / scaleX);
                tileRect.size.height += (1.0 / scaleX);
            }
            // If the tile would stick outside of our bounds, we need to truncate it so as
            // to avoid stretching out the partial tiles at the right and bottom edges
            tileRect = CGRectIntersection(self.bounds, tileRect);
            // Draw in rect
            [tileImage drawInRect:tileRect];
        }
    }
}

- (UIImage *)tileImageForRow:(int)row column:(int)column
{
    NSString *tileImagePath = [_imageFoldPath stringByAppendingPathComponent:[NSString stringWithFormat: @"%@%02i%02i", _imageBaseName, column, row]];
    NSData *tileImageData = [NSData dataWithContentsOfFile:tileImagePath];
    // Decrypt and dcompress
    tileImageData = [tileImageData decryptAndDcompress:tileImageData];
    return [UIImage imageWithData:tileImageData];
}

@end
