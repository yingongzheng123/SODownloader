//
//  SOMusic.h
//  SODownloadExample
//
//  Created by xueyi on 16/5/3.
//  Copyright © 2016年 http://scfhao.coding.me. All rights reserved.
//

#import "SODownloadItem.h"

@interface SOMusic : NSObject

@property (copy, nonatomic) NSString *title;

- (void)download;

+ (NSArray *)allMusicList;

@end
