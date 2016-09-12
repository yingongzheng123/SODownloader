//
//  SOMusicListCell.h
//  SODownloadExample
//
//  Created by scfhao on 16/6/20.
//  Copyright © 2016年 http://scfhao.coding.me. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SOMusic.h"

@interface SOMusicListCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *stateLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;


@property (weak, nonatomic) SOMusic *music;

- (void)configureMusic:(SOMusic *)music;

@end
