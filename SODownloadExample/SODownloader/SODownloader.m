//
//  SODownloader.m
//  SODownloadExample
//
//  Created by xueyi on 16/5/3.
//  Copyright © 2016年 http://scfhao.coding.me. All rights reserved.
//

#import "SODownloader.h"
#import "SODownloadItem.h"

@interface SODownloadTask : NSObject

@property (strong, nonatomic) NSUUID *identifier;
@property (strong, nonatomic) NSString *URLIdentifier;
@property (strong, nonatomic) NSURLSessionDownloadTask *task;
@property (strong, nonatomic) NSProgress *downloadProgress;

@end

@implementation SODownloadTask

@end

@interface SODownloader ()<NSURLSessionDelegate>

@property (nonatomic, assign) NSInteger     maxConcurrentDownloadsCount;
@property (nonatomic, assign) NSInteger     activeDownloadsCount;

@property (nonatomic, strong) NSURLSession *downloadSession;
@property (nonatomic, strong) NSMutableArray *itemsToDownload;

@property (nonatomic, strong) NSMutableDictionary *taskDictionary;

@property (nonatomic, strong) dispatch_queue_t synchronousQueue;
@property (nonatomic, strong) dispatch_queue_t responseQueue;

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

- (NSURLSession *)defaultDownloadSession {
    NSOperationQueue *delegateQueue = [[NSOperationQueue alloc]init];
    delegateQueue.maxConcurrentOperationCount = 1;
    return [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:delegateQueue];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.taskDictionary = [NSMutableDictionary dictionary];
        
        NSURLSession *downloadSession = [self defaultDownloadSession];
        self.downloadSession = downloadSession;
        
        NSString *name = [NSString stringWithFormat:@"cn.scfhao.downloader.synchronousQueue-%@", [NSUUID UUID].UUIDString];
        self.synchronousQueue = dispatch_queue_create([name cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
        
        name = [NSString stringWithFormat:@"cn.scfhao.downloader.responseQueue-%@", [NSUUID UUID].UUIDString];
        self.responseQueue = dispatch_queue_create([name cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (SODownloadTask *)downloadItem:(id<SODownloadItem>)item {
    __block SODownloadTask *task = nil;
    dispatch_sync(self.responseQueue, ^{
        NSAssert(item.downloadURL, @"downloadURL property of SODownloadItem cant be nil!");
        NSString *URLIdentifier = [item.downloadURL absoluteString];
        
    });
    return task;
}

- (BOOL)canStartNewDownloads {
    return self.activeDownloadsCount < self.maxConcurrentDownloadsCount;
}



@end
