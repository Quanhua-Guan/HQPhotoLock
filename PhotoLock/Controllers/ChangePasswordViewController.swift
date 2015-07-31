//
//  AuthenticationViewController.swift
//  PhotoLock
//
//  Created by 泉华 官 on 14/12/28.
//  Copyright (c) 2014年 CQMH. All rights reserved.
//

import UIKit

private let alpha = 0.06 as CGFloat
private let showColor = UIColor(red: 252.0 / 255.0, green: 72.0 / 255.0, blue: 72.0 / 255.0, alpha: 0.70)

class ChangePasswordViewController: UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var isInputingOldPassword = true
    var passwords: [Bool]!
    var passwordsInput: [Bool]!
    var user: User!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.saveButton.enabled = false
        
        let results = DBMasterKey.findInTable(User.self, whereField: "username", equalToValue: "root")!
        user = results.firstObject as! User
        user.password = (user.password as NSString).AES256DecryptWithKey(passwordForEncryptPassword)
        
        passwords = [Bool]()
        passwordsInput = [Bool]()
        
        for (i, flag) in enumerate(user.password) {
            passwordsInput.append(false)
            passwords.append(flag == "0" ? false : true)
            containerView.viewWithTag(9000 + i + 1)?.backgroundColor = UIColor.randomColor(alpha: alpha)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        var title = NSLocalizedString("Old Password", comment: "")
        var message = NSLocalizedString("Please enter your old password", comment: "")
        if self.isInputingOldPassword {
            title = NSLocalizedString("Old Password", comment: "")
            message = NSLocalizedString("Please enter your old password", comment: "")
        } else {
            title = NSLocalizedString("New Password", comment: "")
            message = NSLocalizedString("Please enter your new password", comment: "")
        }
        let otherButtonsTitle = [NSLocalizedString("OK", comment: "")]
        UIAlertView.showWithTitle(title,
        message:message,
        style: UIAlertViewStyle.Default,
        cancelButtonTitle: nil,
        otherButtonTitles: otherButtonsTitle) { (alertView, index) -> Void in
            alertView.dismissWithClickedButtonIndex(index, animated: true)
            self.isInputingOldPassword = true
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func passwordInputChanged(sender: UIButton) {
        let index = sender.tag - 9000 - 1// 0...27
        passwordsInput[index] = !passwordsInput[index]
        sender.backgroundColor = passwordsInput[index] ? showColor : UIColor.randomColor(alpha: alpha)
        if self.isInputingOldPassword {
            self.checkPassword()
        }
    }
    
    func checkPassword() {
        for i in 0..<passwords.count {
            if passwords[i] != passwordsInput[i] {
                return;
            }
        }
        
        let title = NSLocalizedString("New Password", comment: "")
        let message = NSLocalizedString("Please enter your new password", comment: "")
        let otherButtonsTitle = [NSLocalizedString("OK", comment: "")]
        UIAlertView.showWithTitle(title,
            message:message,
            style: UIAlertViewStyle.Default,
            cancelButtonTitle: nil,
            otherButtonTitles: otherButtonsTitle) {[unowned self] (alertView, index) -> Void in
                alertView.dismissWithClickedButtonIndex(index, animated: true)
                self.isInputingOldPassword = false
                self.saveButton.enabled = true
                
                for i in 1...self.passwords.count {
                    self.passwordsInput[i - 1] = false
                    self.containerView.viewWithTag(9000 + i)?.backgroundColor = UIColor.randomColor(alpha: alpha)
                }
        }
    }
    
    @IBAction func savePassword(sender: UIBarButtonItem) {
        let title = NSLocalizedString("Tip", comment: "")
        let message = NSLocalizedString("Do you remember your new passwod?", comment: "")
        let cancelTitle = NSLocalizedString("NO, Wait!", comment: "")
        let otherButtonsTitle = [NSLocalizedString("YES, Save it!", comment: "")]
        UIAlertView.showWithTitle(title,
            message:message,
            style: UIAlertViewStyle.Default,
            cancelButtonTitle: cancelTitle,
            otherButtonTitles: otherButtonsTitle) {[unowned self] (alertView, index) -> Void in
                if index == 0 {
                    // do nothing
                } else if index == 1 {
                    var password = ""
                    for flag in self.passwordsInput {
                        if flag {
                            password += "1"
                        } else {
                            password += "0"
                        }
                    }
                    self.user.password = (password as NSString).AES256EncryptWithKey(passwordForEncryptPassword)
                    DBMasterKey.update(self.user)
                    
                    // 更新验证视图的密码
                    authenticationViewController.updatePassword(self.passwordsInput)
                    
                    // 退出
                    alertView.dismissWithClickedButtonIndex(index, animated: true)
                    self.navigationController?.popViewControllerAnimated(true)
                }
        }
    }
    
}

