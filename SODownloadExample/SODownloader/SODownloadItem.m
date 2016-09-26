//
//  SODownloadItem.m
//  SODownloadExample
//
//  Created by scfhao on 16/5/3.
//  Copyright © 2016年 http://scfhao.coding.me. All rights reserved.
//

#import "SODownloadItem.h"
#import "SOLog.h"

@implementation SODownloadItem
@synthesize so_downloadState, so_downloadProgress;

- (NSURL *)downloadURL {
    SOWarnLog(@"[SODownloader]:Your download item class must implements -(NSURL *)downloadURL method declare in protocol SODownloadItem");
    abort();
}

@end
