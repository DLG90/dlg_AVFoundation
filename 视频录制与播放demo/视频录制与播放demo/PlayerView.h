//
//  PlayerView.h
//  视频录制与播放demo
//
//  Created by 梦回九天 on 16/9/5.
//  Copyright © 2016年 DLG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ButtomView.h"
#import <AVFoundation/AVFoundation.h>
// 播放器的几种状态
typedef NS_ENUM(NSInteger, DLGPlayerState) {
    DLGPlayerStateFailed,        // 播放失败
    DLGPlayerStateBuffering,     // 缓冲中
    DLGPlayerStateReadyToPlay,   // 将要播放
    DLGPlayerStatePlaying,       // 播放中
    DLGPlayerStateStopped,       // 暂停播放
    DLGPlayerStateFinished       // 播放完毕
};
@interface PlayerView : UIView
/**
 *  要播放的视频路径
 */
@property(nonatomic,strong)NSURL *playerUrl;
/**
 *  播放器player
 */
@property(nonatomic)AVPlayer *player;
/**
 *  当前播放的item
 */
@property (nonatomic,strong)AVPlayerItem *playerItem;
@property(nonatomic,weak)AVPlayerLayer *playerLayer;
/**
 *  底部操作视图
 */
@property(nonatomic,weak)ButtomView *buttomView;
/**
 *  开始/暂停 按钮
 */
@property(nonatomic,weak)UIButton *PauseBtn;
/**
 *  菊花（加载框）
 */
@property (nonatomic,strong)UIActivityIndicatorView *loadingView;
/**
 ＊  播放器状态
 */
@property (nonatomic,assign)DLGPlayerState state;

@end
