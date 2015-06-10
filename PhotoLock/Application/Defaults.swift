//
//  Defaults.swift
//  Eleven
//
//  Created by 泉华 官 on 14/11/13.
//  Copyright (c) 2014年 CQMH. All rights reserved.
//

import Foundation
import UIKit

// ScreenSize
let ScreenWidth = UIScreen.mainScreen().bounds.size.width
let ScreenHeight = UIScreen.mainScreen().bounds.size.height

// 数据库操作者
let DBMasterKey = BaseDBMasterKey();

// Segue Identifier
let SegueIdentifierGoSettings = "goSettings"
let SegueIdentifierShowAlbum = "showAlbum"
let SegueIdentifierShowMainMenu = "showMainMenu"
let SegueIdentifierShowPhotos = "showPhotos"

let EmptyAlbumIconName = ""

// 密码界面是否显示
var passwordInterfaceShown = false
var authenticationViewController: AuthenticationViewController!
let passwordForEncryptPassword = "1234567890123456"

// 图片和缩略图的存储文件夹路径
let PictureFoldPath = (NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.LibraryDirectory, NSSearchPathDomainMask.UserDomainMask, true).first as! String).stringByAppendingPathComponent("picture")
let ThumbnailFoldPath = (NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.LibraryDirectory, NSSearchPathDomainMask.UserDomainMask, true).first as! String).stringByAppendingPathComponent("thumbnail")
let FileSharingFoldPath = (NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first as! String)

extension UIColor {
    class func randomColor(alpha:CGFloat = 0.09) -> UIColor{
        var randomRed:CGFloat = CGFloat(drand48())
        var randomGreen:CGFloat = CGFloat(drand48())
        var randomBlue:CGFloat = CGFloat(drand48())
        return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: alpha)
    }
}

extension UIImage {
    
    func imageWithInRect(rect: CGRect) -> UIImage {
        let origin = CGPointMake(-rect.origin.x, -rect.origin.y)
        
        UIGraphicsBeginImageContext(CGSizeMake(rect.size.width, rect.size.height))
        self .drawAtPoint(origin)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return img
    }
    
    func tileImagesWithTileSize(size: CGSize) -> [[UIImage]] {
        var imagess = [[UIImage]]();
        
        var point = CGPoint(x: 0, y: 0)
        let imageBound = CGRectMake(0, 0, self.size.width, self.size.height)
        
        while imageBound.contains(point) {
            var images = [UIImage]()
            while imageBound.contains(point) {
                let rect = CGRectMake(point.x, point.y, size.width, size.height)
                images.append(self.imageWithInRect(rect))
                point.x += size.width
            }
            imagess.append(images)
            
            point.x = 0
            point.y += size.height
        }
        
        return imagess
    }
    
}

func thumbnailFromPhoto(photo:Photo) -> UIImage? {
    var thumbnailData = NSData(contentsOfFile: ThumbnailFoldPath.stringByAppendingPathComponent(photo.thumbnailFilename))
    thumbnailData = thumbnailData?.decryptAndDcompress(thumbnailData)
    return thumbnailData == nil ? nil : UIImage(data: thumbnailData!)!
}

func pictureFromPhoto(photo:Photo) -> UIImage? {
    var pictureData: NSData?
    autoreleasepool { () -> () in
        pictureData = NSData(contentsOfFile: PictureFoldPath.stringByAppendingPathComponent(photo.originalFilename))
        pictureData = pictureData?.decryptAndDcompress(pictureData)
    }
    return pictureData == nil ? nil : UIImage(data: pictureData!)!
}

// AdMob
let AdMob = HQAdMob()
class HQAdMob {
    // adUnitID for AdMob
    let AdUnitID = "ca-app-pub-6958627927268333/2853184404"
    //
    func showAdInView(bannerView: GADBannerView!, inViewController viewController: UIViewController!) {
        // 广告
        // Replace this ad unit ID with your own ad unit ID.
        bannerView.adUnitID = AdUnitID
        bannerView.rootViewController = viewController
        
        let request = GADRequest()
        // Requests test ads on devices you specify. Your test device ID is printed to the console when
        // an ad request is made.
        //request.testDevices = NSArray(array: [GAD_SIMULATOR_ID/*, "5041a084760bfe83b6701fa480ea3756"*/])
        bannerView.loadRequest(request)
    }
}
