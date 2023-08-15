---
title: tinkerpop的使用（下）
abstract: 这是本系列文章的最后一篇，介绍如何在PyCharm里面使用gremlinpython。
---



这是本系列文章的最后一篇，介绍如何在`PyCharm`里面使用`gremlinpython`。

为了展示用法，首先要创建sample project。因为`PyCharm`支持与`pipenv`的整合，因此使用`pipenv`来管理项目是最方便的。

关于`pipenv`以及`pyenv`的使用方法，建议查看博客里面之前的文章：

* [pyenv和pipenv的整合使用](http://weinan.io/2019/03/21/pipenv.html)
* [pipenv和pycharm的整合](http://weinan.io/2019/03/22/pipenv.html)

熟悉了`pipenv`的基本使用方法以后，首先是创建一个项目目录：

```bash
$ mkdir gremlin-notebooks
```

然后在项目目录里面使用`pipenv`安装`gremlinpython`：

```bash
$ pipenv install gremlinpython
```

安装过程如下：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr05/EDC49697-3ECE-4B72-B6B3-B78E3B416734.png)

安装完成后，可以看到`pipenv`生成了相关的项目文件：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr05/ECD9EC8A-43A1-4DA6-A871-62F76541F09F.png)

此时可以使用`PyCharm`打开这个项目：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr05/2A0C5AAA-CE40-45F6-BCE2-84D500048817.png)

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr05/18AA1DBE-8753-4999-AA11-DE5723521D5D.png)

打开项目以后，它会识别到这个项目是使用了`pipenv`管理的，因此会弹出信息让我们安装支持`pipenv`的组件：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr05/325C6686-C345-4A3D-BF35-5EBAA69A70BC.png)

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr05/5DBFE9C6-5907-4259-9E05-C307BAB7C07A.png)

安装完成后，重新启动`PyCharm`，此时项目就可以加载我们使用`pipenv`安装的`gremlinpython`了。此时可以往项目里添加样例代码：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr05/25B87BF1-AF75-412A-B688-C6ADECB550EC.png)

上面的代码里面使用了`gremlinpython`的api去调用`gremlin-server`。此时可以试着运行这个代码，首先是保证gremlin服务端已经启动：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr05/138A4FD3-F4FD-4F1C-B48F-3EF794D33DD0.png)

如上所示gremlin服务已经启动，接下来要通过`gremlin-console`导入所需数据：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr05/0411B420-C362-4D6C-8941-C1CFBDF8397D.png)

如上所示导入数据后，在`PyCharm`里运行代码试试看：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr05/F93EA687-F5D0-41B2-921A-DC322103C8AB.png)

可以看到代码已经可以在`PyCharm`里正确执行了。

以上是对`PyCharm`和`pipenv`结合使用，管理`gremlinpython`应用项目的简单介绍。

这篇文章里使用的`PyCharm`样例项目，我放在了这里：

* [https://github.com/liweinan/gremlin-notebooks](https://github.com/liweinan/gremlin-notebooks) 

有兴趣的小伙伴可以clone下来看看。




