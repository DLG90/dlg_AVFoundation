//
//  DLGFocusView.m
//  视频录制与播放demo
//
//  Created by DLG on 16/9/16.
//  Copyright © 2016年 DLG. All rights reserved.
//

#import "DLGFocusView.h"
#define FocusColor [UIColor greenColor]
@implementation DLGFocusView
{
    CGFloat _width;
    CGFloat _height;
}
-(instancetype)initWithFrame:(CGRect)frame{
    if (self=[super initWithFrame:frame]) {
        _width=CGRectGetWidth(frame);
        _height=_width;
        self.backgroundColor=[UIColor clearColor];
    }
    return self;
}
-(void)focusing{
    self.alpha=1.0;
    [UIView animateWithDuration:0.5 animations:^{
        self.transform=CGAffineTransformScale(CGAffineTransformIdentity, 0.8, 0.8);
        
    }completion:^(BOOL finished) {
        self.transform=CGAffineTransformIdentity;
        [UIView animateWithDuration:0.5 animations:^{
            self.alpha=0.0;
        }];
    }];
}
-(void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    CGContextRef context=UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context,  FocusColor.CGColor);
    CGContextSetLineWidth(context, 1.0);
    
    CGContextMoveToPoint(context, 0.0, 0.0);
    CGContextAddRect(context, self.bounds);
    
    CGFloat len=5;
    
    CGContextMoveToPoint(context, 0, _height/2);
    CGContextAddLineToPoint(context, len, _height/2);
    
    CGContextMoveToPoint(context, _width/2, 0);
    CGContextAddLineToPoint(context, _width/2, len);
    
    CGContextMoveToPoint(context, _width, _height/2);
    CGContextAddLineToPoint(context, _width-len, _height/2);
    
    CGContextMoveToPoint(context, _width/2, _height);
    CGContextAddLineToPoint(context, _width/2, _height-len);
    
    CGContextDrawPath(context, kCGPathStroke);
    
    
}
@end
