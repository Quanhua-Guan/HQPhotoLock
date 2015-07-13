//
//  PhotoLockTableViewController.swift
//  PhotoLock
//
//  Created by 泉华 官 on 14/12/18.
//  Copyright (c) 2014年 CQMH. All rights reserved.
//

import UIKit

class PhotoLockTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, PhotosCollectionViewControllerDelegate, UIAlertViewDelegate, GADBannerViewDelegate {

    // MARK: - Vars
    @IBOutlet weak var tableView: UITableView!
    var albums: [AnyObject]!
    var hintImageView: UIImageView!
    var shouldReloadTable: Bool = false
    private var album: Album!
    @IBOutlet weak var bannerView: GADBannerView!
    @IBOutlet weak var hideAdButton: UIButton!
    @IBOutlet weak var adViewBottomMargin: NSLayoutConstraint!
    
    // MARK: - ViewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        // testing start
//        let fm = NSFileManager.defaultManager()
//        for i in 1...32 {
//            let imagePath = NSBundle.mainBundle().pathForResource("\(i)", ofType: "png")!
//            let imageDesPath = FileSharingFoldPath + "/\(i).png"
//            if !fm.fileExistsAtPath(imageDesPath) {
//                fm.copyItemAtPath(imagePath, toPath: imageDesPath, error: nil)
//            }
//        }
//        // testing end
        
        hintImageView = UIImageView(image: UIImage(named:"AlbumsHintImage"))
        hintImageView.frame = CGRectMake(0, 50, self.view.bounds.size.width, self.view.bounds.size.width)
        hintImageView.contentMode = UIViewContentMode.ScaleAspectFit
        hintImageView.alpha = 0.75
        self.view.addSubview(hintImageView)
        
        let theAlbums: AnyObject? = DBMasterKey.getAll(Album.self)
        albums = (theAlbums ?? []) as! [AnyObject]
        
        // AdMob
        if HideAD == false {
            AdMob.showAdInView(self.bannerView, inViewController: self)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.shouldReloadTable {
            self.tableView.reloadData()
            self.shouldReloadTable = false
        }
        
        if HideAD {
            adViewBottomMargin.constant = -50
            UIView.animateWithDuration(1, animations: { () -> Void in
                self.view.layoutIfNeeded()
            })
        } else {
            adViewBottomMargin.constant = 0
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.setToolbarHidden(true, animated: true)
    }

    // MARK: - Table view data source / delegate

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.hintImageView.hidden = (albums.count > 0)
        self.tableView.hidden = !self.hintImageView.hidden
        return albums.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("PhotoLockTableViewCell", forIndexPath: indexPath) as! UITableViewCell
        if cell.gestureRecognizers == nil || cell.gestureRecognizers!.count == 0 {
            cell.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: "renameWithLongPress:"));
        }
        
        let album = albums[indexPath.row] as! Album
        let text = cell.viewWithTag(1002) as! UILabel
        text.text = album.name
        let imageView = cell.viewWithTag(1001) as! UIImageView
        
        if album.icon == EmptyAlbumIconName {
            imageView.image = UIImage(named: "PHOTO64")
        } else {
            var thumbnailData = NSData(contentsOfFile: ThumbnailFoldPath.stringByAppendingPathComponent(album.icon))
            if thumbnailData != nil {
                thumbnailData = thumbnailData?.decryptAndDcompress(thumbnailData)
                let thumbnail = UIImage(data: thumbnailData!) ?? UIImage(named: "PHOTO64")
                imageView.image = thumbnail
            } else {
                imageView.image = UIImage(named: "PHOTO64")
                album.icon = EmptyAlbumIconName
                DBMasterKey.update(album)
            }
        }
        
        cell.contentView.layoutIfNeeded()
        
        return cell
    }

    // Override to support conditional editing of the table view.
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if albums.count > 0 {
            return true
        } else {
            return false
        }
    }

    // Override to support editing the table view.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            
            let title = NSLocalizedString("Tip", comment: "")
            let message = NSLocalizedString("Delete album will also delete photos in it, which cannot be recovered! Do you want to delete this album?", comment: "")
            let cancelButtonTitle = NSLocalizedString("Cancel", comment: "")
            let otherButtonsTitle = [NSLocalizedString("Delete", comment: "")]
            UIAlertView.showWithTitle(title, message: message,
                style: UIAlertViewStyle.Default,
                cancelButtonTitle: cancelButtonTitle,
                otherButtonTitles: otherButtonsTitle) { (alertView, index) -> Void in
                    if index == 0 {
                    } else if index == 1 {
                        // Delete the row from the data source
                        let album = self.albums[indexPath.row] as! Album
                        DBMasterKey.delete(album)
                        self.albums.removeAtIndex(indexPath.row)
                        //
                        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
                       
                        alertView.dismissWithClickedButtonIndex(index, animated: true)
                        
                        SVProgressHUD.showWithStatus(NSLocalizedString("Processing^_^", comment: ""))
                        
                        let globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
                        dispatch_async(globalQueue, { () -> Void in
                            // 删除对应相册下的所有图片,在文件系统中删除对应的图片
                            let photos = DBMasterKey.findInTable(Photo.self, whereField: Photo.foreignKeys().first as! String, equalToValue: album.createdTime) ?? NSMutableArray()
                            // 删除数据库对应条目4
                            var index = 0
                            DBMasterKey.deleteObjects(photos as [AnyObject])
                            for photo in photos {
                                // 删除文件  原图+缩略图
                                NSFileManager.defaultManager().removeItemAtPath(PictureFoldPath.stringByAppendingPathComponent(photo.originalFilename), error: nil)
                                NSFileManager.defaultManager().removeItemAtPath(ThumbnailFoldPath.stringByAppendingPathComponent(photo.thumbnailFilename), error: nil)
                                //
                                index++
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    SVProgressHUD.showProgress(Float(index)/Float(photos.count), status: NSLocalizedString("Processing^_^", comment: ""))
                                })
                            }
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                // 显示处理完成
                                SVProgressHUD.showSuccessWithStatus(NSLocalizedString("Done", comment: ""))
                            })
                        })
                    }
            }
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
       
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80.0
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = UIColor(white: 1.0, alpha: 0.26)
    }
        
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == SegueIdentifierShowAlbum {
            let indexPath = self.tableView.indexPathForCell(sender as! UITableViewCell)!
            let destViewController = segue.destinationViewController as! PhotosCollectionViewController
            destViewController.album = albums[indexPath.row] as! Album
            destViewController.title = destViewController.album.name
            destViewController.delegate = self
        } else if segue.identifier == SegueIdentifierGoSettings {
            //
        }
    }
    
    // MARK: - IBActions

    @IBAction func addAlbum(sender: UIBarButtonItem) {
        let title = NSLocalizedString("New album", comment: "");
        let message = NSLocalizedString("Please enter album name", comment: "");
        let cancelString = NSLocalizedString("Cancel", comment: "");
        let otherString = NSLocalizedString("OK", comment: "");
        UIAlertView.showWithTitle(title, message: message, style: UIAlertViewStyle.PlainTextInput, cancelButtonTitle: cancelString, otherButtonTitles: [otherString]) { (alertView, index) -> Void in
            if index == 0 {
            } else if index == 1 {
                let albumName = alertView.textFieldAtIndex(0)?.text ?? ""
                var album = Album()
                album.createdTime = NSNumber(double: NSDate.timeIntervalSinceReferenceDate())
                album.name = albumName
                album.icon = EmptyAlbumIconName
                //
                DBMasterKey.add(album)
                self.albums.insert(album, atIndex: 0)
                //
                self.tableView.reloadData()
            }
            alertView.dismissWithClickedButtonIndex(index, animated: true)
        }
    }
    
    func renameWithLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .Began {
            let title = NSLocalizedString("Rename album", comment: "");
            let message = NSLocalizedString("Please enter new album name", comment: "");
            let cancelString = NSLocalizedString("Cancel", comment: "");
            let otherString = NSLocalizedString("OK", comment: "");
            let alertView = UIAlertView(title: title, message: message, delegate: self, cancelButtonTitle: cancelString, otherButtonTitles: otherString)
            alertView.alertViewStyle = UIAlertViewStyle.PlainTextInput
            
            let row = self.tableView.indexPathForCell(sender.view as! UITableViewCell)?.row;
            album = self.albums[row!] as! Album
            alertView.textFieldAtIndex(0)?.text = album.name
            alertView.show()
        }
    }
    
    @IBAction func hideAD(sender: UIButton) {
        var message:String!
        message = String(format: NSLocalizedString("Share THIS %d times to remove AD!", comment:""), SharingTimesNeededForHideAD - SharingTimes)
        UIAlertView.showWithTitle("Tip", message: message, cancelButtonTitle: NSLocalizedString("Cancel", comment: ""), otherButtonTitles: [NSLocalizedString("OK", comment: "")]) { (alert, index) -> Void in
            if index == 1 {
                self.performSegueWithIdentifier(SegueIdentifierGoSettings, sender: sender)
            }
            alert.dismissWithClickedButtonIndex(index, animated: true)
        }
    }
    
    // MARK: - UIAlertViewDelegate
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 0 {
        } else if buttonIndex == 1 {
            let albumName = alertView.textFieldAtIndex(0)?.text ?? ""
            album.name = albumName
            //
            DBMasterKey.update(album)
            //
            self.tableView.reloadData()
        }
    }
    
    // MARK: - PhotosCollectionViewControllerDelegate
    
    func setNeedReloadAlbumsTable() {
        self.shouldReloadTable = true
    }
    
    // MARK: - GADBannerViewDelegate
    
    func adViewDidReceiveAd(view: GADBannerView!) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC * 3)), dispatch_get_main_queue()) { () -> Void in
            UIView.animateWithDuration(1.0, animations: { () -> Void in
                self.hideAdButton.alpha = 1.0
            })
        }
    }
    
}
