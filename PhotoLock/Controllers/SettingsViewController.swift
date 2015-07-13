//
//  SettingsViewController.swift
//  PhotoLock
//
//  Created by 泉华 官 on 14/12/18.
//  Copyright (c) 2014年 CQMH. All rights reserved.
//

import UIKit
import Social

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UMSocialUIDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var slComposerSheet:SLComposeViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1;
        } else {
            return 2;
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return (tableView.dequeueReusableCellWithIdentifier("changePassword", forIndexPath: indexPath)) as! UITableViewCell
        } else {
            if indexPath.row == 0 {
                return (tableView.dequeueReusableCellWithIdentifier("rateThis", forIndexPath: indexPath)) as! UITableViewCell
            } else {
                let cell = (tableView.dequeueReusableCellWithIdentifier("shareThis", forIndexPath: indexPath)) as! UITableViewCell
                let label = cell.viewWithTag(1000) as! UILabel
                if SharingTimesNeededForHideAD > SharingTimes {
                    label.text = String(format: NSLocalizedString("Share THIS %d times to remove AD!", comment:""), SharingTimesNeededForHideAD - SharingTimes)
                } else {
                    label.text = NSLocalizedString("Share THIS", comment:"")
                }
                return cell
            }
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "";
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.section == 1 {
            if indexPath.row == 0 {
//                let url = "itms-apps://itunes.apple.com/app/id" + HQAppID
//                if let URL = NSURL(string: url) {
//                    UIApplication.sharedApplication().openURL(URL)
//                }
                iRate.sharedInstance().ratedThisVersion = true
                iRate.sharedInstance().openRatingsPageInAppStore()
            } else {
                // share
                self.showShareLists()
            }
        }
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            cell.backgroundColor = Color(hex: "FF0000", alpha: CGFloat(0.26))
        } else {
            if indexPath.row == 0 {
                cell.backgroundColor = Color(hex: "007AFF", alpha: CGFloat(0.18))
            } else {
                cell.backgroundColor = Color(hex: "007AFF", alpha: CGFloat(0.26))
            }
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return CGFloat(50)
    }
    
    // MARK: - Share
    
    func showShareLists() {
        var sharingText = NSLocalizedString("SharingText", comment:"")
        let sharingImage = UIImage(named: "SharingImage")
        let sharingURL = NSURL(fileURLWithPath: NSLocalizedString("SharingURL", comment: ""))
        let shareToPlatforms = [UMShareToSina,UMShareToTencent, UMShareToFacebook, UMShareToTwitter]
        // facebook
        UMSocialSnsPlatformManager.getSocialPlatformWithName(UMShareToFacebook).snsClickHandler = {(presentingViewController, socialControllerService, isPresentInController) in
            self.slComposerSheet = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
            if self.slComposerSheet != nil {
                self.slComposerSheet.setInitialText(sharingText)
                self.slComposerSheet.addImage(sharingImage)
                self.slComposerSheet.addURL(sharingURL)
                self.presentViewController(self.slComposerSheet, animated: true, completion: nil)
            } else {
                UIAlertView(title: NSLocalizedString("Tip", comment: ""), message: NSLocalizedString("Service unavailable", comment: ""), delegate: nil, cancelButtonTitle: nil, otherButtonTitles: NSLocalizedString("OK", comment: "")).show()
            }
        }
        // Twitter
        UMSocialSnsPlatformManager.getSocialPlatformWithName(UMShareToTwitter).snsClickHandler = {(presentingViewController, socialControllerService, isPresentInController) in
            self.slComposerSheet = SLComposeViewController(forServiceType: UMShareToTwitter)
            if self.slComposerSheet != nil {
                self.slComposerSheet.setInitialText(sharingText)
                self.slComposerSheet.addImage(sharingImage)
                self.slComposerSheet.addURL(sharingURL)
                self.presentViewController(self.slComposerSheet, animated: true, completion: nil)
            } else {
                UIAlertView(title: NSLocalizedString("Tip", comment: ""), message: NSLocalizedString("Service unavailable", comment: ""), delegate: nil, cancelButtonTitle: nil, otherButtonTitles: NSLocalizedString("OK", comment: "")).show()
            }
        }
        
        UMSocialConfig.hiddenNotInstallPlatforms(nil)
        sharingText = NSLocalizedString("SharingURL", comment: "") + " " + sharingText
        UMSocialSnsService.presentSnsIconSheetView(self, appKey: UMAppKey, shareText: sharingText, shareImage: sharingImage, shareToSnsNames: shareToPlatforms, delegate: self)
    }
    
    // 弹出列表方法presentSnsIconSheetView需要设置delegate为self
    func isDirectShareInIconActionSheet() -> Bool {
        return false
    }
    
    // 分享完成
    func didFinishGetUMSocialDataInViewController(response: UMSocialResponseEntity!) {
        if response.responseCode.value == UMSResponseCodeSuccess.value {
            if SharingTimes < SharingTimesNeededForHideAD {
                SharingTimes++
                if SharingTimes >= SharingTimesNeededForHideAD {
                    HideAD = true
                }
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        let actionSheet = self.navigationController?.view.viewWithTag(Int(kTagSocialIconActionSheet)) as? UMSocialIconActionSheet
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            actionSheet?.dismiss()
        })
    }
    
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        let actionSheet = self.navigationController?.view.viewWithTag(Int(kTagSocialIconActionSheet)) as? UMSocialIconActionSheet
        actionSheet?.dismiss()
    }
}
