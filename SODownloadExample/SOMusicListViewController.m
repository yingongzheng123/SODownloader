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
#import "SODownloader+MusicDownloader.h"

@interface SOMusicListViewController ()

@property (strong, nonatomic) NSArray<SODownloadItem> *musicArray;

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

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.musicArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SOMusicListCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SOMusicListCell class]) forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    SOMusic *music = self.musicArray[indexPath.row];
    [cell configureMusic:music];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SOMusic *music = self.musicArray[indexPath.row];
    switch (music.downloadState) {
        case SODownloadStateError:
        {
            [[SODownloader musicDownloader]resumeItem:music];
        }
            break;
        case SODownloadStatePaused:
        {
            [[SODownloader musicDownloader]resumeItem:music];
        }
            break;
        case SODownloadStateNormal:
        {
            [[SODownloader musicDownloader]downloadItem:music];
        }
            break;
        case SODownloadStateLoading:
        {
            [[SODownloader musicDownloader]pauseItem:music];
        }
            break;
        case SODownloadStateWait:
        {
            [[SODownloader musicDownloader]pauseItem:music];
        }
            break;
        default:
            break;
    }
}

- (IBAction)showActions:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:@"请选择操作" preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:@"全部下载" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[SODownloader musicDownloader]downloadItems:self.musicArray];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"全部暂停" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[SODownloader musicDownloader]pauseAll];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"全部开始" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[SODownloader musicDownloader]resumeAll];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"全部取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[SODownloader musicDownloader]cancenAll];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}


@end
