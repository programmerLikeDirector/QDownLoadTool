//
//  QDownLoadTool.m
//  QDownLoadWheel
//
//  Created by sure on 2018/3/11.
//  Copyright © 2018年 sure. All rights reserved.
//

#import "QDownLoadTool.h"

@interface QDownLoadTool ()<NSURLSessionDataDelegate>

@property (nonatomic,strong) NSString *downLoadURL;
@property (nonatomic,strong) NSString *fileName;

@property (nonatomic,strong) NSString *fullPath;

@property (nonatomic,strong) NSURLSession *session;
@property (nonatomic,strong) NSURLSessionDataTask *dataTask;
@property (nonatomic,assign) long filehandleOffset;
@property (nonatomic,strong) NSFileHandle *filehandle;
@property (nonatomic,assign) NSInteger growth;
@property (nonatomic,assign) NSInteger lastSize;
@property (nonatomic, strong) NSDate *currentDate;

@property (nonatomic,assign) NSInteger currentSize;
@property (nonatomic,assign) NSInteger totalSize;
@property (nonatomic,assign) float progress;
@property (nonatomic,copy) NSString *netWorkSpeed;


@end

@implementation QDownLoadTool

- (instancetype)initWithURL:(NSString *)url Parameter:(DownloadType)para DownloadFilePath:(NSString *)filePath fileName:(NSString *)fileName {
    if (self = [super init]) {
        [self initDownLoadDataWithURL:url Parameter:para DownloadFilePath:filePath fileName:fileName];
    }
    return self;
}


- (void)initDownLoadDataWithURL:(NSString *)url Parameter:(DownloadType)para DownloadFilePath:(NSString *)filePath fileName:(NSString *)fileName {
    
    self.downLoadURL = url;
    self.fileName = fileName;
    [self creatFullPathWithFilePath:filePath FileName:fileName];
}

- (void)downLoadStart {
    [self downLoadResume];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    self.totalSize = response.expectedContentLength + self.currentSize;
    
    if (self.currentSize == 0) {
        [[NSFileManager defaultManager]createFileAtPath:self.fullPath contents:nil attributes:nil];
    }
    
    self.filehandle = [NSFileHandle fileHandleForWritingAtPath:self.fullPath];
    //移动文件句柄指针
    [self.filehandle seekToEndOfFile];
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    
    if (dataTask.error) {
        return;
    }
    
    [self.filehandle writeData:data];
    
    self.currentSize += data.length;
    
    self.progress = (1.0 * self.currentSize / self.totalSize);
    
    NSDate *currentDate = [NSDate date];
    
    if ([currentDate timeIntervalSinceDate:self.currentDate] >= 1 && self.currentDate)  {
        double time = [currentDate timeIntervalSinceDate:self.currentDate];
        self.netWorkSpeed = [NSString stringWithFormat:@"%.1fKB/s",(self.currentSize/1024)/time];
    }

    //调用代理方法
    if ([self.qDownloadDelegate respondsToSelector:@selector(qGetDownloadProgress:currentSize:totalSize:netWorkSpeed:)]){
        [self.qDownloadDelegate qGetDownloadProgress:self.progress currentSize:self.currentSize totalSize:self.totalSize netWorkSpeed:self.netWorkSpeed];
    }
    
    if (self.currentDate == nil) {
        self.currentDate = currentDate;
    }
    
}

- (NSString*)formatByteCount:(long long)size {
    return [NSByteCountFormatter stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleFile];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        [self closeFileHandle];
        
        if (error.code == -1005) {
            
            //lost
        }else if (error.code == -1001){
            
            //timeout
        }else if (error.code == -1002){
            
        }else if (error.code == -999 && ![error.localizedDescription isEqualToString:@"cancelled"]) {
            
        }else if (error.code == -1009) {
            
        }
        
        self.dataTask = nil;
        
        if ([self.qDownloadDelegate respondsToSelector:@selector(qDownloadCompeletedFilePath:Successed:Error:)]) {
            [self.qDownloadDelegate qDownloadCompeletedFilePath:self.fullPath Successed:NO Error:error];
        }
        
        return;
    }
    
    if(self.currentSize == self.totalSize) {
        [self closeFileHandle];
        //NSLog(@"\n\n%@\n",self.fullPath);
        if ([self.qDownloadDelegate respondsToSelector:@selector(qDownloadCompeletedFilePath:Successed:Error:)]) {
            [self.qDownloadDelegate qDownloadCompeletedFilePath:self.fullPath Successed:YES Error:nil];
        }
    }
}

- (void)downLoadResume {
    
    if (self.dataTask.state == NSURLSessionTaskStateSuspended) {
        [self.dataTask resume];
    }
    
}

- (void)downLoadSuspend {
    
    if (self.dataTask.state == NSURLSessionTaskStateRunning) {
        [self.dataTask suspend];
    }
}

- (void)downLoadCancel {
    [self.dataTask cancel];
    self.dataTask = nil;
}

- (void)closeFileHandle {
    [self.filehandle closeFile];
    self.filehandle = nil;
}

- (void)creatFullPathWithFilePath:(NSString *)filePath FileName:(NSString *)fileName {
    
    if(![[NSFileManager defaultManager]fileExistsAtPath:filePath]){
        [[NSFileManager defaultManager]createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    self.fullPath = [filePath stringByAppendingPathComponent:fileName];
}

- (NSURLSessionDataTask *)dataTask {
    if (nil == _dataTask) {
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.downLoadURL]];
        [request addValue:@"" forHTTPHeaderField:@"Accept-Encoding"];
        
        self.currentSize = [self getFileSize];
        //设置请求头信息
        NSString *range = [NSString stringWithFormat:@"bytes=%zd-",self.currentSize];
        [request setValue:range forHTTPHeaderField:@"Range"];
        //[request addValue:@"Keep-Alive" forHTTPHeaderField:@"Connection"];
        
        //request.timeoutInterval = 60;
        
        _dataTask = [self.session dataTaskWithRequest:request];
        
    }
    return _dataTask;
}

- (NSURLSession *)session {
    if (nil == _session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc]init]];
        
    }
    return _session;
}


- (NSInteger)getFileSize {
    NSDictionary *fileInfoDict = [[NSFileManager defaultManager]attributesOfItemAtPath:self.fullPath error:nil];
    return [fileInfoDict[@"NSFileSize"]integerValue];
}


@end
