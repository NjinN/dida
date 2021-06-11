## dida

dida是完全使用Dart语言实现的一个轻量级web-api服务器，主要面向于前后端分离的Web项目的后端快速搭建。路由及中间件实现参考了dartx项目，增加了多线程、Mysql连接、日志等功能。项目目标是提供一个最简化的后端框架，适用于个人及轻量级应用，但不建议应用在严肃的商业项目。

#### 快速开始
第一步、克隆或下载本项目到本地。

第二步、打开项目根目录下的`conf.dart`文件，按照注释提示修改配置。注意，若不想配置数据库，请把db项全部注释，否则启动项目时会报错。

第三步、项目根目录下执行 `pub get` 安装依赖项。

第四步、项目根目录下执行 `dart server.dart` 启动项目，或者编译`server.dart`为二进制文件后启动。

#### 编写接口实现
接口的实现建议放在`/controller`文件夹下，创建新类，建议命名以`Controller`结尾，`Controller`没有继承要求，请参照`/controller/indexController.dart`类引用必需的依赖文件。

每个接口实现为一个`static`方法，参数为`ServerRequest`、`ServerResponse`、`DbConnection`。

`ServerRequest`事实上是对`HttpRequest`数据的封装，包含了http请求的各项参数，`uri`中存放请求路径信息，`body`中存放请求的二进制数据，默认是以json格式通信，则`data`中存放json数据，对应Dart中的`Map`和`List`。

`ServerResponse`是服务器返回的响应，主要包括`code`和`data`、`contentType`，直接设置为希望返回的值，服务器会将数据返回客户端。例如

```
response.data = "Hello world"
```


`DbConnection`是由连接池提供的数据库连接，目前只支持Mysql数据库，支持使用`?`的Sql预编译并传参，使用`query`执行Sql语句。项目提供了`Sqlx`工具来简化数据库查询，对于简单的Sql语句，建议使用`Sqlx`。

#### 注册路由
dida采用多线程处理请求，每个线程称为`Worker`，路由的注册实现在`/core/worker.dart`中，实例如下

```
router.get('/', IndexController.index, useDB: false);	//Get请求，且不使用数据库连接

router.post('/post', IndexController.post);	//Post请求，默认使用数据库连接
```

dida不支持路由传参！

有那么多传参方式，为什么要路由传参。去除路由传参简化了路由实现，且更加高效可靠。

#### 中间件
dida参考dartx，可以对`router`和单个`route`添加中间件，中间件分为前处理和后处理。中间件的实现和接口一致，但只传入`ServerRequest`、`ServerResponse`，有需要数据库连接的可以修改`/core/router.dart`文件，自行添加数据库连接，或者在实现中使用`DB`类新建数据库连接。

添加中间件同样在`/core/worker.dart`中实现，`router.addBeforeWare()`方法和`router.addAfterWare()`用于对整体路由添加前处理和后处理。注册单个路由时，有两可选参数，`bw`代表前处理列表，`aw`代表后处理列表。

#### Sqlx
dida目标是简化后端实现，默认实现不依赖`Model`，使用Sqlx来简化sql操作。

Sqlx的where方法使用参数名称的后缀约定来实现不同的查询条件，例如

```
无指定后缀，默认执行 = 查询
__like结尾的参数表示执行 LIKE 查询条件
__llike
__rlike
__in	对应参数为数组，执行IN查询
__isn 	对应参数为true或false，代表 IS NULL 或 IS NOT NULL
__lt	小于
__gt	大于
__le	小于等于
__ge	大于等于
__gtlt 	参数为长度为2的数组，表示大于第一个参数，切小于第二个参数
__gtle
__gelt
__gele

```

查询参数的第一层名称为：字段名[+指定后缀]，第二层可指定的条件，形式上为`List`或`Map`，例如

```
["like", "ab", "lt", 10, "ge", 5] // field LIKE "%ab%" AND field < 10 AND field >= 5

{"le": 10, "isn": false} // field <= 10 AND field IS NOT NULL


{
  "id__lt": 100,
  "name": {
    "llike": "Jack",
    "or": ["eq", "Jonh", "isn", true]
  }
}
// id < 100 AND name LIKE 'Jack%' AND (name = "Jonh" OR name IS NULL)
```

具体使用示例如下

```
var rows = await Sqlx().select('*').from('user').where({"id__lt": 100}).limit(10, 20).query(conn);
```

#### Util
dida的工具类放在`/util`文件夹下，通用方法实现在`/util/dd.dart`文件下，常用如下

```
DD.checkParams(request.data, ['table', 'values']);	//request必须包含table和values字段，否则返回错误

DD.takeParams(request.data, ['table', 'values']);	//从request中提取table和values字段，避免客户端传非法值
```

#### Common接口
`/controller/commonController.dart`中实现了通用的`query`、`insert`、`update`、`delete`接口，实现对数据库的通用单表查询，例如`/common/query`接口接收`table`和`where`参数，格式符合Sqlx要求，即能返回所需的查询接口。

这些接口对整个数据库开放，虽然Sqlx使用了预编译，基本上可以防止Sql注入，但这些接口的权限过大，建议仅在开发调试中使用，正式环境中注释这些接口。 

####日志
dida支持`access`、`db`、`error`三种日志，在配置中选择是否开启。注意高并发下，日志会影响QPS性能，尤其是db日志。

#### 命令行参数
dida支持命令行参数设置worker数量和数据库连接数

```
dart server.dart -w3 -c5 	//创建3个worker，每个worker持有5个数据库连接
```

#### hotLoader
`/hotLoader.dart`实现了一个简单的项目文件变更监测和自动重启功能，每秒钟检测项目文件是否有变更，如有变动则重新启动服务，主要用户开发期间修改代码后，服务能自动更新。这里似乎无法使用命令行参数，所以为了减少每次启动的耗时，请在配置中设置为1个worker和1个数据库连接。

注意，该实现十分简陋。

#### 性能
未做专业测试，使用的一个名为`Http并发连接测试工具V1.0.1(内网版)`的工具在windows下进行测试，CPU为E5 4627v2，3.3GHz，8核8线程，创建6个worker，每个worker持有5个Mysql连接。Get请求返回`Hello world`字符串，约为6000QPS。请求从20条数据中，使用2个id小于和大于条件、1个字符串Like条件，查询出1条结果，在开启db日志的情况下，约3000QPS。长时间运行稳定。

#### 项目由来
目前主流的后端框架基本都是MVC模型，但是个人写项目感觉一整套下来比较麻烦，所以希望有一个最简化的方案。

最开始是希望使用nodejs的框架，结果尝试了eggjs，被CPU和内存占用惊到了。后来想起了dart兼具静态和动态特性，语言相对灵活，部署也方便，实测内存占用也很满意。然后发现了dartx，然而dartx实现的并不完整，没有接入数据库，也不支持多线程。于是自己动手实现了这个项目。





