//
//  YDDownloadQueue.h
//  Download
//
//  Created by 侯亚迪 on 17/8/25.
//  Copyright © 2017年 侯亚迪. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "YDDownloadTask.h"


@interface YDDownloadQueue : NSObject

/**
 下载任务最大并发数(当为-1时，表示最大并发数没有限制，默认为1)
 */
@property (nonatomic, assign) NSInteger maxConcurrentTaskCount;

/**
 正在执行的下载任务
 */
@property (nonatomic, strong, readonly) NSMutableArray *excutingTasks;

/**
 正在等待中的下载任务
 */
@property (nonatomic, strong, readonly) NSMutableArray *waitingTasks;


/**
 返回单例对象

 @return 返回YDDownloadQueue单例对象
 */
+ (instancetype)defaultQueue;



/**
 添加下载任务到队列中

 @param downloadTask 将要添加的下载任务
 */
- (void)addDownloadTask:(YDDownloadTask *)downloadTask;


/**
 添加下载任务到队列中

 @param priority 任务优先级
 @param urlStr 下载链接
 @param progressHandler 下载进度回调
 @param completionHandler 下载结果回调
 @return 返回YDDownloadTask对象
 */
- (YDDownloadTask *)addDownloadTaskWithPriority:(YDDownloadPriority)priority url:(NSString *)urlStr progressHandler:(void (^)(CGFloat progress, CGFloat speed))progressHandler completionHandler:(void (^)(NSString *filePath, NSError *error))completionHandler;


/**
 移除下载任务（执行该操作会从任务队列中移除该任务，并删除本地数据）

 @param downloadTask 将要移除的下载任务
 */
- (void)removeDownloadTask:(YDDownloadTask *)downloadTask;


/**
 暂停所有的下载任务
 */
- (void)suspendAllTasks;


/**
 移除所有的下载任务（执行该操作会从任务队列中移除所有任务，并删除本地数据）
 */
- (void)removeAllTasks;


/**
 开始/恢复所有的下载任务
 */
- (void)resumeAllTasks;

@end
