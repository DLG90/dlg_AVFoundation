//
//  VideoSaveConfig.h
//  视频录制与播放demo
//
//  Created by DLG on 16/9/19.
//  Copyright © 2016年 DLG. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VideoSaveConfig : NSObject
+ (NSString *)createNewVideo;
+ (void)deleteVideo:(id)videoPath;
+ (void)saveThumImageWithVideoURL:(NSURL *)videoUrl second:(int64_t)second;
@end
