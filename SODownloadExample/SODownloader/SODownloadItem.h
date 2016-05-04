//
//  SODownloadItem.h
//  SODownloadExample
//
//  Created by xueyi on 16/5/3.
//  Copyright © 2016年 http://scfhao.coding.me. All rights reserved.
//

#import <Foundation/Foundation.h>

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

@property (strong, nonatomic) NSProgress *downloadProgress;
@property (assign, nonatomic) SODownloadState *downloadState;
- (NSURL *)downloadURL;

@end

@interface SODownloadItem : NSObject<SODownloadItem>

@end
