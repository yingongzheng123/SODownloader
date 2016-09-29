//
//  SODownloader+MusicDownloader.m
//  SODownloadExample
//
//  Created by scfhao on 16/9/9.
//  Copyright © 2016年 http://scfhao.coding.me. All rights reserved.
//

#import "SODownloader+MusicDownloader.h"
#import "SOLog.h"

@implementation SODownloader (MusicDownloader)

+ (instancetype)musicDownloader {
    static SODownloader *downloader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloader = [[SODownloader alloc]initWithIdentifier:@"music" completeBlock:^(id<SODownloadItem>  _Nonnull item, NSURL * _Nonnull location) {
            SODebugLog(@"%@ 下载成功！%@", item, location);
            // 这个block每下载成功一个文件时被调用，这个block在后台线程中调用，不建议在这里做更新UI的操作
            // 你可以在这里对下载成功做特别的处理，例如：
            // 1. 把下载完成的 item 的信息存入数据库
            // 2. 把下载完成的文件从 location 位置移动到你想要保存到的文件夹
            // 3. 其他处理，如解析下载文件等
        }];
    });
    return downloader;
}

@end
