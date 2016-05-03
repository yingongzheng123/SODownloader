//
//  SODownloadItem.m
//  SODownloadExample
//
//  Created by xueyi on 16/5/3.
//  Copyright © 2016年 http://scfhao.coding.me. All rights reserved.
//

#import "SODownloadItem.h"

@implementation SODownloadItem
@synthesize downloadProgress = _downloadProgress;

- (NSURL *)downloadURL {
    NSLog(@"[SODownloader]:Your download item class must implements -(NSURL *)downloadURL method declare in protocol SODownloadItem");
    abort();
}

- (NSUInteger)hash {
    NSLog(@"[SODownloader]:Your download item must implements -(NSInteger)hash method to avoid download an item twice.");
    abort();
}

- (BOOL)isEqual:(id)object {
    NSLog(@"[SODownloader]:Your download item must implements -(BOOL)isEqual:(id)object method to avoid download an item twice.");
    abort();
}

@end
