//
//  SODownloadItem.h
//  SODownloadExample
//
//  Created by xueyi on 16/5/3.
//  Copyright © 2016年 http://scfhao.coding.me. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SODownloadItem <NSObject>

@property (strong, nonatomic) NSProgress *downloadProgress;
- (NSURL *)downloadURL;

@end

@interface SODownloadItem : NSObject<SODownloadItem>

@end
