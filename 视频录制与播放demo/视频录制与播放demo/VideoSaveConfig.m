//
//  VideoSaveConfig.m
//  视频录制与播放demo
//
//  Created by DLG on 16/9/19.
//  Copyright © 2016年 DLG. All rights reserved.
//

#import "VideoSaveConfig.h"
#import <AVFoundation/AVFoundation.h>
#define  dlgVideoDicName      @"SmallVideo"
@implementation VideoSaveConfig

//保存缩略图
+ (void)saveThumImageWithVideoURL:(NSURL *)videoUrl second:(int64_t)second {
    AVURLAsset *urlSet = [AVURLAsset assetWithURL:videoUrl];
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlSet];
    
    CMTime time = CMTimeMake(second, 10);
    NSError *error = nil;
    CGImageRef cgimage = [imageGenerator copyCGImageAtTime:time actualTime:nil error:&error];
    if (error) {
        NSLog(@"缩略图获取失败!:%@",error);
        return;
    }
    UIImage *image = [UIImage imageWithCGImage:cgimage scale:0.6 orientation:UIImageOrientationRight];
    NSData *imgData = UIImageJPEGRepresentation(image, 1.0);
    NSString *videoPath = [videoUrl.absoluteString stringByReplacingOccurrencesOfString:@"file://" withString: @""];
    NSString *thumPath = [videoPath stringByReplacingOccurrencesOfString:@"MOV" withString: @"JPG"];
    BOOL isok = [imgData writeToFile:thumPath atomically: YES];
    NSLog(@"缩略图获取结果:%d",isok);
    CGImageRelease(cgimage);
}
+ (NSString *)createNewVideo{
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    formatter.dateFormat  = @"yyyy-MM-dd_HH:mm:ss";
    NSString *videoName   = [formatter stringFromDate:currentDate];
    NSString *videoPath   = [self getDocumentSubPath:dlgVideoDicName];
    
    NSString * str        = [videoPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.MOV",videoName]];
    return str;
}
+ (void)deleteVideo:(NSString *)videoPath{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError       *error       = nil;
    [fileManager removeItemAtPath:videoPath error:&error];
    if (error) {
        NSLog(@"删除视频失败：%@",error);
    }
}
+ (NSString *)getDocumentSubPath:(NSString *)dir{
    NSString *document = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    return [document stringByAppendingPathComponent:dir];
}
+ (void)initialize{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString      *dirPath     = [self getDocumentSubPath:dlgVideoDicName];
    NSError       *error       =  nil;
    [fileManager createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:&error];
    if (error) {
        NSLog(@"创建文件夹失败：%@",error);
    }
}
@end
