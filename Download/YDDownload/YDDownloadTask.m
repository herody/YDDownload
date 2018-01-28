//
//  YDDownloadTask.m
//  Download
//
//  Created by 侯亚迪 on 17/8/25.
//  Copyright © 2017年 侯亚迪. All rights reserved.
//

#import "YDDownloadTask.h"
#import "YDDownloadQueue.h"

NSString * const YDDownloadTaskDidChangeStatusNotification = @"YDDownloadTaskDidChangeStatusNotification";

@interface YDDownloadTask ()<NSURLSessionDelegate, NSURLSessionDataDelegate>
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;

@property (nonatomic, strong) NSString *directoryPath;
@property (nonatomic, strong) NSFileHandle *fileHandle;

@property (nonatomic, assign) long long accumulateLength;
@property (nonatomic, strong) NSDate *lastDate;
           
@property (nonatomic, copy) void (^progressHandler)(CGFloat, CGFloat);
@property (nonatomic, copy) void (^completionHandler)(NSString *, NSError *);

@end

@implementation YDDownloadTask

#pragma mark - 生命周期

- (instancetype)init
{
    if (self = [super init]) {
        //创建文件夹
        _directoryPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"YDDownloads"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:_directoryPath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:_directoryPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        //创建NSURLSession
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return self;
}

- (instancetype)initWithUrl:(NSString *)urlStr progressHandler:(void (^)(CGFloat progress, CGFloat speed))progressHandler completionHandler:(void (^)(NSString *filePath, NSError *error))completionHandler
{
    if (self = [self init]) {
        //保存任务相关参数
        _downloadUrl = urlStr;
        self.progressHandler = progressHandler;
        self.completionHandler = completionHandler;
        
        //获取已下载文件信息
        NSDictionary *taskInfo = [self getTaskInfoForUrl:_downloadUrl];
        if (taskInfo) {
            _filePath = [self.directoryPath stringByAppendingPathComponent:taskInfo[@"fileName"]];
            _receivedLength = [self getFileSizeAtPath:_filePath];
            _expectedLength = [taskInfo[@"totalSize"] longLongValue];
        }
        
        //初始化参数
        _taskProgress = 0;
        _taskSpeed = 0;
        _accumulateLength = 0;
        _taskPriority = YDDownloadPriorityDefault;
        self.taskStatus = YDDownloadTaskStatusWaiting;
    }
    return self;
}

+ (instancetype)downloadTaskWithUrl:(NSString *)urlStr progressHandler:(void (^)(CGFloat progress, CGFloat speed))progressHandler completionHandler:(void (^)(NSString *filePath, NSError *error))completionHandler
{
    return [[self alloc] initWithUrl:urlStr progressHandler:progressHandler completionHandler:completionHandler];
}

#pragma mark - getter

- (NSURLSessionDataTask *)dataTask
{
    if (!_dataTask) {
        NSURL *url = [NSURL URLWithString:_downloadUrl];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        NSString *range = [NSString stringWithFormat:@"bytes=%zd-", _receivedLength];
        [request setValue:range forHTTPHeaderField:@"Range"];
        
        _dataTask = [_session dataTaskWithRequest:request];
    }
    return _dataTask;
}

#pragma mark - setter

- (void)setTaskStatus:(YDDownloadTaskStatus)taskStatus
{
    //setter
    _taskStatus = taskStatus;
    
    //发起任务状态改变的通知
    [[NSNotificationCenter defaultCenter] postNotificationName:YDDownloadTaskDidChangeStatusNotification object:self];
}

#pragma mark - 私有方法

//获取指定路径文件的大小
- (long long)getFileSizeAtPath:(NSString *)path
{
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    return [attributes[@"NSFileSize"] longLongValue];
}

//保存文件名与链接的关联
- (void)saveTaskInfo:(NSDictionary *)taskInfo forUrl:(NSString *)url
{
    NSString *plistPath = [_directoryPath stringByAppendingPathComponent:@"download.plist"];
    NSMutableDictionary *plistDic = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    if (!plistDic) {
        plistDic = [NSMutableDictionary dictionary];
    }
    [plistDic setObject:taskInfo forKey:url];
    [plistDic writeToFile:plistPath atomically:YES];
}

//根据链接获取文件名
- (NSDictionary *)getTaskInfoForUrl:(NSString *)url
{
    NSString *plistPath = [_directoryPath stringByAppendingPathComponent:@"download.plist"];
    NSMutableDictionary *plistDic = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    return [plistDic objectForKey:url];
}

//删除文件名与链接的关联
- (void)deleteTaskInfoForUrl:(NSString *)url
{
    NSString *plistPath = [_directoryPath stringByAppendingPathComponent:@"download.plist"];
    NSMutableDictionary *plistDic = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    [plistDic removeObjectForKey:url];
    [plistDic writeToFile:plistPath atomically:YES];
}

#pragma mark - 公开方法

- (void)startDownloadWithUrl:(NSString *)urlStr progressHandler:(void (^)(CGFloat progress, CGFloat speed))progressHandler completionHandler:(void (^)(NSString *filePath, NSError *error))completionHandler
{
    //保存任务相关参数
    _downloadUrl = urlStr;
    self.progressHandler = progressHandler;
    self.completionHandler = completionHandler;
    
    //获取已下载文件信息
    NSDictionary *taskInfo = [self getTaskInfoForUrl:_downloadUrl];
    if (taskInfo) {
        _filePath = [_directoryPath stringByAppendingPathComponent:taskInfo[@"fileName"]];
        _receivedLength = [self getFileSizeAtPath:_filePath];
        _expectedLength = [taskInfo[@"totalSize"] longLongValue];
    }
    
    //初始化参数
    _taskProgress = 0;
    _taskSpeed = 0;
    _accumulateLength = 0;
    _taskPriority = YDDownloadPriorityDefault;
    self.taskStatus = YDDownloadTaskStatusWaiting;

    //开启下载任务
    [self resumeTask];
}

//暂停任务
- (void)suspendTask
{
    //暂停任务
    if (self.taskStatus == YDDownloadTaskStatusRunning || self.taskStatus == YDDownloadTaskStatusFailed) {
        [self.dataTask suspend];
    }
    
    //更改任务状态
    self.taskStatus = YDDownloadTaskStatusSuspended;
}

//取消任务
- (void)cancelTask
{
    //取消任务
    [self.dataTask cancel];
    self.dataTask = nil;
    
    //删除已下载文件及文件关联信息
    [[NSFileManager defaultManager] removeItemAtPath:_filePath error:nil];
    [self deleteTaskInfoForUrl:_downloadUrl];
    
    //更改任务状态
    self.taskStatus = YDDownloadTaskStatusCanceled;
}

//开始/恢复任务
- (void)resumeTask
{
    //更改任务状态
    self.taskStatus = YDDownloadTaskStatusRunning;
    
    //开始/恢复任务
    if (self.taskStatus == YDDownloadTaskStatusRunning) {
        [self.dataTask resume];
    }
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    //创建文件
    _filePath = [self.directoryPath stringByAppendingPathComponent:response.suggestedFilename];
    if (![[NSFileManager defaultManager] fileExistsAtPath:_filePath]) {
        [[NSFileManager defaultManager] createFileAtPath:_filePath contents:nil attributes:nil];
        NSDictionary *taskInfo = @{@"fileName":response.suggestedFilename, @"totalSize":@(response.expectedContentLength)};
        [self saveTaskInfo:taskInfo forUrl:_downloadUrl];
    }
    
    //参数赋初值
    _lastDate = [NSDate date];
    _expectedLength = response.expectedContentLength + self.receivedLength;
    
    //文件句柄指向指定路径
    _fileHandle = [NSFileHandle fileHandleForWritingAtPath:_filePath];
    [_fileHandle seekToEndOfFile];
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    //写入数据
    [_fileHandle writeData:data];
    
    //计算下载进度
    _receivedLength += data.length;
    _taskProgress = _receivedLength * 1.0 / _expectedLength;
    
    //计算下载速度
    _accumulateLength += data.length;
    if ([[NSDate date] timeIntervalSinceDate:_lastDate] >= 1) {
        _taskSpeed = _accumulateLength * 1.0;
        _lastDate = [NSDate date];
        _accumulateLength = 0;
    }
    
    //回调
    if (self.progressHandler) {
        self.progressHandler(_taskProgress, _taskSpeed);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
    //关闭文件句柄
    [_fileHandle closeFile];
    _fileHandle = nil;
    
    //清空参数
    self.dataTask = nil;
    _taskSpeed = 0;
    _accumulateLength = 0;
    
    //删除文件名与下载链接的关联
    if (!error && _taskProgress >= 1.0) {
        [self deleteTaskInfoForUrl:_downloadUrl];
    }
    
    //更改任务状态
    if (error) {
        if (error.code != -999) {
            self.taskStatus = YDDownloadTaskStatusFailed;
        }
    } else {
        self.taskStatus = YDDownloadTaskStatusCompleted;
    }

    //回调
    if (self.completionHandler) {
        self.completionHandler(_filePath, error);
    }
}

@end
