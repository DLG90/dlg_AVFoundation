//
//  PlayerView.m
//  视频录制与播放demo
//
//  Created by 梦回九天 on 16/9/5.
//  Copyright © 2016年 DLG. All rights reserved.
//

#import "PlayerView.h"
static const CGFloat pauseBtnWidth=80;
static const CGFloat buttomViewHeight=44;
@interface PlayerView()<UIGestureRecognizerDelegate>
@property(nonatomic,weak)id timeObserver;
@property(nonatomic,assign)BOOL isInteraction;
@end
@implementation PlayerView
-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    self=[super initWithCoder:aDecoder];
    self.backgroundColor=[UIColor blackColor];
    self.loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self addSubview:self.loadingView];
    
//    self.state=DLGPlayerStateBuffering;
    return self;
}
//default is [CALayer class]. Used when creating the underlying layer for the view.
//创建视图的底层layer时调用该方法
+(Class)layerClass{
    return [AVPlayerLayer class];
}
//获取该视图的AVPlayerLayer
- (AVPlayerLayer *)playerLayer{
    return (AVPlayerLayer *)self.layer;
}
//设置AVPlayerLayer的AVPlayer
- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}
//获取该AVPlayerLayer层的AVPlayer对象
- (AVPlayer*)player {
    return [(AVPlayerLayer *)[self layer] player];
}
-(void)setPlayerItem:(AVPlayerItem *)playerItem{
    if (_playerItem==playerItem) {
        return;
    }
    //先清空以前的_playerItem
    if (_playerItem) {
        [_playerItem removeObserver:self forKeyPath:@"status"];
        [_playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [_playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [_playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
        _playerItem = nil;
    }
    _playerItem=playerItem;
    if (!_playerItem) {
        return;
    }
    [_playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];//kvo 监听AVPlayerItem的status属性
    [_playerItem addObserver:self forKeyPath:@"loadedTimeRanges"options:NSKeyValueObservingOptionNew context:nil];//观察缓存现在的进度
    [_playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];

    [_playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    //添加视频播放结束的通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(moviePlayEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
}
-(void)setPlayerUrl:(NSURL *)playerUrl{
    
    //初始化AVPlayerItem
    AVPlayerItem *item=[[AVPlayerItem alloc]initWithURL:playerUrl];
    self.playerItem=item;
    //初始化AVPlayer
    AVPlayer *player=[[AVPlayer alloc]initWithPlayerItem:item];
    self.player=player;
    self.player.volume=0.0;//静音
    [self.player seekToTime:kCMTimeZero];

    //初始化底部视图
    ButtomView *buttomView=[ButtomView buttomView];
    [self addSubview:buttomView];
    buttomView.hidden=true;
    self.buttomView  =buttomView;
    //滑块按下去的时候
    self.buttomView.mySlider.continuous=NO;
    [self.buttomView.mySlider addTarget:self action:@selector(sliderClickDown:) forControlEvents:UIControlEventTouchDown];
    [self.buttomView.mySlider addTarget:self action:@selector(sliderClickUp:) forControlEvents:UIControlEventValueChanged];
    self.buttomView.mySlider.minimumValue = 0.0;
    self.buttomView.mySlider.minimumTrackTintColor = [UIColor greenColor];
    self.buttomView.mySlider.maximumTrackTintColor = [UIColor clearColor];//设置滑动条颜色
    [self.buttomView.mySlider setThumbImage:[UIImage imageNamed:@"dot"] forState:UIControlStateNormal];
    //设置buttomView约束
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.buttomView.translatesAutoresizingMaskIntoConstraints = NO;
    NSString *Hvfl=@"H:|-0-[buttomView]-0-|";
    NSString *Vvfl=@"V:[buttomView(buttomHeight)]-0-|";
    NSDictionary *metrics=@{@"buttomHeight":@(buttomViewHeight)};
    NSDictionary *views=@{@"buttomView":self.buttomView};
    NSArray *Hconstraints=[NSLayoutConstraint constraintsWithVisualFormat:Hvfl options:0 metrics:metrics views:views];
    NSArray *Vconstraints=[NSLayoutConstraint constraintsWithVisualFormat:Vvfl options:0 metrics:metrics views:views];
    [self addConstraints:Hconstraints];
    [self addConstraints:Vconstraints];
    //初始化屏幕中心暂停按钮
    UIButton *btn=[UIButton buttonWithType:UIButtonTypeCustom];
    [self addSubview:btn];
    [btn addTarget:self action:@selector(PauseBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [btn setImage:[UIImage imageNamed:@"playSmall"] forState:UIControlStateNormal];
    self.PauseBtn=btn;
//    self.PauseBtn.hidden=TRUE;
    //设置屏幕点击的手势识别
    UITapGestureRecognizer *tap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(catchTap:)];
    tap.delegate=self;
    [self addGestureRecognizer:tap];

    // layer的填充属性 和UIImageView的填充属性类似
    // AVLayerVideoGravityResizeAspect 等比例拉伸，会留白
    // AVLayerVideoGravityResizeAspectFill // 等比例拉伸，会裁剪
    // AVLayerVideoGravityResize // 保持原有大小拉伸
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
}
/**
 *  设置播放的状态
 */
- (void)setState:(DLGPlayerState)state
{
    _state = state;
    //控制菊花显示、隐藏
    if (state == DLGPlayerStateBuffering) {
        [self.loadingView startAnimating];
    }else if(state == DLGPlayerStatePlaying){
        [self.loadingView stopAnimating];//
    }else if(state == DLGPlayerStateReadyToPlay){
        [self.loadingView stopAnimating];//
    }else{
        [self.loadingView stopAnimating];//
    }
}
//视频播放完调用
-(void)moviePlayEnd:(NSNotification *)notification{
    self.state =DLGPlayerStateFinished;
    [self.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        self.PauseBtn.hidden=false;
        [self.player pause];
        [self.PauseBtn setImage:[UIImage imageNamed:@"playSmall"] forState:UIControlStateNormal];
    }];
}
//音量控制
- (void)volumeSet:(UISlider *)slider
{
    //Audio音频
    NSArray *audioTracks = [_playerItem.asset tracksWithMediaType:AVMediaTypeAudio];
    NSMutableArray *allAudioParams = [NSMutableArray array];
    for (AVAssetTrack *track in audioTracks) {
        AVMutableAudioMixInputParameters *audioInputParams =
        [AVMutableAudioMixInputParameters audioMixInputParameters];
        [audioInputParams setVolume:slider.value atTime:kCMTimeZero];
        [audioInputParams setTrackID:[track trackID]];
        [allAudioParams addObject:audioInputParams];
    }
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    [audioMix setInputParameters:allAudioParams];
    [_playerItem setAudioMix:audioMix];
}
-(void)catchTap:(UITapGestureRecognizer *)tap{
    if (self.buttomView.hidden==true){
         [self showControlsWithAnimation];
    }else{
        self.isInteraction=false;
        [self hideControls:0.0];
    }
}
-(void)showControlsWithAnimation{
    [UIView animateWithDuration:0.4
                     animations:^{
                         self.PauseBtn.hidden=false;
                         self.buttomView.hidden=false;
                         self.isInteraction=true;
                     }];
}
- (void)PauseBtnClick:(id)sender {
    // 播放器的rate  0 代表暂停   1 代表播放
    if (self.player.rate>0 && !self.player.error) {
        //正在播放中
        self.buttomView.hidden=false;
        self.PauseBtn.hidden=false;
        [self.player pause];
        [self.PauseBtn setImage:[UIImage imageNamed:@"playSmall"] forState:UIControlStateNormal];
       
    }else{
        //停止状态
        self.PauseBtn.hidden=true;
        self.buttomView.hidden=true;
        [self.player play];
        [self.PauseBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    }
}
//延时隐藏按钮
-(void)hideControls:(NSTimeInterval)delay{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay *NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.4
                         animations:^{
                             if (!self.isInteraction) {
                                 self.PauseBtn.hidden=true;
                                 self.buttomView.hidden=true;
                             }
                         }];
    });
}
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    if([keyPath isEqualToString:@"status"]){
        if (self.playerItem.status==AVPlayerStatusReadyToPlay) {
//            NSLog(@"开始播放");
            //需要开始获取数据，包括播放的总时长，播放的缓存，播放的当前时间
            [self addPeriodicTimeObserver];
        }else{
//            NSLog(@"播放失败");
        }
    }else if([keyPath isEqualToString:@"loadedTimeRanges"]){//loadedTimeRanges
        NSArray *arry=[self.playerItem loadedTimeRanges];
        //获取范围
        CMTimeRange range=[arry.firstObject CMTimeRangeValue];
        //从哪里开始缓存
        CGFloat start=CMTimeGetSeconds(range.start);
//        NSLog(@"缓存开始：%f",start);
        
        //缓存了多少
        CGFloat duration=CMTimeGetSeconds(range.duration);
//        NSLog(@"当前缓存了：%f",duration);
        
        //一共缓存了多少
        CGFloat allCache=start + duration;
//        NSLog(@"一共缓存了：%f",allCache);
        
        //设置缓存百分比
        CMTime allTime=[self.playerItem duration];//一共多长时间
        CGFloat time=CMTimeGetSeconds(allTime);
//        NSLog(@"allTime=%f",time);
        
        CGFloat y=allCache/time;
//        NSLog(@"缓存百分比：%f",y);
        //给缓存滑块赋值
        self.buttomView.myProgress.progress=y;
    }else if ([keyPath isEqualToString:@"playbackBufferEmpty"]){
        if (self.playerItem.playbackBufferEmpty) {
            self.state=DLGPlayerStateBuffering;
            
        }
    }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]){
        if (self.playerItem.playbackLikelyToKeepUp&&self.state == DLGPlayerStateBuffering) {
            self.state=DLGPlayerStatePlaying;
        }
    }
}
-(void)addPeriodicTimeObserver{
     __weak typeof(self) weakSelf=self;
    [self.player removeTimeObserver:self.timeObserver];
    //每隔一秒钟调用一次
    self.timeObserver=[self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        //当前播放时间
        CGFloat currentime=weakSelf.playerItem.currentTime.value/weakSelf.playerItem.currentTime.timescale;
//        NSLog(@"当前时间：%f",currentime);
        weakSelf.buttomView.currentTime.text=[weakSelf timeFormatted:currentime];
        //总时长
        CMTime totalTime=weakSelf.playerItem.duration;
        float X = CMTimeGetSeconds(totalTime);
//        NSLog(@"总时长：%f",X);
        weakSelf.buttomView.totalTime.text=[weakSelf timeFormatted:X];
        //设置滑动条的进度
        float precent=currentime/X;
//        NSLog(@"百分比：%f",precent);
        weakSelf.buttomView.mySlider.value=precent;
        
    }];
}
- (NSString *)timeFormatted:(int)totalSeconds
{
    
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    int hours = totalSeconds / 3600;
    if (hours==0) {
        return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
    }
    return [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
}
-(void)sliderClickDown:(UISlider *)slider{
    NSLog(@"slider被按下去了");
    self.isInteraction=TRUE;
    [self.player pause];
  
}
-(void)sliderClickUp:(UISlider *)slider{
    NSLog(@"slider弹起来了");
   
    CGFloat choose=slider.value;//滑块滑动的位置
    //    CMTime time   =self.playerItem.duration;//总时长
    //    double     X   =CMTimeGetSeconds(time);
    double X=[self duration];//总时长
    [self seekToTimeToPlay: X*choose];
    [self hideControls:1.0];
   
}
/**
 *  跳到time处播放
 *  @param seekTime这个时刻，这个时间点
 */
- (void)seekToTimeToPlay:(double)time{
    if (self.player&&self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        if (time > [self duration]) {
            time = [self duration];
        }
        if (time<=0) {
            time=0.0;
        }
        [self.player seekToTime:CMTimeMakeWithSeconds(time, self.playerItem.currentTime.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
            [self.player play];
        }];
        
        
    }
}
//获取视频长度
- (double)duration{
    AVPlayerItem *playerItem = self.player.currentItem;
    if (playerItem.status == AVPlayerItemStatusReadyToPlay){
        return CMTimeGetSeconds([[playerItem asset] duration]);
    }
    else{
        return 0.f;
    }
}
-(void)layoutSubviews{
    [super layoutSubviews];
     self.PauseBtn.frame=CGRectMake(self.frame.size.width/2-pauseBtnWidth/2, self.frame.size.height/2-pauseBtnWidth/2, pauseBtnWidth, pauseBtnWidth);
     self.loadingView.center=CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
}
#pragma mark -UIGestureRecognizerDelegate
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    NSLog(@"%@",touch.view);
    //过滤底部ButtomView点击事件
    if([touch.view isMemberOfClass:[ButtomView class]]||[touch.view isKindOfClass:[UISlider class]]){
        return NO;
    }
    return YES;
}
-(void)dealloc{
    [self.player removeTimeObserver:self.timeObserver];
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.player=nil;
}
@end
