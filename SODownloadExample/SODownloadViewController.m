//
//  SODownloadViewController.m
//  SODownloadExample
//
//  Created by scfhao on 16/7/1.
//  Copyright © 2016年 http://scfhao.coding.me. All rights reserved.
//

#import "SODownloadViewController.h"
#import "SODownloader+MusicDownloader.h"
#import "SOLog.h"
#import "SOMusic.h"

@interface SODownloadViewController ()

@end

@implementation SODownloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(dataChanged:) name:SODownloaderCompleteItemNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:SODownloaderCompleteItemNotification object:nil];
}

- (IBAction)clear:(id)sender {
    [[SODownloader musicDownloader]removeAllCompletedItems];
    [self.tableView reloadData];
}

- (void)dataChanged:(NSNotification *)notification {
    SODebugLog(@"%@", [NSThread isMainThread] ? @"是在主线程": @"通知不在主线程");
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [SODownloader musicDownloader].completeArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    SOMusic *music = [SODownloader musicDownloader].completeArray[indexPath.row];
    cell.textLabel.text = music.title;
    return cell;
}

@end
