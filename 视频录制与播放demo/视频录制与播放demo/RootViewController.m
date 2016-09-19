//
//  RootViewController.m
//  视频录制与播放demo
//
//  Created by 梦回九天 on 16/9/5.
//  Copyright © 2016年 DLG. All rights reserved.
//

#import "RootViewController.h"
#import "RecordingViewController.h"
#import "PlayerViewController.h"
@interface RootViewController ()

@end

@implementation RootViewController

- (IBAction)RecordBtn:(UIButton *)sender {
    RecordingViewController *RVC=[[RecordingViewController alloc]init];
    UINavigationController *CC=[[UINavigationController alloc]initWithRootViewController:RVC];
    [self presentViewController:CC animated:YES completion:nil];
}

- (IBAction)PlayerBtn:(id)sender {
    PlayerViewController *PVC=[[PlayerViewController alloc]init];
    [self presentViewController:PVC animated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
