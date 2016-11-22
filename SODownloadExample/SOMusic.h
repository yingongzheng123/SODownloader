//
//  SOMusic.h
//  SODownloadExample
//
//  Created by scfhao on 16/5/3.
//  Copyright © 2016年 http://scfhao.coding.me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SODownloadItem.h"
@interface SOMusic : NSObject<SODownloadItem>

@property (copy, nonatomic) NSString *title;

+ (NSArray <SODownloadItem>*)allMusicList;

@end
