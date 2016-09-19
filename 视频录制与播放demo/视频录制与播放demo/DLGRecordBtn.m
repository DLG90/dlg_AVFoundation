//
//  DLGRecordBtn.m
//  视频录制与播放demo
//
//  Created by DLG on 16/9/18.
//  Copyright © 2016年 DLG. All rights reserved.
//

#import "DLGRecordBtn.h"
#define btnColor       [UIColor greenColor]
@implementation DLGRecordBtn

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        self.layer.cornerRadius     = self.bounds.size.width/2;
        self.layer.masksToBounds    = YES;
        self.userInteractionEnabled = YES;
        [self setRecordBtn];
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder: aDecoder];
    if (!self) {
        return nil;
    }
    self.layer.cornerRadius     = self.bounds.size.width/2;
    self.layer.masksToBounds    = YES;
    self.userInteractionEnabled = YES;
    [self setRecordBtn];
    return self;
}
- (void)setRecordBtn{
    self.backgroundColor = [UIColor clearColor];
    CGFloat width        = self.frame.size.width;
    UIBezierPath *path   = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:width/2];
    CAShapeLayer *trackLayer = [CAShapeLayer layer];
    trackLayer.frame         = self.bounds;
    trackLayer.strokeColor   = btnColor.CGColor;
    trackLayer.fillColor     = [UIColor clearColor].CGColor;
    trackLayer.opacity       = 1.0;//不透明度
    trackLayer.lineCap       = kCALineCapRound;
    trackLayer.lineWidth     = 2.0;
    trackLayer.path          = path.CGPath;
    [self.layer addSublayer:trackLayer];
    
    CATextLayer *textLayer   = [CATextLayer layer];
    textLayer.string         = @"按住拍";
    textLayer.frame          = CGRectMake(0, 0, 120, 30);
    textLayer.position       = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    UIFont *font             = [UIFont boldSystemFontOfSize:20];
    CFStringRef fontName     = (__bridge CFStringRef)(font.fontName);
    CGFontRef fontRef        = CGFontCreateWithFontName(fontName);
    textLayer.font           = fontRef;
    textLayer.fontSize       = font.pointSize;
    CGFontRelease(fontRef);
    textLayer.contentsScale  = [UIScreen mainScreen].scale;
    textLayer.foregroundColor = btnColor.CGColor;
    textLayer.alignmentMode   = kCAAlignmentCenter;
    textLayer.wrapped         = YES;
    [trackLayer addSublayer:textLayer];
    
    CAGradientLayer *gradLayer = [CAGradientLayer layer];
    gradLayer.frame            =  self.bounds;
    gradLayer.colors           = [self gradualColors];
    [self.layer addSublayer:gradLayer];
    gradLayer.mask             = trackLayer;
    
    
}
- (NSArray *)gradualColors {
    return @[(__bridge id)[UIColor greenColor].CGColor,(__bridge id)[UIColor yellowColor].CGColor,];
}
@end
