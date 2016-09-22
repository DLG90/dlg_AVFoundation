//
//  PlayerViewController.m
//  视频录制与播放demo
//
//  Created by 梦回九天 on 16/9/5.
//  Copyright © 2016年 DLG. All rights reserved.
//

#import "PlayerViewController.h"
#import "PlayerView.h"
@interface PlayerViewController ()
@property (weak, nonatomic) IBOutlet PlayerView *myPlayerView;
@property (weak, nonatomic) IBOutlet UIButton *BackBtn;
@end

@implementation PlayerViewController
- (IBAction)Back:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)viewDidLoad {
    [super viewDidLoad];
//    NSURL * url=[NSURL URLWithString:@"http://play.68mtv.com:8080/play3/57548.mp4"];
    if (self.url) {
      _myPlayerView.playerUrl = self.url;
    }else{
        NSLog(@"请先录制视频！");
    }
    
}




@end
