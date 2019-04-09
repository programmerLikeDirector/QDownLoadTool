# QDownLoadTool
iOS断点续传下载方法（OC）

使用方法：
初始化：
参数说明：

 url:下载地址
 para:下载类型（暂未使用）
 filePath:下载文件路径
 fileName:下载文件名

- (instancetype)initWithURL:(NSString *)url Parameter:(DownloadType)para DownloadFilePath:(NSString *)filePath fileName:(NSString *)fileName；

开始下载or继续下载
- (void)downLoadResume;
暂停下载
- (void)downLoadSuspend;
取消下载
- (void)downLoadCancel;

