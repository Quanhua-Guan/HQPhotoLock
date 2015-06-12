//
//  AppDelegate.swift
//  PhotoLock
//
//  Created by 泉华 官 on 14/12/17.
//  Copyright (c) 2014年 CQMH. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        UINavigationBar.appearance().barStyle = UIBarStyle.BlackTranslucent
        UINavigationBar.appearance().backgroundColor = Color.skyBlueColor()
        UINavigationBar.appearance().tintColor = Color.whiteColor()
        
        SVProgressHUD.setBackgroundColor(UIColor(patternImage: UIImage(named: "HUDBackground")!))
        SVProgressHUD.setForegroundColor(UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0))
        
        // 新建文件夹
        let fileManager = NSFileManager.defaultManager()
        for path in [PictureFoldPath, ThumbnailFoldPath] {
            if !fileManager.fileExistsAtPath(path) {
                var error: NSError?
                fileManager.createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil, error: &error)
                if error != nil {
                    println(error)
                }
            }
        }
        
        // 验证视图控制器
        authenticationViewController = self.window?.rootViewController?.storyboard?.instantiateViewControllerWithIdentifier(NSStringFromClass(AuthenticationViewController.self)) as! AuthenticationViewController
        authenticationViewController.modalTransitionStyle = UIModalTransitionStyle.FlipHorizontal
        
        // 监听锁屏事件
        CommonUtilities.observerLockEvents()
        
        // 加载设置
        loadData()
        
        // 友盟
        UMSocialData.setAppKey(UMAppKey)
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        self.showPasswordInterface()
    }

    func applicationDidEnterBackground(application: UIApplication) {
        saveData()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
    }

    func applicationWillTerminate(application: UIApplication) {
        saveData()
    }
    
    func showPasswordInterface() {
        var currentViewController = self.window?.rootViewController
        while currentViewController != nil && currentViewController?.presentedViewController != nil {
            currentViewController = currentViewController?.presentedViewController
        }
        if passwordInterfaceShown || currentViewController is AuthenticationViewController {
            return;
        }
        currentViewController?.presentViewController(authenticationViewController, animated: false, completion: { () -> Void in
            passwordInterfaceShown = true
        })
    }
}

