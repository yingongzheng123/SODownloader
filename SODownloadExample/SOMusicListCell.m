//
//  SOMusicListCell.m
//  SODownloadExample
//
//  Created by scfhao on 16/6/20.
//  Copyright © 2016年 http://scfhao.coding.me. All rights reserved.
//

#import "SOMusicListCell.h"

@interface SOMusicListCell ()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) SOMusic *music;

@end

@implementation SOMusicListCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)configureMusic:(SOMusic *)music {
    self.nameLabel.text = music.title;
    self.music = music;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
    if (selected) {
        [self.music download];
    }
}

@end
