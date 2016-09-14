//
//  SODownloader.m
//  SOMoviePlayerDemo
//
//  Created by scfhao on 16/6/17.
//  Copyright © 2016年 Phoenix E-Learning. All rights reserved.
//

#import "SODownloader.h"
#import <AFNetworking.h>
#import "SODownloadResponseSerializer.h"
#import <CommonCrypto/CommonDigest.h>
#import "SOLog.h"

NSString * const SODownloaderCompleteItemNotification = @"SODownloaderCompleteItemNotification";
NSString * const SODownloaderCompleteDownloadItemKey = @"SODownloadItemKey";

@interface SODownloader ()

/// downloader identifier
@property (nonatomic, copy) NSString *downloaderIdentifier;
/// current download counts
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

- (BOOL)isControlDownloadFlowForItem:(id<SODownloadItem>)item;

@end

@interface SODownloader (DownloadPath)

- (void)createPath;
- (void)saveResumeData:(NSData *)resumeData forItem:(id<SODownloadItem>)item;
- (void)removeTempDataForItem:(id<SODownloadItem>)item;
- (NSData *)tempDataForItem:(id<SODownloadItem>)item;

@end

@interface SODownloader (DownloadNotify)

- (void)notifyDownloadItem:(id<SODownloadItem>)item withDownloadProgress:(double)downloadProgress;
- (void)notifyDownloadItem:(id<SODownloadItem>)item withDownloadState:(SODownloadState)downloadState;

@end

@implementation SODownloader

+ (NSCache *)downloaderCache {
    static NSCache *downloaderCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloaderCache = [[NSCache alloc]init];
    });
    return downloaderCache;
}

+ (instancetype)downloaderWithIdentifier:(NSString *)identifier completeBlock:(SODownloadCompleteBlock_t)completeBlock {
    SODownloader *downloader = [[self downloaderCache]objectForKey:identifier];
    if (!downloader) {
        downloader = [[[self class]alloc]initWithIdentifier:identifier completeBlock:completeBlock];
        [[self downloaderCache]setObject:downloader forKey:identifier];
    }
    return downloader;
}

- (instancetype)initWithIdentifier:(NSString *)identifier completeBlock:(SODownloadCompleteBlock_t)completeBlock {
    self = [super init];
    if (self) {
        NSString *queueLabel = [NSString stringWithFormat:@"cn.scfhao.downloader.synchronizationQueue-%@", [NSUUID UUID].UUIDString];
        self.synchronizationQueue = dispatch_queue_create([queueLabel UTF8String], DISPATCH_QUEUE_SERIAL);
        
        queueLabel = [NSString stringWithFormat:@"cn.scfhao.downloader.responseQueue-%@", [NSUUID UUID].UUIDString];
        self.responseQueue = dispatch_queue_create([queueLabel UTF8String], DISPATCH_QUEUE_CONCURRENT);
        
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
        self.sessionManager = [[AFHTTPSessionManager alloc]initWithSessionConfiguration:sessionConfiguration];
        self.sessionManager.responseSerializer = [SODownloadResponseSerializer serializer];
        
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
/// 下载
- (void)downloadItem:(id<SODownloadItem>)item {
    if ([self isControlDownloadFlowForItem:item]) {
        SOWarnLog(@"SODownloader: %@ already in download flow!", item);
        return;
    }
    if (item.downloadState != SODownloadStateNormal) {
        SOWarnLog(@"SODownloader only download item in normal state: %@", item);
        return;
    }
    dispatch_sync(self.synchronizationQueue, ^{
        if (item.downloadState == SODownloadStateNormal) {
            [self.downloadArray addObject:item];
            [self notifyDownloadItem:item withDownloadState:SODownloadStateWait];
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
    if (![self isControlDownloadFlowForItem:item]) {
        SOWarnLog(@"SODownloader: can't pause a item not in control of SODownloader!");
        return;
    }
    [self _pauseItem:item isPauseAll:NO];
}

- (void)_pauseItem:(id<SODownloadItem>)item isPauseAll:(BOOL)isPauseAll {
    dispatch_sync(self.synchronizationQueue, ^{
        if (item.downloadState == SODownloadStateLoading || item.downloadState == SODownloadStateWait) {
            if (item.downloadState == SODownloadStateLoading) {
                NSURLSessionDownloadTask *downloadTask = [self downloadTaskForItem:item];
                [downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                    [self saveResumeData:resumeData forItem:item];
                }];
                if (!isPauseAll) {
                    [self startNextTaskIfNecessary];
                }
            }
            [self notifyDownloadItem:item withDownloadState:SODownloadStatePaused];
        }
    });
}

- (void)pauseAll {
    for (id<SODownloadItem>item in self.downloadArray) {
        [self _pauseItem:item isPauseAll:YES];
    }
}

/// 继续
- (void)resumeItem:(id<SODownloadItem>)item {
    if (![self isControlDownloadFlowForItem:item]) {
        SOWarnLog(@"SODownloader: can't resume a item not in control of SODownloader!");
        return;
    }
    dispatch_sync(self.synchronizationQueue, ^{
        if (item.downloadState == SODownloadStatePaused || item.downloadState == SODownloadStateError) {
            if ([self isActiveRequestCountBelowMaximumLimit]) {
                [self startDownloadItem:item];
            } else {
                [self notifyDownloadItem:item withDownloadState:SODownloadStateWait];
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
    if (![self isControlDownloadFlowForItem:item]) {
        SOWarnLog(@"SODownloader: can't cancel a item not in control of SODownloader!");
        return;
    }
    [self _cancelItem:item isAllCancelled:NO];
}

- (void)_cancelItem:(id<SODownloadItem>)item isAllCancelled:(BOOL)isAllCancelled {
    dispatch_sync(self.synchronizationQueue, ^{
        if (item.downloadState == SODownloadStateLoading || item.downloadState == SODownloadStateWait) {
            if (item.downloadState == SODownloadStateLoading) {
                NSURLSessionDownloadTask *downloadTask = [self downloadTaskForItem:item];
                [downloadTask cancel];
                if (!isAllCancelled) {
                    [self startNextTaskIfNecessary];
                }
            }
        }
        [self notifyDownloadItem:item withDownloadState:SODownloadStateNormal];
        [self notifyDownloadItem:item withDownloadProgress:0];
        [self removeTempDataForItem:item];
        if (!isAllCancelled && [self.downloadArray count]) {
            [self.downloadArray removeObject:item];
        }
    });
}

- (void)cancenAll {
    for (id<SODownloadItem>item in self.downloadArray) {
        [self _cancelItem:item isAllCancelled:YES];
    }
    [self.downloadArray removeAllObjects];
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
                [self notifyDownloadItem:item withDownloadState:SODownloadStateWait];
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
            [self notifyDownloadItem:item withDownloadState:SODownloadStateComplete];
            [self.completeArray addObject:item];
        }
            break;
        case SODownloadStateError:
            if ([self.downloadArray containsObject:item]) {
                if (item.downloadState == SODownloadStateComplete) {
                    [self notifyDownloadItem:item withDownloadState:SODownloadStateError];
                    [self notifyDownloadItem:item withDownloadProgress:0];
                }
            }
            break;
        default:
            break;
    }
}

- (void)removeAllCompletedItems {
    dispatch_sync(self.synchronizationQueue, ^{
        for (id<SODownloadItem>item in self.completeArray) {
            [self notifyDownloadItem:item withDownloadState:SODownloadStateNormal];
        }
        [self.completeArray removeAllObjects];
    });
}

#pragma mark -
/// 判断item是否在当前的downloader的控制下，用于条件判断
- (BOOL)isControlDownloadFlowForItem:(id<SODownloadItem>)item {
    return [self.downloadArray containsObject:item];
}

/// 开始下载一个item，这个方法必须在同步线程中调用，且调用前必须先判断是否可以开始新的下载
- (void)startDownloadItem:(id<SODownloadItem>)item {
    [self notifyDownloadItem:item withDownloadState:SODownloadStateLoading];
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
        [self notifyDownloadItem:item withDownloadState:SODownloadStateError];
        [self startNextTaskIfNecessary];
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    // 创建下载完成的回调
    void (^completeBlock)(NSURLResponse *response, NSURL *filePath, NSError *error) = ^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        dispatch_async(self.responseQueue, ^{
            __strong __typeof__(weakSelf) strongSelf = weakSelf;
            if (error) {
                SODebugLog(@"Error:%@", error);
                if (error.code != NSURLErrorCancelled) {
                    [self notifyDownloadItem:item withDownloadState:SODownloadStateError];
                    [self notifyDownloadItem:item withDownloadProgress:0];
                    [self removeTempDataForItem:item];
                }
            } else {
                [self notifyDownloadItem:item withDownloadState:SODownloadStateComplete];
                [self.downloadArray removeObject:item];
                [self.completeArray addObject:item];
                strongSelf.completeBlock ?: strongSelf.completeBlock(item, filePath);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter]postNotificationName:SODownloaderCompleteItemNotification object:strongSelf userInfo:@{SODownloaderCompleteDownloadItemKey: item}];
                });
            }
            [strongSelf safelyRemoveTaskInfoForItem:item];
            [strongSelf safelyDecrementActiveTaskCount];
            [strongSelf safelyStartNextTaskIfNecessary];
        });
    };
    void (^progressBlock)(NSProgress *downloadProgress) = ^(NSProgress *downloadProgress) {
        [self notifyDownloadItem:item withDownloadProgress:downloadProgress.fractionCompleted];
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
    [self log4ActiveCountByTag:@"下载数-1"];
}

- (void)safelyStartNextTaskIfNecessary {
    dispatch_sync(self.synchronizationQueue, ^{
        [self startNextTaskIfNecessary];
    });
}

- (void)startNextTaskIfNecessary {
    [self log4ActiveCountByTag:@"开始下一个"];
    for (id<SODownloadItem>item in self.downloadArray) {
        if (item.downloadState == SODownloadStateWait && [self isActiveRequestCountBelowMaximumLimit]) {
            [self startDownloadItem:item];
            if (![self isActiveRequestCountBelowMaximumLimit]) {
                break;
            }
        }
    }
}

- (BOOL)isActiveRequestCountBelowMaximumLimit {
    return self.activeRequestCount < self.maximumActiveDownloads;
}

- (void)setMaximumActiveDownloads:(NSInteger)maximumActiveDownloads {
    dispatch_sync(self.synchronizationQueue, ^{
        _maximumActiveDownloads = maximumActiveDownloads;
    });
}

- (void)log4ActiveCountByTag:(NSString *)tag {
    SODebugLog(@"%@ 当前下载数：%@", tag, @(self.activeRequestCount).stringValue);
}

- (void)setAcceptableContentTypes:(NSSet<NSString *> *)acceptableContentTypes {
    [self.sessionManager.responseSerializer setAcceptableContentTypes:acceptableContentTypes];
}

- (NSSet<NSString *> *)acceptableContentTypes {
    return self.sessionManager.responseSerializer.acceptableContentTypes;
}

#pragma mark - 后台下载支持
- (void)setDidFinishEventsForBackgroundURLSessionBlock:(void (^)(NSURLSession *session))block {
    [self.sessionManager setDidFinishEventsForBackgroundURLSessionBlock:block];
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
    NSString *tempFileName = [[self pathForDownloadURL:[item downloadURL]]stringByAppendingPathExtension:@"download"];
    return [self.downloaderPath stringByAppendingPathComponent:tempFileName];
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
    CC_MD5(data.bytes, (CC_LONG)data.length, digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return [output copy];
}

@end

@implementation SODownloader (DownloadNotify)

- (void)notifyDownloadItem:(id<SODownloadItem>)item withDownloadState:(SODownloadState)downloadState {
    if ([item respondsToSelector:@selector(setDownloadState:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            item.downloadState = downloadState;
        });
    } else {
        SOWarnLog(@"下载模型必须实现setDownloadState:才能获取到正确的下载状态！");
    }
}

- (void)notifyDownloadItem:(id<SODownloadItem>)item withDownloadProgress:(double)downloadProgress {
    SODebugLog(@"%@ %.2f", item, downloadProgress);
    if ([item respondsToSelector:@selector(setDownloadProgress:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            item.downloadProgress = downloadProgress;
        });
    } else {
        SOWarnLog(@"下载模型必须实现setDownloadProgress:才能获取到正确的下载进度！");
    }
}

@end
