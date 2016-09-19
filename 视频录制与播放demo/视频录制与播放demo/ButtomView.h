//
//  buttomView.h
//  视频录制与播放demo
//
//  Created by 梦回九天 on 16/9/6.
//  Copyright © 2016年 DLG. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ButtomView : UIView
@property (weak, nonatomic) IBOutlet UISlider *mySlider;
@property (weak, nonatomic) IBOutlet UIProgressView *myProgress;
@property (weak, nonatomic) IBOutlet UILabel *currentTime;
@property (weak, nonatomic) IBOutlet UILabel *totalTime;
+(instancetype)buttomView;
@end
