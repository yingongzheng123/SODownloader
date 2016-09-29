//
//  SODownloader.h
//  SODownloadExample
//
//  Created by scfhao on 16/5/3.
//  Copyright © 2016年 http://scfhao.coding.me. All rights reserved.
//

#import "SODownloadItem.h"

NS_ASSUME_NONNULL_BEGIN

/**
 当SODownloader完成下载一个item时，将调用此block回调用户，用户通过设置此block实现来对已下载对象进行处理。例如：将已下载的文件移动到想要的位置、或对其进行解密等其他处理操作。
 这个block中快照的对象需要做weak处理，防止造成内存泄漏。
 @param item 下载项对象
 @param location 文件位置，这个位置位于临时目录，所以用户需从此目录将文件移动到Documents、Library、Cache等目录。此block调用完后，SODownloader会自动移除该位置的文件。
 */
typedef void(^SODownloadCompleteBlock_t)(id<SODownloadItem> item, NSURL *location);

/**
 用于从SODownloader的下载列表和已完成列表中筛选下载项。
 */
typedef BOOL(^SODownloadFilter_t)(id<SODownloadItem> item);

/**
 @interface SODownloader
 下载工具类，基于AFURLSessionManager。
 */
@interface SODownloader : NSObject

/// 每个下载器都有一个唯一标识符，不同的下载器应使用不同的标识符
@property (nonatomic, copy, readonly) NSString *downloaderIdentifier;
/// 最大下载数
@property (nonatomic, assign) NSInteger maximumActiveDownloads;
/// 等待、下载中、暂停状态的下载项数组
@property (nonatomic, strong, readonly) NSMutableArray *downloadArray;
/// 已下载项数组
@property (nonatomic, strong, readonly) NSMutableArray *completeArray;

/**
 下载文件接受类型
 此属性默认为nil，可接收任意类型的文件。
 可以为此属性设置一个可接收类型集合，当下载文件的response中的MIME-Type不符合时，SODownloader将判定其下载失败。
 */
@property (nonatomic, copy, nullable) NSSet <NSString *> *acceptableContentTypes;

#pragma mark - 创建/初始化
/**
 为该identifier创建一个downloader。
 @return identifier对应的downloader
 @param identifier 要获取的downloader的标识符，这个标识符还将被用于downloader临时文件路径名和urlSession的identifier。
 @param completeBlock 完成回调，downloader每完成一个item时会调用此block，此block在非主线程中被调用，如果在block中进行UI操作，需要注意切换到主线程执行。另外也需要注意Block的循环引用问题。
 */
- (instancetype)initWithIdentifier:(NSString *)identifier completeBlock:(SODownloadCompleteBlock_t)completeBlock;

#pragma mark - 下载管理
/// 加入下载并自动开始
- (void)downloadItem:(id<SODownloadItem>)item;
/// 加入下载，如果autoStartDownload参数为YES，自动开始，如果为NO，该item被置为暂停状态。
- (void)downloadItem:(id<SODownloadItem>)item autoStartDownload:(BOOL)autoStartDownload;
- (void)downloadItems:(NSArray<SODownloadItem>*)items;
- (void)downloadItems:(NSArray<SODownloadItem> *)items autoStartDownload:(BOOL)autoStartDownload;

/// 暂停
- (void)pauseItem:(id<SODownloadItem>)item;
- (void)pauseAll;
/// 继续 已暂停或失败状态的下载项
- (void)resumeItem:(id<SODownloadItem>)item;
- (void)resumeAll;
/// 取消／删除
- (void)cancelItem:(id<SODownloadItem>)item;
- (void)cancenAll;

/// 判断该item是否在当前的downloader对象的下载列表或完成列表中
- (BOOL)isControlDownloadFlowForItem:(id<SODownloadItem>)item;

/**
 有时候，写注释的时候就觉得自己有语言困难症。
 这个方法提供一点调整下载项下载状态的功能，但不要滥用，能用前面几个方法解决的问题就别用这个方法。
 使用这个方法可以解决如下问题：
 1. 告诉SODownloader某个item以前已经下载完了（state传SODownloadStateComplete）。
 2. 告诉SODownloader某个已下载的item是错误的，比如下载的文件无法使用，通过state传SODownloadStateError改让SODownloader知晓。
 3. 将item加入下载队列，但将其状态设置为SODownloadStatePaused，这样，不会立即下载。
 
 再次声明：对非上述说明的情况调用此方法不保证逻辑正确性。
 */
- (void)setDownloadState:(SODownloadState)state forItem:(id<SODownloadItem>)item;

/// 删除所有已下载
- (void)removeAllCompletedItems;
/// 将一些下载项标记为已下载
- (void)markItemsAsComplate:(NSArray<SODownloadItem>*)items;

/**
 对象置换：
 在应用中同一条数据可能会有多份对象(比如已完成列表中已有一个代表同一项目的对象，然后在某一列表界面从网络获取到一个文件列表)，这时可能会需要获取SODownloader中的那个具备正确下载状态的对象。
 */
- (id<SODownloadItem>)filterItemUsingFilter:(SODownloadFilter_t)filter;

/**
 错误处理。
 由于下载这项功能的特殊性，如果下载失败，解救的手段有限。SODownloader将下载失败的情况分为两类：
 1. 可以重新下载。对于这种情况，SODownloader会自动重新下载该下载项。
 2. 无法重新下载。例如远程资源根本不存在，重新下载也是白忙。
 3. 其他错误也可以归类到1或2中，如遇到可以继续下载的其他错误，可以在 https://github.com/scfhao/SODownloader/issues 提出。
 将autoCancelFailedItem 属性置为YES时（默认为NO），当一个下载项下载失败且SODownloader无法处理时，自动取消下载该下载项，下载项的下载状态将被置为Normal；默认情况下（此属性为NO时），下载状态被置为Error，下载项的so_downloadError属性将被赋值。
 */
@property (nonatomic, assign) BOOL autoCancelFailedItem;

#pragma mark - 后台下载支持
- (void)setDidFinishEventsForBackgroundURLSessionBlock:(void (^)(NSURLSession *session))block;

@end

/**
 1. SODownloader每完成下载一个item时，会发送此通知。这个通知的object为downloader对象，userInfo中包含了item对象。
 2. 当autoCancelFailedItem为YES时，SODownloader从下载列表中忽略一个下载失败的项时也会发送此通知。
 综合上述情况，每当有下载项从下载列表移除时，发送此通知。
 */

FOUNDATION_EXPORT NSString * const SODownloaderCompleteItemNotification;
/// 在SODownloaderCompleteItemNotification通知中，可以通过此key在userInfo字典中拿到下载完成的item对象。
FOUNDATION_EXPORT NSString * const SODownloaderCompleteDownloadItemKey;

// 版本适配：在此声明，建议尽可能使用较新版本的AFNetworking来进行网络请求，如果你的项目中没有过多的使用基于NSURLConnection的代码，建议都升级到AFNetworking 3.x的版本。为保证代码简洁，SODownloader不会贪多支持多个AFNetworking的版本（理论上讲，SODownloader可以支持AFNetworking 2.x ~ 3.x，见下面的注释）。
/**
 版本适配是个坑，不同版本的AFNetworking，API有所差异，幸好涉及到的地方不多。
 AFNetworking 对下载进度的反馈使用了两种方式，此处描述如下：
 1. 在比较旧的版本中，在2.x中，AFNetworking允许用户传入一个"NSProgress **"来获取下载进度对象。SODownloader默认选择方式2进行处理，如果用户使用的AFNetworking 2.x的版本，注释下面的AFNetworkingUseBlockToNotifyDownloadProgress即可。
 2. 在3.0.0（准确点是从3.0.0的第三个beta版开始的），中使用block通知进度的改变，这个block的参数是NSProgress *对象，用户可在block中做自己想做任何事。
 */

#define AFNetworkingVersion 2

#if AFNetworkingVersion > 2
#define AFNetworkingUseBlockToNotifyDownloadProgress
#endif

NS_ASSUME_NONNULL_END
