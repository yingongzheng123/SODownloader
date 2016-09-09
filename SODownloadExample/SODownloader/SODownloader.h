//
//  SODownloader.h
//  SODownloadExample
//
//  Created by xueyi on 16/5/3.
//  Copyright © 2016年 http://scfhao.coding.me. All rights reserved.
//

#import <AFHTTPSessionManager.h>
#import "SODownloadItem.h"
@protocol SODownloadItem;

NS_ASSUME_NONNULL_BEGIN

/**
 当SODownloader完成下载一个item时，将调用此block回调用户，用户通过设置此block实现来对已下载对象进行处理。例如：将已下载的文件移动到想要的位置、或对其进行解密等其他处理操作。
 这个block中快照的对象需要做weak处理，防止造成内存泄漏。
 @param item 下载项对象
 @param location 文件位置，这个位置位于临时目录，所以用户需从此目录将文件移动到Documents、Library、Cache等目录。此block调用完后，SODownloader会自动移除该位置的文件。
 */
typedef void(^SODownloadCompleteBlock_t)(id<SODownloadItem> item, NSURL *location);

/**
 @interface SODownloader
 下载工具类，基于AFURLSessionManager。
 */
@interface SODownloader : NSObject

/// 每个下载器都有一个唯一标识符
@property (nonatomic, copy) NSString *downloaderIdentifier;
/// 最大下载数
@property (nonatomic, assign) NSInteger maximumActiveDownloads;

#pragma mark - 创建
- (instancetype)initWithIdentifier:(NSString *)identifier completeBlock:(SODownloadCompleteBlock_t)completeBlock;

// 下载管理
/// 下载
- (void)downloadItem:(id<SODownloadItem>)item;
- (void)downloadItems:(NSArray<SODownloadItem>*)items;
/// 暂停
- (void)pauseItem:(id<SODownloadItem>)item;
- (void)pauseAll;
/// 继续
- (void)resumeItem:(id<SODownloadItem>)item;
- (void)resumeAll;
/// 取消／删除
- (void)cancelItem:(id<SODownloadItem>)item;
- (void)cancenAll;

// 状态管理
- (void)setDownloadState:(SODownloadState)state forItem:(id<SODownloadItem>)item;

@end

NS_ASSUME_NONNULL_END
