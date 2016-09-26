//
//  SOMusicListCell.m
//  SODownloadExample
//
//  Created by scfhao on 16/6/20.
//  Copyright © 2016年 http://scfhao.coding.me. All rights reserved.
//

#import "SOMusicListCell.h"

static void * kStateContext = &kStateContext;
static void * kProgressContext = &kProgressContext;

@implementation SOMusicListCell

- (void)configureMusic:(SOMusic *)music {
    self.titleLabel.text = music.title;
    [self updateState:music.so_downloadState];
    self.progressView.progress = music.so_downloadProgress;
    self.music = music;
    self.backgroundColor = [UIColor whiteColor];
}

- (void)updateState:(SODownloadState)state {
    switch (state) {
        case SODownloadStateWait:
            self.stateLabel.text = @"等待中";
            break;
        case SODownloadStatePaused:
            self.stateLabel.text = @"已暂停";
            break;
        case SODownloadStateError:
            self.stateLabel.text = @"失败";
            break;
        case SODownloadStateLoading:
            self.stateLabel.text = @"下载中";
            break;
        case SODownloadStateComplete:
            self.stateLabel.text = @"已下载";
            break;
        default:
            self.stateLabel.text = @"未下载";
            break;
    }
}

/**
 注意这个方法，当参数 music 为 nil 时，调用此方法可移除对之前设置的 music 的下载状态的观察。
 更多关于 UITableViewCell+KVO 需要注意的地方参考 SOMusicListViewController.m 文件。
 */
- (void)setMusic:(SOMusic *)music {
    if (_music) {
        [_music removeObserver:self forKeyPath:@__STRING(so_downloadState)];
        [_music removeObserver:self forKeyPath:@__STRING(so_downloadProgress)];
    }
    _music = music;
    if (_music) {
        [_music addObserver:self forKeyPath:@__STRING(so_downloadState) options:NSKeyValueObservingOptionNew context:kStateContext];
        [_music addObserver:self forKeyPath:@__STRING(so_downloadProgress) options:NSKeyValueObservingOptionNew context:kProgressContext];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (context == kStateContext) {
        SODownloadState newState = [change[NSKeyValueChangeNewKey]integerValue];
        [self updateState:newState];
    } else if (context == kProgressContext) {
        double newProgress = [change[NSKeyValueChangeNewKey]doubleValue];
        self.progressView.progress = newProgress;
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
