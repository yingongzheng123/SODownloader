//
//  SOMusicListViewController.m
//  SODownloadExample
//
//  Created by scfhao on 16/6/20.
//  Copyright © 2016年 http://scfhao.coding.me. All rights reserved.
//

#import "SOMusicListViewController.h"
#import "SOMusic.h"
#import "SOMusicListCell.h"

@interface SOMusicListViewController ()

@property (strong, nonatomic) NSArray *musicArray;

@end

@implementation SOMusicListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.musicArray = [SOMusic allMusicList];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Download action
- (void)downloadMusic:(UIButton *)sender {
    
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.musicArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SOMusicListCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SOMusicListCell class]) forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    SOMusic *music = self.musicArray[indexPath.row];
    cell.titleLabel.text = music.title;
    cell.stateLabel.text = @"未下载";
    cell.downloadButton.tag = indexPath.row;
    [cell.downloadButton addTarget:self action:@selector(downloadMusic:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

@end
