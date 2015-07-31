
//
//  PhotoViewController.swift
//  PhotoLock
//
//  Created by 泉华 官 on 14/12/27.
//  Copyright (c) 2014年 CQMH. All rights reserved.
//

import UIKit

protocol PhotoViewControllerDelegate : class {
    func photoviewControllerSendDismiss(photoViewController:PhotoViewController)
}

extension String {
    func toDouble() -> Double? {
        return NSNumberFormatter().numberFromString(self)?.doubleValue
    }
}

class PhotoViewController: UIViewController, UIScrollViewDelegate {
    
    // MARK: - Views
    private var imageView: UIImageView!
    private var thumbnailImageView: UIImageView!// todo
    private var tilingView: TilingView!
    private var scrollView: UIScrollView!
    private var image: UIImage?
    weak var delegate: PhotoViewControllerDelegate!
    // MARK: - Vars
    var photo: Photo!
    var photoIndex: Int!
    var imagePixelsWidth: CGFloat!
    var imagePixelsHeight: CGFloat!
    
    // MARK: - View Did Load
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.blackColor()
        
        self.scrollView = UIScrollView(frame: UIScreen.mainScreen().bounds)
        self.scrollView.contentMode = UIViewContentMode.Top
        self.scrollView.delegate = self
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.showsVerticalScrollIndicator = false
        self.imageView = UIImageView()
        self.imageView.userInteractionEnabled = true
        self.imageView.contentMode = UIViewContentMode.ScaleAspectFit
        
        self.scrollView.addSubview(self.imageView)
        self.view.addSubview(self.scrollView)
       
        // 单点单击
        let tapOnceGesture = UITapGestureRecognizer(target: self, action: "dismiss:")
        tapOnceGesture.numberOfTapsRequired = 1
        tapOnceGesture.numberOfTouchesRequired = 1
        tapOnceGesture.delaysTouchesBegan = true
        self.imageView.addGestureRecognizer(tapOnceGesture)
        
        // 单点双击
        let tapTwiceGesture = UITapGestureRecognizer(target: self, action: "zoomingImage:")
        tapTwiceGesture.numberOfTapsRequired = 2
        tapTwiceGesture.numberOfTouchesRequired = 1
        self.imageView.addGestureRecognizer(tapTwiceGesture)
        
        tapOnceGesture.requireGestureRecognizerToFail(tapTwiceGesture)
        
        let globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
        autoreleasepool { () -> () in
            dispatch_async(globalQueue, {[unowned self] () -> Void in
                var placeholderImage: UIImage?
                var originalImage: UIImage?
                let iw: CGFloat
                let ih: CGFloat
                if self.photo.originalFilename.hasSuffix(TiledSuffix) {
                    // "filebasename_rows_columns_width_height_tiled"
                    let imageBaseNameRowsColumnsWidthHeight = self.photo.originalFilename.componentsSeparatedByString("_")
                    let imageBaseName = imageBaseNameRowsColumnsWidthHeight[0]
                    let rows = imageBaseNameRowsColumnsWidthHeight[1].toInt()!
                    let columns = imageBaseNameRowsColumnsWidthHeight[2].toInt()!
                    self.imagePixelsWidth = CGFloat(imageBaseNameRowsColumnsWidthHeight[3].toDouble()!)
                    self.imagePixelsHeight = CGFloat(imageBaseNameRowsColumnsWidthHeight[4].toDouble()!)
                    self.tilingView = TilingView(imageFoldPath: PictureFoldPath, imageBaseName: imageBaseName, frame: CGRectMake(0, 0, self.imagePixelsWidth, self.imagePixelsHeight), tileSize: CGSizeMake(TileSize, TileSize), tilesCountHorizontal: Int32(columns), tilesCountVertical: Int32(rows))
                    // 先用占位图代替
                    placeholderImage = placeholderFromPhoto(self.photo) ?? thumbnailFromPhoto(self.photo)!
                    self.image = placeholderImage
                    //
                    iw = self.imagePixelsWidth
                    ih = self.imagePixelsHeight
                } else {
                    // 先用占位图代替
                    placeholderImage = placeholderFromPhoto(self.photo) ?? thumbnailFromPhoto(self.photo)!
                    originalImage = pictureFromPhoto(self.photo)!
                    self.image = originalImage
                    //
                    iw = originalImage!.size.width
                    ih = originalImage!.size.height
                    self.imagePixelsWidth = iw
                    self.imagePixelsHeight = ih
                }
                dispatch_async(dispatch_get_main_queue(), {[unowned self] () -> Void in
                    let sw = self.scrollView.bounds.size.width
                    let sh = self.scrollView.bounds.size.height
                    let scaleW = iw / sw
                    let scaleH = ih / sh
                    var scale = max(scaleW, scaleH)
                    var imageSize = CGSizeMake(iw , ih)
                    self.scrollView.contentSize = imageSize
                    self.scrollView.minimumZoomScale = CGFloat(1.0) / scale
                    self.scrollView.maximumZoomScale = 1.0
                    self.scrollView.zoomScale = CGFloat(1.0) / scale
                    if self.scrollView.maximumZoomScale < self.scrollView.minimumZoomScale {
                        self.scrollView.minimumZoomScale = self.scrollView.maximumZoomScale
                    }
                    
                    imageSize = CGSizeMake(iw / scale, ih / scale)
                    self.imageView.frame = CGRectMake(0, 0, imageSize.width, imageSize.height)
                    // 让图片居中
                    let offsetX = (self.scrollView.bounds.size.width > self.scrollView.contentSize.width) ? (self.scrollView.bounds.size.width - self.scrollView.contentSize.width) * 0.5 : 0.0
                    let offsetY = (self.scrollView.bounds.size.height > self.scrollView.contentSize.height) ? (self.scrollView.bounds.size.height - self.scrollView.contentSize.height) * 0.5 : 0.0
                    self.imageView.center = CGPointMake(self.scrollView.contentSize.width * 0.5 + offsetX, self.scrollView.contentSize.height * 0.5 + offsetY)
                    self.imageView.userInteractionEnabled = true
                    self.imageView.contentMode = UIViewContentMode.ScaleAspectFit
                    // 设置图片
                    self.imageView.image = placeholderImage
                    
                    // 添加tilingView
                    if self.tilingView != nil {
                        self.tilingView.frame = self.imageView.bounds
                        self.imageView.addSubview(self.tilingView)
                    } else {
                        let originalImageView = UIImageView(image: originalImage!)
                        originalImageView.frame = self.imageView.bounds
                        originalImageView.userInteractionEnabled = true
                        originalImageView.alpha = 0.0
                        originalImageView.contentMode = UIViewContentMode.ScaleAspectFit
                        self.imageView.addSubview(originalImageView)
                        UIView.animateWithDuration(1, delay: 0, options: UIViewAnimationOptions.AllowUserInteraction, animations: { () -> Void in
                            originalImageView.alpha = 1.0
                        }, completion: nil)
                    }
                })
            })
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: - Rotation
    
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        // ios 7
        let version = (UIDevice.currentDevice().systemVersion as NSString).doubleValue
        if version >= 7.0 && version < 8.0 {
            self.adjustImageViews(self.view.bounds)
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        // ios 8 & later
        let version = (UIDevice.currentDevice().systemVersion as NSString).doubleValue
        if version >= 8.0 {
            UIView.animateWithDuration(0.5, animations: {[unowned self] () -> Void in
                self.adjustImageViews(CGRectMake(0, 0, size.width, size.height))
            })
        }
    }
    
    func adjustImageViews(viewBound: CGRect) {
        self.scrollView.frame = viewBound
        if let image = self.image {
            let iw = self.imagePixelsWidth
            let ih = self.imagePixelsHeight
            let sw = self.scrollView.frame.size.width
            let sh = self.scrollView.frame.size.height
            let scaleW = iw / sw
            let scaleH = ih / sh
            var scale = max(scaleW, scaleH)
            var imageSize = CGSizeMake(iw , ih)
            self.scrollView.contentSize = imageSize
            self.scrollView.minimumZoomScale = CGFloat(1.0) / scale
            self.scrollView.maximumZoomScale = 1.0
            self.scrollView.zoomScale = CGFloat(1.0) / scale
            if self.scrollView.maximumZoomScale < self.scrollView.minimumZoomScale {
                self.scrollView.minimumZoomScale = self.scrollView.maximumZoomScale
            }
            
            imageSize = CGSizeMake(iw / scale, ih / scale)
            self.imageView.frame = CGRectMake(0, 0, imageSize.width, imageSize.height)
            // 让图片居中
            let offsetX = (self.scrollView.frame.size.width > self.scrollView.contentSize.width) ? (self.scrollView.frame.size.width - self.scrollView.contentSize.width) * 0.5 : 0.0
            let offsetY = (self.scrollView.frame.size.height > self.scrollView.contentSize.height) ? (self.scrollView.frame.size.height - self.scrollView.contentSize.height) * 0.5 : 0.0
            self.imageView.center = CGPointMake(self.scrollView.contentSize.width * 0.5 + offsetX, self.scrollView.contentSize.height * 0.5 + offsetY)
        }
    }
    
    // MARK: - Actions
    
    func dismiss(sender: UITapGestureRecognizer) {
        self.delegate.photoviewControllerSendDismiss(self)
    }
    
    func zoomingImage(sender: UITapGestureRecognizer) {
        UIView.animateWithDuration(0.6, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            if self.scrollView.zoomScale == self.scrollView.minimumZoomScale {
                var newScale = self.scrollView.maximumZoomScale / UIScreen.mainScreen().scale
                if newScale < self.scrollView.minimumZoomScale {
                    newScale = self.scrollView.minimumZoomScale
                }
                self.scrollView.zoomScale = newScale
            } else {
                self.scrollView.zoomScale = self.scrollView.minimumZoomScale
            }
            
            // 让图片居中
            let offsetX = (self.scrollView.bounds.size.width > self.scrollView.contentSize.width) ? (self.scrollView.bounds.size.width - self.scrollView.contentSize.width) * 0.5 : 0.0
            let offsetY = (self.scrollView.bounds.size.height > self.scrollView.contentSize.height) ? (self.scrollView.bounds.size.height - self.scrollView.contentSize.height) * 0.5 : 0.0
            self.imageView.center = CGPointMake(self.scrollView.contentSize.width * 0.5 + offsetX, self.scrollView.contentSize.height * 0.5 + offsetY)
            }, completion: nil)
    }
    
    // MARK: - Functions
    
    func resetScrollViewScaleToFitImage() {
        if self.scrollView.zoomScale != self.scrollView.minimumZoomScale {
            self.scrollView.zoomScale = self.scrollView.minimumZoomScale
        }
    }
    
    // MARK: - UIScrollViewDelegate
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        let offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width) ? (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0
        let offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height) ? (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0
        imageView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX, scrollView.contentSize.height * 0.5 + offsetY)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
    }
    
}
