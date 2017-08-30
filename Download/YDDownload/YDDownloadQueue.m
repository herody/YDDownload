//
//  YDDownloadQueue.m
//  Download
//
//  Created by 侯亚迪 on 17/8/25.
//  Copyright © 2017年 杭州魔品科技. All rights reserved.
//

#import "YDDownloadQueue.h"

@interface YDDownloadQueue ()

@end

@implementation YDDownloadQueue

#pragma mark - 生命周期

- (instancetype)init
{
    if (self = [super init]) {
        //参数初始化
        self.excutingTasks = [NSMutableArray array];
        self.waitingTasks = [NSMutableArray array];
        self.maxConcurrentTaskCount = 1;
        //添加任务状态改变通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadTaskDidChangeStatusNotification:) name:YDDownloadTaskDidChangeStatusNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 单例

+ (instancetype)defaultQueue
{
    static YDDownloadQueue *queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[YDDownloadQueue alloc] init];
    });
    return queue;
}

#pragma mark - setter

- (void)setMaxConcurrentTaskCount:(NSInteger)maxConcurrentTaskCount
{
    if (maxConcurrentTaskCount == -1) {
        _maxConcurrentTaskCount = MAXFLOAT;
    } else {
        _maxConcurrentTaskCount = maxConcurrentTaskCount;
    }
}

#pragma mark - 公开方法

//添加任务到队列中
- (YDDownloadTask *)addDownloadTaskWithPriority:(YDDownloadPriority)priority url:(NSString *)urlStr progressHandler:(void (^)(CGFloat progress, CGFloat speed))progressHandler completionHandler:(void (^)(NSString *filePath, NSError *error))completionHandler
{
    YDDownloadTask *downloadTask = [YDDownloadTask downloadTaskWithUrl:urlStr progressHandler:progressHandler completionHandler:completionHandler];
    downloadTask.taskPriority = priority;
    
    if (self.excutingTasks.count < self.maxConcurrentTaskCount) {
        [self.excutingTasks addObject:downloadTask];
        [downloadTask resumeTask];
    } else {
        [self.waitingTasks addObject:downloadTask];
    }
    return downloadTask;
}

//移除指定任务
- (void)removeDownloadTask:(YDDownloadTask *)downloadTask
{
    [downloadTask cancelTask];
    [self.excutingTasks removeObject:downloadTask];
    [self.waitingTasks removeObject:downloadTask];
}

//暂停全部任务
- (void)suspendAllTasks
{
    for (YDDownloadTask *task in [self.excutingTasks copy]) {
        [task suspendTask];
    }
    for (YDDownloadTask *task in [self.waitingTasks copy]) {
        [task suspendTask];
    }
}

//移除全部任务
- (void)removeAllTasks
{
    for (YDDownloadTask *task in [self.excutingTasks copy]) {
        [task cancelTask];
    }
    for (YDDownloadTask *task in [self.waitingTasks copy]) {
        [task cancelTask];
    }
    [self.excutingTasks removeAllObjects];
    [self.waitingTasks removeAllObjects];
}

//开启/恢复全部任务
- (void)resumeAllTasks
{
    for (YDDownloadTask *task in [self.excutingTasks copy]) {
        [task resumeTask];
    }
    for (YDDownloadTask *task in [self.waitingTasks copy]) {
        [task resumeTask];
    }
}

#pragma mark - 通知

- (void)downloadTaskDidChangeStatusNotification:(NSNotification *)notify
{
    YDDownloadTask *downloadTask = (YDDownloadTask *)notify.object;
    
    if (downloadTask.taskStatus == YDDownloadTaskStatusSuspended || downloadTask.taskStatus == YDDownloadTaskStatusCanceled || downloadTask.taskStatus == YDDownloadTaskStatusCompleted || downloadTask.taskStatus == YDDownloadTaskStatusFailed) {
        //将已完成任务从下载中队列移除
        if (downloadTask.taskStatus == YDDownloadTaskStatusCompleted) {
            [self.excutingTasks removeObject:downloadTask];
        }
        //将任务从下载中队列转移到等待中队列
        if (downloadTask.taskStatus == YDDownloadTaskStatusSuspended || downloadTask.taskStatus == YDDownloadTaskStatusCanceled || downloadTask.taskStatus == YDDownloadTaskStatusFailed) {
            if ([self.excutingTasks containsObject:downloadTask]) {
                [self.waitingTasks addObject:downloadTask];
                [self.excutingTasks removeObject:downloadTask];
            }
        }
        //从等待中队列取任务并转移到下载中队列
        if (self.excutingTasks.count < self.maxConcurrentTaskCount && self.waitingTasks.count) {
            YDDownloadTask *highestTask = nil;
            for (YDDownloadTask *task in [self.waitingTasks copy]) {
                if ((task.taskStatus == YDDownloadTaskStatusWaiting || task.taskStatus == YDDownloadTaskStatusFailed) && (highestTask == nil || task.taskPriority > highestTask.taskPriority)) {
                    highestTask = task;
                }
            }
            if (highestTask) {
                [self.excutingTasks addObject:highestTask];
                [self.waitingTasks removeObject:highestTask];
                [highestTask resumeTask];
            }
        }
    }
    
    if (downloadTask.taskStatus == YDDownloadTaskStatusRunning && [self.waitingTasks containsObject:downloadTask]) {
        if (self.excutingTasks.count < self.maxConcurrentTaskCount) {
            //将任务从等待中队列转移到下载中队列
            [self.excutingTasks addObject:downloadTask];
            [self.waitingTasks removeObject:downloadTask];
        } else {
            //状态改变为等待中
            downloadTask.taskStatus = YDDownloadTaskStatusWaiting;
        }
    }
}

@end
