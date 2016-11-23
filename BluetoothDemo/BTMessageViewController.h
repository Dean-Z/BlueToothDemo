//
//  BTMessageViewController.h
//  BlueTouchDemo
//
//  Created by Z on 2016/11/21.
//  Copyright © 2016年 BT. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BabyBluetooth.h"
#import "SVProgressHUD.h"

@interface BTMessageViewController : UIViewController

@property (nonatomic , strong) CBCharacteristic *character;
@property (nonatomic , strong) CBPeripheral *peripheral;

@end
