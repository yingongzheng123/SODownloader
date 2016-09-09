//
//  SODownloadItem.h
//  SODownloadExample
//
//  Created by xueyi on 16/5/3.
//  Copyright © 2016年 http://scfhao.coding.me. All rights reserved.
//  可下载模型

#import <Foundation/Foundation.h>

/**
 将自定义的模型对象用于SODownloader时，可以通过两种途径实现（二选一即可）：
 
 - 将需要下载的model类集成SODownloadItem类。
 - 将需要下载的model类实现SODownloadItem协议。
 
 继承SODownloadItem类或实现SODownloadItem协议的类即可用于下载。不管选择哪种形式，必须实现：
 - (NSURL *)downloadURL;

 如果选择实现SODownloadItem协议而不继承SODownloadItem类时，必须同时为downloadProgress、downloadState属性合成setter、getter方法（自动或手动合成）
 
 更进一步：为了能达到最佳效果，建议可下载模型实现下面的方法：
 - (NSUInteger)hash
 - (BOOL)isEqual:(id)object
 */

/*!
 @enum 下载状态
 */
typedef NS_ENUM(NSUInteger, SODownloadState) {
    /* 默认状态，不会下载 */
    SODownloadStateNormal,
    /* 等待下载 */
    SODownloadStateWait,
    /* 正在下载 */
    SODownloadStateLoading,
    /* 下载暂停 */
    SODownloadStatePaused,
    /* 下载完成 */
    SODownloadStateComplete,
    /* 下载失败 */
    SODownloadStateError,
};

@protocol SODownloadItem <NSObject>

@property (assign, nonatomic) double downloadProgress;
@property (assign, nonatomic) SODownloadState downloadState;
- (NSURL *)downloadURL;

@end

@interface SODownloadItem : NSObject<SODownloadItem>

@end
