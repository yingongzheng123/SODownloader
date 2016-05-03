//
//  SODownloader.m
//  SODownloadExample
//
//  Created by xueyi on 16/5/3.
//  Copyright © 2016年 http://scfhao.coding.me. All rights reserved.
//

#import "SODownloader.h"

@interface SODownloader ()<NSURLSessionDownloadDelegate>

@property (nonatomic, assign) NSInteger     maxConcurrentDownloadsCount;
@property (nonatomic, assign) NSInteger     activeDownloadsCount;

@property (nonatomic, strong) NSURLSession *downloadSession;
@property (nonatomic, strong) NSMutableArray *itemsToDownload;

@property (nonatomic, strong) dispatch_queue_t synchronousQueue;

@end

@implementation SODownloader

+ (instancetype)sharedDownloader {
    static SODownloader *downloader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloader = nil;
    });
    return downloader;
}

+ (NSURLSession *)defaultDownloadSession {
    NSOperationQueue *delegateQueue = [[NSOperationQueue alloc]init];
    delegateQueue.maxConcurrentOperationCount = 1;
    return [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:delegateQueue];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSURLSession *downloadSession = [[self class]defaultDownloadSession];
        self.downloadSession = downloadSession;
        
        
    }
    return self;
}

- (BOOL)canStartNewDownloads {
    return self.activeDownloadsCount < self.maxConcurrentDownloadsCount;
}

@end
