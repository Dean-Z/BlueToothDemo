//
//  ViewController.m
//  BlueTouchDemo
//
//  Created by Z on 2016/11/21.
//  Copyright © 2016年 BT. All rights reserved.
//

#import "ViewController.h"
#import "BTViewController.h"
#import "BTPeripheralController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
 
}

- (IBAction)stub:(id)sender {
    BTPeripheralController *per = [[BTPeripheralController alloc]initWithNibName:NSStringFromClass([BTPeripheralController class]) bundle:nil];
    [self presentViewController:per animated:YES completion:nil];
}

- (IBAction)severs:(id)sender {
    BTViewController *bt = [[BTViewController alloc]initWithNibName:NSStringFromClass([BTViewController class]) bundle:nil];
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:bt];
    [nav setNavigationBarHidden:YES];
    [self presentViewController:nav animated:YES completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}


@end
