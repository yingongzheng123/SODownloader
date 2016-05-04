//
//  SODownloader.h
//  SODownloadExample
//
//  Created by xueyi on 16/5/3.
//  Copyright © 2016年 http://scfhao.coding.me. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SODownloadPriorityType) {
    SODownloadPriorityTypeFIFO,
    SODownloadPriorityTypeLIFO
};

@interface SODownloader : NSObject

+ (instancetype)sharedDownloader;


@end
