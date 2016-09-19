//
//  buttomView.m
//  视频录制与播放demo
//
//  Created by 梦回九天 on 16/9/6.
//  Copyright © 2016年 DLG. All rights reserved.
//

#import "ButtomView.h"

@implementation ButtomView
+(instancetype)buttomView{
    return [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil] lastObject];
}
@end
