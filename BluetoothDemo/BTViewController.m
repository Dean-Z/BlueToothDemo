//
//  BTViewController.m
//  BlueTouchDemo
//
//  Created by Z on 2016/11/21.
//  Copyright © 2016年 BT. All rights reserved.
//

#import "BTViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "BabyBluetooth.h"
#import "SVProgressHUD.h"

#import "BTMessageViewController.h"

static NSString *kChannelOnPeripheralView = @"kChannelOnPeripheralView";

@interface BTViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic , weak) IBOutlet UITableView *tableView;
@property (nonatomic , weak) IBOutlet UIActivityIndicatorView *indicationView;

@property (nonatomic , strong) NSMutableArray *peripherals;
@property (nonatomic , strong) NSMutableArray *peripheralsAD;

@property (nonatomic , strong) BabyBluetooth *baby;
@property (nonatomic , strong) CBPeripheral *currentPeripheral;
@property (nonatomic , strong) CBCharacteristic *notifyCharacterstic;
@property (nonatomic , strong) BTMessageViewController * message;

@end

@implementation BTViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self babyDelegate];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    [self.baby cancelAllPeripheralsConnection];
    self.baby.scanForPeripherals().begin();
    [self.indicationView startAnimating];
}

- (IBAction)dismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - STEP 1 Search

- (void)babyDelegate {
    __weak typeof(self) weakSelf = self;
    [self.baby setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        if(central.state == CBManagerStatePoweredOn) {
            NSLog(@"设备打开成功，开始扫描设备");
        }
    }];
    
    [self.baby setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        [weakSelf insertTableView:peripheral advertisementData:advertisementData];
    }];
    
    [self.baby setFilterOnDiscoverPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        return peripheralName.length > 0;
    }];
    
    [self.baby setBlockOnDiscoverServices:^(CBPeripheral *peripheral, NSError *error) {
        for (int i=0; i<weakSelf.peripherals.count; i++) {
            UITableViewCell *cell = [weakSelf.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            if ([cell.textLabel.text isEqualToString:peripheral.name]) {
                cell.detailTextLabel.text = @(peripheral.services.count).stringValue;
            }
        }
    }];
    
    NSDictionary *scanForPeripheralsWithOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
    [self.baby setBabyOptionsWithScanForPeripheralsWithOptions:scanForPeripheralsWithOptions connectPeripheralWithOptions:nil scanForPeripheralsWithServices:nil discoverWithServices:nil discoverWithCharacteristics:nil];
}

-(void)insertTableView:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData {
    if(![self.peripherals containsObject:peripheral]) {
        NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.peripherals.count inSection:0];
        [indexPaths addObject:indexPath];
        [self.peripherals addObject:peripheral];
        [self.peripheralsAD addObject:advertisementData];
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}


#pragma mark - STEP 2 Connect 

- (void)connectPeripheral {
    __weak typeof(self)weakSelf = self;
    [self.baby setBlockOnConnectedAtChannel:kChannelOnPeripheralView
                                      block:^(CBCentralManager *central, CBPeripheral *peripheral)
    {
        [SVProgressHUD showSuccessWithStatus:@"连接成功"];
        [weakSelf.navigationController pushViewController:weakSelf.message animated:YES];
    }];
    
    [self.baby setBlockOnFailToConnectAtChannel:kChannelOnPeripheralView
                                          block:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error)
    {
        [SVProgressHUD showSuccessWithStatus:@"链接失败"];
    }];
    
    [self.baby setBlockOnDiscoverCharacteristicsAtChannel:kChannelOnPeripheralView
                                                    block:^(CBPeripheral *peripheral, CBService *service, NSError *error)
    {
        for (CBCharacteristic *characters in service.characteristics) {
            if (characters.properties & CBCharacteristicPropertyNotify) {
                weakSelf.message.peripheral = peripheral;
                weakSelf.message.character = characters;
                break;
            }
        }
    }];
    
    NSDictionary *connectOptions = @{CBConnectPeripheralOptionNotifyOnConnectionKey:@YES,
                                     CBConnectPeripheralOptionNotifyOnDisconnectionKey:@YES,
                                     CBConnectPeripheralOptionNotifyOnNotificationKey:@YES};
    
    NSDictionary *scanForPeripheralsWithOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
    [self.baby setBabyOptionsAtChannel:kChannelOnPeripheralView scanForPeripheralsWithOptions:scanForPeripheralsWithOptions connectPeripheralWithOptions:connectOptions scanForPeripheralsWithServices:nil discoverWithServices:nil discoverWithCharacteristics:nil];
    
    [SVProgressHUD showInfoWithStatus:@"开始连接设备"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        weakSelf.baby.having(weakSelf.currentPeripheral).and.channel(kChannelOnPeripheralView).then.connectToPeripherals().discoverServices().discoverCharacteristics().readValueForCharacteristic().discoverDescriptorsForCharacteristic().readValueForDescriptors().begin();
    });
}

- (void)connect {
    [self.baby cancelScan];
    [self.indicationView stopAnimating];
    self.indicationView.hidden = YES;
    [self connectPeripheral];
    [self.tableView setUserInteractionEnabled:NO];
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.peripherals.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
    CBPeripheral *peripheral = [self.peripherals objectAtIndex:indexPath.row];
    NSDictionary *ad = [self.peripheralsAD objectAtIndex:indexPath.row];
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    //peripheral的显示名称,优先用kCBAdvDataLocalName的定义，若没有再使用peripheral name
    NSString *localName;
    if ([ad objectForKey:@"kCBAdvDataLocalName"]) {
        localName = [NSString stringWithFormat:@"%@",[ad objectForKey:@"kCBAdvDataLocalName"]];
    } else {
        localName = peripheral.name;
    }
    cell.textLabel.text = localName;
    cell.detailTextLabel.text = @"读取中...";
    //找到cell并修改detaisText
    NSArray *serviceUUIDs = [ad objectForKey:@"kCBAdvDataServiceUUIDs"];
    if (serviceUUIDs) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu个service",(unsigned long)serviceUUIDs.count];
    } else {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"0个service"];
    }
    
    //次线程读取RSSI和服务数量
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.currentPeripheral = self.peripherals[indexPath.row];
    [self connect];
}

#pragma mark - 

- (NSMutableArray *)peripherals {
    if (!_peripherals) {
        _peripherals = @[].mutableCopy;
    }
    return _peripherals;
}

- (NSMutableArray *)peripheralsAD {
    if (!_peripheralsAD) {
        _peripheralsAD = @[].mutableCopy;
    }
    return _peripheralsAD;
}

- (BabyBluetooth *)baby{
    if (!_baby) {
        _baby = [BabyBluetooth shareBabyBluetooth];
    }
    return _baby;
}

- (BTMessageViewController *)message {
    if (!_message) {
        _message = [BTMessageViewController new];
    }
    return _message;
}

@end
