//
//  AppDelegate.m
//  SODownloadExample
//
//  Created by xueyi on 16/5/3.
//  Copyright © 2016年 http://scfhao.coding.me. All rights reserved.
//

#import "AppDelegate.h"
#import "SOLog.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    SODebugLog(@"%@", NSHomeDirectory());
    SODebugLog(@"%@", NSStringFromSelector(_cmd));
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    SODebugLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    SODebugLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)applicationWillTerminate:(UIApplication *)application {
    SODebugLog(@"%@", NSStringFromSelector(_cmd));
}

@end
