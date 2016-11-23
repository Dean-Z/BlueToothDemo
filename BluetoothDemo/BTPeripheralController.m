//
//  BTPeripheralController.m
//  BlueTouchDemo
//
//  Created by Z on 2016/11/21.
//  Copyright © 2016年 BT. All rights reserved.
//

#import "BTPeripheralController.h"
#import "BabyBluetooth.h"
#import "SVProgressHUD.h"

@interface BTPeripheralController ()

@property (nonatomic , weak) IBOutlet UITextField *textField;

@property (nonatomic , strong) CBCharacteristic *currentCharacterstic;
@property (nonatomic , strong) BabyBluetooth *baby;
@property (nonatomic , assign) BOOL notifying;

@end

@implementation BTPeripheralController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (IBAction)dismissAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)sendAction:(id)sender {
    if (!self.notifying) {
        [SVProgressHUD showErrorWithStatus:@"Not Notifying"];
        return;
    }
    NSData *data = [self.textField.text dataUsingEncoding:NSUTF8StringEncoding];
    if ([self.baby.peripheralManager updateValue:data forCharacteristic:(CBMutableCharacteristic *)self.currentCharacterstic onSubscribedCentrals:nil]) {
        [SVProgressHUD showSuccessWithStatus:@"发送成功"];
    } else {
        [SVProgressHUD showSuccessWithStatus:@"发送失败"];
    }
}

#pragma mark -

- (void)setup {
    CBMutableService *service = makeCBService(genUUID());
    makeCharacteristicToService(service, genUUID(), @"n", @"Notify service");
    self.baby.bePeripheral().addServices(@[service]).startAdvertising();
    
    [self babyDelegate];
}

- (void)babyDelegate {
    [self.baby peripheralModelBlockOnPeripheralManagerDidUpdateState:^(CBPeripheralManager *peripheral) {
        NSLog(@"peripheralModelBlockOnPeripheralManagerDidUpdateState -- %ld",(long)peripheral.state);
    }];
    
    [self.baby peripheralModelBlockOnDidStartAdvertising:^(CBPeripheralManager *peripheral, NSError *error) {
        NSLog(@"peripheralModelBlockOnDidStartAdvertising -- %ld",(long)peripheral.state);
    }];
    
    [self.baby peripheralModelBlockOnDidReceiveReadRequest:^(CBPeripheralManager *peripheral, CBATTRequest *request) {
        if (request.characteristic.properties & CBAttributePermissionsReadable) {
            NSData *data = request.characteristic.value;
            request.value = data;
            [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
        } else {
            [peripheral respondToRequest:request withResult:CBATTErrorReadNotPermitted];
        }
    }];
    
    [self.baby peripheralModelBlockOnDidReceiveWriteRequests:^(CBPeripheralManager *peripheral, NSArray *requests) {
        CBATTRequest *request = [requests firstObject];
        if (request.characteristic.properties & CBAttributePermissionsWriteable) {
            NSData *data = request.characteristic.value;
            request.value = data;
            [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
        } else {
            [peripheral respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
        }
    }];
    
    __weak typeof(self) weakSelf = self;
    [self.baby peripheralModelBlockOnDidSubscribeToCharacteristic:^(CBPeripheralManager *peripheral, CBCentral *central, CBCharacteristic *characteristic) {
        weakSelf.notifying = YES;
        weakSelf.currentCharacterstic = characteristic;
        NSLog(@"peripheralModelBlockOnDidSubscribeToCharacteristic");
    }];
    
    //设置添加service委托 | set didAddService block
    [self.baby peripheralModelBlockOnDidUnSubscribeToCharacteristic:^(CBPeripheralManager *peripheral, CBCentral *central, CBCharacteristic *characteristic) {
        weakSelf.notifying = NO;
        NSLog(@"peripheralModelBlockOnDidUnSubscribeToCharacteristic");
    }];
}

#pragma mark  - 

- (BabyBluetooth *)baby {
    if (!_baby) {
        _baby = [BabyBluetooth shareBabyBluetooth];
    }
    return _baby;
}

@end
