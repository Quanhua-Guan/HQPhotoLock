//
//  PhotosCollectionViewController.swift
//  PhotoLock
//
//  Created by 泉华 官 on 14/12/18.
//  Copyright (c) 2014年 CQMH. All rights reserved.
//

import UIKit

let reuseIdentifier = "PhotoCollectionViewCell"

protocol PhotosCollectionViewControllerDelegate {
    func setNeedReloadAlbumsTable()
}

class PhotosCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, CTAssetsPickerControllerDelegate, ImportPhotosFromFileSharingViewControllerDelegate {
    
    // Veiws
    @IBOutlet weak var collectionViewBottomMargin: NSLayoutConstraint!
    @IBOutlet weak var importPhotoButtonItem: UIBarButtonItem!
    @IBOutlet weak var hintImageView: UIImageView!
    
    // MARK: - Vars
    var delegate: PhotosCollectionViewControllerDelegate!
    
    var cellSize = CGSizeMake(70, 70)// 缩略图大小
    var album: Album!
    var photos: [AnyObject]! // 和photosSelected同时操作
    var photosSelected: [Bool]!
    var numPicturePerRow:Int = 4
    var insectForCell: UIEdgeInsets!
    
    var isNowEditing = false
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: - View Did Load
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 初始化
        let screeWidth = UIScreen.mainScreen().bounds.size.width
        if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone {
            numPicturePerRow = 4
        } else {
            numPicturePerRow = 8
        }
        let w = ((screeWidth + 2.0) / CGFloat(numPicturePerRow)) - 2.0
        cellSize = CGSizeMake(w, w)
        let insect = (screeWidth - (CGFloat(numPicturePerRow) * w)) / (CGFloat(numPicturePerRow) - 1.0)
        insectForCell = UIEdgeInsetsMake(insect, 0, 0, 0)
        //
        self.navigationController?.setToolbarHidden(true, animated: true)
        // load album
        let photosArrayObject: AnyObject? = DBMasterKey.findInTable(Photo.self, whereField: Photo.foreignKeys().first as! String, equalToValue: album.createdTime) as AnyObject?
        photos = (photosArrayObject != nil ? (photosArrayObject as! [AnyObject]) : [])
        photosSelected = [Bool]()
        for i in 0..<photos.count {
            photosSelected.append(false)
        }
    }
        
    // MARK: - IBActions
    
    @IBAction func addPhotos(sender: UIBarButtonItem) {
        if !isNowEditing {
            UIAlertView.showWithTitle(NSLocalizedString("Import Pictures", comment: ""),
                message: NSLocalizedString("Please select where to import picture:", comment: ""),
                cancelButtonTitle: NSLocalizedString("Cancel", comment: ""),
                otherButtonTitles: [NSLocalizedString("iTunes file sharing", comment: ""), NSLocalizedString("Photos", comment: ""),],
                tapBlock: { (alertView, index) -> Void in
                    if index == 1 {// iTunes file sharing fold
                        let importViewController = ImportPhotosFromFileSharingViewController()
                        importViewController.importDelegate = self
                        let importNavigationViewController = UINavigationController(rootViewController: importViewController)
                        self.presentViewController(importNavigationViewController, animated: true, completion: nil)
                    } else if index == 2 {// Photo albums
                        let pickerViewController = CTAssetsPickerController()
                        pickerViewController.delegate = self
                        pickerViewController.assetsFilter = ALAssetsFilter.allPhotos()
                        pickerViewController.showsCancelButton = true
                        pickerViewController.showsNumberOfAssets = true
                        pickerViewController.alwaysEnableDoneButton = true
                        self.presentViewController(pickerViewController, animated: true, completion: nil)
                    } else if index == 0 {
                        
                    } else {
                        
                    }
                    alertView.dismissWithClickedButtonIndex(index, animated: true)
            })
        }
    }
    
    @IBAction func editPhotos(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.Began {
            isNowEditing = true
            self.importPhotoButtonItem.enabled = false
            self.navigationController?.setToolbarHidden(false, animated: true)
            //
            UIView.animateWithDuration(0.3, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                self.view.layoutIfNeeded()
                }, completion: nil)
        }
    }
    
    @IBAction func deleteSelectedPhotos(sender: UIBarButtonItem) {
        var indexPaths = [NSIndexPath]()
        var indexs = [Int]()
        var photosToDelete = [Photo]()
        for i in 0..<self.photos.count {
            if self.photosSelected[i] {
                indexs.insert(i, atIndex: 0)
                let section = i / self.numPicturePerRow
                let item = i % self.numPicturePerRow
                indexPaths.append(NSIndexPath(forItem: item, inSection: section))
                photosToDelete.append(self.photos[i] as! Photo)
            }
        }
        
        // 未选择需要删除的照片,提示
        if indexs.count == 0 {
            let title = NSLocalizedString("Tip", comment: "")
            let message = NSLocalizedString("Please select at least 1 picture!", comment: "")
            let otherButtonsTitle = [NSLocalizedString("OK", comment: "")]
            UIAlertView.showWithTitle(title,
            message:message,
            style: UIAlertViewStyle.Default,
            cancelButtonTitle: nil,
            otherButtonTitles: otherButtonsTitle) { (alertView, index) -> Void in
                alertView.dismissWithClickedButtonIndex(index, animated: true)
            }
            return;
        }
        
        // 提示
        let title = NSLocalizedString("Tip", comment: "")
        let message = NSLocalizedString("Deleted pictures can not be recovered! Do you want to delete these pictures?", comment: "")
        let cancelButtonTitle = NSLocalizedString("Cancel", comment: "")
        let otherButtonsTitle = [NSLocalizedString("Delete", comment: "")]
        UIAlertView.showWithTitle(title,
        message:message,
        style: UIAlertViewStyle.Default,
        cancelButtonTitle: cancelButtonTitle,
        otherButtonTitles: otherButtonsTitle) { (alertView, index) -> Void in
            if index == 0 {
                //
            } else if index == 1 {
                // 删除数据库中对应条目
                DBMasterKey.deleteObjects(photosToDelete)
                // 删除文件 原图+缩略图
                let fileManager = NSFileManager.defaultManager()
                for photo in photosToDelete {
                    fileManager.removeItemAtPath(PictureFoldPath.stringByAppendingPathComponent(photo.originalFilename), error: nil)
                    fileManager.removeItemAtPath(ThumbnailFoldPath.stringByAppendingPathComponent(photo.thumbnailFilename), error: nil)
                }
                // 删除collectionView数据源中对应条目
                for i in indexs {
                    self.photos.removeAtIndex(i)
                    self.photosSelected.removeAtIndex(i)
                }
                // 刷新视图
                self.collectionView.reloadData()
            }
            alertView.dismissWithClickedButtonIndex(index, animated: true)
        }
        
    }
    
    @IBAction func done(sender: UIBarButtonItem) {
        // 将所有图片重置为未选择
        for i in 0..<photosSelected.count {
            if photosSelected[i] {
                let section = i / self.numPicturePerRow
                let item = i % self.numPicturePerRow
                let cell = self.collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: item, inSection: section))
                cell?.alpha = 1.0
                // 重置
                photosSelected[i] = false
            }
        }
        self.navigationController?.setToolbarHidden(true, animated: true)
        //
        collectionViewBottomMargin.constant = 0
        UIView.animateWithDuration(0.3, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                self.view.layoutIfNeeded()
            }) { (finished) -> Void in
                self.isNowEditing = false
                self.importPhotoButtonItem.enabled = true
        }
    }
    
    // MARK: - Funcitons
    
    func imageWithImage(image:UIImage, scaledToFillSize size:CGSize) -> UIImage {
        let scale = max(size.width / image.size.width, size.height / image.size.height)
        let width = image.size.width * scale
        let height = image.size.height * scale
        let imageRect = CGRectMake((size.width - width) / 2.0, (size.height - height) / 2.0, width, height)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        image.drawInRect(imageRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    // MARK: - Navigation
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        return !isNowEditing
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == SegueIdentifierShowPhotos {
            let indexPath = sender as! NSIndexPath
            let destViewController = segue.destinationViewController as! PhotoDisplayViewController
            destViewController.photos = photos
            destViewController.currentPhotoIndex = indexPath.section * numPicturePerRow + indexPath.row
        }
    }
    
    // MARK: UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        self.hintImageView.hidden = (photos.count != 0)
        return Int(ceil(Float(photos.count) / Float(numPicturePerRow)))
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section * numPicturePerRow + numPicturePerRow > photos.count {
            return photos.count - section * numPicturePerRow
        } else {
            return numPicturePerRow
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! UICollectionViewCell
        
        let index = indexPath.section * numPicturePerRow + indexPath.row
        let photo = photos[index] as! Photo
        
        var thumbnailData = NSData(contentsOfFile: ThumbnailFoldPath.stringByAppendingPathComponent(photo.thumbnailFilename))
        thumbnailData = thumbnailData?.decryptAndDcompress(thumbnailData)
        let thumbnail = UIImage(data: thumbnailData!)
        
        let imageView = cell.viewWithTag(2014) as! UIImageView
        imageView.image = thumbnail ?? UIImage(named: "PHOTO64")
        imageView.frame = cell.bounds
        
        if photosSelected[index] {
            cell.alpha = 0.3
        } else {
            cell.alpha = 1.0
        }
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if isNowEditing {
            let index = indexPath.section * numPicturePerRow + indexPath.row
            photosSelected[index] = !photosSelected[index]
            self.collectionView.cellForItemAtIndexPath(indexPath)?.alpha = photosSelected[index] ? 0.3 : 1.0
        } else {
            self.performSegueWithIdentifier(SegueIdentifierShowPhotos, sender: indexPath)
        }
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return cellSize
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return self.insectForCell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return self.insectForCell.top
    }
    
    // MARK: - CTAssetsPickerControllerDelegate
    
    func assetsPickerController(picker: CTAssetsPickerController!, didFinishPickingAssets assets: [AnyObject]!) {
        
        // 用户没有选择图片时,提示用户
        if assets.count == 0 {
            let title = NSLocalizedString("Tip", comment: "")
            let message = NSLocalizedString("Please select at least 1 picture!", comment: "")
            let otherButtonsTitle = [NSLocalizedString("OK", comment: "")]
            UIAlertView.showWithTitle(title,
            message:message,
            style: UIAlertViewStyle.Default,
            cancelButtonTitle: nil,
            otherButtonTitles: otherButtonsTitle) { (alertView, index) -> Void in
                alertView.dismissWithClickedButtonIndex(index, animated: true)
            }
            return;
        }
        
        // 字符串格式化器
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        // 显示正在处理
        SVProgressHUD.showProgress(0, status: NSLocalizedString("Processing^_^", comment: ""))
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        
        // 退出图片选择控制器
        picker.dismissViewControllerAnimated(true, completion: { () -> Void in
            self.delegate.setNeedReloadAlbumsTable()
        })
        
        let globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
        dispatch_async(globalQueue, { () -> Void in
            // 获取已选图片->压缩&加密->复制到APP的文件夹目录->记录到数据库
            let fm = NSFileManager.defaultManager()
            var pictureData: NSData!
            var thumbnailData: NSData!
            var pictureProcessedOK: Bool = false
            var thumbnailProcessedOK: Bool = false
            var buffer: UnsafeMutablePointer<UInt8>!
            
            var index = 0
            var errorOccours = false
            var photo: Photo!
            for asset in assets as! [ALAsset] {
                autoreleasepool({ () -> () in
                    // 新建Photo对象
                    photo = Photo()
                    photo.createdTime = NSNumber(double: NSDate.timeIntervalSinceReferenceDate())
                    photo.name = dateFormatter.stringFromDate(asset.valueForProperty(ALAssetPropertyDate) as! NSDate)//用日期作为名称
                    photo.originalFilename = String(format: "%lf", photo.createdTime.doubleValue)
                    photo.thumbnailFilename = photo.originalFilename
                    photo.albumCreatedTime = self.album.createdTime
                    // 获取图片NSData
                    let representation = asset.defaultRepresentation()
                    let l = Int(representation.size())
                    buffer = UnsafeMutablePointer<UInt8>.alloc(l)
                    let length = representation.getBytes(buffer, fromOffset: 0, length: l, error: nil)
                    pictureData = NSData(bytes: buffer, length: length)
                    buffer.dealloc(l)
                    
                    // 获取缩略图NSData
                    var pictureImage = UIImage(data: pictureData)!
                    pictureImage = UIImage.fixOrientation(pictureImage)
                    let image = self.imageWithImage(pictureImage, scaledToFillSize: self.cellSize)
                    thumbnailData = UIImagePNGRepresentation(image)
                    if thumbnailData == nil {
                        thumbnailData = UIImageJPEGRepresentation(image, 1.0)
                    }
                    
                    // 压缩&加密 NSData
                    pictureData = pictureData.compressAndEncrypt(pictureData)
                    thumbnailData = thumbnailData.compressAndEncrypt(thumbnailData)
                    // 保存指定文件路径下
                    pictureProcessedOK = fm.createFileAtPath(PictureFoldPath.stringByAppendingPathComponent(photo.originalFilename), contents: pictureData, attributes: nil)
                    thumbnailProcessedOK = fm.createFileAtPath(ThumbnailFoldPath.stringByAppendingPathComponent(photo.thumbnailFilename), contents: thumbnailData, attributes: nil)
                    // 检查是否成功保存文件
                    if pictureProcessedOK && thumbnailProcessedOK {
                        // 将数据写入数据库,添加到photos数组
                        if !DBMasterKey.add(photo) {
                            errorOccours = true
                        }
                        self.photos.append(photo)
                        self.photosSelected.append(false)
                    } else {
                        errorOccours = true
                    }
                })
                index++
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    SVProgressHUD.showProgress(Float(index)/Float(assets.count), status: NSLocalizedString("Processing^_^", comment: ""))
                })
            }
            
            // 确定该相册是否有icon,如果没有的话,将最后一张图片的缩略图作为相册icon
            if self.album.icon == EmptyAlbumIconName {
                self.album.icon = photo.thumbnailFilename
                DBMasterKey.update(self.album)
            }
            
            // 若发生错误,(保存数据到数据库,或者保存图片到应用的文件夹下)时发生的错误, 提示用户
            if errorOccours {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    SVProgressHUD.dismiss()
                    UIApplication.sharedApplication().endIgnoringInteractionEvents()
                    self.collectionView.reloadData()
                })
                let title = NSLocalizedString("Tip", comment: "")
                let message = NSLocalizedString("Error occurs", comment: "")
                let otherButtonsTitle = [NSLocalizedString("OK", comment: "")]
                UIAlertView.showWithTitle(title,
                    message:message,
                    style: UIAlertViewStyle.Default,
                    cancelButtonTitle: nil,
                    otherButtonTitles: otherButtonsTitle) { (alertView, index) -> Void in
                        alertView.dismissWithClickedButtonIndex(index, animated: true)
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    // 显示处理完成
                    SVProgressHUD.showSuccessWithStatus(NSLocalizedString("Done", comment: ""))
                    UIApplication.sharedApplication().endIgnoringInteractionEvents()
                    self.collectionView.reloadData()
                })
            }
        })
    }
    
    func assetsPickerControllerDidCancel(picker: CTAssetsPickerController!) {
    }

    // MARK: - ImportPhotosFromFileSharingViewControllerDelegate
    
    func importPhotosFromFileSharingViewController(importViewController: ImportPhotosFromFileSharingViewController, hasFinishedPickFiles files: [String]) {
        // 显示正在处理
        SVProgressHUD.showProgress(0, status: NSLocalizedString("Processing^_^", comment: ""))
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        
        // 退出图片选择控制器
        importViewController.dismissViewControllerAnimated(true, completion: { () -> Void in
            self.delegate.setNeedReloadAlbumsTable()
        })
        
        let globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
        dispatch_async(globalQueue, { () -> Void in
            // 获取已选图片->压缩&加密->复制到APP的文件夹目录->记录到数据库
            let fm = NSFileManager()
            var pictureData: NSData!
            var thumbnailData: NSData!
            var pictureProcessedOK: Bool = false
            var thumbnailProcessedOK: Bool = false
            var buffer: UnsafeMutablePointer<UInt8>!
            
            var index = 0
            var photo: Photo!
            var errorOccours = false
            for file in files {
                autoreleasepool({ () -> () in
                    // 新建Photo对象
                    photo = Photo()
                    photo.createdTime = NSNumber(double: NSDate.timeIntervalSinceReferenceDate())
                    photo.name = "\(photo.createdTime.doubleValue)"
                    photo.originalFilename = String(format: "%lf", photo.createdTime.doubleValue)
                    photo.thumbnailFilename = photo.originalFilename
                    photo.albumCreatedTime = self.album.createdTime
                    // 获取图片NSData
                    pictureData = NSData(contentsOfFile: file)
                    // 获取缩略图NSData
                    let originalImage = UIImage(data: pictureData)!
                    let image = self.imageWithImage(originalImage, scaledToFillSize: self.cellSize)
                    thumbnailData = UIImagePNGRepresentation(image)
                    if thumbnailData == nil {
                        thumbnailData = UIImageJPEGRepresentation(image, 1.0)
                    }
                    
                    // 压缩&加密 NSData
                    pictureData = pictureData.compressAndEncrypt(pictureData)
                    thumbnailData = thumbnailData.compressAndEncrypt(thumbnailData)
                    // 保存指定文件路径下
                    pictureProcessedOK = fm.createFileAtPath(PictureFoldPath.stringByAppendingPathComponent(photo.originalFilename), contents: pictureData, attributes: nil)
                    if thumbnailData != nil {
                        thumbnailProcessedOK = fm.createFileAtPath(ThumbnailFoldPath.stringByAppendingPathComponent(photo.thumbnailFilename),
                            contents: thumbnailData, attributes: nil)
                    }
                    // 检查是否成功保存文件
                    if pictureProcessedOK && thumbnailProcessedOK {
                        // 将数据写入数据库,添加到photos数组
                        if !DBMasterKey.add(photo) {
                            errorOccours = true
                        }
                        self.photos.append(photo)
                        self.photosSelected.append(false)
                        // 删除文件
                        //testing//fm.removeItemAtPath(file, error: nil)
                    } else {
                        errorOccours = true
                    }
                })
                index++
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    SVProgressHUD.showProgress(Float(index)/Float(files.count), status: NSLocalizedString("Processing^_^", comment: ""))
                })
            }
            
            // 确定该相册是否有icon,如果没有的话,将最后一张图片的缩略图作为相册icon
            if self.album.icon == EmptyAlbumIconName {
                self.album.icon = photo.thumbnailFilename
                DBMasterKey.update(self.album)
            }
            
            // 若发生错误,(保存数据到数据库,或者保存图片到应用的文件夹下)时发生的错误, 提示用户
            if errorOccours {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    SVProgressHUD.dismiss()
                    UIApplication.sharedApplication().endIgnoringInteractionEvents()
                    self.collectionView.reloadData()
                })
                let title = NSLocalizedString("Tip", comment: "")
                let message = NSLocalizedString("Error occurs", comment: "")
                let otherButtonsTitle = [NSLocalizedString("OK", comment: "")]
                UIAlertView.showWithTitle(title,
                    message:message,
                    style: UIAlertViewStyle.Default,
                    cancelButtonTitle: nil,
                    otherButtonTitles: otherButtonsTitle) { (alertView, index) -> Void in
                        alertView.dismissWithClickedButtonIndex(index, animated: true)
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    // 显示处理完成
                    SVProgressHUD.showSuccessWithStatus(NSLocalizedString("Done", comment: ""))
                    UIApplication.sharedApplication().endIgnoringInteractionEvents()
                    self.collectionView.reloadData()
                })
            }
        })
    }
    
}
