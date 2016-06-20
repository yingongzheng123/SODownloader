//
//  SODownloader.h
//  SODownloadExample
//
//  Created by xueyi on 16/5/3.
//  Copyright © 2016年 http://scfhao.coding.me. All rights reserved.
//

#import "AFHTTPSessionManager.h"

/**
 @enum 下载优先级
 建议尽量使用Normal优先级，如果所有下载都使用高优先级，那和都使用普通优先级是一样的效果。除非是特别紧要的任务才使用高优先级。
 */
typedef NS_ENUM(NSUInteger, SODownloadPriority) {
    /* 默认的优先级，下载对象会追加到下载队列的末尾 */
    SODownloadPriorityNormal,
    /* 高优先级，会优先于下载队列中的下载对象下载 */
    SODownloadPriorityHigh,
};

NS_ASSUME_NONNULL_BEGIN

/**
 @interface SODownloader
 下载工具类，基于AFURLSessionManager。
 */
@interface SODownloader : NSObject

/// 最大下载数
@property (nonatomic, assign) NSInteger maximumActiveDownloads;

+ (instancetype)sharedDownloader;

- (NSURLSessionDownloadTask *)downloadFileFromURLString:(NSString *)URLIdentifier
                                               priority:(SODownloadPriority)priority
                                               progress:(nullable void (^)(NSProgress *downloadProgress)) downloadProgressBlock
                                            destination:(nullable NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
                                                success:(nullable void (^)(NSURLResponse *response, NSURL * _Nullable filePath))success
                                                failure:(nullable void (^)(NSURLResponse * _Nullable response, NSError * _Nullable error))failure;

@end

NS_ASSUME_NONNULL_END
