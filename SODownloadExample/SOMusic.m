//
//  SOMusic.m
//  SODownloadExample
//
//  Created by scfhao on 16/5/3.
//  Copyright © 2016年 http://scfhao.coding.me. All rights reserved.
//

#import "SOMusic.h"
#import "SODownloader.h"

@interface SOMusic ()

@property (strong, nonatomic) NSString *urlString;

@end

@implementation SOMusic
@synthesize so_downloadProgress, so_downloadState;

+ (NSArray *)allMusicList {
    static NSArray *array = nil;
    if (array == nil) {
        array = @[
                  [SOMusic musicWithTitle:@"QQ for Mac" urlString:@"http://dldir1.qq.com/qqfile/QQforMac/QQ_V5.1.1.dmg"],
                  [SOMusic musicWithTitle:@"Layout and Animation Techniques for WatchKit" urlString:@"http://devstreaming.apple.com/videos/wwdc/2015/216isrjt4ku9w4/216/216_sd_layout_and_animation_techniques_for_watchkit.mp4?dl=1"],
                  [SOMusic musicWithTitle:@"Advanced NSOperations" urlString:@"http://devstreaming.apple.com/videos/wwdc/2015/2267p2ni281ba/226/226_sd_advanced_nsoperations.mp4?dl=1"],
                  [SOMusic musicWithTitle:@"Building Document Based Apps" urlString:@"http://devstreaming.apple.com/videos/wwdc/2015/234reaz1byqc/234/234_sd_building_document_based_apps.mp4?dl=1"],
                  [SOMusic musicWithTitle:@"Creating Complications with CloukKit" urlString:@"http://devstreaming.apple.com/videos/wwdc/2015/209c9277tttlt9/209/209_sd_creating_complications_with_clockkit.mp4?dl=1"],
                  [SOMusic musicWithTitle:@"Apple Watch Accessibility" urlString:@"http://devstreaming.apple.com/videos/wwdc/2015/2048w4vdjhe1i1m/204/204_sd_apple_watch_accessibility.mp4?dl=1"],
                  [SOMusic musicWithTitle:@"Networking with NSURLSession" urlString:@"http://devstreaming.apple.com/videos/wwdc/2015/711y6zlz0ll/711/711_sd_networking_with_nsurlsession.mp4?dl=1"],
                  [SOMusic musicWithTitle:@"What's New in Web Development in WebKit and Safari" urlString:@"http://devstreaming.apple.com/videos/wwdc/2015/501g8vwlgg2/501/501_sd_whats_new_in_web_development_in_webkit_and_safari.mp4?dl=1"],
                  [SOMusic musicWithTitle:@"Supporting the Enterprise with OS X Automation" urlString:@"http://devstreaming.apple.com/videos/wwdc/2015/306vjwcqnm/306/306_sd_supporting_the_enterprise_with_os_x_automation.mp4?dl=1"],
                  [SOMusic musicWithTitle:@"What's New in MapKit" urlString:@"http://devstreaming.apple.com/videos/wwdc/2015/206v5ce46maax7s/206/206_sd_whats_new_in_mapkit.mp4?dl=1"],
                  [SOMusic musicWithTitle:@"Optimizing Your App for Multitasking on iPad in iOS 9" urlString:@"http://devstreaming.apple.com/videos/wwdc/2015/212mm5ra3oau66/212/212_sd_optimizing_your_app_for_multitasking_on_ipad_in_ios_9.mp4?dl=1"],
                  [SOMusic musicWithTitle:@"Introducing GameplayKit" urlString:@"http://devstreaming.apple.com/videos/wwdc/2015/608rpwq1ltvg5nmk/608/608_sd_introducing_gameplaykit.mp4?dl=1"],
                  [SOMusic musicWithTitle:@"What's New in UIKit Dynamics and Visual Effects" urlString:@"http://devstreaming.apple.com/videos/wwdc/2015/229fksrj39nd/229/229_sd_whats_new_in_uikit_dynamics_and_visual_effects.mp4?dl=1"]
                  ];
    }
    return array;
}

+ (instancetype)musicWithTitle:(NSString *)title urlString:(NSString *)urlString {
    return [[self alloc]initWithTitle:title urlString:urlString];
}

- (instancetype)initWithTitle:(NSString *)title urlString:(NSString *)urlString {
    self = [super init];
    if (self) {
        self.title = title;
        self.urlString = urlString;
    }
    return self;
}


#pragma mark - SODownloadItem必须实现的方法
- (NSURL *)downloadURL {
    return [NSURL URLWithString:self.urlString];
}

#pragma mark - SODownloadItem建议实现的方法
- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[SOMusic class]]) {
        return [super isEqual:object];
    }
    SOMusic *music = (SOMusic *)object;
    return [self.title isEqualToString:music.title];
}

- (NSUInteger)hash {
    return [self.title hash];
}

- (NSString *)description {
    return self.title;
}

@end
