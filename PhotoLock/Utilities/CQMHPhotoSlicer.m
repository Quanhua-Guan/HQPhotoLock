//
//  CQMHPhotoSlicer.m
//  PhotoLock
//
//  Created by 泉华 官 on 15/7/19.
//  Copyright (c) 2015年 CQMH. All rights reserved.
//

#import "CQMHPhotoSlicer.h"
#import <ImageIO/ImageIO.h>
#import "NSData+CommonCrypto.h"

@implementation CQMHPhotoSlicer

+ (CGSize) imageSizeWithImageData:(NSData *)imageData {
    CFDictionaryRef options = (__bridge CFDictionaryRef) @{(id) kCGImageSourceTypeIdentifierHint : @YES};
    CGImageSourceRef imageSourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, options);
    NSDictionary *imagePropertiesDictionary = CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(imageSourceRef, 0, NULL));
    CFRelease(imageSourceRef);
    
    NSNumber *width = imagePropertiesDictionary[(__bridge NSString *)kCGImagePropertyPixelWidth];
    NSNumber *height = imagePropertiesDictionary[(__bridge NSString *)kCGImagePropertyPixelHeight];
    return CGSizeMake(width.floatValue, height.floatValue);
}

+ (NSArray *)sliceImageData:(NSData *)imageData  tileSize:(CGFloat)tileSize destinationFoldPath:(NSString *)outputPath tileImageBaseName:(NSString *)tileImageBaseName shouldDoLossyCompression:(BOOL)shouldDoLossyCompression {
    
    @autoreleasepool{
        int rows = 0;// Horizontal tiles count
        int columns = 0;// Vertical tiles count
        // Create options
        CFDictionaryRef options = (__bridge CFDictionaryRef) @{(id) kCGImageSourceTypeIdentifierHint : @YES};
        
        // Get NSData
        CGImageSourceRef imageSourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, options);
        NSDictionary *imagePropertiesDictionary = CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(imageSourceRef, 0, NULL));
        
        NSNumber *width = imagePropertiesDictionary[(__bridge NSString *)kCGImagePropertyPixelWidth];
        NSNumber *height = imagePropertiesDictionary[(__bridge NSString *)kCGImagePropertyPixelHeight];
        CGSize size = CGSizeMake(width.floatValue, height.floatValue);
        
        // Create CGImageRef
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSourceRef, 0, options);
        CFRelease(imageSourceRef);
        
        // Calculate rows and columns
        rows = ceil(size.height / tileSize);
        columns = ceil(size.width / tileSize);
        
        // Generate tiles
        for (int r = 0; r < rows; ++r) {
            for (int c = 0; c < columns; ++c) {
                @autoreleasepool{
                    // Path to save file
                    NSString *pathToSaveFile = [outputPath stringByAppendingPathComponent:[NSString stringWithFormat: @"%@%02i%02i", tileImageBaseName, c, r]];
                    
                    // Check file existence
                    if([[NSFileManager new] fileExistsAtPath:pathToSaveFile]) {
                        NSLog(@"%@-%@:Error, File Name Collision!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
                    }
                    
                    // Extract tile image
                    CGRect tileRect = CGRectMake(c * tileSize, r * tileSize, tileSize, tileSize);
                    CGImageRef tileImageRef = CGImageCreateWithImageInRect(imageRef, tileRect);
                    
                    // Convert to jpeg data
                    UIImage *tileImage = [UIImage imageWithCGImage:tileImageRef];
                    CGImageRelease(tileImageRef);
                    
                    NSData *tileImageData = nil;
                    if (shouldDoLossyCompression) {
                        tileImageData = UIImageJPEGRepresentation(tileImage, 0.80);
                    } else {
                        //tileImageData = UIImagePNGRepresentation(tileImage);
                        tileImageData = UIImageJPEGRepresentation(tileImage, 0.90);
                    }
                    // Compress and encrypt
                    tileImageData = [tileImageData compressAndEncrypt:tileImageData];
                    // Save to file
                    [tileImageData writeToFile:pathToSaveFile atomically:NO];
                }
            }
        }
        CGImageRelease(imageRef);
        return @[@(rows), @(columns)];
    }
    
}

@end
