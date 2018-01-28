//
//  ViewController.m
//  Download
//
//  Created by 侯亚迪 on 17/8/25.
//  Copyright © 2017年 侯亚迪. All rights reserved.
//

#import "ViewController.h"
#import "YDDownload.h"
#import "DownloadCell.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *urlArr;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"下载列表";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"全部暂停" style:UIBarButtonItemStylePlain target:self action:@selector(handleAllSuspend)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"全部开始" style:UIBarButtonItemStylePlain target:self action:@selector(handleAllResume)];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    [self.tableView registerClass:[DownloadCell class] forCellReuseIdentifier:@"download"];
    
    self.urlArr = @[
        @"http://downali.game.uc.cn/s/6/14/20170815152404d64a22_onmyoji_uc_platform_gc_2_1.0.26.apk?x-oss-process=udf/uc-apk,AiDDjEgeLVtgAsOP3be530011ce0ab1f",
        @"http://sw.bos.baidu.com/sw-search-sp/software/5f5ecfa13d98c/androidstudio_2.3.0.0.exe",
        @"http://dlsw.baidu.com/sw-search-sp/soft/d2/24274/600zi_1.0.0.0.1393240013.exe",
        @"http://dlied5.myapp.com/myapp/1104466820/sgame/2017_com.tencent.tmgp.sgame_h100_1.21.2.5.apk",
        @"http://sw.bos.baidu.com/sw-search-sp/software/df96059fd1835/buyudaren_4.0.1087.exe",
        @"http://dlsw.baidu.com/sw-search-sp/soft/5b/22122/10350318.1329783614.exe",
        @"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4",
        @"http://sw.bos.baidu.com/sw-search-sp/software/1877fabbce78e/NeteaseMusic_1.5.1.530_mac.dmg",
        @"http://dlsw.baidu.com/sw-search-sp/soft/66/13103/TTPod_installer_v1.0.6.7957.1436437104.exe",
        @"http://sw.bos.baidu.com/sw-search-sp/software/b3282eadef1fd/Kugou_mac_2.0.2.dmg",
        ];
}

#pragma mark - UITableViewDelegate, UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DownloadCell *cell = [tableView dequeueReusableCellWithIdentifier:@"download" forIndexPath:indexPath];
    cell.nameLabel.text = [NSString stringWithFormat:@"%ld", indexPath.row];
    cell.url = self.urlArr[indexPath.row];
    cell.indexPath = indexPath;
    return cell;
}

#pragma mark - 按钮触发事件

- (void)handleAllSuspend
{
    [[YDDownloadQueue defaultQueue] removeAllTasks];
}

- (void)handleAllResume
{
    [[YDDownloadQueue defaultQueue] resumeAllTasks];
}

@end
