# SODownloader设计

SODownloader设计目标为一个通用性强的下载管理封装，暂时先只实现对单文件任务下载的支持，对批量下载任务后续再慢慢支持。

### 通用下载功能

* 下载进度支持
* 

### 特有下载处理

对下载进度处理是为每个item提供下载进度支持
对下载位置和完成处理的解决方案是先下载到临时目录，由用户决定如何处理。

* 对下载进度的处理
* 对下载位置的处理
* 对已完成文件的处理

## 类设计

### SODownloader 

SODownloader作为下载管理器类，负责一类下载任务的管理，如果存在多个下载模型，则建议使用多个SODownloader对象。

SODownloader应该提供的接口：

- 添加一个任务
- 添加多个任务
- 暂停一个任务
- 全部暂停
- 全部开始
- 全部取消
- 取消（删除）一个任务
- 同时下载数管理
- 已下载管理

### SODownloadItem

SODownloadItem是SODownloader下载器支持的可下载项，可下载项应具有的功能。item应设计为接口（Protocol）

*这里还有个想法，在SODownloader中为每个item创建一个对应的Delegate对象，用这些对象来提供下载接口*

SODownloadItem具有的下载状态：

* Normal 没加到SODownloader中
* Wait 等待状态
* Loading 下载状态
* Pause 暂停状态
* Complete 完成状态
* Error 失败状态

SODownloadItem应具支持的功能（这些功能都是封装SODownloader对象的功能，item实现这些功能只是为了调用更加方便）：

*仔细一想：如果要创建多个SODownloader对象，这些方法则无法实现了，除非告诉这些item它们要被加到哪个SODownloader对象中*

* 进度（current ／ total、progress）
* 下载状态
* 开始下载
* 暂停下载
* 取消下载
* 标记为完成状态

