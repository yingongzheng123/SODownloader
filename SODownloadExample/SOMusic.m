//
//  SOMusic.m
//  SODownloadExample
//
//  Created by xueyi on 16/5/3.
//  Copyright © 2016年 http://scfhao.coding.me. All rights reserved.
//

#import "SOMusic.h"
#import "SODownloader.h"

@implementation SOMusic

+ (NSArray *)allMusicList {
    return @[
        [SOMusic musicWithTitle:@"暧昧" fileName:@"AiMei"],
        [SOMusic musicWithTitle:@"百年孤寂" fileName:@"BaiNianGuJi"],
        [SOMusic musicWithTitle:@"不爱我的我不爱" fileName:@"BuAiWoDeWoBuAi"],
        [SOMusic musicWithTitle:@"不留" fileName:@"BuLiu"],
        [SOMusic musicWithTitle:@"传奇" fileName:@"ChuanQi"],
        [SOMusic musicWithTitle:@"催眠" fileName:@"CuiMian"],
        [SOMusic musicWithTitle:@"Di Dar" fileName:@"DiDar"],
        [SOMusic musicWithTitle:@"蝴蝶" fileName:@"HuDie"],
        [SOMusic musicWithTitle:@"花事了" fileName:@"HuaShiLiao"],
        [SOMusic musicWithTitle:@"流年" fileName:@"LiuNian"],
        [SOMusic musicWithTitle:@"闷" fileName:@"Meng"],
        [SOMusic musicWithTitle:@"迷魂记" fileName:@"MiHongJi"],
        [SOMusic musicWithTitle:@"那些花儿" fileName:@"NaXieHuaEr"],
        [SOMusic musicWithTitle:@"棋子" fileName:@"QiZi"],
        [SOMusic musicWithTitle:@"人间" fileName:@"RenJian"],
        [SOMusic musicWithTitle:@"容易受伤的女人" fileName:@"RongYiShouShangDeNvRen"],
        [SOMusic musicWithTitle:@"誓言" fileName:@"ShiYan"],
        [SOMusic musicWithTitle:@"天与地" fileName:@"TianYuDi"],
        [SOMusic musicWithTitle:@"笑忘书" fileName:@"XiaoWangShu"],
        [SOMusic musicWithTitle:@"旋木" fileName:@"XuanMu"]
    ];
}

+ (instancetype)musicWithTitle:(NSString *)title fileName:(NSString *)fileName {
    return [[self alloc]initWithTitle:title fileName:fileName];
}

- (instancetype)initWithTitle:(NSString *)title fileName:(NSString *)fileName {
    self = [super init];
    if (self) {
        self.title = title;
        self.fileName = fileName;
    }
    return self;
}

- (NSString *)downloadURL {
    return [NSString stringWithFormat:@"http://o6lpg3g95.bkt.clouddn.com/%@.mp3", self.fileName];
}

@end
