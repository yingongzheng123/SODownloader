//
//  SODownloader.m
//  SOMoviePlayerDemo
//
//  Created by scfhao on 16/6/17.
//  Copyright © 2016年 Phoenix E-Learning. All rights reserved.
//

#import "SODownloader.h"
#import <CommonCrypto/CommonDigest.h>
#import "SOLog.h"

@interface SODownloader ()

/// 当前下载数
@property (nonatomic, assign) NSInteger activeRequestCount;

@property (nonatomic, strong) NSMutableDictionary *tasks;
@property (nonatomic, strong) NSMutableArray *downloadArray;
@property (nonatomic, strong) NSMutableArray *completeArray;


@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
@property (nonatomic, strong) dispatch_queue_t synchronizationQueue;
@property (nonatomic, strong) dispatch_queue_t responseQueue;

// paths
@property (nonatomic, strong) NSString *downloaderPath;

// complete block
@property (nonatomic, copy) SODownloadCompleteBlock_t completeBlock;

@end

@interface SODownloader (DownloadPath)

- (void)createPath;
- (NSString *)tempPathForItem:(id<SODownloadItem>)item;
- (void)saveResumeData:(NSData *)resumeData forItem:(id<SODownloadItem>)item;
- (void)removeTempDataForItem:(id<SODownloadItem>)item;
- (NSData *)tempDataForItem:(id<SODownloadItem>)item;

@end

@implementation SODownloader

- (instancetype)initWithIdentifier:(NSString *)identifier completeBlock:(SODownloadCompleteBlock_t)completeBlock {
    self = [super init];
    if (self) {
        NSString *queueLabel = [NSString stringWithFormat:@"cn.scfhao.downloader.synchronizationQueue-%@", [NSUUID UUID].UUIDString];
        self.synchronizationQueue = dispatch_queue_create([queueLabel UTF8String], DISPATCH_QUEUE_SERIAL);
        
        queueLabel = [NSString stringWithFormat:@"cn.scfhao.downloader.responseQueue-%@", [NSUUID UUID].UUIDString];
        self.responseQueue = dispatch_queue_create([queueLabel UTF8String], DISPATCH_QUEUE_CONCURRENT);
        
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.sessionManager = [[AFHTTPSessionManager alloc]initWithSessionConfiguration:sessionConfiguration];
        
        self.downloaderIdentifier = identifier;
        self.completeBlock = completeBlock;
        self.maximumActiveDownloads = 1;
        self.downloaderPath = [NSTemporaryDirectory() stringByAppendingPathComponent:self.downloaderIdentifier];
        
        self.tasks = [[NSMutableDictionary alloc]init];
        self.downloadArray = [[NSMutableArray alloc]init];
        self.completeArray = [[NSMutableArray alloc]init];
        
        [self createPath];
    }
    return self;
}

#pragma mark - Public APIs - Download Control
// 下载管理
/// 下载
- (void)downloadItem:(id<SODownloadItem>)item {
    NSAssert(item.downloadState == SODownloadStateNormal, @"SODownloader只下载Normal状态的item");
    dispatch_sync(self.synchronizationQueue, ^{
        if (item.downloadState == SODownloadStateNormal) {
            [self.downloadArray addObject:item];
            item.downloadState = SODownloadStateWait;
            if ([self isActiveRequestCountBelowMaximumLimit]) {
                [self startDownloadItem:item];
            }
        }
    });
}

- (void)downloadItems:(NSArray<SODownloadItem>*)items {
    for (id<SODownloadItem>item in items) {
        [self downloadItem:item];
    }
}

/// 暂停
- (void)pauseItem:(id<SODownloadItem>)item {
    dispatch_sync(self.synchronizationQueue, ^{
        if (item.downloadState == SODownloadStateLoading || item.downloadState == SODownloadStateWait) {
            if (item.downloadState == SODownloadStateLoading) {
                NSURLSessionDownloadTask *downloadTask = [self downloadTaskForItem:item];
                [downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                    [self saveResumeData:resumeData forItem:item];
                }];
            }
            item.downloadState = SODownloadStatePaused;
        }
    });
}

- (void)pauseAll {
    for (id<SODownloadItem>item in self.downloadArray) {
        [self pauseItem:item];
    }
}

/// 继续
- (void)resumeItem:(id<SODownloadItem>)item {
    dispatch_sync(self.synchronizationQueue, ^{
        if (item.downloadState == SODownloadStatePaused) {
            if ([self isActiveRequestCountBelowMaximumLimit]) {
                [self startDownloadItem:item];
            } else {
                item.downloadState = SODownloadStateWait;
            }
        }
    });
}

- (void)resumeAll {
    for (id<SODownloadItem>item in self.downloadArray) {
        [self resumeItem:item];
    }
}

/// 取消／删除
- (void)cancelItem:(id<SODownloadItem>)item {
    dispatch_sync(self.synchronizationQueue, ^{
        if (item.downloadState == SODownloadStateLoading || item.downloadState == SODownloadStateWait) {
            if (item.downloadState == SODownloadStateLoading) {
                NSURLSessionDownloadTask *downloadTask = [self downloadTaskForItem:item];
                [downloadTask cancel];
            }
            item.downloadState = SODownloadStateNormal;
            [self.downloadArray removeObject:item];
        }
    });
}

- (void)cancenAll {
    for (id<SODownloadItem>item in self.downloadArray) {
        [self cancelItem:item];
    }
}

- (void)setDownloadState:(SODownloadState)state forItem:(id<SODownloadItem>)item {
    switch (state) {
        case SODownloadStateNormal:
        {
            if ([self.downloadArray containsObject:item]) {
                [self cancelItem:item];
            }
        }
            break;
        case SODownloadStateWait:
        {
            if (item.downloadState == SODownloadStateNormal) {
                [self downloadItem:item];
            } else if (item.downloadState == SODownloadStateError) {
                item.downloadState = SODownloadStateWait;
                [self safelyStartNextTaskIfNecessary];
            }
        }
            break;
        case SODownloadStateLoading:
        {
            [self resumeItem:item];
        }
            break;
        case SODownloadStatePaused:
        {
            [self pauseItem:item];
        }
            break;
        case SODownloadStateComplete:
        {
            if ([self.downloadArray containsObject:item]) {
                [self cancelItem:item];
            }
            item.downloadState = state;
            [self.completeArray addObject:item];
        }
            break;
        case SODownloadStateError:
            // 没这个必要
            break;
        default:
            break;
    }
}

#pragma mark -
/// 开始下载一个item，这个方法必须在同步线程中调用，且调用前必须先判断是否可以开始新的下载
- (void)startDownloadItem:(id<SODownloadItem>)item {
    item.downloadState = SODownloadStateLoading;
    NSString *URLIdentifier = [item.downloadURL absoluteString];
    
    NSURLSessionDownloadTask *existingDownloadTask = self.tasks[URLIdentifier];
    if (existingDownloadTask) {
        return ;
    }
    NSURLSessionDownloadTask *downloadTask = nil;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URLIdentifier]];
    if (!request) {
        NSError *URLError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil];
        SOErrorLog(@"SODownload fail %@", URLError);
        // TODO: 下载失败进行处理
        item.downloadState = SODownloadStateError;
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    // 创建下载完成的回调
    void (^completeBlock)(NSURLResponse *response, NSURL *filePath, NSError *error) = ^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        dispatch_async(self.responseQueue, ^{
            __strong __typeof__(weakSelf) strongSelf = weakSelf;
            if (error) {
                // TODO: 对下载失败进行处理，注意取消的情况（取消／删除）
                item.downloadState = SODownloadStateError;
            } else {
                item.downloadState = SODownloadStateComplete;
                [self.downloadArray removeObject:item];
                [self.completeArray addObject:item];
                strongSelf.completeBlock ?: strongSelf.completeBlock(item, filePath);
            }
            [strongSelf safelyRemoveTaskInfoForItem:item];
            [strongSelf safelyDecrementActiveTaskCount];
            [strongSelf safelyStartNextTaskIfNecessary];
        });
    };
    void (^progressBlock)(NSProgress *downloadProgress) = ^(NSProgress *downloadProgress) {
        item.downloadProgress = downloadProgress.fractionCompleted;
    };
    // 创建task
    NSData *tempData = [self tempDataForItem:item];
    if (tempData) {
        downloadTask = [self.sessionManager downloadTaskWithResumeData:tempData progress:progressBlock destination:nil completionHandler:completeBlock];
    } else {
        downloadTask = [self.sessionManager downloadTaskWithRequest:request progress:progressBlock destination:nil completionHandler:completeBlock];
    }
    [self startDownloadTask:downloadTask forItem:item];
    SODebugLog(@"启动下载（%li）%@", self.activeRequestCount, URLIdentifier);
}

- (void)startDownloadTask:(NSURLSessionDownloadTask *)downloadTask forItem:(id<SODownloadItem>)item {
    self.tasks[[item.downloadURL absoluteString]] = downloadTask;
    [downloadTask resume];
    ++self.activeRequestCount;
}

- (NSURLSessionDownloadTask *)downloadTaskForItem:(id<SODownloadItem>)item {
    return self.tasks[[item.downloadURL absoluteString]];
}

- (void)safelyRemoveTaskInfoForItem:(id<SODownloadItem>)item {
    dispatch_sync(self.synchronizationQueue, ^{
        [self.tasks removeObjectForKey:[item.downloadURL absoluteString]];
    });
}

- (void)safelyDecrementActiveTaskCount {
    dispatch_sync(self.synchronizationQueue, ^{
        if (self.activeRequestCount > 0) {
            self.activeRequestCount -= 1;
        }
    });
}

- (void)safelyStartNextTaskIfNecessary {
    dispatch_sync(self.synchronizationQueue, ^{
        for (id<SODownloadItem>item in self.downloadArray) {
            if (item.downloadState == SODownloadStateWait && [self isActiveRequestCountBelowMaximumLimit]) {
                [self downloadItem:item];
            }
        }
    });
}

- (BOOL)isActiveRequestCountBelowMaximumLimit {
    return self.activeRequestCount < self.maximumActiveDownloads;
}

- (void)setMaximumActiveDownloads:(NSInteger)maximumActiveDownloads {
    dispatch_sync(self.synchronizationQueue, ^{
        _maximumActiveDownloads = maximumActiveDownloads;
    });
}

@end

@implementation SODownloader (DownloadPath)

- (void)createPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL exist = [fileManager fileExistsAtPath:self.downloaderPath isDirectory:&isDir];
    if (!exist || !isDir) {
        NSError *error;
        [fileManager createDirectoryAtPath:self.downloaderPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            SOErrorLog(@"SODownloader create downloaderPath fail!");
        }
    }
}

- (NSString *)tempPathForItem:(id<SODownloadItem>)item {
    NSAssert([item downloadURL] != nil, @"SODownloader needs downloadURL for download item!");
    return [[self.downloaderPath stringByAppendingPathComponent:[self pathForDownloadURL:[item downloadURL]]]stringByAppendingPathExtension:@"download"];
}

- (void)removeTempDataForItem:(id<SODownloadItem>)item {
    [[NSFileManager defaultManager]removeItemAtPath:[self tempPathForItem:item] error:nil];
}

- (void)saveResumeData:(NSData *)resumeData forItem:(id<SODownloadItem>)item {
    [resumeData writeToFile:[self tempPathForItem:item] atomically:YES];
}

- (NSData *)tempDataForItem:(id<SODownloadItem>)item {
    NSData *data = [NSData dataWithContentsOfFile:[self tempPathForItem:item]];
    if ([data length]) {
        return data;
    } else {
        return nil;
    }
}

- (NSString *)pathForDownloadURL:(NSURL *)url {
    NSData *data = [[url absoluteString] dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_MD5_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (CC_LONG)data.length, digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}

@end
