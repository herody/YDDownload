//
//  YDDownloadTask.h
//  Download
//
//  Created by 侯亚迪 on 17/8/25.
//  Copyright © 2017年 侯亚迪. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


/**
 下载任务状态变更通知
 */
extern NSString * const YDDownloadTaskDidChangeStatusNotification;

/**
 下载任务状态枚举

 - YDDownloadTaskStatusWaiting: 等待中
 - YDDownloadTaskStatusRunning: 下载中
 - YDDownloadTaskStatusSuspended: 已暂停
 - YDDownloadTaskStatusCanceled: 已取消
 - YDDownloadTaskStatusCompleted: 已结束
 - YDDownloadTaskStatusFailed: 下载失败
 */
typedef NS_ENUM(NSUInteger, YDDownloadTaskStatus) {
    YDDownloadTaskStatusWaiting = 0,
    YDDownloadTaskStatusRunning = 1,
    YDDownloadTaskStatusSuspended = 2,
    YDDownloadTaskStatusCanceled = 3,
    YDDownloadTaskStatusCompleted = 4,
    YDDownloadTaskStatusFailed = 5
};

/**
 下载任务优先级枚举
 
 - YDDownloadPriorityLow: 低优先级
 - YDDownloadPriorityDefault: 默认优先级
 - YDDownloadPriorityHigh: 高优先级
 */
typedef NS_ENUM(NSUInteger, YDDownloadPriority) {
    YDDownloadPriorityLow = 0,
    YDDownloadPriorityDefault = 1,
    YDDownloadPriorityHigh = 2,
};

@interface YDDownloadTask : NSObject

/**
 下载状态
 */
@property (nonatomic, assign, readonly) YDDownloadTaskStatus taskStatus;

/**
 下载任务优先级,默认为YDDownloadPriorityDefault
 */
@property (nonatomic, assign) YDDownloadPriority taskPriority;

/**
 下载链接
 */
@property (nonatomic, strong, readonly) NSString *downloadUrl;

/**
 下载完成后的文件地址
 */
@property (nonatomic, strong, readonly) NSString *filePath;

/**
 下载进度
 */
@property (nonatomic, assign, readonly) CGFloat taskProgress;

/**
 下载速度
 */
@property (nonatomic, assign, readonly) CGFloat taskSpeed;

/**
 文件总大小
 */
@property (nonatomic, assign, readonly) long long expectedLength;

/**
 已接收文件大小
 */
@property (nonatomic, assign, readonly) long long receivedLength;


/**
 创建下载任务（需调用resumeTask开启任务）

 @param urlStr 下载链接
 @param progressHandler 下载进度回调
 @param completionHandler 下载结果回调
 @return 返回YDDownloadTask对象
 */
+ (instancetype)downloadTaskWithUrl:(NSString *)urlStr progressHandler:(void (^)(CGFloat progress, CGFloat speed))progressHandler completionHandler:(void (^)(NSString *filePath, NSError *error))completionHandler;


/**
 开启下载任务（该操作会自动调用resumeTask开启任务）
 
 @param urlStr 下载链接
 @param progressHandler 下载进度回调
 @param completionHandler 下载结果回调
 */
- (void)startDownloadWithUrl:(NSString *)urlStr progressHandler:(void (^)(CGFloat progress, CGFloat speed))progressHandler completionHandler:(void (^)(NSString *filePath, NSError *error))completionHandler;


/**
 暂停下载任务
 */
- (void)suspendTask;


/**
 取消下载任务（执行该操作会删除本地数据）
 */
- (void)cancelTask;


/**
 开始/恢复下载任务
 */
- (void)resumeTask;

@end
