//
//  AppDelegate+SODownloader.m
//  SODownloadExample
//
//  Created by scfhao on 16/9/12.
//  Copyright © 2016年 http://scfhao.coding.me. All rights reserved.
//

#import "AppDelegate+SODownloader.h"
#import "SODownloader+MusicDownloader.h"
#import "SOLog.h"

@implementation AppDelegate (SODownloader)

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
    if ([identifier isEqualToString:@"music"]) {
        SODownloader *downloader = [SODownloader musicDownloader];
        [downloader setDidFinishEventsForBackgroundURLSessionBlock:^(NSURLSession * _Nonnull session) {
            completionHandler();
        }];
    }
}

@end
