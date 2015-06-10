//
//  NavigationViewController.swift
//  PhotoLock
//
//  Created by 泉华 官 on 15/6/10.
//  Copyright (c) 2015年 CQMH. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController, UIViewControllerTransitioningDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Status bar white font
        self.navigationBar.barStyle = UIBarStyle.BlackTranslucent
        self.navigationBar.tintColor = UIColor.whiteColor()
    }
}
