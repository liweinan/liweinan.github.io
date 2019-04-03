---
title: tinkerpop的使用（上）
abstract: tinkerpop是主流的图数据引擎，它现在主要由两部分组成，一个是gremlin-console，还有一个是gremlin-server。其中gremlin-console默认使用groovy语言作为交互工具。
---

## {{ page.title }}

`tinkerpop`是主流的图数据引擎，它现在主要由两部分组成，一个是`gremlin-console`，还有一个是`gremlin-server`。其中`gremlin-console`默认使用`groovy`语言作为交互工具。

这个系列准备一共做三篇文章进行讲解：

* `tinkerpop`的安装与使用，以及数据导入。
* 使用`jupyter-book`操作图数据库。
* 使用`pycharm`操作图数据库。

本文是第一篇，讲解`tinkerpop`的安装与使用，以及数据导入。

首先是下载Gremlin Console和Gremlin Server，下载地址在这里：

* [http://tinkerpop.apache.org/](http://tinkerpop.apache.org/) 

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr03/2C7C17A3-7E77-4C8B-A114-6E89F392B1AC.png)

下载完两个压缩包以后解压：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr03/6FE0B0E8-6191-4F22-8948-EA13B1A2BC18.png)

这样两个组件就都准备好了。接下来是启动`gremlin-server`：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr03/6640AC28-872A-4CD9-8A99-68886AC1C254.png)

此时我们可以调用`gremlin-console`对服务端进行连接。首先是启动`gremlin-console`：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr03/B7E5B0E0-6928-4594-AF10-B58ACDC9BB4C.png)

如上图所示，我们进入了`gremlin-console`的终端，此时可以使用命令连接服务端：

```bash
gremlin> :remote connect tinkerpop.server conf/remote.yaml
==>Configured localhost/127.0.0.1:8182
```

可以看到此时已经连接到`gremlin-server`了。此时我们可以往服务端导入一些数据。

可以考虑使用这套数据：

* [GitHub - AndrewChau/learn-gremlin-jupyter-notebook](https://github.com/AndrewChau/learn-gremlin-jupyter-notebook)

把这个项目clone到本地：

```bash
$ git clone https://github.com/AndrewChau/learn-gremlin-jupyter-notebook.git
```

然后看一下项目的`data`目录：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr03/947A9EA6-71E7-4E58-A5D9-052AA5191EB3.png)

可以看到里面有不少样例数据。我们可以在`gremlin-console`里导入其中一个数据文件试试看：

```bash
gremlin> :> graph.io(graphml()).readGraph('/Users/weli/works/krlawrence-graph/sample-data/air-routes-latest.graphml')
```

上面的命令在`gremlin-console`里将数据导入了。可以在终端里查看一下导入的数据量：

```bash
gremlin> :> g.V().count()
==>3666
```

可以看到导入了`air-routes-latest.graphml`里面的`3666`条数据。

这篇文章里，我们初步使用了`gremlin-server`和`gremlin-console`，并准备好了数据。下篇文章讲数据的查询，以及如何在`jupyter-notebook`里使用`gremlinpython`进行数据的查询和分析。

∎