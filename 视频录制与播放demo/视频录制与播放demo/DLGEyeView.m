//
//  DLGEyeView.m
//  视频录制与播放demo
//
//  Created by DLG on 16/9/18.
//  Copyright © 2016年 DLG. All rights reserved.
//

#import "DLGEyeView.h"
typedef struct eyePath{
    CGMutablePathRef strokePath;//空心路径
    CGMutablePathRef fillPath;//实心路径
}DLGEyePath;

@implementation DLGEyeView
- (instancetype)initWithFrame:(CGRect)frame{
    if (self=[super initWithFrame:frame]) {
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.9];
        [self setupSubView];
    }
    return self;
}
- (void)setupSubView{
    UIToolbar *bar = [[UIToolbar alloc]initWithFrame:self.bounds];
    [bar setBarStyle:UIBarStyleBlackTranslucent];
    bar.clipsToBounds = YES;
    [self addSubview:bar];

    UIView *view = [[UIView alloc]initWithFrame:self.bounds];
    view.backgroundColor = [UIColor clearColor];
    [self addSubview:view];
    
    DLGEyePath path = createEyePath(self.bounds);
    UIColor *color  = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.9];
    
    CAShapeLayer *shapelayer1 = [CAShapeLayer layer];
    shapelayer1.frame = self.bounds;
    shapelayer1.strokeColor = color.CGColor;
    shapelayer1.fillColor = [UIColor clearColor].CGColor;
    shapelayer1.opaque    = 1.0;
    shapelayer1.lineCap   = kCALineCapRound;
    shapelayer1.lineWidth = 1.0;
    shapelayer1.path      = path.strokePath;
    [view.layer addSublayer:shapelayer1];
    
    CAShapeLayer *shapelayer2   = [CAShapeLayer layer];
    shapelayer2.frame           = self.bounds;
    shapelayer2.strokeColor     = color.CGColor;
    shapelayer2.fillColor       = color.CGColor;
    shapelayer2.opacity         = 1.0;
    shapelayer2.lineCap         = kCALineCapRound;
    shapelayer2.lineWidth       = 1.0;
    shapelayer2.path            = path.fillPath;
    [view.layer addSublayer:shapelayer2];
    DLGEyePathRelease(path);
    
}
//通过quarzt2d中带有creat/copy/retain方法创建出来的值都必须手动的释放
void DLGEyePathRelease(DLGEyePath path){
    CGPathRelease(path.fillPath);
    CGPathRelease(path.strokePath);
}
DLGEyePath createEyePath(CGRect rect){
    CGPoint selfCent = CGPointMake(CGRectGetWidth(rect)/2, CGRectGetHeight(rect)/2);
    CGFloat eyeWidth = 64.0;
    CGFloat eyeHeight = 40.0;
    CGFloat curvectrH = 44;//曲线的高度
    
    CGAffineTransform transform = CGAffineTransformMakeScale(1.0, 1.0);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, &transform, selfCent.x - eyeWidth/2, selfCent.y);
    CGPathAddQuadCurveToPoint(path, &transform, selfCent.x, selfCent.y - curvectrH, selfCent.x + eyeWidth/2, selfCent.y);//画二次曲线
    CGPathAddQuadCurveToPoint(path, &transform, selfCent.x, selfCent.y + curvectrH, selfCent.x - eyeWidth/2, selfCent.y);
    CGFloat arcRadius = eyeHeight/2 -1;
    CGPathMoveToPoint(path, &transform, selfCent.x + arcRadius, selfCent.y);
    CGPathAddArc(path, &transform, selfCent.x, selfCent.y, arcRadius, 0, M_PI *2, false);//画中心圆
    
    CGFloat startAngle = 100;
    CGFloat angle1     = startAngle + 30;
    CGFloat angle2     = angle1 + 20;
    CGFloat angle3     = angle2 + 10;
    
    CGFloat arcRadius2 = arcRadius - 4;
    CGFloat arcRadius3 = arcRadius2 - 7;
    
    CGMutablePathRef path2 = createRingPath(selfCent, angleTransformRadian(startAngle), angleTransformRadian(angle1), arcRadius2, arcRadius3, &transform);
    CGMutablePathRef path3 = createRingPath(selfCent, angleTransformRadian(angle2), angleTransformRadian(angle3), arcRadius2, arcRadius3, &transform);
    CGPathAddPath(path2, NULL, path3);
    
    CGPathRelease(path3);
    
    return (DLGEyePath){path,path2};
}
//角度转弧度
CGFloat angleTransformRadian(CGFloat angle)
{
    return angle/180.0*M_PI;
}
/**
 *  创建圆环路径
 *
 *  @param center      圆环的中心点
 *  @param startAngle  开始角度
 *  @param endAngle    结束角度
 *  @param bigRadius   圆环的外半径
 *  @param smallRadius 圆环的内半径
 *  @param transform   路径的形变参数
 *
 *  @return CGMutablePathRef
 */
CGMutablePathRef createRingPath(CGPoint center, CGFloat startAngle,CGFloat endAngle,CGFloat bigRadius, CGFloat smallRadius, CGAffineTransform *transform){
    CGFloat arcStart = M_PI*2 - startAngle;
    CGFloat arcEnd   = M_PI*2 - endAngle;
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, transform, center.x + bigRadius *cos(startAngle), center.y - bigRadius *sin(startAngle));
    CGPathAddArc(path, transform, center.x, center.y, bigRadius, arcStart, arcEnd, true);
    CGPathAddLineToPoint(path, transform, center.x + smallRadius *cos(endAngle), center.y - smallRadius *sin(endAngle));
    CGPathAddArc(path, transform, center.x, center.y, smallRadius, arcEnd, arcStart, false);
    CGPathAddLineToPoint(path, transform, center.x + bigRadius *cos(startAngle), center.y -bigRadius *sin(startAngle));
    return path;
}
@end
