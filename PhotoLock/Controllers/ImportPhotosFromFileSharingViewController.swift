//
//  ImportPhotosFromITunesFileSharingDirectoryTableViewController.swift
//  PhotoLock
//
//  Created by 泉华 官 on 14/12/26.
//  Copyright (c) 2014年 CQMH. All rights reserved.
//

import UIKit

protocol ImportPhotosFromFileSharingViewControllerDelegate {
    func importPhotosFromFileSharingViewController(vc:ImportPhotosFromFileSharingViewController, hasFinishedPickFiles files:[String])
}

class ImportPhotosFromFileSharingViewController: UITableViewController {

    // MARK: - Views
    var doneButtonItem :UIBarButtonItem!
    
    // MARK: - Vars
    var importDelegate: ImportPhotosFromFileSharingViewControllerDelegate!
    var photos: [String]!
    
    var timerForRefresh: NSTimer!
    
    // MARK: - View Did Load
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Pictures", comment: "")
        doneButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "importFiles")
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: "refreshFiles"), doneButtonItem]
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancel")
        
        // 读取Document目录下的图片文件
        self.refreshFiles()
        
        timerForRefresh = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "timerHandler", userInfo: nil, repeats: true)
    }
    
    func timerHandler() {
        self.refreshFiles()
    }
    
    // MARK: - Actions
    
    func importFiles() {
        self.timerForRefresh.invalidate()
        self.timerForRefresh = nil
        
        self.refreshFiles()
        
        self.importDelegate.importPhotosFromFileSharingViewController(self, hasFinishedPickFiles: photos)
    }
    
    func refreshFiles() {
        self.refresh()
        self.tableView.reloadData()
    }
    
    func refresh() {
        // 读取Document目录下的图片文件
        let fileManager = NSFileManager.defaultManager()
        photos = (fileManager.subpathsAtPath(FileSharingFoldPath) ?? []) as! [String]
        
        // 忽略非.png/.jpeg文件
        var toDelete = [Int]()
        for i in 0..<photos.count {
            if !(photos[i].hasSuffix(".png") || photos[i].hasSuffix(".PNG")
                || photos[i].hasSuffix(".JPEG") || photos[i].hasSuffix(".jpeg")
                || photos[i].hasSuffix(".jpg") || photos[i].hasSuffix(".JPG")) {
                toDelete.append(Int(i))
            }
        }
        while toDelete.count > 0 {
            photos.removeAtIndex(toDelete.last!)
            toDelete.removeLast()
        }
        
        photos = photos.map {FileSharingFoldPath + "/\($0)"}
        self.doneButtonItem.enabled = (photos.count > 0)
    }
    
    func cancel() {
        if self.navigationController == nil {
            self.dismissViewControllerAnimated(true, completion: nil)
        } else {
            self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    // MARK: - Functions
    
    // MARK: - Override
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let reuseIdentifier = "reuseIdentifier"
        var cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as? UITableViewCell
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: reuseIdentifier)
            cell?.accessoryType = UITableViewCellAccessoryType.Checkmark
        }
        
        cell?.textLabel?.text = photos[indexPath.row].lastPathComponent
        
        return cell!
    }

}
