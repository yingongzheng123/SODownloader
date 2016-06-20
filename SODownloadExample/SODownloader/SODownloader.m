//
//  SODownloader.m
//  SOMoviePlayerDemo
//
//  Created by scfhao on 16/6/17.
//  Copyright © 2016年 Phoenix E-Learning. All rights reserved.
//

#import "SODownloader.h"
#import "SODownloadItem.h"

@interface SODownloader ()

@property (nonatomic, assign) NSInteger activeRequestCount;
@property (nonatomic, strong) NSMutableArray *highPriorityTasks;
@property (nonatomic, strong) NSMutableArray *normalPriorityTasks;
@property (nonatomic, strong) NSMutableDictionary *tasks;
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
@property (nonatomic, strong) dispatch_queue_t synchronizationQueue;
@property (nonatomic, strong) dispatch_queue_t responseQueue;

@end

@implementation SODownloader

+ (instancetype)sharedDownloader {
    static SODownloader *downloader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloader = [[self alloc]init];
        downloader.maximumActiveDownloads = 1;
    });
    return downloader;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *queueLabel = [NSString stringWithFormat:@"cn.scfhao.downloader.synchronizationQueue-%@", [NSUUID UUID].UUIDString];
        self.synchronizationQueue = dispatch_queue_create([queueLabel UTF8String], DISPATCH_QUEUE_SERIAL);
        
        queueLabel = [NSString stringWithFormat:@"cn.scfhao.downloader.responseQueue-%@", [NSUUID UUID].UUIDString];
        self.responseQueue = dispatch_queue_create([queueLabel UTF8String], DISPATCH_QUEUE_CONCURRENT);
        
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.sessionManager = [[AFHTTPSessionManager alloc]initWithSessionConfiguration:sessionConfiguration];
        
        self.highPriorityTasks = [[NSMutableArray alloc]init];
        self.normalPriorityTasks = [[NSMutableArray alloc]init];
        self.tasks = [[NSMutableDictionary alloc]init];
    }
    return self;
}

- (NSURLSessionDownloadTask *)downloadFileFromURLString:(NSString *)URLIdentifier
                                               priority:(SODownloadPriority)priority
                                               progress:(nullable void (^)(NSProgress *downloadProgress)) downloadProgressBlock
                                            destination:(nullable NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
                                                success:(nullable void (^)(NSURLResponse *response, NSURL * _Nullable filePath))success
                                                failure:(nullable void (^)(NSURLResponse * _Nullable response, NSError * _Nullable error))failure {
    __block NSURLSessionDownloadTask *downloadTask = nil;
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(self.synchronizationQueue, ^{
        NSURLSessionDownloadTask *existingDownloadTask = self.tasks[URLIdentifier];
        if (existingDownloadTask) {
            downloadTask = existingDownloadTask;
            return ;
        }
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URLIdentifier]];
        if (!request && failure) {
            NSError *URLError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(nil, URLError);
            });
            return;
        }
        downloadTask = [self.sessionManager downloadTaskWithRequest:request progress:downloadProgressBlock destination:destination completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            dispatch_async(self.responseQueue, ^{
                __strong __typeof__(weakSelf) strongSelf = weakSelf;
                [strongSelf safelyRemoveDownloadTaskWithURLIdentifier:URLIdentifier];
                if (error) {
                    if (failure) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            failure((NSHTTPURLResponse *)response, error);
                        });
                    }
                } else {
                    if (success) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            success((NSHTTPURLResponse *)response, filePath);
                        });
                    }
                }
                [strongSelf safelyDecrementActiveTaskCount];
                [strongSelf safelyStartNextTaskIfNecessary];
            });
        }];
        if ([self isActiveRequestCountBelowMaximumLimit]) {
            [self startDownloadTask:downloadTask];
        } else {
            [self enqueueTask:downloadTask priority:priority];
        }
    });
    return downloadTask;
}

- (void)cancelDownloadingTaskFromURLIdentifier:(NSString *)URLIdentifier {
    dispatch_sync(self.synchronizationQueue, ^{
        NSURLSessionDownloadTask *task = self.tasks[URLIdentifier];
        [task cancel];
        [self removeDownloadTaskWithURLIdentifier:URLIdentifier];
    });
}

#pragma mark -
- (NSURLSessionDownloadTask *)safelyRemoveDownloadTaskWithURLIdentifier:(NSString *)URLIdentifier {
    __block NSURLSessionDownloadTask *task = nil;
    dispatch_sync(self.synchronizationQueue, ^{
        task = [self removeDownloadTaskWithURLIdentifier:URLIdentifier];
    });
    return task;
}

- (NSURLSessionDownloadTask *)removeDownloadTaskWithURLIdentifier:(NSString *)URLIdentifier {
    NSURLSessionDownloadTask *task = self.tasks[URLIdentifier];
    [self.tasks removeObjectForKey:URLIdentifier];
    return task;
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
        if ([self isActiveRequestCountBelowMaximumLimit]) {
            while ([self.highPriorityTasks count] + [self.normalPriorityTasks count] > 0) {
                NSURLSessionDownloadTask *task = [self dequeueTask];
                if (task.state == NSURLSessionTaskStateSuspended) {
                    [self startDownloadTask:task];
                    break;
                }
            }
        }
    });
}

- (void)startDownloadTask:(NSURLSessionDownloadTask *)task {
    [task resume];
    ++self.activeRequestCount;
}

- (void)enqueueTask:(NSURLSessionDownloadTask *)task priority:(SODownloadPriority)priority {
    switch (priority) {
        case SODownloadPriorityHigh:
            [self.highPriorityTasks addObject:task];
            break;
        case SODownloadPriorityNormal:
            [self.normalPriorityTasks addObject:task];
            break;
    }
}

- (NSURLSessionDownloadTask *)dequeueTask {
    NSURLSessionDownloadTask *task = nil;
    if ([self.highPriorityTasks count]) {
        task = [self.highPriorityTasks firstObject];
        [self.highPriorityTasks removeObject:task];
    } else if ([self.normalPriorityTasks count]) {
        task = [self.normalPriorityTasks firstObject];
        [self.highPriorityTasks removeObject:task];
    }
    return task;
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
