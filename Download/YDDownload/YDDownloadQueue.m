//
//  YDDownloadQueue.m
//  Download
//
//  Created by 侯亚迪 on 17/8/25.
//  Copyright © 2017年 侯亚迪. All rights reserved.
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
        _excutingTasks = [NSMutableArray array];
        _waitingTasks = [NSMutableArray array];
        _maxConcurrentTaskCount = 1;
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
- (void)addDownloadTask:(YDDownloadTask *)downloadTask
{
    if (_excutingTasks.count < _maxConcurrentTaskCount) {
        [_excutingTasks addObject:downloadTask];
        [downloadTask resumeTask];
    } else {
        [_waitingTasks addObject:downloadTask];
    }
}

//添加任务到队列中
- (YDDownloadTask *)addDownloadTaskWithPriority:(YDDownloadPriority)priority url:(NSString *)urlStr progressHandler:(void (^)(CGFloat progress, CGFloat speed))progressHandler completionHandler:(void (^)(NSString *filePath, NSError *error))completionHandler
{
    YDDownloadTask *downloadTask = [YDDownloadTask downloadTaskWithUrl:urlStr progressHandler:progressHandler completionHandler:completionHandler];
    downloadTask.taskPriority = priority;
    [self addDownloadTask:downloadTask];
    return downloadTask;
}

//移除指定任务
- (void)removeDownloadTask:(YDDownloadTask *)downloadTask
{
    [downloadTask cancelTask];
    [_excutingTasks removeObject:downloadTask];
    [_waitingTasks removeObject:downloadTask];
}

//暂停全部任务
- (void)suspendAllTasks
{
    //暂停全部任务
    NSInteger taskNum = _excutingTasks.count;
    for (YDDownloadTask *task in [_waitingTasks copy]) {
        [task suspendTask];
    }
    for (YDDownloadTask *task in [_excutingTasks copy]) {
        [task suspendTask];
    }
    
    //将下载中的任务移至等待中队列顶部
    NSIndexSet *taskIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(_waitingTasks.count - taskNum, taskNum)];
    NSArray *tasks = [_waitingTasks objectsAtIndexes:taskIndexes];
    [_waitingTasks removeObjectsAtIndexes:taskIndexes];
    NSIndexSet *insertIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, taskNum)];
    [_waitingTasks insertObjects:tasks atIndexes:insertIndexes];
}

//移除全部任务
- (void)removeAllTasks
{
    //取消全部任务
    for (YDDownloadTask *task in [_waitingTasks copy]) {
        [task cancelTask];
    }
    for (YDDownloadTask *task in [_excutingTasks copy]) {
        [task cancelTask];
    }
    
    //清空队列
    [_waitingTasks removeAllObjects];
    [_excutingTasks removeAllObjects];
}

//开启/恢复全部任务
- (void)resumeAllTasks
{
    for (YDDownloadTask *task in [_excutingTasks copy]) {
        [task resumeTask];
    }
    for (YDDownloadTask *task in [_waitingTasks copy]) {
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
            [_excutingTasks removeObject:downloadTask];
        }
        //将任务从下载中队列转移到等待中队列
        if (downloadTask.taskStatus == YDDownloadTaskStatusSuspended || downloadTask.taskStatus == YDDownloadTaskStatusCanceled || downloadTask.taskStatus == YDDownloadTaskStatusFailed) {
            if ([_excutingTasks containsObject:downloadTask]) {
                [_waitingTasks addObject:downloadTask];
                [_excutingTasks removeObject:downloadTask];
            }
        }
        //从等待中队列取任务并转移到下载中队列
        if (_excutingTasks.count < _maxConcurrentTaskCount && _waitingTasks.count) {
            YDDownloadTask *highestTask = nil;
            for (YDDownloadTask *task in [_waitingTasks copy]) {
                if ((task.taskStatus == YDDownloadTaskStatusWaiting || task.taskStatus == YDDownloadTaskStatusFailed) && (highestTask == nil || task.taskPriority > highestTask.taskPriority)) {
                    highestTask = task;
                }
            }
            if (highestTask) {
                [_excutingTasks addObject:highestTask];
                [_waitingTasks removeObject:highestTask];
                [highestTask resumeTask];
            }
        }
    }
    
    if (downloadTask.taskStatus == YDDownloadTaskStatusRunning && [_waitingTasks containsObject:downloadTask]) {
        if (_excutingTasks.count < _maxConcurrentTaskCount) {
            //将任务从等待中队列转移到下载中队列
            [_excutingTasks addObject:downloadTask];
            [_waitingTasks removeObject:downloadTask];
        } else {
            //状态改变为等待中
            [downloadTask setValue:@(YDDownloadTaskStatusWaiting) forKeyPath:@"taskStatus"];
        }
    }
}

@end
