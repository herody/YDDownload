//
//  DownloadCell.m
//  Download
//
//  Created by 侯亚迪 on 17/8/25.
//  Copyright © 2017年 杭州魔品科技. All rights reserved.
//

#import "DownloadCell.h"
#import "YDDownload.h"

@implementation DownloadCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self.contentView addSubview:self.nameLabel];
        [self.contentView addSubview:self.downLoadBtn];
        [self.contentView addSubview:self.progressView];
    }
    return self;
}

- (UILabel *)nameLabel
{
    if (!_nameLabel) {
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 60, 20)];
        _nameLabel.font = [UIFont systemFontOfSize:16];
    }
    return _nameLabel;
}

- (UIButton *)downLoadBtn
{
    if (!_downLoadBtn) {
        self.downLoadBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _downLoadBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 15 - 50, 10, 50, 20);
        [_downLoadBtn setTitle:@"下载" forState:UIControlStateNormal];
        [_downLoadBtn setTitle:@"暂停" forState:UIControlStateSelected];
        [_downLoadBtn addTarget:self action:@selector(handleDownload:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _downLoadBtn;
}

- (UIProgressView *)progressView
{
    if (!_progressView) {
        self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_nameLabel.frame), 19, CGRectGetMinX(_downLoadBtn.frame) - CGRectGetMaxX(_nameLabel.frame) - 20, 2)];
        _progressView.progress = 0.0f;
    }
    return _progressView;
}

- (void)handleDownload:(UIButton *)sender
{
    sender.selected = !sender.selected;
    
    if (sender.selected) {
        if (!self.downloadTask) {
            YDDownloadPriority priority = self.indexPath.row % 3;
            self.downloadTask = [[YDDownloadQueue defaultQueue] addDownloadTaskWithPriority:priority url:self.url progressHandler:^(CGFloat progress, CGFloat speed) {
                self.progressView.progress = progress;
                NSLog(@"%.2fK", speed / 1024);
            } completionHandler:^(NSString *filePath, NSError *error) {
                NSLog(@"%@", filePath);
            }];
        } else {
            [self.downloadTask resumeTask];
        }
    } else {
        [self.downloadTask suspendTask];
    }
}

@end
