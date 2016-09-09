//
//  SODownloader+MusicDownloader.m
//  SODownloadExample
//
//  Created by scfhao on 16/9/9.
//  Copyright © 2016年 http://scfhao.coding.me. All rights reserved.
//

#import "SODownloader+MusicDownloader.h"

@implementation SODownloader (MusicDownloader)

+ (instancetype)musicDownloader {
    static SODownloader *downloader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloader = [[SODownloader alloc]initWithIdentifier:@"music" completeBlock:^(id<SODownloadItem>  _Nonnull item, NSURL * _Nonnull location) {
            
        }];
    });
    return downloader;
}

@end
