//
//  DownloadCell.h
//  Download
//
//  Created by 侯亚迪 on 17/8/25.
//  Copyright © 2017年 侯亚迪. All rights reserved.
//

#import <UIKit/UIKit.h>

@class YDDownloadTask;
@interface DownloadCell : UITableViewCell
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UILabel *speedLabel;
@property (nonatomic, strong) UIButton *downLoadBtn;

@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) YDDownloadTask *downloadTask;
@property (nonatomic, strong) NSIndexPath *indexPath;
@end
