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
private let defaultPass = "1000000000000000000000000000";

class AuthenticationViewController: UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    
    var passwords: [Bool]!
    var passwordsInput: [Bool]!
    var user: User!
    @IBOutlet weak var defaultPasswordButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let results = DBMasterKey.findInTable(User.self, whereField: "username", equalToValue: "root")
        if results == nil {
            user = User()
            user.username = "root"
            user.password = (defaultPass as NSString).AES256EncryptWithKey(passwordForEncryptPassword)
            DBMasterKey.add(user)
        } else {
            user = results.firstObject as! User
        }
        user.password = (user.password as NSString).AES256DecryptWithKey(passwordForEncryptPassword)
        
        passwords = [Bool]()
        passwordsInput = [Bool]()
        
        for (i, flag) in enumerate(user.password) {
            passwordsInput.append(false)
            passwords.append(flag == "0" ? false : true)
            containerView.viewWithTag(9000 + i + 1)?.backgroundColor = UIColor.randomColor(alpha: alpha)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if (user.password == defaultPass) {
            defaultPasswordButton.setImage(UIImage(named: "tapGesture"), forState: .Normal)
        } else {
            defaultPasswordButton.setImage(nil, forState: .Normal)
        }
    }
        
    func updatePassword(pws: [Bool]!) {
        self.passwords = pws
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func passwordInputChanged(sender: UIButton) {
        let index = sender.tag - 9000 - 1// 0...27
        passwordsInput[index] = !passwordsInput[index]
        sender.backgroundColor = passwordsInput[index] ? showColor : UIColor.randomColor(alpha: alpha)
        
        UIView.animateWithDuration(0.5, delay: 0, options: UIViewAnimationOptions.CurveLinear | UIViewAnimationOptions.AllowUserInteraction | UIViewAnimationOptions.BeginFromCurrentState, animations: { () -> Void in
            for i in 1...self.passwords.count {
                if self.passwordsInput[i - 1] == false && i != index + 1 {
                    self.containerView.viewWithTag(9000 + i)?.backgroundColor = UIColor.randomColor(alpha: alpha)
                }
            }
        }, completion: nil)
        
        self.checkPassword()
    }
    
    func checkPassword() {
        for i in 0..<passwords.count {
            if passwords[i] != passwordsInput[i] {
                return;
            }
        }
        
        if passwordInterfaceShown {
            self.dismissViewControllerAnimated(true, completion: {[unowned self] () -> Void in
                passwordInterfaceShown = false
                for i in 1...self.passwords.count {
                    if self.passwordsInput[i - 1] {
                        self.passwordsInput[i - 1] = false
                        self.containerView.viewWithTag(9000 + i)?.backgroundColor = UIColor.randomColor(alpha: alpha)
                    }
                }
            })
        } else {
            self.performSegueWithIdentifier(SegueIdentifierShowMainMenu, sender: nil)
        }
        
        self.showAllert()
    }
    
    func showAllert() {
        if (user.password == defaultPass) {
            UIAlertView(title: NSLocalizedString("Tip", comment: ""), message: NSLocalizedString("Please change your password ASAP!", comment: ""), delegate: nil, cancelButtonTitle: NSLocalizedString("OK", comment: "")).show()
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
