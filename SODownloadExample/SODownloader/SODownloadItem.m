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
@synthesize downloadProgress = _downloadProgress;
@synthesize downloadState = _downloadState;

- (NSURL *)downloadURL {
    SOWarnLog(@"[SODownloader]:Your download item class must implements -(NSURL *)downloadURL method declare in protocol SODownloadItem");
    abort();
}

- (NSUInteger)hash {
    SOWarnLog(@"[SODownloader]:Your download item must implements -(NSInteger)hash method to avoid download an item twice.");
    abort();
}

- (BOOL)isEqual:(id)object {
    SOWarnLog(@"[SODownloader]:Your download item must implements -(BOOL)isEqual:(id)object method to avoid download an item twice.");
    abort();
}

@end
