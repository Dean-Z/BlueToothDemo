//
//  BTMessageViewController.m
//  BlueTouchDemo
//
//  Created by Z on 2016/11/21.
//  Copyright © 2016年 BT. All rights reserved.
//

#import "BTMessageViewController.h"

@interface BTMessageViewController ()

@property (nonatomic , weak) IBOutlet UIButton *notifyButton;

@property (nonatomic , strong) BabyBluetooth *baby;

@end

@implementation BTMessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (IBAction)dismissAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)notifyAction:(id)sender {
    [self.notifyButton setTitle:self.character.isNotifying?@"开启Notify":@"关闭Notify" forState:UIControlStateNormal];
    if (self.character.isNotifying) {
        [self.baby cancelNotify:self.peripheral characteristic:self.character];
    } else {
        [self.baby notify:self.peripheral characteristic:self.character block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
            NSData *data = characteristics.value;
            NSString *result = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
            [SVProgressHUD showSuccessWithStatus:result];
        }];
    }
}

#pragma mark - 

- (BabyBluetooth *)baby {
    if (!_baby) {
        _baby = [BabyBluetooth shareBabyBluetooth];
    }
    return _baby;
}

@end
