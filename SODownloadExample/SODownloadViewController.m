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
    [[SODownloader musicDownloader].completeArray addObserver:self forKeyPath:@__STRING(completeArray) options:NSKeyValueObservingOptionNew context:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@__STRING(completeArray)]) {
        SODebugLog(@"completeArray changed!");
        [self.tableView reloadData];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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
