#SODownloader

简单几步，集成功能齐全的下载功能！关于 SODownloader 更详细的介绍可以参考[SODownloader介绍](http://scfhao.coding.me/2016/09/14/introduce-sodownloader.html)

## 使用步骤

### 一、导入所需文件

将 SODownloader 文件夹中的文件 @[SODownloader, SODownloadItem, AppDelegate+SODownloader, SODownloadResponseSerializer] 导入到你自己的项目中。

### 二、适配下载模型

将项目中需要下载的模型类继承或实现 SODownloadItem 协议。

1. 实现 downloadURL 方法返回模型代表的下载文件的 URL。
2. 如果模型继承了 SODownloadItem 类，直接跳过此步。如果模型实现 SODownloadItem 协议，需要为下载状态和下载进度合成属性访问器，只需在.m文件中加上`@synthesize downloadProgress, downloadState;`即可。

### 三、创建下载器进行下载

完成步骤一、二后，就可以创建 SODownloader 类的对象对步骤二中适配的 model 进行下载啦。

1. 创建 Downloader 调用`+ (instancetype)downloaderWithIdentifier:(NSString *)identifier completeBlock:(SODownloadCompleteBlock_t)completeBlock`方法即可，注意`identifier`参数的唯一性。
2. 调用 SODownloader.h 文件中定义的下载、暂停等下载管理方法。

### 四、观察下载状态并更新界面

可以通过 KVO 下载 model 的`downloadProgress`来更新UI中的下载进度，观察下载 model 的`downloadState`属性来更新下载状态。

## 建议反馈

欢迎通过[Issue](https://github.com/scfhao/SODownloader/issues)提出优化建议。