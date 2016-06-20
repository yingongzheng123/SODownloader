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
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.musicArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SOMusicListCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SOMusicListCell class]) forIndexPath:indexPath];
    
    SOMusic *music = self.musicArray[indexPath.row];
    [cell configureMusic:music];
    
    return cell;
}

@end
