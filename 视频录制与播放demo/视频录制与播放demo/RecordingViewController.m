//
//  RecordingViewController.m
//  视频录制与播放demo
//
//  Created by 梦回九天 on 16/9/5.
//  Copyright © 2016年 DLG. All rights reserved.
//

#import "RecordingViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "DLGFocusView.h"
#import "DLGEyeView.h"
#import "DLGRecordBtn.h"
#import "VideoSaveConfig.h"
#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
//视频长宽比例
#define dlgVideoRatio_w_h (4.0/3)
//视频录制时长
#define dlgRecordTime      15.0
//视频宽的分辨率
#define  dlgVideoWidthPx   640.0
#define  dlgVideoHeightPx  dlgVideoWidthPx / dlgVideoRatio_w_h
//iOS设备的屏幕刷新频率(FPS)是60Hz，因此CADisplayLink的selector默认调用周期是每秒60次，这个周期可以通过frameInterval属性设置
#define kTrans SCREEN_WIDTH/dlgRecordTime/60.0 //15秒内要走完屏幕的宽度的前提下，每刷新一次要走的距离

typedef NS_ENUM(NSUInteger,VideoStatus){
    VideoStatusEnded = 0,
    VideoStatusStart
};

@interface RecordingViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>{
    AVCaptureSession *_captureSession;
    AVCaptureDevice  *_videoDevice;
    AVCaptureDevice  *_audioDevice;
    AVCaptureDeviceInput *_videoInput;
    AVCaptureDeviceInput *_audioInput;
    AVCaptureVideoDataOutput *_videoDataOutput;
    AVCaptureAudioDataOutput *_audioDataOutput;
    dispatch_queue_t _recoding_queue;
    AVCaptureVideoPreviewLayer *_captureVideoPreviewLayer;
    
    AVAssetWriter *_assetWriter;
    AVAssetWriterInputPixelBufferAdaptor *_assetWriterInputPixelBufferAdaptor;
    AVAssetWriterInput *_assetWriterVideoInput;
    AVAssetWriterInput *_assetWriterAudioInput;
    BOOL _recoding;
    CMTime _currentSampleTime;
    DLGEyeView      *_eyeView;
    NSURL           *_outURL;//保存视频的路径
}
@property (weak, nonatomic) IBOutlet UIButton *changeOrientationBtn;
@property (weak, nonatomic) IBOutlet UIButton *flashBtn;
@property (weak, nonatomic) IBOutlet UIView *videoView;
@property (weak, nonatomic) IBOutlet UIView *progressView;
@property (weak, nonatomic) IBOutlet DLGRecordBtn *recordBtn;
@property (weak, nonatomic) IBOutlet UILabel *cancelLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *progressWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cancelLabelBottom;
@property (strong, nonatomic) DLGFocusView *focusCircle;
@property (strong, nonatomic) CADisplayLink *link;
@property (assign, nonatomic) VideoStatus    status;
@end

@implementation RecordingViewController
- (IBAction)OrientationBtn:(id)sender
{
    NSLog(@"点击了镜头切换按钮！");
    NSLog(@"%ld",(long)_videoDevice.position);
    switch (_videoDevice.position) {
        case AVCaptureDevicePositionBack:
            _videoDevice = [self deviceWithMediaType:AVMediaTypeVideo Position:AVCaptureDevicePositionFront];
            break;
        case AVCaptureDevicePositionFront:
            _videoDevice = [self deviceWithMediaType:AVMediaTypeVideo Position:AVCaptureDevicePositionBack];
            break;
        default:
            return;
            break;
    }
    
    NSLog(@"%ld",(long)_videoDevice.position);
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        NSError *error;
        AVCaptureDeviceInput *newInput = [[AVCaptureDeviceInput alloc]initWithDevice:_videoDevice error:&error];
        if (newInput != nil) {
            [_captureSession removeInput:_videoInput];
            if ([_captureSession canAddInput:newInput]) {
                [_captureSession addInput:newInput];
                _videoInput = newInput;
            }else{
                [_captureSession addInput:_videoInput];
            }
        }else if (error){
            NSLog(@"摄像头切换失败！");
        }
    }];
    
}

/**
 *  闪光灯开启和关闭
 *
 *  @param sender 切换按钮
 */
- (IBAction)FlashBtn:(UIButton *)sender
{
    NSLog(@"点击了闪光灯按钮！");
    BOOL hastorch = [_videoDevice hasTorch];//支持手电筒模式
    BOOL hasflash = [_videoDevice hasFlash];//支持闪光灯
    if(hastorch && hasflash){
        [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
            if (_videoDevice.flashMode==AVCaptureFlashModeOn) {
                [_videoDevice setFlashMode:AVCaptureFlashModeOff];
                [_videoDevice setTorchMode:AVCaptureTorchModeOff];
                
            }else if (_videoDevice.flashMode == AVCaptureFlashModeOff){//闪光灯关
                [_videoDevice setFlashMode:AVCaptureFlashModeOn];
                [_videoDevice setTorchMode:AVCaptureTorchModeOn];
                
            }
        }];
        sender.selected = !sender.isSelected;
    }else{
        NSLog(@"不能切换闪光灯");
    }
}

//更改取消label的状态
- (void)changeCancelLabelCondition:(BOOL)condition{
    if (condition) {
        self.cancelLabelBottom.constant = 25;
        self.cancelLabel.text = @"↑上移取消";
        self.cancelLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        self.cancelLabel.textColor = [UIColor whiteColor];
    }else{
        _recoding = NO;//停止录制
        self.cancelLabelBottom.constant = 25+15;
        self.cancelLabel.text = @"松开取消";
        self.cancelLabel.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.5];
        self.cancelLabel.textColor = [UIColor whiteColor];
    }
}
- (DLGFocusView *)focusCircle
{
    if (!_focusCircle) {
        _focusCircle=[[DLGFocusView alloc]initWithFrame:CGRectMake(0, 0, 50, 50)];
        [self.videoView addSubview:_focusCircle];
    }
    return _focusCircle;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setUpUI];
    [self getAuthorization];
    [self addGenstureRecongnizer];
}
//在此方法中获取xib中控件尺寸大小最准确
//- (void)viewDidLayoutSubviews{
//
//}


-(void)viewWillAppear:(BOOL)animated{
    
    CGRect eyeRect = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH/dlgVideoRatio_w_h);
    _eyeView = [[DLGEyeView alloc]initWithFrame:eyeRect];
    [_videoView addSubview:_eyeView];

}
-(void)viewDidAppear:(BOOL)animated
{
    
    if (TARGET_IPHONE_SIMULATOR) {
        return;
    }
    //- (UIView *)snapshotViewAfterScreenUpdates:(BOOL)afterUpdates NS_AVAILABLE_IOS(7_0);
    //afterUpdates参数表示是否在所有效果应用在视图上了以后再获取快照。例如，如果该参数为NO，则立马获取该视图现在状态的快照
    UIView * sysSnapshot     = [_eyeView snapshotViewAfterScreenUpdates:NO];
    CGFloat videoViewHeight  = CGRectGetHeight(_videoView.frame);
    CGFloat videoViewWidth   = CGRectGetWidth(_videoView.frame);
    _eyeView.alpha           = 0;
    CGRect  topFrame         = CGRectMake(0, 0, videoViewWidth, videoViewHeight/2);
    UIView *topView          = [sysSnapshot resizableSnapshotViewFromRect:topFrame afterScreenUpdates:NO withCapInsets:UIEdgeInsetsZero];
    CGRect  bottomFrame      = CGRectMake(0, videoViewHeight/2, videoViewWidth, videoViewHeight/2);
    UIView *buttomView       = [sysSnapshot resizableSnapshotViewFromRect:bottomFrame afterScreenUpdates:NO withCapInsets:UIEdgeInsetsZero];
    buttomView.frame         = bottomFrame;
    [_videoView addSubview:topView];
    [_videoView addSubview:buttomView];
    _videoView.clipsToBounds = true;
//    UIViewAnimationOptionCurveEaseInOut：动画先缓慢，然后逐渐加速。
//    
//    UIViewAnimationOptionCurveEaseIn ：动画逐渐变慢。
//    
//    UIViewAnimationOptionCurveEaseOut：动画逐渐加速。
//    
//    UIViewAnimationOptionCurveLinear ：动画匀速执行，默认值。
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        //CGAffineTransformMakeTranslation //创建一个平移的变化
        topView.transform    = CGAffineTransformMakeTranslation(0, -videoViewHeight/2);
        buttomView.transform = CGAffineTransformMakeTranslation(0, videoViewHeight/2);
        
    } completion:^(BOOL finished) {
        [topView removeFromSuperview];
        [buttomView removeFromSuperview];
        [_eyeView removeFromSuperview];
        _eyeView = nil;
        [self.videoView bringSubviewToFront:self.flashBtn];
        [self.videoView bringSubviewToFront:self.changeOrientationBtn];
        [self.videoView bringSubviewToFront:self.cancelLabel];
        //设置焦点曝光点的位置
        CGPoint cameraPoint = [_captureVideoPreviewLayer captureDevicePointOfInterestForPoint:CGPointMake(_videoView.bounds.size.width/2, _videoView.bounds.size.height/2)];
        [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
            //聚焦
            if([captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]){
                [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
            }else{
                NSLog(@"聚焦模式修改失败");
            }
            //聚焦点的位置
            if([captureDevice isFocusPointOfInterestSupported]){
                [captureDevice setFocusPointOfInterest:cameraPoint];
            }
            //曝光模式（曝光自动调整一次然后锁定）
            if([captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]){
                [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
            }else{
                NSLog(@"曝光模式修改失败");
            }
            //曝光点的位置
            if([captureDevice isExposurePointOfInterestSupported]){
                [captureDevice setExposurePointOfInterest:cameraPoint];
            }
            
        }];
    }];
}
/**
 *  获取录像权限
 */
- (void)getAuthorization
{
    if (TARGET_IPHONE_SIMULATOR) {
        NSLog(@"模拟器不可以");
        return;
    }
    AVAuthorizationStatus audioAuthStatus=[AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (audioAuthStatus) {
        case AVAuthorizationStatusAuthorized:
        {
            NSLog(@"有录音权限");
            break;
        }
        case AVAuthorizationStatusNotDetermined:
        {
            NSLog(@"未进行授权选择");
            //再次请求授权
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                if (granted) {
                    NSLog(@"录音授权成功");
                    
                }else{
                    NSLog(@"用户拒接授权");
                    [self showMessageTitle:@"提示" Content:@"录音权限被拒绝，请检查下\n设置->隐私/通用等权限设置"];
                    return ;
                }
            }];
            break;
        }
        default:
        {
            [self showMessageTitle:@"提示" Content:@"录音权限被拒绝，请检查下\n设置->隐私/通用等权限设置"];
            return;
        }
            break;
    }

    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusAuthorized:
        {
            NSLog(@"有权限");
            [self setupAVCaptureInfo];
            break;
        }
        case AVAuthorizationStatusNotDetermined:
        {
            NSLog(@"未进行授权选择");
            //再次请求授权
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    NSLog(@"授权成功");
                    [self setupAVCaptureInfo];

                }else{
                    NSLog(@"用户拒接授权");
                    [self showMessageTitle:@"提示" Content:@"摄像头权限被拒绝，请检查下\n设置->隐私/通用等权限设置"];
                    return ;
                }
            }];
            break;
        }
        default:
        {
            [self showMessageTitle:@"提示" Content:@"摄像头权限被拒绝，请检查下\n设置->隐私/通用等权限设置"];
            return;
        }
            break;
    }
    
}
/**
 *  AVCaptureSession基本信息设置
 */
- (void)setupAVCaptureInfo
{
    [self setSession];
    [_captureSession beginConfiguration];

    //获取后置摄像头
    _videoDevice = [self deviceWithMediaType:AVMediaTypeVideo Position:AVCaptureDevicePositionBack];
    NSError *videoError;
    _videoInput  = [[AVCaptureDeviceInput alloc]initWithDevice:_videoDevice error:&videoError];
    if (videoError) {
        NSLog(@"获取摄像头AVCaptureDeviceInput出错  %@",videoError);
        return;
    }
    //将视频输入对象添加到会话中
    if ([_captureSession canAddInput:_videoInput]) {
        [_captureSession addInput:_videoInput];
    }
    
    NSError *audioError;
    _audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    _audioInput  = [[AVCaptureDeviceInput alloc]initWithDevice:_audioDevice error:&audioError];
    if (audioError) {
        NSLog(@"获取录音设备AVCaptureDeviceInput出错 %@",audioError);
        return;
    }
    
    //将音频输入对象添加到会话中
    if ([_captureSession canAddInput:_audioInput]) {
        [_captureSession addInput:_audioInput];
    }
    
    _recoding_queue = dispatch_queue_create("com.dlg.queue", DISPATCH_QUEUE_SERIAL);//串行队列
    _videoDataOutput = [[AVCaptureVideoDataOutput alloc]init];
    _videoDataOutput.videoSettings = @{(__bridge NSString*)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};//设置像素格式
    _videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    [_videoDataOutput setSampleBufferDelegate:self queue:_recoding_queue];
    if ([_captureSession canAddOutput:_videoDataOutput]) {
        [_captureSession addOutput:_videoDataOutput];
    }
    _audioDataOutput = [[AVCaptureAudioDataOutput alloc]init];
    [_audioDataOutput setSampleBufferDelegate:self queue:_recoding_queue];
    if ([_captureSession canAddOutput:_audioDataOutput]) {
        [_captureSession addOutput:_audioDataOutput];
    }
    
    [self.view layoutIfNeeded];
    //创建预览层
    _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:_captureSession];
    _captureVideoPreviewLayer.frame = CGRectMake(0, 0, _videoView.frame.size.width, _videoView.frame.size.height);
    _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [_videoView.layer addSublayer:_captureVideoPreviewLayer];
    
    
    
    [_captureSession commitConfiguration];
    
    //开启会话（不等于开始录制）
    [_captureSession startRunning];
    

}


-(AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType Position:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = devices.firstObject;
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            captureDevice = device;
            break;
        }
    }
    return captureDevice;
}

/**
 *  初始化AVCaptureSession
 */
- (void) setSession
{
    _captureSession = [[AVCaptureSession alloc]init];
    //设置视频分辨率
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        [_captureSession setSessionPreset:AVCaptureSessionPreset640x480];
    }
}
-(void)showMessageTitle:(NSString *)title Content:(NSString *)content
{
 
    [[[UIAlertView alloc]initWithTitle:title message:content delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
}

/**
 *  创建videoView单击和双击手势
 */
- (void)addGenstureRecongnizer
{
    UITapGestureRecognizer *singleTap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(singleTap:)];
    singleTap.numberOfTapsRequired=1;
    singleTap.delaysTouchesBegan=YES;
    UITapGestureRecognizer *doubleTap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTap:)];
    doubleTap.numberOfTapsRequired=2;
    doubleTap.delaysTouchesBegan=YES;
    [singleTap requireGestureRecognizerToFail:doubleTap];
    [self.videoView addGestureRecognizer:singleTap];
    [self.videoView addGestureRecognizer:doubleTap];
}
-(void)singleTap:(UITapGestureRecognizer *)tapGesture
{
    NSLog(@"%s",__FUNCTION__);
    CGPoint point = [tapGesture locationInView:self.videoView];
    //将UI坐标转换为摄像头坐标，摄像头聚焦范围为0~1
    CGPoint cameraPoint = [_captureVideoPreviewLayer captureDevicePointOfInterestForPoint:point];
    NSLog(@"%@",NSStringFromCGPoint(cameraPoint));
    self.focusCircle.center = point;
    [self.focusCircle focusing];//光圈动画
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        //聚焦
        if([captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]){
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }else{
            NSLog(@"聚焦模式修改失败");
        }
        //聚焦点的位置
        if([captureDevice isFocusPointOfInterestSupported]){
            [captureDevice setFocusPointOfInterest:cameraPoint];
        }
        //曝光模式（曝光自动调整一次然后锁定）
        if([captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]){
            [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }else{
            NSLog(@"曝光模式修改失败");
        }
        //曝光点的位置
        if([captureDevice isExposurePointOfInterestSupported]){
            [captureDevice setExposurePointOfInterest:cameraPoint];
        }
        
    }];
    
}
//设置焦距
-(void)doubleTap:(UITapGestureRecognizer *)tapGesture
{
    NSLog(@"%s",__FUNCTION__);
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if (captureDevice.videoZoomFactor == 1.0) {
            CGFloat current = 1.5;
            if (current < captureDevice.activeFormat.videoMaxZoomFactor) {
                [captureDevice rampToVideoZoomFactor:current withRate:10];//从当前的缩放因子开始平稳过渡到另一个。
            }
        }else{
            [captureDevice rampToVideoZoomFactor:1.0 withRate:10];
        }
    }];
}
//更改设备属性前一定要上锁
- (void)changeDeviceProperty:(void (^)(AVCaptureDevice *captureDevice))propertyChange
{
    AVCaptureDevice *captureDevice = [_videoInput device];
    NSError *error;
    BOOL lock = [captureDevice lockForConfiguration:&error];
    if (!lock) {
        NSLog(@"锁定出错：%@",error.localizedDescription);
    }else{
        [_captureSession beginConfiguration];
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
        [_captureSession commitConfiguration];
    }
}

/**
 *  初始化导航栏返回按钮
 */
-(void)setUpUI
{
    UIBarButtonItem *backBtn=[[UIBarButtonItem alloc]initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    self.navigationItem.leftBarButtonItem=backBtn;
}


#pragma mark 触摸事件
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{

    if([touches anyObject].view == self.recordBtn){
        [self changeCancelLabelCondition:YES];
        [self startAnimation];
        self.changeOrientationBtn.hidden = self.flashBtn.hidden = YES;
    }
}
-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point  = [touch locationInView:self.recordBtn.superview];
    if(CGRectContainsPoint(self.recordBtn.frame, point)){
       [self changeCancelLabelCondition:YES];
    }else{
        
       [self changeCancelLabelCondition:NO];
    }
}
-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{

    if([touches anyObject].view == self.recordBtn){
        if (self.progressWidth.constant < SCREEN_WIDTH * 0.67) {
            //录制完成
            NSLog(@"录制完成！");
            [self endAnimation];
           
            //保存视频
            [self saveVideo:^(NSURL *outFileURL) {
               
                _assetWriterVideoInput = nil;
                _assetWriterAudioInput = nil;
                _assetWriterInputPixelBufferAdaptor = nil;
                //退出当前控制器
                if (self.getVideoURL) {
                    self.getVideoURL(_outURL);
                }
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
            
        }else{
            NSLog(@"录制时间短，取消录制！");
            [self endAnimation];
             self.progressWidth.constant = SCREEN_WIDTH;
            //删除保存的视频
            [VideoSaveConfig deleteVideo:_outURL];
            
        }
    }
    
 
    [self changeCancelLabelCondition:YES];
    self.changeOrientationBtn.hidden = self.flashBtn.hidden = NO;
}
- (CADisplayLink *)link
{
    if (!_link) {
        _link = [CADisplayLink displayLinkWithTarget:self selector:@selector(refresh:)];
        self.progressWidth.constant = [UIScreen mainScreen].bounds.size.width;
        //开始录制
        NSURL *outURL = [NSURL fileURLWithPath:[VideoSaveConfig createNewVideo]];
        _outURL        = outURL;
        [self createWriter:outURL];
        _recoding = YES;
    }
    return _link;
}
- (void)refresh:(CADisplayLink *)link
{
    if (self.progressWidth.constant <= 0) {
        self.progressWidth.constant = 0;
        NSLog(@"录制完成！！");
        //录制完成
        [self endAnimation];
        //保存视频
       
        [self saveVideo:^(NSURL *outFileURL) {
            
            _assetWriterVideoInput = nil;
            _assetWriterAudioInput = nil;
            _assetWriterInputPixelBufferAdaptor = nil;
            //退出当前控制器
            if (self.getVideoURL) {
                self.getVideoURL(_outURL);
            }
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        return;
    }
    self.progressWidth.constant -= kTrans;
}
- (void)stopLink
{
    _link.paused = YES;
    [_link invalidate];
    _link        = nil;
}
- (void)startAnimation
{
    if (self.status == VideoStatusEnded) {
        self.status = VideoStatusStart;
        [_captureSession startRunning];
        [self stopLink];
        [self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.recordBtn.transform = CGAffineTransformMakeScale(1.5, 1.5);
        } completion:^(BOOL finished) {
            
        }];
    }
}
- (void)endAnimation
{
    if (self.status == VideoStatusStart) {
        self.status = VideoStatusEnded;
        self.recordBtn.transform = CGAffineTransformIdentity;
        [self stopLink];//关闭定时器
        //录制完成了
        _recoding = NO;
        [_captureSession stopRunning];
    }
}
- (void)saveVideo:(void (^)(NSURL *outFileURL))complier{
    if (_recoding) {//如果还在录制状态下不保存
        return;
    }
    if(!_recoding_queue){
        complier(nil);
        return;
    }
    dispatch_async(_recoding_queue, ^{
        [_assetWriter finishWritingWithCompletionHandler:^{
             _assetWriter = nil;
            [VideoSaveConfig saveThumImageWithVideoURL:_outURL second:1];
            if (complier) {
                complier(_outURL);
            }
        }];
    });
}
- (void)createWriter:(NSURL *)assetUrl{
    _assetWriter = [AVAssetWriter assetWriterWithURL:assetUrl fileType:AVFileTypeMPEG4 error:nil];
    int videoWidthpx = dlgVideoWidthPx;
    int videoHeightpx  = dlgVideoHeightPx;
    //码率和帧率的设置
    //视频码率就是数据传输时单位时间传送的数据位数，一般我们用的单位是kbps即千位每秒(决定生成视频的大小)
    NSDictionary *compressionProperties = @{ AVVideoAverageBitRateKey : @(500000),
                                             AVVideoExpectedSourceFrameRateKey :@(30),
                                             AVVideoAverageBitRateKey : @(30)};
    NSDictionary *outputSettings        = @{
                                             AVVideoCodecKey : AVVideoCodecH264,
                                             AVVideoWidthKey : @(videoHeightpx),
                                             AVVideoHeightKey: @(videoWidthpx),
                                             AVVideoScalingModeKey:AVVideoScalingModeResizeAspectFill,
                                             AVVideoCompressionPropertiesKey :compressionProperties
                                             };
    _assetWriterVideoInput              = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:outputSettings];
    _assetWriterVideoInput.expectsMediaDataInRealTime = YES;
    _assetWriterVideoInput.transform = CGAffineTransformMakeRotation(M_PI /2.0);//旋转90度。
    
    
    NSDictionary *audioOutputSettings = @{
                                          AVFormatIDKey:@(kAudioFormatMPEG4AAC),
                                          AVSampleRateKey:@(8000),
                                          AVNumberOfChannelsKey:@(2),
                                          };
    _assetWriterAudioInput            = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings];
    _assetWriterAudioInput.expectsMediaDataInRealTime = YES;
    
    NSDictionary *AWIBA = @{
                             (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
                            (__bridge NSString *)kCVPixelFormatOpenGLESCompatibility : ((__bridge NSNumber *)kCFBooleanTrue)
                            };

//     NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
    _assetWriterInputPixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_assetWriterVideoInput sourcePixelBufferAttributes:AWIBA];
    
    if ([_assetWriter canAddInput:_assetWriterVideoInput]) {
        [_assetWriter addInput:_assetWriterVideoInput];
    }else{
        NSLog(@"添加视频_assetWriterVideoInput失败");
    }
    if([_assetWriter canAddInput:_assetWriterAudioInput]){
        [_assetWriter addInput:_assetWriterAudioInput];
    }else{
        NSLog(@"添加音频_assetWriterAudioInput失败");
    }
    
}

#pragma mark -AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
    if (!_recoding) {
        return;
    }
    @autoreleasepool {
        _currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
        if (_assetWriter.status != AVAssetWriterStatusWriting) {
            [_assetWriter startWriting];
            [_assetWriter startSessionAtSourceTime:_currentSampleTime];
        }
        //视频输出
        if (captureOutput == _videoDataOutput) {
            if (_assetWriterInputPixelBufferAdaptor.assetWriterInput.isReadyForMoreMediaData) {
                CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
                BOOL success = [_assetWriterInputPixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:_currentSampleTime];
                if (!success) {
                    NSLog(@"_assetWriterInputPixelBufferAdaptor没有Append成功");
                }
            }
        }
        //音频输出
        if(captureOutput == _audioDataOutput){
            [_assetWriterAudioInput appendSampleBuffer:sampleBuffer];
        }
    }
}

-(void)goBack
{
    [_captureSession stopRunning];
    [self dismissViewControllerAnimated:YES completion:nil];
    
}




@end
