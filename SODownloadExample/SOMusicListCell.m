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

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)configureMusic:(SOMusic *)music {
    self.titleLabel.text = music.title;
    [self updateState:music.downloadState];
    self.progressView.progress = music.downloadProgress;
    self.music = music;
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

- (void)setMusic:(SOMusic *)music {
    if (_music) {
        [_music removeObserver:self forKeyPath:@__STRING(downloadState)];
        [_music removeObserver:self forKeyPath:@__STRING(downloadProgress)];
    }
    _music = music;
    if (_music) {
        [_music addObserver:self forKeyPath:@__STRING(downloadState) options:NSKeyValueObservingOptionNew context:kStateContext];
        [_music addObserver:self forKeyPath:@__STRING(downloadProgress) options:NSKeyValueObservingOptionNew context:kProgressContext];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (context == kStateContext) {
        SODownloadState newState = [change[NSKeyValueChangeNewKey]integerValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateState:newState];
        });
    } else if (context == kProgressContext) {
        double newProgress = [change[NSKeyValueChangeNewKey]doubleValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView.progress = newProgress;
        });
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
