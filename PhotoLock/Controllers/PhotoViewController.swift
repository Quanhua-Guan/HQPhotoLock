
//
//  PhotoViewController.swift
//  PhotoLock
//
//  Created by 泉华 官 on 14/12/27.
//  Copyright (c) 2014年 CQMH. All rights reserved.
//

import UIKit

protocol PhotoViewControllerDelegate {
    func photoviewControllerSendDismiss(photoViewController:PhotoViewController)
}

class PhotoViewController: UIViewController, UIScrollViewDelegate {
    
    // MARK: - Views
    private var imageView: UIImageView!
    private var scrollView: UIScrollView!
    private var image: UIImage?
    var delegate: PhotoViewControllerDelegate!
    // MARK: - Vars
    var photo: Photo!
    var photoIndex: Int!
    
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
            dispatch_async(globalQueue, { () -> Void in
                var image = pictureFromPhoto(self.photo)!
                self.image = image;
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let iw = image.size.width
                    let ih = image.size.height
                    let sw = self.scrollView.bounds.size.width
                    let sh = self.scrollView.bounds.size.height
                    let scaleW = iw / sw
                    let scaleH = ih / sh
                    var scale = max(scaleW, scaleH)
                    var imageSize = CGSizeMake(iw / scale, ih / scale)
                    self.scrollView.contentSize = imageSize
                    self.scrollView.minimumZoomScale = 1.0
                    self.scrollView.maximumZoomScale = scale
                    
                    self.imageView.frame = CGRectMake(0, 0, imageSize.width, imageSize.height)
                    // 让图片居中
                    let offsetX = (self.scrollView.bounds.size.width > self.scrollView.contentSize.width) ? (self.scrollView.bounds.size.width - self.scrollView.contentSize.width) * 0.5 : 0.0
                    let offsetY = (self.scrollView.bounds.size.height > self.scrollView.contentSize.height) ? (self.scrollView.bounds.size.height - self.scrollView.contentSize.height) * 0.5 : 0.0
                    self.imageView.center = CGPointMake(self.scrollView.contentSize.width * 0.5 + offsetX, self.scrollView.contentSize.height * 0.5 + offsetY)
                    self.imageView.userInteractionEnabled = true
                    self.imageView.contentMode = UIViewContentMode.ScaleAspectFit
                    
                    self.imageView.image = image
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
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                self.adjustImageViews(CGRectMake(0, 0, size.width, size.height))
            })
        }
    }
    
    func adjustImageViews(viewBound: CGRect) {
        self.scrollView.frame = viewBound
        self.scrollView.zoomScale = 1.0
        if let image = self.image {
            let iw = image.size.width
            let ih = image.size.height
            let sw = self.scrollView.frame.size.width
            let sh = self.scrollView.frame.size.height
            let scaleW = iw / sw
            let scaleH = ih / sh
            var scale = max(scaleW, scaleH)
            var imageSize = CGSizeMake(iw / scale, ih / scale)
            self.scrollView.contentSize = imageSize
            self.scrollView.minimumZoomScale = 1.0
            self.scrollView.maximumZoomScale = scale
            
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
                self.scrollView.zoomScale = self.scrollView.maximumZoomScale
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
