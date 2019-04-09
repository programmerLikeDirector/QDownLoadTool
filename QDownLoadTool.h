//
//  QDownLoadTool.h
//  QDownLoadWheel
//
//  Created by sure on 2018/3/11.
//  Copyright © 2018年 qishuo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    resume,
    noResume,
} DownloadType;


@protocol QDownLoadDelegate <NSObject>

/**
 获取下载过程数据代理方法
 参数说明：
 progress：进度
 currentSize:已下载文件大小
 totalSize:全部文件大小
 networkspeed:实时网速
 */

- (void)qGetDownloadProgress:(float)progress currentSize:(NSInteger)currentSize totalSize:(NSInteger)totalSize netWorkSpeed:(NSString *)netWorkSpeed;

/**
 下载完成／报错 代理方法
 参数说明：
 filePath:下载文件路径
 successed:是否下载成功
 error:报错信息（下载成功时返回nil）
 */
- (void)qDownloadCompeletedFilePath:(NSString *)filePath Successed:(BOOL)successed Error:(NSError *)error;

@end


@interface QDownLoadTool : NSObject

@property (nonatomic,weak) id <QDownLoadDelegate> qDownloadDelegate;

/**
 初始化方法
 参数说明：
 url:下载地址
 para:下载类型（暂未使用）
 filePath:下载文件路径
 fileName:下载文件名
 */

- (instancetype)initWithURL:(NSString *)url Parameter:(DownloadType)para DownloadFilePath:(NSString *)filePath fileName:(NSString *)fileName;

//开始下载or继续下载
- (void)downLoadResume;
//暂停下载
- (void)downLoadSuspend;
//取消下载
- (void)downLoadCancel;

@end
