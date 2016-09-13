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
    return [SODownloader downloaderWithIdentifier:@"music" completeBlock:^(id<SODownloadItem>  _Nonnull item, NSURL * _Nonnull location) {
        SODebugLog(@"Download %@ complete!", item);
    }];
}

@end
