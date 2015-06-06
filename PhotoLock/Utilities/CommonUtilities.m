//
//  CommonUtilities.m
//  PhotoLock
//
//  Created by 泉华 官 on 14/12/30.
//  Copyright (c) 2014年 CQMH. All rights reserved.
//

#import "CommonUtilities.h"
#import <UIKit/UIKit.h>
#import <notify.h>
#import "PhotoLock-Swift.h"

#define NotificationLock CFSTR("com.apple.springboard.lockcomplete")
#define NotificationChange CFSTR("com.apple.springboard.lockstate")
#define NotificationPwdUI CFSTR("com.apple.springboard.hasBlankedScreen")

@implementation CommonUtilities

static void screenLockStateChanged(CFNotificationCenterRef center,void* observer,CFStringRef name,const void* object,CFDictionaryRef userInfo)
{
    NSString* lockstate = (__bridge NSString*)name;
    if ([lockstate isEqualToString:(__bridge  NSString*)NotificationLock]) {
        [[UIApplication sharedApplication].delegate performSelector:@selector(showPasswordInterface)];
    }
}

+(void)observerLockEvents {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, screenLockStateChanged, NotificationLock, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, screenLockStateChanged, NotificationChange, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, screenLockStateChanged, NotificationPwdUI, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}

@end
