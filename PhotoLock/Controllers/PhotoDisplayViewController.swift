//
//  PhotoDisplayViewController.swift
//  PhotoLock
//
//  Created by 泉华 官 on 14/12/27.
//  Copyright (c) 2014年 CQMH. All rights reserved.
//

import UIKit

class PhotoDisplayViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, PhotoViewControllerDelegate {

    // MARK: - Vars
    var currentPhotoIndex: Int = 0
    var photos:[AnyObject]!
    var toolBar: UIToolbar!
    
    // MARK: - View Did Load
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.blackColor()
        
        let photoViewController = storyboard?.instantiateViewControllerWithIdentifier(NSStringFromClass(PhotoViewController.self)) as! PhotoViewController
        photoViewController.delegate = self
        photoViewController.photoIndex = currentPhotoIndex
        photoViewController.photo = photos[currentPhotoIndex] as! Photo
        self.setViewControllers([photoViewController], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
        self.dataSource = self
        self.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: - Actions
    
    // MARK: - Functions
    
    // MARK: - Override
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    // MARK: - UIPageViewControllerDataSource
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        let nextPhotoIndex = (viewController as! PhotoViewController).photoIndex + 1
        if nextPhotoIndex == photos.count {
            return nil
        }
        
        let photoViewController = storyboard?.instantiateViewControllerWithIdentifier(NSStringFromClass(PhotoViewController.self)) as! PhotoViewController
        photoViewController.delegate = self
        photoViewController.photoIndex = nextPhotoIndex
        photoViewController.photo = photos[photoViewController.photoIndex] as! Photo
        return photoViewController
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        let previousPhotoIndex = (viewController as! PhotoViewController).photoIndex - 1
        if previousPhotoIndex == -1 {
            return nil
        }
        
        let photoViewController = storyboard?.instantiateViewControllerWithIdentifier(NSStringFromClass(PhotoViewController.self)) as! PhotoViewController
        photoViewController.delegate = self
        photoViewController.photoIndex = previousPhotoIndex
        photoViewController.photo = photos[photoViewController.photoIndex] as! Photo
        return photoViewController
    }
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [AnyObject], transitionCompleted completed: Bool) {
        let previousViewController = previousViewControllers.first as! PhotoViewController
        previousViewController.resetScrollViewScaleToFitImage()
    }
    
    func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [AnyObject]) {
        
    }
    
    // MARK: - PhotoViewControllerDelegate
    
    func photoviewControllerSendDismiss(photoViewController: PhotoViewController) {
        photoViewController.dismissViewControllerAnimated(true, completion: nil)
    }
}
