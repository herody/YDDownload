//
//  DownloadCell.m
//  Download
//
//  Created by 侯亚迪 on 17/8/25.
//  Copyright © 2017年 侯亚迪. All rights reserved.
//

#import "DownloadCell.h"
#import "YDDownload.h"

@implementation DownloadCell

#pragma mark - 生命周期

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self.contentView addSubview:self.nameLabel];
        [self.contentView addSubview:self.downLoadBtn];
        [self.contentView addSubview:self.progressView];
        [self.contentView addSubview:self.speedLabel];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadTaskDidChangeStatusNotification:) name:YDDownloadTaskDidChangeStatusNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - getter

- (UILabel *)nameLabel
{
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 30, 20)];
        _nameLabel.font = [UIFont systemFontOfSize:16];
    }
    return _nameLabel;
}

- (UIButton *)downLoadBtn
{
    if (!_downLoadBtn) {
        _downLoadBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _downLoadBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 15 - 50, 10, 50, 20);
        [_downLoadBtn setTitle:@"下载" forState:UIControlStateNormal];
        [_downLoadBtn addTarget:self action:@selector(handleDownload:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _downLoadBtn;
}

- (UIProgressView *)progressView
{
    if (!_progressView) {
        _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_nameLabel.frame), 19, CGRectGetMinX(_downLoadBtn.frame) - CGRectGetMaxX(_nameLabel.frame) - 75, 2)];
        _progressView.progress = 0.0f;
    }
    return _progressView;
}

- (UILabel *)speedLabel
{
    if (!_speedLabel) {
        _speedLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_progressView.frame) + 5, 10, 70, 20)];
        _speedLabel.font = [UIFont systemFontOfSize:14];
        _speedLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _speedLabel;
}

#pragma mark - 按钮触发事件

- (void)handleDownload:(UIButton *)sender
{
    if ([sender.currentTitle isEqualToString:@"下载"]) {
        
        self.downloadTask = [[YDDownloadQueue defaultQueue] addDownloadTaskWithPriority:YDDownloadPriorityDefault url:self.url progressHandler:^(CGFloat progress, CGFloat speed) {
            
            self.progressView.progress = progress;
            if (speed < 1024) {
                self.speedLabel.text = [NSString stringWithFormat:@"%.2fB/s", speed];
            } else if (speed < 1024 * 1024) {
                self.speedLabel.text = [NSString stringWithFormat:@"%.2fK/s", speed / 1024];
            } else {
                self.speedLabel.text = [NSString stringWithFormat:@"%.2fM/s", speed / 1024 / 1024];
            }
            
        } completionHandler:^(NSString *filePath, NSError *error) {
            
            self.speedLabel.text = nil;
            if (error.code == -999) {
                self.progressView.progress = 0;
            }
            NSLog(@"%@", filePath);
            
        }];
        
    } else if ([sender.currentTitle isEqualToString:@"继续"]) {
        
        [self.downloadTask resumeTask];

    } else if ([sender.currentTitle isEqualToString:@"暂停"] || [sender.currentTitle isEqualToString:@"等待中"]) {
        
        [self.downloadTask suspendTask];
        self.speedLabel.text = nil;
    }
}

#pragma mark - 通知

- (void)downloadTaskDidChangeStatusNotification:(NSNotification *)notify
{
    YDDownloadTask *downloadTask = (YDDownloadTask *)notify.object;
    if (![downloadTask.downloadUrl isEqualToString:self.url]) {
        return;
    }
    switch (downloadTask.taskStatus) {
        case YDDownloadTaskStatusWaiting:
        case YDDownloadTaskStatusFailed: {
            [_downLoadBtn setTitle:@"等待中" forState:UIControlStateNormal];
        }
            break;
        case YDDownloadTaskStatusRunning: {
            [_downLoadBtn setTitle:@"暂停" forState:UIControlStateNormal];
        }
            break;
        case YDDownloadTaskStatusSuspended: {
            [_downLoadBtn setTitle:@"继续" forState:UIControlStateNormal];
        }
            break;
        case YDDownloadTaskStatusCanceled: {
            [_downLoadBtn setTitle:@"下载" forState:UIControlStateNormal];
        }
            break;
        case YDDownloadTaskStatusCompleted: {
            [_downLoadBtn setTitle:@"已完成" forState:UIControlStateNormal];
        }
            break;
        default: {
            [_downLoadBtn setTitle:@"下载" forState:UIControlStateNormal];
        }
            break;
    }
}

@end
